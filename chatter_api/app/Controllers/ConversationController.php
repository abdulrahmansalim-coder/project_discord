<?php

namespace App\Controllers;

use App\Models\ConversationModel;
use App\Models\ConversationParticipantModel;
use App\Models\MessageModel;

class ConversationController extends BaseController
{
    private ConversationModel            $convos;
    private ConversationParticipantModel $participants;
    private MessageModel                 $messages;

    public function __construct()
    {
        $this->convos       = new ConversationModel();
        $this->participants = new ConversationParticipantModel();
        $this->messages     = new MessageModel();
    }

    // GET /api/v1/conversations
    public function index()
    {
        $userId = $this->authUserId();

        // All conversation IDs the user belongs to
        $convIds = $this->participants
            ->where('user_id', $userId)
            ->findColumn('conversation_id') ?? [];

        if (empty($convIds)) return $this->ok([]);

        $convos = $this->convos->whereIn('id', $convIds)
            ->orderBy('updated_at', 'DESC')
            ->findAll();

        $result = array_map(fn($c) => $this->formatConversation($c, $userId), $convos);

        return $this->ok($result);
    }

    // POST /api/v1/conversations  (create group)
    public function create()
    {
        $body  = $this->jsonBody();
        $rules = [
            'name'            => 'required|min_length[2]|max_length[150]',
            'participant_ids' => 'required',
        ];

        if (!$this->validateData($body, $rules)) {
            return $this->badRequest('Validation failed', $this->validator->getErrors());
        }

        $userId = $this->authUserId();
        $ids    = array_unique(array_merge((array)$body['participant_ids'], [$userId]));

        $db = \Config\Database::connect();
        $db->transStart();

        $convoId = $this->convos->insert([
            'type'       => 'group',
            'name'       => $body['name'],
            'avatar_url' => $body['avatar_url'] ?? null,
            'created_by' => $userId,
        ]);

        foreach ($ids as $pid) {
            $this->participants->insert([
                'conversation_id' => $convoId,
                'user_id'         => $pid,
                'role'            => $pid == $userId ? 'admin' : 'member',
            ]);
        }

        $db->transComplete();

        $convo = $this->convos->find($convoId);
        return $this->created($this->formatConversation($convo, $userId));
    }

    // POST /api/v1/conversations/direct
    public function getOrCreateDirect()
    {
        $body = $this->jsonBody();
        if (empty($body['user_id'])) return $this->badRequest('user_id required');

        $userId   = $this->authUserId();
        $targetId = (int)$body['user_id'];

        if ($userId === $targetId) return $this->badRequest('Cannot start chat with yourself');

        // Check if direct convo already exists between these two
        $db = \Config\Database::connect();
        $existing = $db->query("
            SELECT c.* FROM conversations c
            JOIN conversation_participants p1 ON p1.conversation_id = c.id AND p1.user_id = ?
            JOIN conversation_participants p2 ON p2.conversation_id = c.id AND p2.user_id = ?
            WHERE c.type = 'direct'
            LIMIT 1
        ", [$userId, $targetId])->getResultArray();

        if (!empty($existing)) {
            return $this->ok($this->formatConversation($existing[0], $userId));
        }

        // Create new
        $db->transStart();
        $convoId = $this->convos->insert(['type' => 'direct', 'created_by' => $userId]);
        $this->participants->insert(['conversation_id' => $convoId, 'user_id' => $userId]);
        $this->participants->insert(['conversation_id' => $convoId, 'user_id' => $targetId]);
        $db->transComplete();

        return $this->created($this->formatConversation($this->convos->find($convoId), $userId));
    }

    // GET /api/v1/conversations/:id
    public function show($id = null)
    {
        $userId = $this->authUserId();
        if (!$this->isMember($id, $userId)) return $this->forbidden();

        $convo = $this->convos->find($id);
        if (!$convo) return $this->notFound();

        return $this->ok($this->formatConversation($convo, $userId));
    }

    // PUT /api/v1/conversations/:id
    public function update($id = null)
    {
        $userId = $this->authUserId();
        $part   = $this->participants->where('conversation_id', $id)->where('user_id', $userId)->first();
        if (!$part || $part['role'] !== 'admin') return $this->forbidden();

        $body = $this->jsonBody();
        $data = array_filter([
            'name'       => $body['name'] ?? null,
            'avatar_url' => $body['avatar_url'] ?? null,
        ], fn($v) => $v !== null);

        $this->convos->update($id, $data);
        return $this->ok($this->formatConversation($this->convos->find($id), $userId));
    }

    // DELETE /api/v1/conversations/:id
    public function destroy($id = null)
    {
        $userId = $this->authUserId();
        // Remove the user from the conversation (leave)
        $this->participants->where('conversation_id', $id)->where('user_id', $userId)->delete();
        return $this->ok(null, 'Left conversation');
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private function isMember(int $convoId, int $userId): bool
    {
        return (bool)$this->participants
            ->where('conversation_id', $convoId)
            ->where('user_id', $userId)
            ->first();
    }

    private function formatConversation(array $c, int $myId): array
    {
        $parts = $this->participants
            ->select('conversation_participants.*, users.name, users.username, users.avatar_url, users.status')
            ->join('users', 'users.id = conversation_participants.user_id')
            ->where('conversation_id', $c['id'])
            ->findAll();

        $myPart     = collect($parts)->firstWhere('user_id', $myId) ?? null;
        $lastMsg    = $this->messages
            ->where('conversation_id', $c['id'])
            ->where('is_deleted', 0)
            ->orderBy('created_at', 'DESC')
            ->first();

        // Unread count
        $lastReadAt = $myPart['last_read_at'] ?? null;
        $unreadCount = $lastReadAt
            ? $this->messages
                ->where('conversation_id', $c['id'])
                ->where('sender_id !=', $myId)
                ->where('created_at >', $lastReadAt)
                ->where('is_deleted', 0)
                ->countAllResults()
            : 0;

        return [
            'id'           => $c['id'],
            'type'         => $c['type'],
            'name'         => $c['name'],
            'avatar_url'   => $c['avatar_url'],
            'participants' => array_map(fn($p) => [
                'id'         => $p['user_id'],
                'name'       => $p['name'],
                'username'   => $p['username'],
                'avatar_url' => $p['avatar_url'],
                'status'     => $p['status'],
                'role'       => $p['role'],
            ], $parts),
            'last_message' => $lastMsg ? [
                'id'         => $lastMsg['id'],
                'content'    => $lastMsg['content'],
                'type'       => $lastMsg['type'],
                'sender_id'  => $lastMsg['sender_id'],
                'created_at' => $lastMsg['created_at'],
            ] : null,
            'unread_count' => $unreadCount,
            'is_muted'     => (bool)($myPart['is_muted'] ?? false),
            'updated_at'   => $c['updated_at'],
        ];
    }
}

// Tiny collection helper (no Laravel needed)
function collect(array $arr) {
    return new class($arr) {
        public function __construct(private array $items) {}
        public function firstWhere(string $key, mixed $value): ?array {
            foreach ($this->items as $item) {
                if (($item[$key] ?? null) == $value) return $item;
            }
            return null;
        }
    };
}

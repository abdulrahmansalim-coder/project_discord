<?php

namespace App\Controllers;

use App\Models\MessageModel;
use App\Models\MessageReadModel;
use App\Models\ConversationParticipantModel;
use App\Models\ConversationModel;

class MessageController extends BaseController
{
    private MessageModel                 $messages;
    private MessageReadModel             $reads;
    private ConversationParticipantModel $participants;
    private ConversationModel            $convos;

    public function __construct()
    {
        $this->messages     = new MessageModel();
        $this->reads        = new MessageReadModel();
        $this->participants = new ConversationParticipantModel();
        $this->convos       = new ConversationModel();
    }

    // GET /api/v1/conversations/:id/messages?page=1&limit=50
    public function index($convoId = null)
    {
        $userId = $this->authUserId();
        if (!$this->isMember($convoId, $userId)) return $this->forbidden();

        $page  = max(1, (int)($this->request->getGet('page') ?? 1));
        $limit = min(100, max(10, (int)($this->request->getGet('limit') ?? 50)));

        $messages = $this->messages
            ->select('messages.*, users.name as sender_name, users.avatar_url as sender_avatar')
            ->join('users', 'users.id = messages.sender_id')
            ->where('messages.conversation_id', $convoId)
            ->orderBy('messages.created_at', 'DESC')
            ->paginate($limit, 'default', $page);

        $total = $this->messages->where('conversation_id', $convoId)->countAllResults();

        return $this->ok([
            'messages'   => array_reverse(array_map([$this, 'formatMessage'], $messages)),
            'pagination' => [
                'page'        => $page,
                'limit'       => $limit,
                'total'       => $total,
                'total_pages' => ceil($total / $limit),
            ],
        ]);
    }

    // POST /api/v1/conversations/:id/messages
    public function send($convoId = null)
    {
        $userId = $this->authUserId();
        if (!$this->isMember($convoId, $userId)) return $this->forbidden();

        $body  = $this->jsonBody();
        $rules = [
            'content' => 'required|max_length[5000]',
            'type'    => 'permit_empty|in_list[text,image,audio,file,emoji]',
        ];

        if (!$this->validateData($body, $rules)) {
            return $this->badRequest('Validation failed', $this->validator->getErrors());
        }

        $type    = $body['type'] ?? 'text';
        $content = $body['content'];
        // For image messages, store URL in both content and media_url
        $mediaUrl = $body['media_url'] ?? ($type === 'image' ? $content : null);

        $msgId = $this->messages->insert([
            'conversation_id' => $convoId,
            'sender_id'       => $userId,
            'content'         => $content,
            'type'            => $type,
            'reply_to_id'     => $body['reply_to_id'] ?? null,
            'media_url'       => $mediaUrl,
        ]);

        // Touch conversation updated_at so it bubbles to top of list
        $this->convos->update($convoId, ['updated_at' => date('Y-m-d H:i:s')]);

        // Auto-mark as read for sender
        $this->reads->insert(['message_id' => $msgId, 'user_id' => $userId]);

        $msg = $this->messages
            ->select('messages.*, users.name as sender_name, users.avatar_url as sender_avatar')
            ->join('users', 'users.id = messages.sender_id')
            ->find($msgId);

        return $this->created($this->formatMessage($msg));
    }

    // PUT /api/v1/messages/:id
    public function update($msgId = null)
    {
        $userId = $this->authUserId();
        $msg    = $this->messages->find($msgId);

        if (!$msg) return $this->notFound();
        if ($msg['sender_id'] != $userId) return $this->forbidden('Cannot edit others\' messages');

        $body = $this->jsonBody();
        if (empty($body['content'])) return $this->badRequest('Content required');

        $this->messages->update($msgId, ['content' => $body['content']]);

        return $this->ok($this->formatMessage($this->messages
            ->select('messages.*, users.name as sender_name, users.avatar_url as sender_avatar')
            ->join('users', 'users.id = messages.sender_id')
            ->find($msgId)));
    }

    // DELETE /api/v1/messages/:id  (soft delete)
    public function destroy($msgId = null)
    {
        $userId = $this->authUserId();
        $msg    = $this->messages->find($msgId);

        if (!$msg) return $this->notFound();
        if ($msg['sender_id'] != $userId) return $this->forbidden();

        $this->messages->update($msgId, ['is_deleted' => 1, 'content' => 'This message was deleted']);
        return $this->ok(null, 'Message deleted');
    }

    // POST /api/v1/messages/:id/read
    public function markRead($msgId = null)
    {
        $userId = $this->authUserId();
        $msg    = $this->messages->find($msgId);
        if (!$msg) return $this->notFound();

        // Upsert
        $existing = $this->reads->where('message_id', $msgId)->where('user_id', $userId)->first();
        if (!$existing) {
            $this->reads->insert(['message_id' => $msgId, 'user_id' => $userId]);
        }

        return $this->ok(null, 'Marked as read');
    }

    // POST /api/v1/conversations/:id/read-all
    public function markAllRead($convoId = null)
    {
        $userId = $this->authUserId();
        if (!$this->isMember($convoId, $userId)) return $this->forbidden();

        $this->participants
            ->where('conversation_id', $convoId)
            ->where('user_id', $userId)
            ->set(['last_read_at' => date('Y-m-d H:i:s')])
            ->update();

        return $this->ok(null, 'All messages marked as read');
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private function isMember(int $convoId, int $userId): bool
    {
        return (bool)$this->participants
            ->where('conversation_id', $convoId)
            ->where('user_id', $userId)
            ->first();
    }

    private function formatMessage(array $m): array
    {
        $readCount = $this->reads->where('message_id', $m['id'])->countAllResults();
        return [
            'id'              => $m['id'],
            'conversation_id' => $m['conversation_id'],
            'sender_id'       => $m['sender_id'],
            'sender_name'     => $m['sender_name'] ?? null,
            'sender_avatar'   => $m['sender_avatar'] ?? null,
            'reply_to_id'     => $m['reply_to_id'],
            'type'            => $m['type'],
            'content'         => $m['is_deleted'] ? 'This message was deleted' : $m['content'],
            'media_url'       => $m['media_url'],
            'is_deleted'      => (bool)$m['is_deleted'],
            'read_count'      => $readCount,
            'created_at'      => $m['created_at'],
            'updated_at'      => $m['updated_at'],
        ];
    }
}

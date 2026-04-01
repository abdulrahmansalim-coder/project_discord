<?php

namespace App\Controllers;

use App\Models\UserModel;

class UserController extends BaseController
{
    private UserModel $users;

    public function __construct()
    {
        $this->users = new UserModel();
    }

    // GET /api/v1/users/me
    public function me()
    {
        $user = $this->users->find($this->authUserId());
        if (!$user) return $this->notFound('User not found');
        return $this->ok($this->formatUser($user));
    }

    // PUT /api/v1/users/me
    public function updateProfile()
    {
        $body  = $this->jsonBody();
        $rules = [
            'name'           => 'permit_empty|min_length[2]|max_length[100]',
            'status_message' => 'permit_empty|max_length[150]',
            'avatar_url'     => 'permit_empty|valid_url|max_length[500]',
        ];

        if (!$this->validateData($body, $rules)) {
            return $this->badRequest('Validation failed', $this->validator->getErrors());
        }

        $data = array_filter([
            'name'           => $body['name'] ?? null,
            'status_message' => $body['status_message'] ?? null,
            'avatar_url'     => $body['avatar_url'] ?? null,
        ], fn($v) => $v !== null);

        $this->users->update($this->authUserId(), $data);
        return $this->ok($this->formatUser($this->users->find($this->authUserId())));
    }

    // PUT /api/v1/users/me/status
    public function updateStatus()
    {
        $body = $this->jsonBody();
        $allowed = ['online', 'away', 'offline'];

        if (!in_array($body['status'] ?? '', $allowed)) {
            return $this->badRequest('Status must be one of: ' . implode(', ', $allowed));
        }

        $this->users->update($this->authUserId(), [
            'status'       => $body['status'],
            'last_seen_at' => date('Y-m-d H:i:s'),
        ]);

        return $this->ok(['status' => $body['status']]);
    }

    // GET /api/v1/users/search?q=name
    public function search()
    {
        $q = trim($this->request->getGet('q') ?? '');
        if (strlen($q) < 2) {
            return $this->badRequest('Query must be at least 2 characters');
        }

        $users = $this->users
            ->like('name', $q)
            ->orLike('username', $q)
            ->where('id !=', $this->authUserId())
            ->where('is_active', 1)
            ->findAll(20);

        return $this->ok(array_map([$this, 'formatUser'], $users));
    }

    // GET /api/v1/users/:id
    public function show($id = null)
    {
        $user = $this->users->find($id);
        if (!$user) return $this->notFound();
        return $this->ok($this->formatUser($user));
    }

    // ── Helper ────────────────────────────────────────────────────────────────

    private function formatUser(array $u): array
    {
        return [
            'id'             => $u['id'],
            'name'           => $u['name'],
            'username'       => $u['username'],
            'avatar_url'     => $u['avatar_url'],
            'status'         => $u['status'],
            'status_message' => $u['status_message'],
            'last_seen_at'   => $u['last_seen_at'],
        ];
    }
}

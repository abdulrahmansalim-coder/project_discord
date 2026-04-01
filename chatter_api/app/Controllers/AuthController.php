<?php

namespace App\Controllers;

use App\Models\UserModel;
use App\Models\AuthTokenModel;
use App\Services\JwtService;

class AuthController extends BaseController
{
    private UserModel      $users;
    private AuthTokenModel $tokens;
    private JwtService     $jwt;

    public function __construct()
    {
        $this->users  = new UserModel();
        $this->tokens = new AuthTokenModel();
        $this->jwt    = new JwtService();
    }

    // POST /api/v1/auth/register
    public function register()
    {
        $body = $this->jsonBody();

        $rules = [
            'name'     => 'required|min_length[2]|max_length[100]',
            'username' => 'required|min_length[3]|max_length[50]|alpha_dash|is_unique[users.username]',
            'email'    => 'required|valid_email|is_unique[users.email]',
            'password' => 'required|min_length[8]',
        ];

        if (!$this->validateData($body, $rules)) {
            return $this->badRequest('Validation failed', $this->validator->getErrors());
        }

        $userId = $this->users->insert([
            'name'          => trim($body['name']),
            'username'      => strtolower(trim($body['username'])),
            'email'         => strtolower(trim($body['email'])),
            'password_hash' => password_hash($body['password'], PASSWORD_BCRYPT),
        ]);

        if (!$userId) {
            return $this->serverError('Could not create user');
        }

        $user = $this->users->find($userId);
        [$accessToken, $refreshToken] = $this->issueTokens($userId);

        return $this->created([
            'user'          => $this->formatUser($user),
            'access_token'  => $accessToken,
            'refresh_token' => $refreshToken,
            'expires_in'    => (int) env('JWT_EXPIRE', 3600),
        ], 'Registration successful');
    }

    // POST /api/v1/auth/login
    public function login()
    {
        $body = $this->jsonBody();

        if (empty($body['email']) || empty($body['password'])) {
            return $this->badRequest('Email and password are required');
        }

        $user = $this->users->where('email', strtolower(trim($body['email'])))->first();

        if (!$user || !password_verify($body['password'], $user['password_hash'])) {
            return $this->unauthorized('Invalid credentials');
        }

        if (!$user['is_active']) {
            return $this->forbidden('Account is disabled');
        }

        // Update status to online
        $this->users->update($user['id'], [
            'status'       => 'online',
            'last_seen_at' => date('Y-m-d H:i:s'),
        ]);

        [$accessToken, $refreshToken] = $this->issueTokens($user['id'], $body['device_name'] ?? null);

        return $this->ok([
            'user'          => $this->formatUser($user),
            'access_token'  => $accessToken,
            'refresh_token' => $refreshToken,
            'expires_in'    => (int) env('JWT_EXPIRE', 3600),
        ], 'Login successful');
    }

    // POST /api/v1/auth/refresh
    public function refresh()
    {
        $body  = $this->jsonBody();
        $token = $body['refresh_token'] ?? '';

        if (!$token) {
            return $this->badRequest('Refresh token required');
        }

        $record = $this->tokens
            ->where('token', $token)
            ->where('expires_at >', date('Y-m-d H:i:s'))
            ->first();

        if (!$record) {
            return $this->unauthorized('Invalid or expired refresh token');
        }

        // Rotate: delete old, issue new
        $this->tokens->delete($record['id']);
        [$accessToken, $refreshToken] = $this->issueTokens($record['user_id']);

        return $this->ok([
            'access_token'  => $accessToken,
            'refresh_token' => $refreshToken,
            'expires_in'    => (int) env('JWT_EXPIRE', 3600),
        ]);
    }

    // POST /api/v1/auth/logout
    public function logout()
    {
        $body  = $this->jsonBody();
        $token = $body['refresh_token'] ?? '';

        if ($token) {
            $this->tokens->where('token', $token)->delete();
        }

        // Set user offline
        $this->users->update($this->authUserId(), [
            'status'       => 'offline',
            'last_seen_at' => date('Y-m-d H:i:s'),
        ]);

        return $this->ok(null, 'Logged out');
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private function issueTokens(int $userId, ?string $deviceName = null): array
    {
        $accessToken  = $this->jwt->generateAccessToken(['sub' => $userId]);
        $refreshToken = $this->jwt->generateRefreshToken();
        $expire       = (int) env('JWT_REFRESH_EXPIRE', 604800);

        $this->tokens->insert([
            'user_id'     => $userId,
            'token'       => $refreshToken,
            'device_name' => $deviceName,
            'expires_at'  => date('Y-m-d H:i:s', time() + $expire),
        ]);

        return [$accessToken, $refreshToken];
    }

    private function formatUser(array $user): array
    {
        return [
            'id'         => $user['id'],
            'name'       => $user['name'],
            'username'   => $user['username'],
            'email'      => $user['email'],
            'avatar_url' => $user['avatar_url'],
            'status'     => $user['status'],
        ];
    }
}

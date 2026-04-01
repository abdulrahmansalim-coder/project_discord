<?php

namespace App\Services;

/**
 * Lightweight JWT implementation (no external library needed).
 * Uses HS256 (HMAC-SHA256).
 */
class JwtService
{
    private string $secret;
    private int    $expire;

    public function __construct()
    {
        $this->secret = env('JWT_SECRET', 'change_me');
        $this->expire  = (int) env('JWT_EXPIRE', 3600);
    }

    // ── Generate access token ─────────────────────────────────────────────────

    public function generateAccessToken(array $payload): string
    {
        $payload['exp'] = time() + $this->expire;
        $payload['iat'] = time();
        $payload['type'] = 'access';
        return $this->encode($payload);
    }

    // ── Generate refresh token (random, stored in DB) ─────────────────────────

    public function generateRefreshToken(): string
    {
        return bin2hex(random_bytes(40));
    }

    // ── Decode & verify ───────────────────────────────────────────────────────

    public function decode(string $token): ?array
    {
        $parts = explode('.', $token);
        if (count($parts) !== 3) return null;

        [$headerB64, $payloadB64, $sigB64] = $parts;

        $sig = $this->base64UrlDecode($sigB64);
        $expected = hash_hmac('sha256', "$headerB64.$payloadB64", $this->secret, true);

        if (!hash_equals($expected, $sig)) return null;

        $payload = json_decode($this->base64UrlDecode($payloadB64), true);
        if (!$payload) return null;

        if (isset($payload['exp']) && $payload['exp'] < time()) return null;

        return $payload;
    }

    // ── Internal helpers ──────────────────────────────────────────────────────

    private function encode(array $payload): string
    {
        $header  = $this->base64UrlEncode(json_encode(['alg' => 'HS256', 'typ' => 'JWT']));
        $body    = $this->base64UrlEncode(json_encode($payload));
        $sig     = $this->base64UrlEncode(
            hash_hmac('sha256', "$header.$body", $this->secret, true)
        );
        return "$header.$body.$sig";
    }

    private function base64UrlEncode(string $data): string
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    private function base64UrlDecode(string $data): string
    {
        return base64_decode(strtr($data, '-_', '+/') . str_repeat('=', (4 - strlen($data) % 4) % 4));
    }
}

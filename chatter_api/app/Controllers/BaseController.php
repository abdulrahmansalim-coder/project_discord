<?php

namespace App\Controllers;

use CodeIgniter\RESTful\ResourceController;

class BaseController extends ResourceController
{
    // ── Standard responses ────────────────────────────────────────────────────

    protected function ok($data = null, string $message = 'Success', int $code = 200)
    {
        $body = ['status' => 'success', 'message' => $message];
        if ($data !== null) $body['data'] = $data;
        return $this->response->setStatusCode($code)->setJSON($body);
    }

    protected function created($data = null, string $message = 'Created')
    {
        return $this->ok($data, $message, 201);
    }

    protected function badRequest(string $message = 'Bad Request', $errors = null)
    {
        $body = ['status' => 'error', 'message' => $message];
        if ($errors) $body['errors'] = $errors;
        return $this->response->setStatusCode(400)->setJSON($body);
    }

    protected function unauthorized(string $message = 'Unauthorized')
    {
        return $this->response->setStatusCode(401)->setJSON(['status' => 'error', 'message' => $message]);
    }

    protected function forbidden(string $message = 'Forbidden')
    {
        return $this->response->setStatusCode(403)->setJSON(['status' => 'error', 'message' => $message]);
    }

    protected function notFound(string $message = 'Not found')
    {
        return $this->response->setStatusCode(404)->setJSON(['status' => 'error', 'message' => $message]);
    }

    protected function serverError(string $message = 'Server error')
    {
        return $this->response->setStatusCode(500)->setJSON(['status' => 'error', 'message' => $message]);
    }

    // ── Auth helper ───────────────────────────────────────────────────────────

    protected function authUserId(): int
    {
        return (int) $this->request->user_id;
    }

    // ── JSON body helper ──────────────────────────────────────────────────────

    protected function jsonBody(): array
    {
        return (array) $this->request->getJSON(true);
    }
}

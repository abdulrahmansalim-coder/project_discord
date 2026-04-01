<?php

namespace App\Controllers;

use App\Models\ContactModel;
use App\Models\UserModel;

class ContactController extends BaseController
{
    private ContactModel $contacts;
    private UserModel    $users;

    public function __construct()
    {
        $this->contacts = new ContactModel();
        $this->users    = new UserModel();
    }

    // GET /api/v1/contacts — accepted contacts
    public function index()
    {
        $userId = $this->authUserId();

        $contacts = $this->contacts
            ->select('contacts.*, users.name, users.username, users.avatar_url, users.status, users.status_message, users.last_seen_at')
            ->join('users', 'users.id = contacts.contact_id')
            ->where('contacts.user_id', $userId)
            ->where('contacts.status', 'accepted')
            ->findAll();

        return $this->ok(array_map(fn($c) => [
            'id'             => $c['contact_id'],
            'name'           => $c['name'],
            'username'       => $c['username'],
            'avatar_url'     => $c['avatar_url'],
            'status'         => $c['status'],
            'status_message' => $c['status_message'],
            'last_seen_at'   => $c['last_seen_at'],
        ], $contacts));
    }

    // GET /api/v1/contacts/requests — incoming pending requests
    public function requests()
    {
        $userId = $this->authUserId();

        $requests = $this->contacts
            ->select('contacts.*, users.name, users.username, users.avatar_url, users.status')
            ->join('users', 'users.id = contacts.user_id')
            ->where('contacts.contact_id', $userId)
            ->where('contacts.status', 'pending')
            ->findAll();

        return $this->ok(array_map(fn($r) => [
            'id'         => $r['user_id'],
            'name'       => $r['name'],
            'username'   => $r['username'],
            'avatar_url' => $r['avatar_url'],
            'status'     => $r['status'],
        ], $requests));
    }

    // POST /api/v1/contacts — send request (auto-accepts for simplicity)
    public function sendRequest()
    {
        $body = $this->jsonBody();
        if (empty($body['user_id'])) return $this->badRequest('user_id required');

        $userId    = $this->authUserId();
        $contactId = (int)$body['user_id'];

        if ($userId === $contactId) return $this->badRequest('Cannot add yourself');
        if (!$this->users->find($contactId)) return $this->notFound('User not found');

        // Check if already exists in any form
        $existing = $this->contacts
            ->where('user_id', $userId)
            ->where('contact_id', $contactId)
            ->first();

        if ($existing) {
            if ($existing['status'] === 'accepted') {
                return $this->badRequest('Already in your contacts');
            }
            return $this->badRequest('Request already sent');
        }

        // Insert both directions as accepted immediately (no pending step)
        $this->contacts->insert(['user_id' => $userId,    'contact_id' => $contactId, 'status' => 'accepted']);
        $this->contacts->insert(['user_id' => $contactId, 'contact_id' => $userId,    'status' => 'accepted']);

        // Return the added user's info
        $user = $this->users->find($contactId);
        return $this->created([
            'id'         => $user['id'],
            'name'       => $user['name'],
            'username'   => $user['username'],
            'avatar_url' => $user['avatar_url'],
            'status'     => $user['status'],
        ], 'Contact added successfully');
    }

    // PUT /api/v1/contacts/:id/accept
    public function accept($contactUserId = null)
    {
        $userId = $this->authUserId();

        $request = $this->contacts
            ->where('user_id', $contactUserId)
            ->where('contact_id', $userId)
            ->where('status', 'pending')
            ->first();

        if (!$request) return $this->notFound('No pending request found');

        $this->contacts->update($request['id'], ['status' => 'accepted']);

        // Add reverse direction
        $reverse = $this->contacts
            ->where('user_id', $userId)
            ->where('contact_id', $contactUserId)
            ->first();
        if (!$reverse) {
            $this->contacts->insert(['user_id' => $userId, 'contact_id' => $contactUserId, 'status' => 'accepted']);
        } else {
            $this->contacts->update($reverse['id'], ['status' => 'accepted']);
        }

        return $this->ok(null, 'Contact accepted');
    }

    // DELETE /api/v1/contacts/:id
    public function destroy($contactId = null)
    {
        $userId = $this->authUserId();
        $this->contacts->where('user_id', $userId)->where('contact_id', $contactId)->delete();
        $this->contacts->where('user_id', $contactId)->where('contact_id', $userId)->delete();
        return $this->ok(null, 'Contact removed');
    }

    // PUT /api/v1/contacts/:id/block
    public function block($contactId = null)
    {
        $userId = $this->authUserId();
        $this->contacts
            ->where('user_id', $userId)
            ->where('contact_id', $contactId)
            ->set(['status' => 'blocked'])
            ->update();
        return $this->ok(null, 'User blocked');
    }
}

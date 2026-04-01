<?php

namespace App\Controllers;

use App\Models\StoryModel;
use App\Models\StoryViewModel;

class StoryController extends BaseController
{
    private StoryModel     $stories;
    private StoryViewModel $views;

    public function __construct()
    {
        $this->stories = new StoryModel();
        $this->views   = new StoryViewModel();
    }

    // GET /api/v1/stories  — stories from contacts (last 24h)
    public function index()
    {
        $userId = $this->authUserId();

        $stories = $this->stories
            ->select('stories.*, users.name as user_name, users.username, users.avatar_url')
            ->join('users', 'users.id = stories.user_id')
            ->where('stories.expires_at >', date('Y-m-d H:i:s'))
            ->orderBy('stories.created_at', 'DESC')
            ->findAll();

        $result = array_map(function ($s) use ($userId) {
            $viewed = (bool)$this->views
                ->where('story_id', $s['id'])
                ->where('viewer_id', $userId)
                ->first();

            $viewCount = $this->views->where('story_id', $s['id'])->countAllResults();

            return [
                'id'         => $s['id'],
                'user'       => [
                    'id'         => $s['user_id'],
                    'name'       => $s['user_name'],
                    'username'   => $s['username'],
                    'avatar_url' => $s['avatar_url'],
                ],
                'type'       => $s['type'],
                'content'    => $s['content'],
                'media_url'  => $s['media_url'],
                'bg_color'   => $s['bg_color'],
                'viewed'     => $viewed,
                'view_count' => $viewCount,
                'expires_at' => $s['expires_at'],
                'created_at' => $s['created_at'],
            ];
        }, $stories);

        return $this->ok($result);
    }

    // POST /api/v1/stories
    public function create()
    {
        $body  = $this->jsonBody();
        $rules = [
            'type'     => 'required|in_list[text,image,video]',
            'content'  => 'permit_empty|max_length[500]',
            'media_url'=> 'permit_empty|valid_url',
        ];

        if (!$this->validateData($body, $rules)) {
            return $this->badRequest('Validation failed', $this->validator->getErrors());
        }

        $storyId = $this->stories->insert([
            'user_id'    => $this->authUserId(),
            'type'       => $body['type'],
            'content'    => $body['content'] ?? null,
            'media_url'  => $body['media_url'] ?? null,
            'bg_color'   => $body['bg_color'] ?? '#6C63FF',
            'expires_at' => date('Y-m-d H:i:s', strtotime('+24 hours')),
        ]);

        return $this->created(['id' => $storyId], 'Story created');
    }

    // DELETE /api/v1/stories/:id
    public function destroy($id = null)
    {
        $story = $this->stories->find($id);
        if (!$story) return $this->notFound();
        if ($story['user_id'] != $this->authUserId()) return $this->forbidden();

        $this->stories->delete($id);
        return $this->ok(null, 'Story deleted');
    }

    // POST /api/v1/stories/:id/view
    public function markViewed($id = null)
    {
        $userId   = $this->authUserId();
        $existing = $this->views->where('story_id', $id)->where('viewer_id', $userId)->first();
        if (!$existing) {
            $this->views->insert(['story_id' => $id, 'viewer_id' => $userId]);
        }
        return $this->ok(null, 'Viewed');
    }
}

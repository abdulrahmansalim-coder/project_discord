<?php namespace App\Models;
use CodeIgniter\Model;

class StoryViewModel extends Model {
    protected $table         = 'story_views';
    protected $primaryKey    = 'id';
    protected $allowedFields = ['story_id','viewer_id','viewed_at'];
    protected $useTimestamps = false;
}

<?php namespace App\Models;
use CodeIgniter\Model;

class StoryModel extends Model {
    protected $table         = 'stories';
    protected $primaryKey    = 'id';
    protected $allowedFields = ['user_id','type','content','media_url','bg_color','expires_at'];
    protected $useTimestamps = true;
    protected $createdField  = 'created_at';
    protected $updatedField  = '';
}

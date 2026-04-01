<?php namespace App\Models;
use CodeIgniter\Model;

class ConversationModel extends Model {
    protected $table         = 'conversations';
    protected $primaryKey    = 'id';
    protected $allowedFields = ['type','name','avatar_url','created_by','updated_at'];
    protected $useTimestamps = true;
}

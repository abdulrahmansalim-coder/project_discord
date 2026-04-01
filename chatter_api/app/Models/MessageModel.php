<?php namespace App\Models;
use CodeIgniter\Model;

class MessageModel extends Model {
    protected $table         = 'messages';
    protected $primaryKey    = 'id';
    protected $allowedFields = ['conversation_id','sender_id','reply_to_id','type','content','media_url','is_deleted'];
    protected $useTimestamps = true;
}

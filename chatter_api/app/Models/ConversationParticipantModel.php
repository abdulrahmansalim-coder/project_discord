<?php namespace App\Models;
use CodeIgniter\Model;

class ConversationParticipantModel extends Model {
    protected $table         = 'conversation_participants';
    protected $primaryKey    = 'id';
    protected $allowedFields = ['conversation_id','user_id','role','last_read_at','is_muted'];
    protected $useTimestamps = false;
}

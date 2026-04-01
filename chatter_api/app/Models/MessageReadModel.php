<?php namespace App\Models;
use CodeIgniter\Model;

class MessageReadModel extends Model {
    protected $table         = 'message_reads';
    protected $primaryKey    = 'id';
    protected $allowedFields = ['message_id','user_id','read_at'];
    protected $useTimestamps = false;
}

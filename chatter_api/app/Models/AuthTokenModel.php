<?php namespace App\Models;
use CodeIgniter\Model;

class AuthTokenModel extends Model {
    protected $table         = 'auth_tokens';
    protected $primaryKey    = 'id';
    protected $allowedFields = ['user_id','token','device_name','expires_at'];
    protected $useTimestamps = false;
}

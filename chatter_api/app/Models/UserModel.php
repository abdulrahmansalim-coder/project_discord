<?php
// ── UserModel ─────────────────────────────────────────────────────────────────
namespace App\Models;
use CodeIgniter\Model;

class UserModel extends Model {
    protected $table         = 'users';
    protected $primaryKey    = 'id';
    protected $allowedFields = ['name','username','email','password_hash','avatar_url','status','status_message','last_seen_at','is_active'];
    protected $useTimestamps = true;
    protected $hidden        = ['password_hash'];
}

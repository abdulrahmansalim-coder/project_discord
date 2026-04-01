<?php namespace App\Models;
use CodeIgniter\Model;

class ContactModel extends Model {
    protected $table         = 'contacts';
    protected $primaryKey    = 'id';
    protected $allowedFields = ['user_id','contact_id','status'];
    protected $useTimestamps = true;
}

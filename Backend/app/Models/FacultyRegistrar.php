<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class FacultyRegistrar extends Model
{
    protected $table = 'facultyregistrar';
    protected $primaryKey = 'FacultyRegistrar_ID';
    public $incrementing = true;
    public $timestamps = false;

    protected $fillable = [
        'User_ID',
        'Faculty',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'User_ID');
    }

    public function schedules()
    {
        return $this->hasMany(RegistrationSchedule::class, 'FacultyRegistrar_ID');
    }
}
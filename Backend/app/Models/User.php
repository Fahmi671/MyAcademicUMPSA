<?php

namespace App\Models;

use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $table = 'user';
    protected $primaryKey = 'User_ID';
    public $incrementing = true;
    public $timestamps = false;

    protected $fillable = [
        'User_FullName',
        'User_Email',
        'User_Password',
        'User_PhoneNumber',
        'User_Gender',
        'User_Age',
        'User_Role',
    ];

    protected $hidden = [
        'User_Password',
    ];

    public function student()
    {
        return $this->hasOne(Student::class, 'User_ID');
    }

    public function lecturer()
    {
        return $this->hasOne(Lecturer::class, 'User_ID');
    }

    public function facultyRegistrar()
    {
        return $this->hasOne(FacultyRegistrar::class, 'User_ID');
    }

    public function pusatAdab()
    {
        return $this->hasOne(PusatAdab::class, 'User_ID');
    }
}

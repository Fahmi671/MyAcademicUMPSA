<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Lecturer extends Model
{
    protected $table = 'lecturer';
    protected $primaryKey = 'Lecturer_ID';
    public $incrementing = true;
    public $timestamps = false;

    protected $fillable = [
        'User_ID',
        'Faculty',
        'Office_Room',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'User_ID');
    }

    public function subjects()
    {
        return $this->hasMany(Subject::class, 'Lecturer_ID');
    }
}
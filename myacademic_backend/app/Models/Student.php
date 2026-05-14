<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Student extends Model
{
    protected $table = 'student';
    protected $primaryKey = 'Student_ID';
    public $incrementing = false; // VARCHAR(10)
    protected $keyType = 'string';
    public $timestamps = false;

    protected $fillable = [
        'Student_ID',
        'User_ID',
        'Faculty',
        'Programme',
        'Year_of_Study',
        'Academic_Status',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'User_ID');
    }

    public function enrollments()
    {
        return $this->hasMany(SubjectEnrollment::class, 'Student_ID');
    }
}

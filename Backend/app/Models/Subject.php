<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Subject extends Model
{
    protected $table = 'subject';
    protected $primaryKey = 'Subject_ID';
    public $incrementing = true;
    public $timestamps = false;

    protected $fillable = [
        'Subject_Code',
        'Subject_Name',
        'Credit_Hours',
        'Lecturer_ID',
        'Day',
        'Time',
        'Venue',
        'Quota',
        'Section',
        'Lab',
    ];

    public function lecturer()
    {
        return $this->belongsTo(Lecturer::class, 'Lecturer_ID');
    }

    public function enrollments()
    {
        return $this->hasMany(SubjectEnrollment::class, 'Subject_ID', 'Subject_ID');
    }

    public function attendanceSessions()
    {
        return $this->hasMany(AttendanceSession::class, 'subject_id', 'Subject_ID');
    }
}
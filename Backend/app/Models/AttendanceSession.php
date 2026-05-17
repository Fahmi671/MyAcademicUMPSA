<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AttendanceSession extends Model
{
    protected $fillable = [
        'subject_id',
        'activity_id',
        'session_type',
        'attendance_code',
        'time_limit',
        'status',
        'opened_at',
    ];

    public function subject()
    {
        return $this->belongsTo(Subject::class, 'subject_id', 'Subject_ID');
    }

    public function records()
    {
        return $this->hasMany(AttendanceRecord::class, 'session_id');
    }
}
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SubjectEnrollment extends Model
{
    protected $table = 'subjectenrollment';
    protected $primaryKey = 'Enrollment_ID';
    public $timestamps = false;

    protected $fillable = [
        'Student_ID',
        'Subject_Code',
        'Subject_ID',
        'Enrollment_Date',
    ];

    public function student()
    {
        return $this->belongsTo(Student::class, 'Student_ID');
    }

    public function subject()
    {
        if (array_key_exists('Subject_ID', $this->attributes) && $this->attributes['Subject_ID'] !== null) {
            return $this->belongsTo(Subject::class, 'Subject_ID', 'Subject_ID');
        }

        return $this->belongsTo(Subject::class, 'Subject_Code', 'Subject_Code');
    }
}

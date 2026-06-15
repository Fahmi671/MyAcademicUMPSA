<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Notification extends Model
{
    protected $table = 'notification';
    protected $primaryKey = 'Notification_ID';
    public $timestamps = false;

    protected $fillable = [
        'Student_ID',
        'Title',
        'Message',
        'Is_Read',
        'Created_At'
    ];

    protected $casts = [
        'Is_Read' => 'boolean',
        'Created_At' => 'datetime',
    ];

    public function student()
    {
        return $this->belongsTo(Student::class, 'Student_ID', 'Student_ID');
    }
}

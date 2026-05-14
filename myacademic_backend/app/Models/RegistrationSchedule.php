<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RegistrationSchedule extends Model
{
    protected $table = 'registrationschedule';
    protected $primaryKey = 'Schedule_ID';
    public $timestamps = false;

    protected $fillable = [
        'FacultyRegistrar_ID',
        'Year_of_Study',
        'Start_Date',
        'End_Date',
        'Start_Time',
        'End_Time',
    ];

    public function facultyRegistrar()
    {
        return $this->belongsTo(FacultyRegistrar::class, 'FacultyRegistrar_ID');
    }
}
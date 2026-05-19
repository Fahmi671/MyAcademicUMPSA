<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Participation extends Model
{
    protected $table = 'participation';
    protected $primaryKey = 'Participation_ID';

    public $timestamps = false;

    protected $fillable = [
        'Student_ID',
        'Activity_ID',
        'Registered_At',
        'Registration_Status',
    ];
}
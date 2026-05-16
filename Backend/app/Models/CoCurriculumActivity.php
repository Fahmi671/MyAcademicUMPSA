<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CoCurriculumActivity extends Model
{
    protected $table = 'cocurriculum_activity';
    protected $primaryKey = 'Activity_ID';

    public $incrementing = false;
    protected $keyType = 'string';
    public $timestamps = false;

    protected $fillable = [
        'Activity_ID',
        'PusatAdab_ID',
        'Module_Code',
        'Module_Name',
        'Campus',
        'Venue',
        'Activity_Date',
        'Activity_Time',
        'Capacity',
        'Available_Slots',
        'Status',
        'Description',
    ];
}
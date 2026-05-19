<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CreditClaim extends Model
{
    protected $table = 'credit_claim';
    protected $primaryKey = 'Claim_ID';

    public $timestamps = false;

    protected $fillable = [
        'PusatAdab_ID',
        'Participation_ID',
        'Attendance_Status',
        'Claim_Status',
        'Remarks',
        'Created_At',
    ];
}
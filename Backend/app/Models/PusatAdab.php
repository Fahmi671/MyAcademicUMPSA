<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PusatAdab extends Model
{
    protected $table = 'pusat_adab';
    protected $primaryKey = 'PusatAdab_ID';

    public $incrementing = false;
    protected $keyType = 'string';
    public $timestamps = false;

    protected $fillable = [
        'PusatAdab_ID',
        'User_ID',
    ];
}
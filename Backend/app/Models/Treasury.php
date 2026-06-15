<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Treasury extends Model
{
    protected $table = 'treasury';
    protected $primaryKey = 'Treasury_ID';
    public $timestamps = false;

    protected $fillable = [
        'User_ID',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'User_ID');
    }

    public function ledger()
    {
        return $this->hasMany(TuitionFee::class, 'Treasury_ID');
    }
}

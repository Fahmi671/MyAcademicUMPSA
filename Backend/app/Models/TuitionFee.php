<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TuitionFee extends Model
{
    protected $table = 'tuition_fee';
    protected $primaryKey = 'TuitionFee_ID';
    public $timestamps = false; // We use custom timestamp fields

    protected $fillable = [
        'Student_ID',
        'Total_Invoice',
        'Balance',
        'Payment_Status',
        'Academic_Access',
        'Created_At',
        'Updated_At'
    ];

    protected $casts = [
        'Total_Invoice' => 'decimal:2',
        'Balance' => 'decimal:2',
        'Created_At' => 'datetime',
        'Updated_At' => 'datetime',
    ];

    public function student()
    {
        return $this->belongsTo(Student::class, 'Student_ID', 'Student_ID');
    }

    public function transactions()
    {
        return $this->hasMany(PaymentTransaction::class, 'TuitionFee_ID', 'TuitionFee_ID');
    }
}

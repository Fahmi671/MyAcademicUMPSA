<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PaymentTransaction extends Model
{
    protected $table = 'payment_transaction';
    protected $primaryKey = 'Transaction_ID';
    public $timestamps = false;

    protected $fillable = [
        'TuitionFee_ID',
        'Student_ID',
        'Amount_Paid',
        'Payment_Method',
        'Bank_Name',
        'Remarks',
        'Transaction_Date',
        'Transaction_Status'
    ];

    protected $casts = [
        'Amount_Paid' => 'decimal:2',
        'Transaction_Date' => 'datetime',
    ];

    public function tuitionFee()
    {
        return $this->belongsTo(TuitionFee::class, 'TuitionFee_ID', 'TuitionFee_ID');
    }

    public function student()
    {
        return $this->belongsTo(Student::class, 'Student_ID', 'Student_ID');
    }
}

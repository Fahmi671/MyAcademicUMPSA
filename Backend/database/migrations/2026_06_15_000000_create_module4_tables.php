<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('treasury', function (Blueprint $table) {
            $table->id('Treasury_ID');
            $table->unsignedBigInteger('User_ID');
            // Foreign key relation can be added if User_ID exists in user table
            // $table->foreign('User_ID')->references('User_ID')->on('user')->onDelete('cascade');
        });

        Schema::create('tuition_fee', function (Blueprint $table) {
            $table->id('TuitionFee_ID');
            $table->string('Student_ID', 10);
            $table->decimal('Total_Invoice', 10, 2);
            $table->decimal('Balance', 10, 2);
            $table->string('Payment_Status', 20)->default('Unpaid');
            $table->string('Academic_Access', 10)->default('Active');
            $table->timestamp('Created_At')->useCurrent();
            $table->timestamp('Updated_At')->useCurrent()->useCurrentOnUpdate();

            // Foreign key to student table
            // $table->foreign('Student_ID')->references('Student_ID')->on('student')->onDelete('cascade');
        });

        Schema::create('payment_transaction', function (Blueprint $table) {
            $table->id('Transaction_ID');
            $table->unsignedBigInteger('TuitionFee_ID');
            $table->string('Student_ID', 10);
            $table->decimal('Amount_Paid', 10, 2);
            $table->string('Payment_Method', 50);
            $table->string('Bank_Name', 100);
            $table->text('Remarks')->nullable();
            $table->timestamp('Transaction_Date')->useCurrent();
            $table->string('Transaction_Status', 20)->default('Success');

            // Foreign keys
            // $table->foreign('TuitionFee_ID')->references('TuitionFee_ID')->on('tuition_fee')->onDelete('cascade');
            // $table->foreign('Student_ID')->references('Student_ID')->on('student')->onDelete('cascade');
        });

        Schema::create('notification', function (Blueprint $table) {
            $table->id('Notification_ID');
            $table->string('Student_ID', 10);
            $table->string('Title', 100);
            $table->text('Message');
            $table->boolean('Is_Read')->default(false);
            $table->timestamp('Created_At')->useCurrent();

            // Foreign key
            // $table->foreign('Student_ID')->references('Student_ID')->on('student')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('notification');
        Schema::dropIfExists('payment_transaction');
        Schema::dropIfExists('tuition_fee');
        Schema::dropIfExists('treasury');
    }
};

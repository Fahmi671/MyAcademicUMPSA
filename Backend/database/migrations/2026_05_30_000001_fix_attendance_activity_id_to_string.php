<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('attendance_sessions')) {
            DB::statement('ALTER TABLE attendance_sessions MODIFY activity_id VARCHAR(20) NULL');
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('attendance_sessions')) {
            DB::statement('ALTER TABLE attendance_sessions MODIFY activity_id BIGINT UNSIGNED NULL');
        }
    }
};

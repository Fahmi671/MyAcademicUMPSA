<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement('ALTER TABLE `subject` DROP PRIMARY KEY');
        DB::statement('ALTER TABLE `subject` ADD COLUMN `Subject_ID` INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY FIRST');
        DB::statement('ALTER TABLE `subject` ADD UNIQUE KEY `subject_code_section_lab_unique` (`Subject_Code`, `Section`, `Lab`)');
        DB::statement('ALTER TABLE `subject` ADD KEY `subject_subject_code_index` (`Subject_Code`)');
    }

    public function down(): void
    {
        DB::statement('ALTER TABLE `subject` DROP KEY `subject_code_section_lab_unique`');
        DB::statement('ALTER TABLE `subject` DROP KEY `subject_subject_code_index`');
        DB::statement('ALTER TABLE `subject` DROP COLUMN `Subject_ID`');
        DB::statement('ALTER TABLE `subject` ADD PRIMARY KEY (`Subject_Code`)');
    }
};

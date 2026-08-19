<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('attendances', function (Blueprint $table) {
            $table->foreignId('work_assignment_id')
                ->nullable()
                ->after('attendance_zone_id')
                ->constrained('work_assignments')
                ->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('attendances', function (Blueprint $table) {
            $table->dropForeign(['work_assignment_id']);
            $table->dropColumn('work_assignment_id');
        });
    }
};

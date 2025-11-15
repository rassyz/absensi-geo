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
        Schema::create('department_attendance_zone', function (Blueprint $table) {
            $table->primary(['department_id', 'attendance_zone_id']);
            $table->foreignId('department_id')->constrained()->onDelete('cascade');
            $table->foreignId('attendance_zone_id')->constrained()->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('department_attendance_zone');
    }
};

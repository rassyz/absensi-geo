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
        Schema::create('employee_evaluations', function (Blueprint $table) {
            $table->id();

            $table->foreignId('employee_id')->constrained()->onDelete('cascade');

            // periode evaluasi
            $table->integer('month');
            $table->integer('year');

            // nilai kriteria
            $table->float('attendance_percentage');
            $table->integer('total_attendance');
            $table->integer('late_count');
            $table->integer('early_leave_count');
            $table->integer('absent_count');

            // hasil SAW
            $table->float('final_score');

            // hasil keputusan
            $table->string('status'); // sangat disiplin / cukup / pembinaan

            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('employee_evaluations');
    }
};

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('work_assignment_employees', function (Blueprint $table) {
            $table->id();

            $table->foreignId('work_assignment_id')
                ->constrained('work_assignments')
                ->cascadeOnDelete();

            $table->foreignId('employee_id')
                ->constrained('employees')
                ->cascadeOnDelete();

            $table->timestamps();

            $table->unique([
                'work_assignment_id',
                'employee_id',
            ]);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists(
            'work_assignment_employees'
        );
    }
};

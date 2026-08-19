<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('work_assignments', function (Blueprint $table) {
            $table->id();

            $table->foreignId('employee_id')
                ->constrained('employees')
                ->cascadeOnDelete();

            $table->string('assignment_number')->unique();

            $table->date('start_date');
            $table->date('end_date');

            $table->string('destination');
            $table->text('purpose');

            $table->string('attachment');

            $table->boolean('is_active')->default(true);

            $table->foreignId('created_by')
                ->nullable()
                ->constrained('users')
                ->nullOnDelete();

            $table->timestamps();

            $table->index([
                'employee_id',
                'start_date',
                'end_date',
                'is_active',
            ]);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('work_assignments');
    }
};

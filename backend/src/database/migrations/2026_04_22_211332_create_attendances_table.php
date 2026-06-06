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
        Schema::create('attendances', function (Blueprint $table) {
            $table->id();

            $table->foreignId('employee_id')->constrained('employees')->onDelete('cascade');
            $table->foreignId('attendance_zone_id')->nullable()->constrained('attendance_zones')->onDelete('cascade');
            $table->foreignId('leave_id')->nullable()->constrained('leaves')->nullOnDelete();
            $table->date('date');
            $table->timestamp('check_in')->nullable();
            $table->timestamp('check_out')->nullable();
            $table->decimal('check_in_latitude', 10, 8)->nullable();
            $table->decimal('check_in_longitude', 11, 8)->nullable();
            $table->decimal('check_out_latitude', 10, 8)->nullable();
            $table->decimal('check_out_longitude', 11, 8)->nullable();
            $table->string('check_in_photo_path')->nullable();
            $table->string('check_out_photo_path')->nullable();
            $table->string('status', 20)->nullable();
            $table->string('source', 20)->nullable();

            $table->timestamps();

            // --- INDEXING ---
            $table->index(['employee_id', 'date']);
            $table->index('date');
            $table->index(['employee_id', 'check_in']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('attendances');
    }
};

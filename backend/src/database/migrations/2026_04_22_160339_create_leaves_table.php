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
        Schema::create('leaves', function (Blueprint $table) {
            $table->id();
            // Link to the employee requesting the leave
            $table->foreignId('employee_id')->constrained()->cascadeOnDelete();

            // Leave details
            $table->string('leave_type'); // e.g., 'Cuti Tahunan', 'Cuti Sakit'
            $table->date('start_date');
            $table->date('end_date');
            $table->integer('apply_days'); // Total days requested
            $table->text('reason');
            $table->string('attachment')->nullable(); // File path for sick notes, etc.

            // Status and Approval
            $table->enum('status', ['Pending', 'Approved', 'Rejected', 'Cancelled'])->default('Pending');
            // Assuming the approver is linked to the users table. Adjust if it links to employees instead.
            $table->foreignId('approved_by')->nullable()->constrained('users')->nullOnDelete();

            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('leaves');
    }
};

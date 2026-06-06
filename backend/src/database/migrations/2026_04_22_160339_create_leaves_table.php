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
            $table->foreignId('leave_type_id')->constrained()->cascadeOnDelete();
            $table->date('start_date');
            $table->date('end_date');
            $table->integer('apply_days');
            $table->text('reason');
            $table->string('attachment')->nullable();

            // Status and Approval
            $table->enum('status', ['Pending', 'Approved', 'Rejected', 'Cancelled'])->default('Pending');
            $table->foreignId('approved_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('approved_at')->nullable();
            $table->text('rejection_reason')->nullable();

            $table->timestamps();

            // --- INDEXING ---
            $table->index(['employee_id', 'status']);
            $table->index(['approved_by', 'status']);
            $table->index('created_at');
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

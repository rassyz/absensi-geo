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
        // 1. Tabel Utama: Jadwal Lembur dari Admin
        Schema::create('overtimes', function (Blueprint $table) {
            $table->id();

            // Relasi ke tabel users (karena admin ada di tabel users)
            $table->foreignId('admin_id')->constrained('users')->onDelete('cascade');

            $table->string('title');
            $table->date('date');
            $table->time('planned_start_time');
            $table->time('planned_end_time');
            $table->text('notes')->nullable();

            $table->timestamps();
        });

        // 2. Tabel Pivot: Detail Eksekusi Lembur oleh Karyawan
        Schema::create('overtime_employees', function (Blueprint $table) {
            $table->id();

            // Relasi ke jadwal lembur dan karyawan
            $table->foreignId('overtime_id')->constrained('overtimes')->onDelete('cascade');
            $table->foreignId('employee_id')->constrained('employees')->onDelete('cascade');

            $table->string('status')->default('Pending'); // Pending, Hadir, Tidak Hadir

            // Perekam Jejak Clock In
            $table->timestamp('check_in')->nullable();
            $table->decimal('check_in_latitude', 10, 8)->nullable();
            $table->decimal('check_in_longitude', 11, 8)->nullable();

            // Perekam Jejak Clock Out
            $table->timestamp('check_out')->nullable();
            $table->decimal('check_out_latitude', 10, 8)->nullable();
            $table->decimal('check_out_longitude', 11, 8)->nullable();

            $table->timestamps();

            // Memastikan 1 karyawan hanya bisa dimasukkan 1 kali di jadwal lembur yang sama
            $table->unique(['overtime_id', 'employee_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Harus drop tabel pivot dulu sebelum tabel utamanya (karena ada foreign key)
        Schema::dropIfExists('overtime_employees');
        Schema::dropIfExists('overtimes');
    }
};

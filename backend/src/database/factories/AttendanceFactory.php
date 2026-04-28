<?php

namespace Database\Factories;

use App\Models\Attendance;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Carbon;

/**
 * @extends Factory<Attendance>
 */
class AttendanceFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        // Buat tanggal random untuk kolom date
        $date = Carbon::today()->subDays(rand(0, 30));

        $checkIn = $date->copy()->setTime(rand(7, 9), rand(0, 59));
        $checkOut = (clone $checkIn)->addHours(rand(7, 9));

        return [
            'employee_id' => 1,
            'attendance_zone_id' => 1,

            'date' => $date->format('Y-m-d'), // 👈 TAMBAHKAN INI
            'check_in' => $checkIn,
            'check_out' => $checkOut,

            'check_in_latitude' => -6.24,
            'check_in_longitude' => 106.47,

            'check_out_latitude' => -6.24,
            'check_out_longitude' => 106.47,

            'check_in_photo_path' => 'photos/checkin.jpg',
            'check_out_photo_path' => 'photos/checkout.jpg',

            'status' => 'present',
        ];
    }
}

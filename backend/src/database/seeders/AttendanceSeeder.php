<?php

namespace Database\Seeders;

use App\Models\Attendance;
// use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;

class AttendanceSeeder extends Seeder
{
    public function run(): void
    {
        $polygon = [
            [106.472261, -6.240775],
            [106.477325, -6.237192],
            [106.480415, -6.237746],
            [106.480887, -6.243847],
            [106.478355, -6.245169],
            [106.478913, -6.248881],
            [106.472347, -6.24807],
            [106.472905, -6.243036],
            [106.472261, -6.240775],
        ];

        $startDate = Carbon::parse('2026-03-01');
        $endDate   = Carbon::parse('2026-04-23');

        $employees = [1, 2, 3, 4];

        foreach ($employees as $employeeId) {
            $date = $startDate->copy();

            while ($date <= $endDate) {
                if (!$date->isWeekend()) {

                    $checkIn = $date->copy()->setTime(rand(7, 9), rand(0, 59));
                    $checkOut = (clone $checkIn)->addHours(rand(7, 9));

                    $checkInPoint = $this->randomPointInPolygon($polygon);
                    $checkOutPoint = $this->randomPointInPolygon($polygon);

                    $status = 'Hadir';
                    if ($checkIn->hour >= 9) {
                        $status = 'Telat';
                    }

                    if (rand(1, 100) <= 5) {
                        $status = 'absent';
                        $checkIn = null;
                        $checkOut = null;
                    }

                    Attendance::create([
                        'employee_id' => $employeeId,
                        'attendance_zone_id' => 1,

                        'date' => $date->format('Y-m-d'), // 👈 TAMBAHKAN INI
                        'check_in' => $checkIn,
                        'check_out' => $checkOut,

                        'check_in_latitude' => $checkInPoint['latitude'] ?? null,
                        'check_in_longitude' => $checkInPoint['longitude'] ?? null,

                        'check_out_latitude' => $checkOutPoint['latitude'] ?? null,
                        'check_out_longitude' => $checkOutPoint['longitude'] ?? null,

                        'check_in_photo_path' => $status !== 'absent' ? 'photos/checkin.jpg' : null,
                        'check_out_photo_path' => $status !== 'absent' ? 'photos/checkout.jpg' : null,

                        'status' => $status,
                    ]);
                }

                $date->addDay();
            }
        }
    }

    // =========================
    // HELPER: POINT IN POLYGON
    // =========================
    private function pointInPolygon($point, $polygon)
    {
        $x = $point[0];
        $y = $point[1];

        $inside = false;
        $n = count($polygon);

        for ($i = 0, $j = $n - 1; $i < $n; $j = $i++) {
            $xi = $polygon[$i][0];
            $yi = $polygon[$i][1];
            $xj = $polygon[$j][0];
            $yj = $polygon[$j][1];

            $intersect = (($yi > $y) != ($yj > $y)) &&
                ($x < ($xj - $xi) * ($y - $yi) / ($yj - $yi + 0.0000001) + $xi);

            if ($intersect) {
                $inside = !$inside;
            }
        }

        return $inside;
    }

    // =========================
    // HELPER: RANDOM POINT
    // =========================
    private function randomPointInPolygon($polygon)
    {
        $minLng = min(array_column($polygon, 0));
        $maxLng = max(array_column($polygon, 0));
        $minLat = min(array_column($polygon, 1));
        $maxLat = max(array_column($polygon, 1));

        do {
            $lng = $minLng + lcg_value() * ($maxLng - $minLng);
            $lat = $minLat + lcg_value() * ($maxLat - $minLat);
        } while (!$this->pointInPolygon([$lng, $lat], $polygon));

        return [
            'longitude' => $lng,
            'latitude' => $lat,
        ];
    }
}

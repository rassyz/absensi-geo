<?php

namespace App\Services;

use App\Models\Attendance;
use App\Models\Employee;
use App\Models\EmployeeEvaluation;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use InvalidArgumentException;

class EmployeeEvaluationService
{
    /**
     * Membuat evaluasi kedisiplinan karyawan berdasarkan:
     * 1. Kehadiran
     * 2. Keterlambatan
     * 3. Alpa
     */
    public function generate($month, $year): void
    {
        $month = (int) $month;
        $year = (int) $year;

        if ($month < 1 || $month > 12) {
            throw new InvalidArgumentException('Bulan harus berada antara 1 sampai 12.');
        }

        if ($year < 2000 || $year > 2100) {
            throw new InvalidArgumentException('Tahun evaluasi tidak valid.');
        }

        $periodStart = Carbon::create($year, $month, 1)->startOfDay();
        $periodEnd = $periodStart->copy()->endOfMonth()->endOfDay();

        $workingDays = $this->getWorkingDays($month, $year);

        $employees = Employee::query()
            ->orderBy('id')
            ->get();

        /*
         * Mengambil data berdasarkan kolom date.
         *
         * Tidak lagi menggunakan:
         * - bulan/tahun dari check_in
         * - created_at sebagai tanggal presensi
         * - early_leave
         */
        $attendancesByEmployee = Attendance::query()
            ->whereIn('employee_id', $employees->pluck('id'))
            ->whereBetween('date', [
                $periodStart->toDateString(),
                $periodEnd->toDateString(),
            ])
            ->orderBy('date')
            ->orderBy('check_in')
            ->get()
            ->groupBy('employee_id');

        $results = [];

        foreach ($employees as $employee) {
            $employeeAttendances = $attendancesByEmployee
                ->get($employee->id, collect());

            /*
             * Satu tanggal hanya dihitung satu kali walaupun terdapat
             * lebih dari satu record presensi pada tanggal yang sama.
             */
            $dailyAttendances = $employeeAttendances->groupBy(
                fn(Attendance $attendance): string =>
                Carbon::parse($attendance->date)->toDateString()
            );

            $presentDays = 0;
            $lateCount = 0;
            $absentCount = 0;

            foreach ($dailyAttendances as $date => $records) {
                $attendanceDate = Carbon::parse($date);

                // Sabtu dan Minggu tidak masuk perhitungan.
                if ($attendanceDate->isWeekend()) {
                    continue;
                }

                $presentRecord = $records
                    ->filter(
                        fn(Attendance $attendance): bool =>
                        $attendance->check_in !== null
                    )
                    ->sortBy('check_in')
                    ->first();

                if ($presentRecord !== null) {
                    $presentDays++;

                    $checkIn = Carbon::parse($presentRecord->check_in);

                    $workStart = $attendanceDate
                        ->copy()
                        ->setTime(9, 0, 0);

                    if ($checkIn->gt($workStart)) {
                        $lateCount++;
                    }

                    continue;
                }


                $hasAbsentStatus = $records->contains(
                    function (Attendance $attendance): bool {
                        $status = strtolower(
                            trim((string) $attendance->status)
                        );

                        return $attendance->check_in === null
                            && in_array(
                                $status,
                                ['alpa', 'alpa', 'absent'],
                                true
                            );
                    }
                );

                if ($hasAbsentStatus) {
                    $absentCount++;
                }
            }

            $attendancePercentage = $workingDays > 0
                ? ($presentDays / $workingDays) * 100
                : 0;

            $results[] = [
                'employee' => $employee,
                'total_attendance' => $presentDays,
                'attendance' => round($attendancePercentage, 2),
                'late' => $lateCount,
                'alpa' => $absentCount,
            ];
        }

        /*
         * NORMALISASI SAW
         *
         * Kehadiran = benefit
         * Terlambat = cost
         * Alpa      = cost
         */
        $resultCollection = collect($results);

        $maxAttendance = max(
            (float) ($resultCollection->max('attendance') ?? 0),
            1
        );

        $maxLate = max(
            (int) ($resultCollection->max('late') ?? 0),
            1
        );

        $maxalpa = max(
            (int) ($resultCollection->max('alpa') ?? 0),
            1
        );

        foreach ($results as &$result) {
            // Kriteria benefit: semakin tinggi semakin baik.
            $result['r_attendance'] =
                $result['attendance'] / $maxAttendance;

            // Kriteria cost: semakin rendah semakin baik.
            $result['r_late'] =
                1 - ($result['late'] / $maxLate);

            $result['r_alpa'] =
                1 - ($result['alpa'] / $maxalpa);

            $score =
                (0.50 * $result['r_attendance']) +
                (0.20 * $result['r_late']) +
                (0.30 * $result['r_alpa']);

            $result['score'] = round($score, 4);

            if ($result['alpa'] >= 3 || $result['late'] > 5) {
                $result['status'] = 'pembinaan';
            } elseif ($result['score'] >= 0.85) {
                $result['status'] = 'disiplin';
            } elseif ($result['score'] >= 0.70) {
                $result['status'] = 'cukup';
            } else {
                $result['status'] = 'pembinaan';
            }
        }

        unset($result);

        $hasLegacyEarlyLeaveColumn = Schema::hasColumn(
            'employee_evaluations',
            'early_leave_count'
        );

        DB::transaction(
            function () use (
                $results,
                $month,
                $year,
                $hasLegacyEarlyLeaveColumn
            ): void {
                EmployeeEvaluation::query()
                    ->where('month', $month)
                    ->where('year', $year)
                    ->delete();

                foreach ($results as $result) {
                    $evaluationData = [
                        'employee_id' => $result['employee']->id,
                        'month' => $month,
                        'year' => $year,
                        'total_attendance' =>
                        $result['total_attendance'],
                        'attendance_percentage' =>
                        $result['attendance'],
                        'late_count' => $result['late'],
                        'absent_count' => $result['alpa'],
                        'final_score' => $result['score'],
                        'status' => $result['status'],
                    ];

                    if ($hasLegacyEarlyLeaveColumn) {
                        $evaluationData['early_leave_count'] = 0;
                    }

                    EmployeeEvaluation::query()->create(
                        $evaluationData
                    );
                }
            }
        );
    }

    /**
     * Menghitung jumlah hari kerja dalam satu bulan.
     * Hari kerja adalah Senin sampai Jumat.
     */
    private function getWorkingDays(int $month, int $year): int
    {
        $currentDate = Carbon::create($year, $month, 1);
        $endDate = $currentDate->copy()->endOfMonth();

        $workingDays = 0;

        while ($currentDate->lte($endDate)) {
            if (!$currentDate->isWeekend()) {
                $workingDays++;
            }

            $currentDate->addDay();
        }

        return $workingDays;
    }
}

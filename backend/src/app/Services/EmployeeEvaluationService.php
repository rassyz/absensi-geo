<?php

namespace App\Services;

use App\Models\Employee;
use App\Models\Attendance;
use App\Models\EmployeeEvaluation;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class EmployeeEvaluationService
{
    public function generate($month, $year)
    {
        $employees = Employee::all();
        $results = [];

        $workingDays = $this->getWorkingDays($month, $year);

        foreach ($employees as $employee) {

            // 🔥 SINGLE DATASET (IMPORTANT)
            $attendances = Attendance::where('employee_id', $employee->id)
                ->where(function ($q) use ($month, $year) {
                    $q->whereMonth('check_in', $month)
                      ->whereYear('check_in', $year);
                })
                ->orWhere(function ($q) use ($month, $year, $employee) {
                    $q->where('employee_id', $employee->id)
                      ->whereNull('check_in')
                      ->whereMonth('created_at', $month)
                      ->whereYear('created_at', $year);
                })
                ->get()
                ->groupBy(function ($att) {
                    return Carbon::parse($att->check_in ?? $att->created_at)->toDateString();
                });

            $presentDays = 0;
            $late = 0;
            $early = 0;

            foreach ($attendances as $date => $records) {

                $dateCarbon = Carbon::parse($date);

                // skip weekend
                if ($dateCarbon->isWeekend()) {
                    continue;
                }

                $workStart = $dateCarbon->copy()->setTime(9, 0, 0);
                $workEnd   = $dateCarbon->copy()->setTime(17, 0, 0);

                // 🔥 pick valid check-in record
                $att = $records->firstWhere('check_in', '!=', null);

                if ($att) {
                    $presentDays++;

                    $checkIn = Carbon::parse($att->check_in);

                    // late
                    if ($checkIn->gt($workStart)) {
                        $late++;
                    }

                    // early leave
                    if ($att->check_out) {
                        $checkOut = Carbon::parse($att->check_out);

                        if ($checkOut->lt($workEnd)) {
                            $early++;
                        }
                    }
                }
            }

            $totalDaysWithData = $attendances->count();
            $alpha = max($totalDaysWithData - $presentDays, 0);

            $attendancePercentage = $workingDays > 0
                ? ($presentDays / $workingDays) * 100
                : 0;

            $results[] = [
                'employee' => $employee,
                'total_attendance' => $presentDays,
                'attendance' => $attendancePercentage,
                'late' => $late,
                'early' => $early,
                'alpha' => $alpha,
            ];
        }

        // ======================
        // 🔥 SAW CALCULATION (IMPROVED)
        // ======================

        $maxAttendance = collect($results)->max('attendance') ?: 1;

        $maxLate = max(collect($results)->max('late'), 1);
        $maxEarly = max(collect($results)->max('early'), 1);
        $maxAlpha = max(collect($results)->max('alpha'), 1);

        foreach ($results as &$r) {

            // benefit
            $r['r_attendance'] = $r['attendance'] / $maxAttendance;

            // cost (better normalization)
            $r['r_late'] = 1 - ($r['late'] / $maxLate);
            $r['r_early'] = 1 - ($r['early'] / $maxEarly);
            $r['r_alpha'] = 1 - ($r['alpha'] / $maxAlpha);

            $score =
                (0.5 * $r['r_attendance']) +
                (0.2 * $r['r_late']) +
                (0.15 * $r['r_early']) +
                (0.15 * $r['r_alpha']);

            $r['score'] = $score;

            // softer business rule
            if ($r['alpha'] >= 3) {
                $r['status'] = 'pembinaan';
            } elseif ($score >= 0.85) {
                $r['status'] = 'sangat disiplin';
            } elseif ($score >= 0.7) {
                $r['status'] = 'cukup';
            } else {
                $r['status'] = 'pembinaan';
            }
        }

        // ======================
        // 💾 SAVE
        // ======================

        DB::transaction(function () use ($results, $month, $year) {

            EmployeeEvaluation::where('month', $month)
                ->where('year', $year)
                ->delete();

            foreach ($results as $r) {
                EmployeeEvaluation::create([
                    'employee_id' => $r['employee']->id,
                    'month' => $month,
                    'year' => $year,
                    'total_attendance' => $r['total_attendance'],
                    'attendance_percentage' => $r['attendance'],
                    'late_count' => $r['late'],
                    'early_leave_count' => $r['early'],
                    'absent_count' => $r['alpha'],
                    'final_score' => $r['score'],
                    'status' => $r['status'],
                ]);
            }
        });
    }

    // ======================
    // 🔥 HELPER: WORKING DAYS
    // ======================
    private function getWorkingDays($month, $year)
    {
        $start = Carbon::create($year, $month, 1);
        $end = $start->copy()->endOfMonth();

        $days = 0;

        while ($start <= $end) {
            if (!$start->isWeekend()) {
                $days++;
            }
            $start->addDay();
        }

        return $days;
    }
}

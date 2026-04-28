<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Employee;
use App\Models\Attendance;
use Carbon\Carbon;

class MarkAbsences extends Command
{
    protected $signature = 'attendance:mark-absences';
    protected $description = 'Mark employees as Absent if they did not clock in today';

    public function handle()
    {
        $today = Carbon::today();

        // 1. Get all active employees
        $employees = Employee::all(); // Add conditions like ->where('status', 'active') if you have them

        $absentCount = 0;

        foreach ($employees as $employee) {
            // 2. Check if the employee already has an attendance record for today
            $hasAttended = Attendance::where('employee_id', $employee->id)
                ->whereDate('date', $today)
                ->exists();

            // 3. If no record exists, create an 'Absent' record
            if (!$hasAttended) {
                Attendance::create([
                    'employee_id' => $employee->id,
                    'date'        => $today,
                    'clock_in'    => null,
                    'clock_out'   => null,
                    'status'      => 'Absent', // Or 'Alpha', depending on your standard
                ]);
                $absentCount++;
            }
        }

        $this->info("Successfully marked {$absentCount} employees as absent for today.");
    }
}

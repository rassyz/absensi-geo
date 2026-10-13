<?php

declare(strict_types=1);

namespace App\Repositories\Eloquent;

use App\Models\AttendanceZone;
use App\Models\Employee;
use App\Models\Overtime;
use App\Repositories\Contracts\OvertimeRepositoryInterface;
use Illuminate\Support\Collection;

class OvertimeRepository implements OvertimeRepositoryInterface
{
    /**
     * {@inheritdoc}
     */
    public function getEmployeeOvertimes(int $employeeId): Collection
    {
        $employee = Employee::find($employeeId);

        if (!$employee) {
            return collect();
        }

        return $employee->overtimes()
            ->withPivot('status', 'check_in', 'check_out')
            ->orderBy('date', 'asc')
            ->get();
    }

    /**
     * {@inheritdoc}
     */
    public function findAssignedOvertime(int $employeeId, int $overtimeId): ?Overtime
    {
        $employee = Employee::find($employeeId);

        if (!$employee) {
            return null;
        }

        return $employee->overtimes()
            ->where('overtimes.id', $overtimeId)
            ->first();
    }

    /**
     * {@inheritdoc}
     */
    public function updatePivot(int $employeeId, int $overtimeId, array $attributes): bool
    {
        $employee = Employee::find($employeeId);

        if (!$employee) {
            return false;
        }

        $employee->overtimes()->updateExistingPivot($overtimeId, $attributes);

        return true;
    }

    /**
     * {@inheritdoc}
     */
    public function isLocationInZones(
        array $zoneIds,
        float $latitude,
        float $longitude,
        int $toleranceMeters = 10
    ): bool {
        if (empty($zoneIds)) {
            return false;
        }

        return AttendanceZone::whereIn('id', $zoneIds)
            ->whereRaw(
                'ST_DWithin(area::geography, ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography, ?)',
                [$longitude, $latitude, $toleranceMeters]
            )
            ->exists();
    }
}


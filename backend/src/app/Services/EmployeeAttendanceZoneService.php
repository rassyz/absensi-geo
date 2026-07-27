<?php

namespace App\Services;

use App\Models\Employee;
use Illuminate\Support\Collection;
use RuntimeException;

class EmployeeAttendanceZoneService
{
    /**
     * Prioritas zona:
     * 1. Zona khusus karyawan jika attendance_zone_id terisi.
     * 2. Seluruh zona departemen jika zona khusus tidak diatur.
     */
    public function getApplicableZoneIds(Employee $employee): Collection
    {
        $employee->loadMissing([
            'attendanceZone',
            'department.attendanceZones',
        ]);

        if ($employee->attendance_zone_id !== null) {
            if (!$employee->attendanceZone) {
                throw new RuntimeException(
                    'Zona presensi khusus karyawan tidak ditemukan.'
                );
            }

            return collect([(int) $employee->attendanceZone->id]);
        }

        if (!$employee->department) {
            throw new RuntimeException(
                'Karyawan tidak terdaftar di departemen manapun.'
            );
        }

        $zoneIds = $employee->department->attendanceZones
            ->pluck('id')
            ->map(fn($id) => (int) $id)
            ->values();

        if ($zoneIds->isEmpty()) {
            throw new RuntimeException(
                'Departemen Anda tidak memiliki zona absensi.'
            );
        }

        return $zoneIds;
    }

    public function getZoneSource(Employee $employee): string
    {
        return $employee->attendance_zone_id !== null
            ? 'employee'
            : 'department';
    }
}

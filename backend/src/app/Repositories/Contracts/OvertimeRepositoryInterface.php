<?php

declare(strict_types=1);

namespace App\Repositories\Contracts;

use App\Models\Overtime;
use Illuminate\Support\Collection;

interface OvertimeRepositoryInterface
{
    /**
     * Mengambil seluruh daftar jadwal lembur yang ditugaskan kepada karyawan beserta data pivot.
     *
     * @return Collection<int, Overtime>
     */
    public function getEmployeeOvertimes(int $employeeId): Collection;

    /**
     * Mencari satu penugasan lembur tertentu milik karyawan beserta relasi pivot.
     */
    public function findAssignedOvertime(int $employeeId, int $overtimeId): ?Overtime;

    /**
     * Memperbarui kolom data pada tabel pivot overtime_employees.
     *
     * @param array<string, mixed> $attributes
     */
    public function updatePivot(int $employeeId, int $overtimeId, array $attributes): bool;

    /**
     * Memvalidasi apakah koordinat berada di dalam radius zona presensi yang ditentukan menggunakan PostGIS.
     *
     * @param list<int> $zoneIds
     */
    public function isLocationInZones(
        array $zoneIds,
        float $latitude,
        float $longitude,
        int $toleranceMeters = 10
    ): bool;
}


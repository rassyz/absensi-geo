<?php

declare(strict_types=1);

namespace App\Repositories\Contracts;

use App\Models\Leave;
use Illuminate\Support\Collection;

interface LeaveRepositoryInterface
{
    /**
     * Menyimpan data pengajuan cuti baru.
     *
     * @param array<string, mixed> $data
     */
    public function create(array $data): Leave;

    /**
     * Mencari data cuti berdasarkan ID beserta relasinya.
     *
     * @param list<string> $relations
     */
    public function findById(int $id, array $relations = []): ?Leave;

    /**
     * Mengambil ringkasan jumlah cuti berdasarkan status untuk seorang karyawan.
     *
     * @return Collection<string, int>
     */
    public function getStatusCounts(int $employeeId): Collection;

    /**
     * Mengambil daftar riwayat cuti seorang karyawan.
     *
     * @param list<string> $relations
     * @return Collection<int, Leave>
     */
    public function getEmployeeLeaves(int $employeeId, array $relations = ['leaveType', 'approver']): Collection;

    /**
     * Mengambil daftar pengajuan cuti tim yang berstatus Pending sesuai peran dan posisi approver.
     *
     * @param list<string> $relations
     * @return Collection<int, Leave>
     */
    public function getPendingTeamLeaves(
        int $employeeId,
        string $position,
        ?int $departmentId,
        array $relations = ['employee.user', 'employee.department', 'leaveType']
    ): Collection;

    /**
     * Memperbarui data cuti berdasarkan ID.
     *
     * @param array<string, mixed> $data
     */
    public function update(int $id, array $data): bool;
}


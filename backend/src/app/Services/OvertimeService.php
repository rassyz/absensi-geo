<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\Employee;
use App\Models\Overtime;
use App\Models\User;
use App\Repositories\Contracts\OvertimeRepositoryInterface;
use Carbon\Carbon;
use RuntimeException;

class OvertimeService
{
    public const TOLERANCE_METERS = 10;

    public function __construct(
        private readonly OvertimeRepositoryInterface $overtimeRepository,
        private readonly EmployeeAttendanceZoneService $zoneService
    ) {}

    /**
     * Mengambil daftar penugasan lembur karyawan.
     *
     * @return list<array<string, mixed>>
     */
    public function getEmployeeOvertimes(User $user): array
    {
        $employee = $this->getEmployeeOrThrow($user);

        return $this->overtimeRepository->getEmployeeOvertimes((int) $employee->id)
            ->map(static function (Overtime $overtime): array {
                $actualCheckIn = $overtime->pivot?->check_in
                    ? Carbon::parse($overtime->pivot->check_in)->format('H:i')
                    : null;

                $actualCheckOut = $overtime->pivot?->check_out
                    ? Carbon::parse($overtime->pivot->check_out)->format('H:i')
                    : null;

                return [
                    'id'                 => $overtime->id,
                    'title'              => $overtime->title,
                    'date'               => Carbon::parse($overtime->date)->translatedFormat('d M Y'),
                    'raw_date'           => Carbon::parse($overtime->date)->format('Y-m-d'),
                    'planned_start_time' => Carbon::parse($overtime->planned_start_time)->format('H:i'),
                    'planned_end_time'   => Carbon::parse($overtime->planned_end_time)->format('H:i'),
                    'notes'              => $overtime->notes,
                    'status'             => $overtime->pivot?->status,
                    'actual_check_in'    => $actualCheckIn,
                    'actual_check_out'   => $actualCheckOut,
                ];
            })
            ->values()
            ->all();
    }

    /**
     * Memproses Clock In lembur.
     *
     * @return array{
     *     status: 'ok'|'outside_zone'|'not_assigned'|'already_clocked_in',
     *     message: string
     * }
     */
    public function clockIn(User $user, int $overtimeId, float $latitude, float $longitude): array
    {
        $employee = $this->getEmployeeOrThrow($user);

        $isValidLocation = $this->validateLocation($employee, $latitude, $longitude);
        if (!$isValidLocation) {
            return [
                'status'  => 'outside_zone',
                'message' => 'Gagal memcatat lembur. Anda berada di luar area absensi kantor.',
            ];
        }

        $overtime = $this->overtimeRepository->findAssignedOvertime((int) $employee->id, $overtimeId);
        if (!$overtime) {
            return [
                'status'  => 'not_assigned',
                'message' => 'Anda tidak ditugaskan untuk lembur ini.',
            ];
        }

        if ($overtime->pivot?->check_in) {
            return [
                'status'  => 'already_clocked_in',
                'message' => 'Anda sudah melakukan clock-in lembur.',
            ];
        }

        $this->overtimeRepository->updatePivot((int) $employee->id, $overtime->id, [
            'check_in'           => Carbon::now(),
            'check_in_latitude'  => $latitude,
            'check_in_longitude' => $longitude,
            'status'             => 'Sedang Lembur',
        ]);

        return [
            'status'  => 'ok',
            'message' => 'Clock In Lembur Berhasil. Anda berada di dalam area.',
        ];
    }

    /**
     * Memproses Clock Out lembur.
     *
     * @return array{
     *     status: 'ok'|'outside_zone'|'not_clocked_in'|'already_clocked_out',
     *     message: string
     * }
     */
    public function clockOut(User $user, int $overtimeId, float $latitude, float $longitude): array
    {
        $employee = $this->getEmployeeOrThrow($user);

        $isValidLocation = $this->validateLocation($employee, $latitude, $longitude);
        if (!$isValidLocation) {
            return [
                'status'  => 'outside_zone',
                'message' => 'Anda berada di luar area absensi kantor.',
            ];
        }

        $overtime = $this->overtimeRepository->findAssignedOvertime((int) $employee->id, $overtimeId);
        if (!$overtime || !$overtime->pivot?->check_in) {
            return [
                'status'  => 'not_clocked_in',
                'message' => 'Anda belum melakukan clock-in lembur.',
            ];
        }

        if ($overtime->pivot?->check_out) {
            return [
                'status'  => 'already_clocked_out',
                'message' => 'Anda sudah melakukan clock-out lembur.',
            ];
        }

        $this->overtimeRepository->updatePivot((int) $employee->id, $overtime->id, [
            'check_out'           => Carbon::now(),
            'check_out_latitude'  => $latitude,
            'check_out_longitude' => $longitude,
            'status'              => 'Selesai',
        ]);

        return [
            'status'  => 'ok',
            'message' => 'Clock Out Lembur Berhasil. Terima kasih atas kerja kerasnya!',
        ];
    }

    /**
     * Memvalidasi apakah koordinat GPS berada di dalam zona absensi kantor.
     */
    public function validateLocation(Employee $employee, float $latitude, float $longitude): bool
    {
        $zoneIds = $this->zoneService->getApplicableZoneIds($employee)
            ->map(static fn($id): int => (int) $id)
            ->all();

        return $this->overtimeRepository->isLocationInZones(
            $zoneIds,
            $latitude,
            $longitude,
            self::TOLERANCE_METERS
        );
    }

    /**
     * Mengambil profil karyawan dari user atau melempar RuntimeException.
     */
    private function getEmployeeOrThrow(User $user): Employee
    {
        $user->loadMissing('employee');

        if (!$user->employee) {
            throw new RuntimeException('Data karyawan tidak ditemukan.');
        }

        return $user->employee;
    }
}


<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\Attendance;
use App\Models\Employee;
use App\Models\User;
use App\Models\WorkAssignment;
use App\Repositories\Contracts\AttendanceRepositoryInterface;
use Carbon\Carbon;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Collection;
use RuntimeException;

class AttendanceService
{
    public const TOLERANCE_METERS = 10;

    public function __construct(
        private readonly AttendanceRepositoryInterface $attendanceRepository,
        private readonly EmployeeAttendanceZoneService $zoneService
    ) {}

    /**
     * Mengambil konfigurasi zona presensi karyawan atau surat tugas aktif.
     *
     * @return array<string, mixed>
     */
    public function getUserZoneConfig(User $user): array
    {
        $employee = $this->getEmployeeOrThrow($user);
        $workAssignment = $this->attendanceRepository->findActiveWorkAssignment((int) $employee->id);

        if ($workAssignment) {
            return [
                'success'         => true,
                'attendance_mode' => 'outside_duty',
                'zone_source'     => null,
                'zones'           => [],
                'work_assignment' => $this->formatWorkAssignment($workAssignment),
            ];
        }

        $zoneIds = $this->zoneService->getApplicableZoneIds($employee)
            ->map(static fn($id): int => (int) $id)
            ->all();

        $zones = $this->attendanceRepository->getZonesWktByIds($zoneIds)
            ->map(static fn(object $zone): array => [
                'id'   => (int) $zone->id,
                'name' => $zone->name,
                'area' => $zone->area,
            ])
            ->values();

        $zoneSource = $this->zoneService->getZoneSource($employee);

        return [
            'success'         => true,
            'attendance_mode' => 'regular',
            'zone_source'     => $zoneSource,
            'zones'           => $zones,
            'work_assignment' => null,
        ];
    }

    /**
     * Memvalidasi lokasi real-time sebelum membuka kamera presensi.
     *
     * @return array<string, mixed>
     */
    public function validateLocationStatus(User $user, float $latitude, float $longitude): array
    {
        $attendanceBlock = $this->getTodayAttendanceBlockResult($user);

        if ($attendanceBlock['is_blocked']) {
            return [
                'success'               => true,
                'is_valid'              => false,
                'location_status'       => 'attendance_blocked',
                'message'               => $attendanceBlock['message'],
                'zone_id'               => null,
                'zone_name'             => null,
                'is_attendance_blocked' => true,
                'attendance_status'     => $attendanceBlock['status'],
            ];
        }

        $locationResult = $this->getLocationValidationResult($user, $latitude, $longitude);

        return [
            'success'               => true,
            'is_valid'              => $locationResult['is_valid'],
            'location_status'       => $locationResult['location_status'],
            'message'               => $locationResult['message'],
            'zone_id'               => $locationResult['zone_id'],
            'zone_name'             => $locationResult['zone_name'],
            'work_assignment_id'    => $locationResult['work_assignment_id'],
            'work_assignment'       => $locationResult['work_assignment'],
            'is_attendance_blocked' => false,
            'attendance_status'     => null,
        ];
    }

    /**
     * Memproses presensi masuk (Check-In).
     *
     * @return array{
     *     status: 'ok'|'blocked'|'already_checked_in'|'outside_zone',
     *     message: string,
     *     location_status?: string,
     *     work_assignment?: array<string, mixed>|null,
     *     data?: Attendance,
     *     attendance_status?: string|null
     * }
     */
    public function checkIn(User $user, float $latitude, float $longitude, ?UploadedFile $photo): array
    {
        $employee = $this->getEmployeeOrThrow($user);

        $attendanceBlock = $this->getTodayAttendanceBlockResult($user);
        if ($attendanceBlock['is_blocked']) {
            return [
                'status'            => 'blocked',
                'message'           => $attendanceBlock['message'],
                'attendance_status' => $attendanceBlock['status'],
            ];
        }

        if ($this->attendanceRepository->findTodayCheckedInAttendance((int) $employee->id) !== null) {
            return [
                'status'  => 'already_checked_in',
                'message' => 'Anda sudah melakukan presensi masuk hari ini.',
            ];
        }

        $locationResult = $this->getLocationValidationResult($user, $latitude, $longitude);
        if (!$locationResult['is_valid']) {
            return [
                'status'          => 'outside_zone',
                'message'         => $locationResult['message'],
                'location_status' => $locationResult['location_status'],
            ];
        }

        $photoPath = $photo?->store('attendances', 'public');

        $checkInTime = now();
        $workStart = Carbon::today()->setTime(9, 0, 0);
        $today = Carbon::today()->toDateString();
        $status = $checkInTime->gt($workStart) ? 'Telat' : 'Hadir';

        $attendance = $this->attendanceRepository->create([
            'employee_id'        => $employee->id,
            'attendance_zone_id' => $locationResult['zone_id'],
            'work_assignment_id' => $locationResult['work_assignment_id'],
            'date'               => $today,
            'check_in'           => $checkInTime,
            'check_in_latitude'  => $latitude,
            'check_in_longitude' => $longitude,
            'check_in_photo_path'=> $photoPath,
            'status'             => $status,
            'source'             => 'Mobile',
        ]);

        $message = $locationResult['location_status'] === 'outside_duty'
            ? 'Presensi tugas luar berhasil.'
            : 'Presensi masuk berhasil.';

        return [
            'status'          => 'ok',
            'message'         => $message,
            'location_status' => $locationResult['location_status'],
            'work_assignment' => $locationResult['work_assignment'],
            'data'            => $attendance,
        ];
    }

    /**
     * Memproses presensi keluar (Check-Out).
     *
     * @return array{
     *     status: 'ok'|'blocked'|'outside_zone'|'not_checked_in',
     *     message: string,
     *     location_status?: string,
     *     work_assignment?: array<string, mixed>|null,
     *     data?: Attendance,
     *     attendance_status?: string|null
     * }
     */
    public function checkOut(User $user, float $latitude, float $longitude, ?UploadedFile $photo): array
    {
        $employee = $this->getEmployeeOrThrow($user);

        $attendanceBlock = $this->getTodayAttendanceBlockResult($user);
        if ($attendanceBlock['is_blocked']) {
            return [
                'status'            => 'blocked',
                'message'           => $attendanceBlock['message'],
                'attendance_status' => $attendanceBlock['status'],
            ];
        }

        $locationResult = $this->getLocationValidationResult($user, $latitude, $longitude);
        if (!$locationResult['is_valid']) {
            return [
                'status'          => 'outside_zone',
                'message'         => $locationResult['message'],
                'location_status' => $locationResult['location_status'],
            ];
        }

        $attendance = $this->attendanceRepository->findTodayCheckedInAttendance((int) $employee->id);
        if (!$attendance) {
            return [
                'status'  => 'not_checked_in',
                'message' => 'Anda belum melakukan presensi masuk hari ini.',
            ];
        }

        $photoPath = $photo?->store('attendances', 'public');

        $this->attendanceRepository->update($attendance, [
            'check_out'            => now(),
            'check_out_latitude'   => $latitude,
            'check_out_longitude'  => $longitude,
            'check_out_photo_path' => $photoPath,
        ]);

        $message = $locationResult['location_status'] === 'outside_duty'
            ? 'Presensi keluar tugas luar berhasil.'
            : 'Presensi keluar berhasil. Hati-hati di jalan!';

        return [
            'status'          => 'ok',
            'message'         => $message,
            'location_status' => $locationResult['location_status'],
            'work_assignment' => $locationResult['work_assignment'],
            'data'            => $attendance,
        ];
    }

    /**
     * Endpoint sementara untuk uji kuantitatif geofencing.
     *
     * @return array<string, mixed>
     */
    public function testGeofence(User $user, float $latitude, float $longitude): array
    {
        $employee = $this->getEmployeeOrThrow($user);
        $zoneIds = $this->zoneService->getApplicableZoneIds($employee)
            ->map(static fn($id): int => (int) $id)
            ->all();

        $zone = $this->attendanceRepository->testNearestZoneDistance(
            $zoneIds,
            $latitude,
            $longitude,
            self::TOLERANCE_METERS
        );

        if (!$zone) {
            return [
                'found'   => false,
                'message' => 'Zona presensi tidak ditemukan.',
            ];
        }

        $locationStatus = $zone->location_status;
        $isValid = in_array($locationStatus, ['inside_area', 'tolerance_zone'], true);

        $message = match ($locationStatus) {
            'inside_area'    => 'Lokasi berada di dalam polygon.',
            'tolerance_zone' => 'Lokasi berada di zona toleransi.',
            default          => 'Lokasi berada di luar zona toleransi.',
        };

        return [
            'found'                      => true,
            'latitude'                   => $latitude,
            'longitude'                  => $longitude,
            'zone_id'                    => (int) $zone->id,
            'zone_name'                  => $zone->name,
            'distance_to_polygon_meters' => round((float) $zone->distance_meters, 2),
            'tolerance_meters'           => self::TOLERANCE_METERS,
            'is_valid'                   => $isValid,
            'location_status'            => $locationStatus,
            'message'                    => $message,
        ];
    }

    /**
     * Mengambil status presensi hari ini.
     *
     * @return array<string, mixed>
     */
    public function getTodayStatus(User $user): array
    {
        $employee = $this->getEmployeeOrThrow($user);
        $attendanceBlock = $this->getTodayAttendanceBlockResult($user);

        $attendance = $this->attendanceRepository->findTodayCheckedInAttendance((int) $employee->id)
            ?? $this->attendanceRepository->findTodayAttendance((int) $employee->id);

        if ($attendanceBlock['is_blocked']) {
            return [
                'success'               => true,
                'has_checked_in'        => false,
                'has_checked_out'       => false,
                'check_in_time'         => '-- : -- : --',
                'check_out_time'        => '-- : -- : --',
                'is_attendance_blocked' => true,
                'attendance_status'     => $attendanceBlock['status'],
                'attendance_message'    => $attendanceBlock['message'],
            ];
        }

        if ($attendance && $attendance->check_in !== null) {
            $checkInTime = Carbon::parse($attendance->check_in)
                ->timezone('Asia/Jakarta')
                ->format('H : i : s');

            $checkOutTime = $attendance->check_out
                ? Carbon::parse($attendance->check_out)->timezone('Asia/Jakarta')->format('H : i : s')
                : '-- : -- : --';

            return [
                'success'               => true,
                'has_checked_in'        => true,
                'check_in_time'         => $checkInTime,
                'has_checked_out'       => $attendance->check_out !== null,
                'check_out_time'        => $checkOutTime,
                'is_attendance_blocked' => false,
                'attendance_status'     => $attendance->status,
                'attendance_message'    => null,
            ];
        }

        return [
            'success'               => true,
            'has_checked_in'        => false,
            'has_checked_out'       => false,
            'check_in_time'         => '-- : -- : --',
            'check_out_time'        => '-- : -- : --',
            'is_attendance_blocked' => false,
            'attendance_status'     => $attendance?->status,
            'attendance_message'    => null,
        ];
    }

    /**
     * Mengambil statistik presensi bulanan.
     *
     * @return array<string, mixed>
     */
    public function getMonthlyStats(User $user): array
    {
        $employee = $this->getEmployeeOrThrow($user);
        $now = Carbon::now();

        $counts = $this->attendanceRepository->getMonthlyCounts(
            (int) $employee->id,
            (int) $now->month,
            (int) $now->year
        );

        return [
            'success'          => true,
            'total_attendance' => str_pad((string) $counts['total_attendance'], 2, '0', STR_PAD_LEFT),
            'late_clock_in'    => str_pad((string) $counts['late_clock_in'], 2, '0', STR_PAD_LEFT),
            'no_clock_in'      => str_pad((string) $counts['no_clock_in'], 2, '0', STR_PAD_LEFT),
        ];
    }

    /**
     * Mengambil riwayat 5 presensi terakhir.
     *
     * @return Collection<int, array<string, mixed>>
     */
    public function getHistory(User $user): Collection
    {
        $employee = $this->getEmployeeOrThrow($user);

        return $this->attendanceRepository->getRecentHistory((int) $employee->id, 5)
            ->map(function (Attendance $att): array {
                $actualDate = Carbon::parse($att->date)->timezone('Asia/Jakarta');

                $checkInTime = $att->check_in
                    ? Carbon::parse($att->check_in)->timezone('Asia/Jakarta')
                    : null;

                $checkOutTime = $att->check_out
                    ? Carbon::parse($att->check_out)->timezone('Asia/Jakarta')
                    : null;

                $status = ucfirst((string) ($att->status ?? 'Absent'));

                if ($checkInTime && $checkInTime->format('H : i : s') > '09:00:00') {
                    $status = 'Telat';
                }

                return [
                    'date'      => $actualDate->translatedFormat('j F Y'),
                    'status'    => $status,
                    'check_in'  => $checkInTime ? $checkInTime->format('H : i : s') : null,
                    'check_out' => $checkOutTime ? $checkOutTime->format('H : i : s') : null,
                ];
            });
    }

    /**
     * Mengambil laporan presensi bulanan lengkap beserta riwayat.
     *
     * @return array<string, mixed>
     */
    public function getMonthlyReport(User $user, ?int $month = null, ?int $year = null): array
    {
        $employee = $this->getEmployeeOrThrow($user);

        $targetMonth = $month ?? (int) Carbon::now()->month;
        $targetYear = $year ?? (int) Carbon::now()->year;

        $counts = $this->attendanceRepository->getMonthlyCounts(
            (int) $employee->id,
            $targetMonth,
            $targetYear
        );

        $attendances = $this->attendanceRepository->getMonthlyAttendances(
            (int) $employee->id,
            $targetMonth,
            $targetYear
        )->map(function (Attendance $att): array {
            $actualDate = Carbon::parse($att->date)->timezone('Asia/Jakarta');

            $checkInTime = $att->check_in
                ? Carbon::parse($att->check_in)->timezone('Asia/Jakarta')
                : null;

            $checkOutTime = $att->check_out
                ? Carbon::parse($att->check_out)->timezone('Asia/Jakarta')
                : null;

            $status = ucfirst((string) ($att->status ?? 'Absent'));

            if ($checkInTime && $checkInTime->format('H : i : s') > '09:00:00') {
                $status = 'Telat';
            }

            return [
                'raw_date'  => $actualDate->format('Y-m-d'),
                'date'      => $actualDate->translatedFormat('j F Y'),
                'status'    => $status,
                'check_in'  => $checkInTime ? $checkInTime->format('H : i : s') : null,
                'check_out' => $checkOutTime ? $checkOutTime->format('H : i : s') : null,
            ];
        });

        return [
            'success' => true,
            'stats'   => [
                'total_attendance' => str_pad((string) $counts['total_attendance'], 2, '0', STR_PAD_LEFT),
                'late_clock_in'    => str_pad((string) $counts['late_clock_in'], 2, '0', STR_PAD_LEFT),
                'no_clock_in'      => str_pad((string) $counts['no_clock_in'], 2, '0', STR_PAD_LEFT),
            ],
            'history' => $attendances,
        ];
    }

    /**
     * Mengambil presensi anggota tim dalam bulan/tahun tertentu.
     *
     * @return Collection<int, Attendance>
     */
    public function getMemberAttendances(Employee $targetEmployee, ?int $month = null, ?int $year = null): Collection
    {
        $targetMonth = $month ?? (int) Carbon::now()->month;
        $targetYear = $year ?? (int) Carbon::now()->year;

        $startDate = Carbon::create($targetYear, $targetMonth, 1)->startOfMonth()->toDateString();
        $endDate = Carbon::create($targetYear, $targetMonth, 1)->endOfMonth()->toDateString();

        return $this->attendanceRepository->getMemberAttendances((int) $targetEmployee->id, $startDate, $endDate);
    }

    /**
     * Memeriksa dan mengembalikan profil karyawan dari user.
     */
    private function getEmployeeOrThrow(User $user): Employee
    {
        $user->loadMissing('employee');

        if (!$user->employee) {
            throw new RuntimeException('Profil karyawan tidak ditemukan.');
        }

        return $user->employee;
    }

    /**
     * Menentukan apakah presensi hari ini diblokir (cuti/alpa).
     *
     * @return array{is_blocked: bool, status: ?string, message: ?string}
     */
    public function getTodayAttendanceBlockResult(User $user): array
    {
        $employee = $this->getEmployeeOrThrow($user);
        $blockedAttendance = $this->attendanceRepository->findTodayBlockedAttendance((int) $employee->id);

        if (!$blockedAttendance || $blockedAttendance->check_in !== null) {
            return [
                'is_blocked' => false,
                'status'     => null,
                'message'    => null,
            ];
        }

        $status = trim((string) $blockedAttendance->status);
        $normalizedStatus = strtolower($status);

        if (!in_array($normalizedStatus, ['cuti', 'alpa'], true)) {
            return [
                'is_blocked' => false,
                'status'     => $status !== '' ? $status : null,
                'message'    => null,
            ];
        }

        $message = $normalizedStatus === 'cuti'
            ? 'Presensi tidak dapat dilakukan karena Anda sedang cuti hari ini.'
            : 'Presensi tidak dapat dilakukan karena status kehadiran hari ini adalah alpa.';

        return [
            'is_blocked' => true,
            'status'     => ucfirst($normalizedStatus),
            'message'    => $message,
        ];
    }

    /**
     * Menentukan validasi lokasi (tugas luar vs polygon geofence).
     *
     * @return array<string, mixed>
     */
    public function getLocationValidationResult(User $user, float $latitude, float $longitude): array
    {
        $employee = $this->getEmployeeOrThrow($user);
        $workAssignment = $this->attendanceRepository->findActiveWorkAssignment((int) $employee->id);

        if ($workAssignment) {
            return [
                'is_valid'           => true,
                'location_status'    => 'outside_duty',
                'message'            => 'Surat tugas luar aktif. Lokasi GPS aktual akan dicatat sebagai bukti presensi.',
                'zone_id'            => null,
                'zone_name'          => null,
                'work_assignment_id' => (int) $workAssignment->id,
                'work_assignment'    => $this->formatWorkAssignment($workAssignment),
            ];
        }

        $zoneIds = $this->zoneService->getApplicableZoneIds($employee)
            ->map(static fn($id): int => (int) $id)
            ->all();

        $zone = $this->attendanceRepository->matchNearestZone(
            $zoneIds,
            $latitude,
            $longitude,
            self::TOLERANCE_METERS
        );

        if (!$zone) {
            return [
                'is_valid'           => false,
                'location_status'    => 'outside_area',
                'message'            => 'Lokasi berada di luar area presensi.',
                'zone_id'            => null,
                'zone_name'          => null,
                'work_assignment_id' => null,
                'work_assignment'    => null,
            ];
        }

        $isInsideArea = $zone->location_status === 'inside_area';

        return [
            'is_valid'           => true,
            'location_status'    => $zone->location_status,
            'message'            => $isInsideArea
                ? 'Lokasi berada di area presensi.'
                : 'Lokasi berada di zona toleransi.',
            'zone_id'            => (int) $zone->id,
            'zone_name'          => $zone->name,
            'work_assignment_id' => null,
            'work_assignment'    => null,
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function formatWorkAssignment(WorkAssignment $workAssignment): array
    {
        return [
            'id'                => (int) $workAssignment->id,
            'assignment_number' => $workAssignment->assignment_number,
            'destination'       => $workAssignment->destination,
            'purpose'           => $workAssignment->purpose,
            'start_date'        => $workAssignment->start_date?->toDateString(),
            'end_date'          => $workAssignment->end_date?->toDateString(),
        ];
    }
}


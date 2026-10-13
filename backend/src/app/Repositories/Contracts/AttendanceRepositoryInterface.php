<?php

declare(strict_types=1);

namespace App\Repositories\Contracts;

use App\Models\Attendance;
use App\Models\WorkAssignment;
use Illuminate\Support\Collection;

interface AttendanceRepositoryInterface
{
    /**
     * Membuat catatan presensi baru.
     *
     * @param array<string, mixed> $data
     */
    public function create(array $data): Attendance;

    /**
     * Memperbarui catatan presensi.
     *
     * @param array<string, mixed> $data
     */
    public function update(Attendance $attendance, array $data): bool;

    /**
     * Mencari data presensi karyawan pada tanggal tertentu (default: hari ini).
     */
    public function findTodayAttendance(int $employeeId, ?string $date = null): ?Attendance;

    /**
     * Mencari data presensi yang sudah check-in pada tanggal tertentu (default: hari ini).
     */
    public function findTodayCheckedInAttendance(int $employeeId, ?string $date = null): ?Attendance;

    /**
     * Mencari data presensi yang berstatus diblokir (cuti/alpa tanpa check-in).
     */
    public function findTodayBlockedAttendance(int $employeeId, ?string $date = null): ?Attendance;

    /**
     * Mengambil surat tugas luar yang aktif untuk karyawan pada tanggal tertentu.
     */
    public function findActiveWorkAssignment(int $employeeId, ?string $date = null): ?WorkAssignment;

    /**
     * Mengambil daftar zona presensi beserta WKT representasi polygon (ST_AsText).
     *
     * @param list<int> $zoneIds
     * @return Collection<int, object>
     */
    public function getZonesWktByIds(array $zoneIds): Collection;

    /**
     * Menjalankan query spasial untuk mencocokkan titik koordinat dengan zona valid atau toleransi.
     *
     * @param list<int> $zoneIds
     */
    public function matchNearestZone(
        array $zoneIds,
        float $latitude,
        float $longitude,
        int $toleranceMeters = 10
    ): ?object;

    /**
     * Menjalankan query spasial uji geofencing untuk menghitung jarak terdekat ke polygon dan status area.
     *
     * @param list<int> $zoneIds
     */
    public function testNearestZoneDistance(
        array $zoneIds,
        float $latitude,
        float $longitude,
        int $toleranceMeters = 10
    ): ?object;

    /**
     * Mengambil ringkasan statistik presensi bulanan (total hadir, telat, tanpa check-in).
     *
     * @return array{total_attendance: int, late_clock_in: int, no_clock_in: int}
     */
    public function getMonthlyCounts(int $employeeId, int $month, int $year): array;

    /**
     * Mengambil riwayat presensi terbaru (default 5 item).
     *
     * @return Collection<int, Attendance>
     */
    public function getRecentHistory(int $employeeId, int $limit = 5): Collection;

    /**
     * Mengambil seluruh data presensi dalam satu bulan kalender.
     *
     * @return Collection<int, Attendance>
     */
    public function getMonthlyAttendances(int $employeeId, int $month, int $year): Collection;

    /**
     * Mengambil daftar presensi anggota tim dalam rentang tanggal tertentu.
     *
     * @return Collection<int, Attendance>
     */
    public function getMemberAttendances(int $employeeId, string $startDate, string $endDate): Collection;
}


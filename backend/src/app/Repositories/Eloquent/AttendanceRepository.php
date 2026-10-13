<?php

declare(strict_types=1);

namespace App\Repositories\Eloquent;

use App\Models\Attendance;
use App\Models\WorkAssignment;
use App\Repositories\Contracts\AttendanceRepositoryInterface;
use Carbon\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class AttendanceRepository implements AttendanceRepositoryInterface
{
    /**
     * {@inheritdoc}
     */
    public function create(array $data): Attendance
    {
        return Attendance::create($data);
    }

    /**
     * {@inheritdoc}
     */
    public function update(Attendance $attendance, array $data): bool
    {
        return $attendance->update($data);
    }

    /**
     * {@inheritdoc}
     */
    public function findTodayAttendance(int $employeeId, ?string $date = null): ?Attendance
    {
        $targetDate = $date ?? Carbon::today()->toDateString();

        return Attendance::where('employee_id', $employeeId)
            ->whereDate('date', $targetDate)
            ->orderByDesc('id')
            ->first();
    }

    /**
     * {@inheritdoc}
     */
    public function findTodayCheckedInAttendance(int $employeeId, ?string $date = null): ?Attendance
    {
        $targetDate = $date ?? Carbon::today()->toDateString();

        return Attendance::where('employee_id', $employeeId)
            ->whereDate('date', $targetDate)
            ->whereNotNull('check_in')
            ->orderByDesc('id')
            ->first();
    }

    /**
     * {@inheritdoc}
     */
    public function findTodayBlockedAttendance(int $employeeId, ?string $date = null): ?Attendance
    {
        $targetDate = $date ?? Carbon::today()->toDateString();

        return Attendance::where('employee_id', $employeeId)
            ->whereDate('date', $targetDate)
            ->whereNull('check_in')
            ->whereRaw('LOWER(TRIM(status)) IN (?, ?)', ['cuti', 'alpa'])
            ->orderByDesc('id')
            ->first();
    }

    /**
     * {@inheritdoc}
     */
    public function findActiveWorkAssignment(int $employeeId, ?string $date = null): ?WorkAssignment
    {
        $targetDate = $date ?? Carbon::today()->toDateString();

        return WorkAssignment::query()
            ->whereHas('employees', static function ($query) use ($employeeId): void {
                $query->where('employees.id', $employeeId);
            })
            ->where('is_active', true)
            ->whereDate('start_date', '<=', $targetDate)
            ->whereDate('end_date', '>=', $targetDate)
            ->orderByDesc('start_date')
            ->orderByDesc('id')
            ->first();
    }

    /**
     * {@inheritdoc}
     */
    public function getZonesWktByIds(array $zoneIds): Collection
    {
        if (empty($zoneIds)) {
            return collect();
        }

        return DB::table('attendance_zones')
            ->whereIn('id', $zoneIds)
            ->select(['id', 'name'])
            ->selectRaw('ST_AsText(area) AS area')
            ->orderBy('id')
            ->get();
    }

    /**
     * {@inheritdoc}
     */
    public function matchNearestZone(
        array $zoneIds,
        float $latitude,
        float $longitude,
        int $toleranceMeters = 10
    ): ?object {
        if (empty($zoneIds)) {
            return null;
        }

        $zonePlaceholders = implode(', ', array_fill(0, count($zoneIds), '?'));

        $sql = <<<SQL
            WITH point AS (
                SELECT ST_SetSRID(
                    ST_MakePoint(?, ?),
                    4326
                ) AS geom
            ),
            matched_zone AS MATERIALIZED (
                SELECT
                    attendance_zones.id,
                    attendance_zones.name,
                    CASE
                        WHEN ST_Covers(
                            attendance_zones.area,
                            point.geom
                        )
                        THEN 'inside_area'
                        ELSE 'tolerance_zone'
                    END AS location_status
                FROM attendance_zones
                CROSS JOIN point
                WHERE attendance_zones.id IN ({$zonePlaceholders})
                AND ST_DWithin(
                        attendance_zones.area::geography,
                        point.geom::geography,
                        ?
                )
            )
            SELECT
                id,
                name,
                location_status
            FROM matched_zone
            ORDER BY
                CASE location_status
                    WHEN 'inside_area' THEN 0
                    ELSE 1
                END,
                id
            LIMIT 1
        SQL;

        $bindings = [
            $longitude,
            $latitude,
            ...$zoneIds,
            $toleranceMeters,
        ];

        return DB::selectOne($sql, $bindings);
    }

    /**
     * {@inheritdoc}
     */
    public function testNearestZoneDistance(
        array $zoneIds,
        float $latitude,
        float $longitude,
        int $toleranceMeters = 10
    ): ?object {
        if (empty($zoneIds)) {
            return null;
        }

        $zonePlaceholders = implode(', ', array_fill(0, count($zoneIds), '?'));

        $sql = <<<SQL
            WITH point AS (
                SELECT ST_SetSRID(
                    ST_MakePoint(?, ?),
                    4326
                ) AS geom
            ),
            nearest_zone AS (
                SELECT
                    attendance_zones.id,
                    attendance_zones.name,
                    ST_Covers(
                        attendance_zones.area,
                        point.geom
                    ) AS is_inside,
                    ST_Distance(
                        attendance_zones.area::geography,
                        point.geom::geography
                    ) AS distance_meters
                FROM attendance_zones
                CROSS JOIN point
                WHERE attendance_zones.id IN ({$zonePlaceholders})
                ORDER BY
                    distance_meters ASC,
                    attendance_zones.id ASC
                LIMIT 1
            )
            SELECT
                id,
                name,
                is_inside,
                distance_meters,
                CASE
                    WHEN is_inside
                        THEN 'inside_area'
                    WHEN distance_meters <= ?
                        THEN 'tolerance_zone'
                    ELSE 'outside_area'
                END AS location_status
            FROM nearest_zone
        SQL;

        $bindings = [
            $longitude,
            $latitude,
            ...$zoneIds,
            $toleranceMeters,
        ];

        return DB::selectOne($sql, $bindings);
    }

    /**
     * {@inheritdoc}
     */
    public function getMonthlyCounts(int $employeeId, int $month, int $year): array
    {
        $totalAttendance = Attendance::where('employee_id', $employeeId)
            ->whereMonth('check_in', $month)
            ->whereYear('check_in', $year)
            ->whereNotNull('check_in')
            ->count();

        $lateClockIn = Attendance::where('employee_id', $employeeId)
            ->whereMonth('check_in', $month)
            ->whereYear('check_in', $year)
            ->whereTime('check_in', '>', '09:00:00')
            ->count();

        $noClockIn = Attendance::where('employee_id', $employeeId)
            ->whereMonth('date', $month)
            ->whereYear('date', $year)
            ->whereNull('check_in')
            ->count();

        return [
            'total_attendance' => $totalAttendance,
            'late_clock_in'    => $lateClockIn,
            'no_clock_in'      => $noClockIn,
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function getRecentHistory(int $employeeId, int $limit = 5): Collection
    {
        return Attendance::where('employee_id', $employeeId)
            ->orderBy('date', 'desc')
            ->take($limit)
            ->get();
    }

    /**
     * {@inheritdoc}
     */
    public function getMonthlyAttendances(int $employeeId, int $month, int $year): Collection
    {
        return Attendance::where('employee_id', $employeeId)
            ->whereMonth('date', $month)
            ->whereYear('date', $year)
            ->orderBy('date', 'desc')
            ->get();
    }

    /**
     * {@inheritdoc}
     */
    public function getMemberAttendances(int $employeeId, string $startDate, string $endDate): Collection
    {
        return Attendance::where('employee_id', $employeeId)
            ->select([
                'id',
                'employee_id',
                'date',
                'check_in',
                'check_out',
                'status',
            ])
            ->whereBetween('date', [$startDate, $endDate])
            ->orderByDesc('date')
            ->get();
    }
}


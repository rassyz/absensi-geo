<?php

declare(strict_types=1);

namespace Tests\Unit;

use App\Models\Attendance;
use App\Models\Department;
use App\Models\Employee;
use App\Models\User;
use App\Models\WorkAssignment;
use App\Repositories\Contracts\AttendanceRepositoryInterface;
use App\Services\AttendanceService;
use App\Services\EmployeeAttendanceZoneService;
use Carbon\Carbon;
use Mockery;
use Tests\TestCase;

class AttendanceServiceTest extends TestCase
{
    private AttendanceRepositoryInterface $repository;
    private EmployeeAttendanceZoneService $zoneService;
    private AttendanceService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->repository = Mockery::mock(AttendanceRepositoryInterface::class);
        $this->zoneService = Mockery::mock(EmployeeAttendanceZoneService::class);
        $this->service = new AttendanceService($this->repository, $this->zoneService);
    }

    protected function tearDown(): void
    {
        Mockery::close();
        parent::tearDown();
    }

    private function makeUserWithEmployee(int $employeeId = 1, string $position = 'Staff'): User
    {
        $user = new User();
        $user->id = 10;
        $employee = new Employee();
        $employee->id = $employeeId;
        $employee->position = $position;
        $employee->department_id = 2;
        $user->setRelation('employee', $employee);

        return $user;
    }

    public function test_get_user_zone_config_returns_outside_duty_when_active_assignment_exists(): void
    {
        $user = $this->makeUserWithEmployee();

        $assignment = new WorkAssignment();
        $assignment->id = 99;
        $assignment->assignment_number = 'ST-001';
        $assignment->destination = 'Jakarta';
        $assignment->purpose = 'Rapat dinas';
        $assignment->start_date = Carbon::parse('2026-10-10');
        $assignment->end_date = Carbon::parse('2026-10-15');

        $this->repository->shouldReceive('findActiveWorkAssignment')
            ->once()
            ->with(1)
            ->andReturn($assignment);

        $result = $this->service->getUserZoneConfig($user);

        $this->assertTrue($result['success']);
        $this->assertSame('outside_duty', $result['attendance_mode']);
        $this->assertNull($result['zone_source']);
        $this->assertEmpty($result['zones']);
        $this->assertSame('ST-001', $result['work_assignment']['assignment_number']);
    }

    public function test_get_user_zone_config_returns_regular_mode_when_no_assignment(): void
    {
        $user = $this->makeUserWithEmployee();

        $this->repository->shouldReceive('findActiveWorkAssignment')
            ->once()
            ->with(1)
            ->andReturn(null);

        $this->zoneService->shouldReceive('getApplicableZoneIds')
            ->once()
            ->andReturn(collect([101, 102]));

        $zoneObj = (object) [
            'id'   => 101,
            'name' => 'Kantor Pusat',
            'area' => 'POLYGON((...))',
        ];

        $this->repository->shouldReceive('getZonesWktByIds')
            ->once()
            ->with([101, 102])
            ->andReturn(collect([$zoneObj]));

        $this->zoneService->shouldReceive('getZoneSource')
            ->once()
            ->andReturn('department');

        $result = $this->service->getUserZoneConfig($user);

        $this->assertTrue($result['success']);
        $this->assertSame('regular', $result['attendance_mode']);
        $this->assertSame('department', $result['zone_source']);
        $this->assertCount(1, $result['zones']);
        $this->assertSame('Kantor Pusat', $result['zones'][0]['name']);
    }

    public function test_validate_location_status_returns_blocked_when_user_is_on_leave(): void
    {
        $user = $this->makeUserWithEmployee();

        $blocked = new Attendance();
        $blocked->status = 'Cuti';
        $blocked->check_in = null;

        $this->repository->shouldReceive('findTodayBlockedAttendance')
            ->once()
            ->with(1)
            ->andReturn($blocked);

        $result = $this->service->validateLocationStatus($user, -6.200, 106.816);

        $this->assertTrue($result['success']);
        $this->assertFalse($result['is_valid']);
        $this->assertTrue($result['is_attendance_blocked']);
        $this->assertSame('Cuti', $result['attendance_status']);
        $this->assertSame('attendance_blocked', $result['location_status']);
    }

    public function test_check_in_fails_when_already_checked_in(): void
    {
        $user = $this->makeUserWithEmployee();

        $this->repository->shouldReceive('findTodayBlockedAttendance')
            ->once()
            ->with(1)
            ->andReturn(null);

        $existing = new Attendance();
        $existing->id = 55;
        $existing->check_in = Carbon::now();

        $this->repository->shouldReceive('findTodayCheckedInAttendance')
            ->once()
            ->with(1)
            ->andReturn($existing);

        $result = $this->service->checkIn($user, -6.200, 106.816, null);

        $this->assertSame('already_checked_in', $result['status']);
        $this->assertSame('Anda sudah melakukan presensi masuk hari ini.', $result['message']);
    }

    public function test_check_in_fails_when_outside_zone(): void
    {
        $user = $this->makeUserWithEmployee();

        $this->repository->shouldReceive('findTodayBlockedAttendance')
            ->once()
            ->with(1)
            ->andReturn(null);

        $this->repository->shouldReceive('findTodayCheckedInAttendance')
            ->once()
            ->with(1)
            ->andReturn(null);

        $this->repository->shouldReceive('findActiveWorkAssignment')
            ->once()
            ->with(1)
            ->andReturn(null);

        $this->zoneService->shouldReceive('getApplicableZoneIds')
            ->once()
            ->andReturn(collect([10]));

        $this->repository->shouldReceive('matchNearestZone')
            ->once()
            ->with([10], -6.200, 106.816, 10)
            ->andReturn(null);

        $result = $this->service->checkIn($user, -6.200, 106.816, null);

        $this->assertSame('outside_zone', $result['status']);
        $this->assertSame('outside_area', $result['location_status']);
    }

    public function test_check_in_succeeds_when_inside_zone(): void
    {
        $user = $this->makeUserWithEmployee();

        $this->repository->shouldReceive('findTodayBlockedAttendance')
            ->once()
            ->with(1)
            ->andReturn(null);

        $this->repository->shouldReceive('findTodayCheckedInAttendance')
            ->once()
            ->with(1)
            ->andReturn(null);

        $this->repository->shouldReceive('findActiveWorkAssignment')
            ->once()
            ->with(1)
            ->andReturn(null);

        $this->zoneService->shouldReceive('getApplicableZoneIds')
            ->once()
            ->andReturn(collect([10]));

        $matchedZone = (object) [
            'id'              => 10,
            'name'            => 'Head Office',
            'location_status' => 'inside_area',
        ];

        $this->repository->shouldReceive('matchNearestZone')
            ->once()
            ->with([10], -6.200, 106.816, 10)
            ->andReturn($matchedZone);

        $createdAttendance = new Attendance();
        $createdAttendance->id = 77;
        $createdAttendance->status = 'Hadir';

        $this->repository->shouldReceive('create')
            ->once()
            ->with(Mockery::on(function (array $data): bool {
                return $data['employee_id'] === 1
                    && $data['attendance_zone_id'] === 10
                    && $data['source'] === 'Mobile';
            }))
            ->andReturn($createdAttendance);

        $result = $this->service->checkIn($user, -6.200, 106.816, null);

        $this->assertSame('ok', $result['status']);
        $this->assertSame('Presensi masuk berhasil.', $result['message']);
        $this->assertSame($createdAttendance, $result['data']);
    }

    public function test_check_out_fails_when_not_checked_in(): void
    {
        $user = $this->makeUserWithEmployee();

        $this->repository->shouldReceive('findTodayBlockedAttendance')
            ->once()
            ->with(1)
            ->andReturn(null);

        $this->repository->shouldReceive('findActiveWorkAssignment')
            ->once()
            ->with(1)
            ->andReturn(null);

        $this->zoneService->shouldReceive('getApplicableZoneIds')
            ->once()
            ->andReturn(collect([10]));

        $matchedZone = (object) [
            'id'              => 10,
            'name'            => 'Head Office',
            'location_status' => 'inside_area',
        ];

        $this->repository->shouldReceive('matchNearestZone')
            ->once()
            ->with([10], -6.200, 106.816, 10)
            ->andReturn($matchedZone);

        $this->repository->shouldReceive('findTodayCheckedInAttendance')
            ->once()
            ->with(1)
            ->andReturn(null);

        $result = $this->service->checkOut($user, -6.200, 106.816, null);

        $this->assertSame('not_checked_in', $result['status']);
        $this->assertSame('Anda belum melakukan presensi masuk hari ini.', $result['message']);
    }

    public function test_check_out_succeeds_when_checked_in(): void
    {
        $user = $this->makeUserWithEmployee();

        $this->repository->shouldReceive('findTodayBlockedAttendance')
            ->once()
            ->with(1)
            ->andReturn(null);

        $this->repository->shouldReceive('findActiveWorkAssignment')
            ->once()
            ->with(1)
            ->andReturn(null);

        $this->zoneService->shouldReceive('getApplicableZoneIds')
            ->once()
            ->andReturn(collect([10]));

        $matchedZone = (object) [
            'id'              => 10,
            'name'            => 'Head Office',
            'location_status' => 'inside_area',
        ];

        $this->repository->shouldReceive('matchNearestZone')
            ->once()
            ->with([10], -6.200, 106.816, 10)
            ->andReturn($matchedZone);

        $checkedInAttendance = new Attendance();
        $checkedInAttendance->id = 88;

        $this->repository->shouldReceive('findTodayCheckedInAttendance')
            ->once()
            ->with(1)
            ->andReturn($checkedInAttendance);

        $this->repository->shouldReceive('update')
            ->once()
            ->with($checkedInAttendance, Mockery::on(function (array $data): bool {
                return isset($data['check_out']) && $data['check_out_latitude'] === -6.200;
            }))
            ->andReturn(true);

        $result = $this->service->checkOut($user, -6.200, 106.816, null);

        $this->assertSame('ok', $result['status']);
        $this->assertSame('Presensi keluar berhasil. Hati-hati di jalan!', $result['message']);
    }

    public function test_get_monthly_stats_formats_with_zero_padding(): void
    {
        $user = $this->makeUserWithEmployee();

        $this->repository->shouldReceive('getMonthlyCounts')
            ->once()
            ->andReturn([
                'total_attendance' => 5,
                'late_clock_in'    => 1,
                'no_clock_in'      => 0,
            ]);

        $stats = $this->service->getMonthlyStats($user);

        $this->assertTrue($stats['success']);
        $this->assertSame('05', $stats['total_attendance']);
        $this->assertSame('01', $stats['late_clock_in']);
        $this->assertSame('00', $stats['no_clock_in']);
    }
}


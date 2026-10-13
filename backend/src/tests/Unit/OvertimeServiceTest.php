<?php

declare(strict_types=1);

namespace Tests\Unit;

use App\Models\Employee;
use App\Models\Overtime;
use App\Models\User;
use App\Repositories\Contracts\OvertimeRepositoryInterface;
use App\Services\EmployeeAttendanceZoneService;
use App\Services\OvertimeService;
use Carbon\Carbon;
use Mockery;
use Tests\TestCase;

class OvertimeServiceTest extends TestCase
{
    private OvertimeRepositoryInterface $repository;
    private EmployeeAttendanceZoneService $zoneService;
    private OvertimeService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->repository = Mockery::mock(OvertimeRepositoryInterface::class);
        $this->zoneService = Mockery::mock(EmployeeAttendanceZoneService::class);
        $this->service = new OvertimeService($this->repository, $this->zoneService);
    }

    protected function tearDown(): void
    {
        Mockery::close();
        parent::tearDown();
    }

    private function makeUserWithEmployee(int $employeeId = 1): User
    {
        $user = new User();
        $user->id = 10;
        $employee = new Employee();
        $employee->id = $employeeId;
        $employee->department_id = 3;
        $user->setRelation('employee', $employee);

        return $user;
    }

    public function test_get_employee_overtimes_formats_data_correctly(): void
    {
        $user = $this->makeUserWithEmployee();

        $overtime = new Overtime();
        $overtime->id = 5;
        $overtime->title = 'Lembur Akhir Bulan';
        $overtime->date = '2026-10-30';
        $overtime->planned_start_time = '17:00:00';
        $overtime->planned_end_time = '20:00:00';
        $overtime->notes = 'Penyusunan laporan keuangan';

        $pivot = (object) [
            'status'    => 'Pending',
            'check_in'  => null,
            'check_out' => null,
        ];
        $overtime->setRelation('pivot', $pivot);

        $this->repository->shouldReceive('getEmployeeOvertimes')
            ->once()
            ->with(1)
            ->andReturn(collect([$overtime]));

        $result = $this->service->getEmployeeOvertimes($user);

        $this->assertCount(1, $result);
        $this->assertSame(5, $result[0]['id']);
        $this->assertSame('Lembur Akhir Bulan', $result[0]['title']);
        $this->assertSame('2026-10-30', $result[0]['raw_date']);
        $this->assertSame('17:00', $result[0]['planned_start_time']);
        $this->assertSame('20:00', $result[0]['planned_end_time']);
        $this->assertSame('Pending', $result[0]['status']);
        $this->assertNull($result[0]['actual_check_in']);
        $this->assertNull($result[0]['actual_check_out']);
    }

    public function test_clock_in_fails_when_outside_zone(): void
    {
        $user = $this->makeUserWithEmployee();

        $this->zoneService->shouldReceive('getApplicableZoneIds')
            ->once()
            ->andReturn(collect([20]));

        $this->repository->shouldReceive('isLocationInZones')
            ->once()
            ->with([20], -6.200, 106.816, 10)
            ->andReturn(false);

        $result = $this->service->clockIn($user, 5, -6.200, 106.816);

        $this->assertSame('outside_zone', $result['status']);
        $this->assertSame('Gagal memcatat lembur. Anda berada di luar area absensi kantor.', $result['message']);
    }

    public function test_clock_in_fails_when_not_assigned(): void
    {
        $user = $this->makeUserWithEmployee();

        $this->zoneService->shouldReceive('getApplicableZoneIds')
            ->once()
            ->andReturn(collect([20]));

        $this->repository->shouldReceive('isLocationInZones')
            ->once()
            ->with([20], -6.200, 106.816, 10)
            ->andReturn(true);

        $this->repository->shouldReceive('findAssignedOvertime')
            ->once()
            ->with(1, 5)
            ->andReturn(null);

        $result = $this->service->clockIn($user, 5, -6.200, 106.816);

        $this->assertSame('not_assigned', $result['status']);
        $this->assertSame('Anda tidak ditugaskan untuk lembur ini.', $result['message']);
    }

    public function test_clock_in_fails_when_already_clocked_in(): void
    {
        $user = $this->makeUserWithEmployee();

        $this->zoneService->shouldReceive('getApplicableZoneIds')
            ->once()
            ->andReturn(collect([20]));

        $this->repository->shouldReceive('isLocationInZones')
            ->once()
            ->with([20], -6.200, 106.816, 10)
            ->andReturn(true);

        $overtime = new Overtime();
        $overtime->id = 5;
        $pivot = (object) [
            'status'   => 'Sedang Lembur',
            'check_in' => Carbon::now()->toDateTimeString(),
        ];
        $overtime->setRelation('pivot', $pivot);

        $this->repository->shouldReceive('findAssignedOvertime')
            ->once()
            ->with(1, 5)
            ->andReturn($overtime);

        $result = $this->service->clockIn($user, 5, -6.200, 106.816);

        $this->assertSame('already_clocked_in', $result['status']);
        $this->assertSame('Anda sudah melakukan clock-in lembur.', $result['message']);
    }

    public function test_clock_in_succeeds_when_valid(): void
    {
        $user = $this->makeUserWithEmployee();

        $this->zoneService->shouldReceive('getApplicableZoneIds')
            ->once()
            ->andReturn(collect([20]));

        $this->repository->shouldReceive('isLocationInZones')
            ->once()
            ->with([20], -6.200, 106.816, 10)
            ->andReturn(true);

        $overtime = new Overtime();
        $overtime->id = 5;
        $pivot = (object) [
            'status'   => 'Pending',
            'check_in' => null,
        ];
        $overtime->setRelation('pivot', $pivot);

        $this->repository->shouldReceive('findAssignedOvertime')
            ->once()
            ->with(1, 5)
            ->andReturn($overtime);

        $this->repository->shouldReceive('updatePivot')
            ->once()
            ->with(1, 5, Mockery::on(function (array $data): bool {
                return $data['status'] === 'Sedang Lembur'
                    && $data['check_in_latitude'] === -6.200
                    && $data['check_in_longitude'] === 106.816
                    && isset($data['check_in']);
            }))
            ->andReturn(true);

        $result = $this->service->clockIn($user, 5, -6.200, 106.816);

        $this->assertSame('ok', $result['status']);
        $this->assertSame('Clock In Lembur Berhasil. Anda berada di dalam area.', $result['message']);
    }

    public function test_clock_out_fails_when_outside_zone(): void
    {
        $user = $this->makeUserWithEmployee();

        $this->zoneService->shouldReceive('getApplicableZoneIds')
            ->once()
            ->andReturn(collect([20]));

        $this->repository->shouldReceive('isLocationInZones')
            ->once()
            ->with([20], -6.200, 106.816, 10)
            ->andReturn(false);

        $result = $this->service->clockOut($user, 5, -6.200, 106.816);

        $this->assertSame('outside_zone', $result['status']);
        $this->assertSame('Anda berada di luar area absensi kantor.', $result['message']);
    }

    public function test_clock_out_fails_when_not_clocked_in(): void
    {
        $user = $this->makeUserWithEmployee();

        $this->zoneService->shouldReceive('getApplicableZoneIds')
            ->once()
            ->andReturn(collect([20]));

        $this->repository->shouldReceive('isLocationInZones')
            ->once()
            ->with([20], -6.200, 106.816, 10)
            ->andReturn(true);

        $overtime = new Overtime();
        $overtime->id = 5;
        $pivot = (object) [
            'status'   => 'Pending',
            'check_in' => null,
        ];
        $overtime->setRelation('pivot', $pivot);

        $this->repository->shouldReceive('findAssignedOvertime')
            ->once()
            ->with(1, 5)
            ->andReturn($overtime);

        $result = $this->service->clockOut($user, 5, -6.200, 106.816);

        $this->assertSame('not_clocked_in', $result['status']);
        $this->assertSame('Anda belum melakukan clock-in lembur.', $result['message']);
    }

    public function test_clock_out_fails_when_already_clocked_out(): void
    {
        $user = $this->makeUserWithEmployee();

        $this->zoneService->shouldReceive('getApplicableZoneIds')
            ->once()
            ->andReturn(collect([20]));

        $this->repository->shouldReceive('isLocationInZones')
            ->once()
            ->with([20], -6.200, 106.816, 10)
            ->andReturn(true);

        $overtime = new Overtime();
        $overtime->id = 5;
        $pivot = (object) [
            'status'    => 'Selesai',
            'check_in'  => Carbon::now()->subHours(3)->toDateTimeString(),
            'check_out' => Carbon::now()->toDateTimeString(),
        ];
        $overtime->setRelation('pivot', $pivot);

        $this->repository->shouldReceive('findAssignedOvertime')
            ->once()
            ->with(1, 5)
            ->andReturn($overtime);

        $result = $this->service->clockOut($user, 5, -6.200, 106.816);

        $this->assertSame('already_clocked_out', $result['status']);
        $this->assertSame('Anda sudah melakukan clock-out lembur.', $result['message']);
    }

    public function test_clock_out_succeeds_when_valid(): void
    {
        $user = $this->makeUserWithEmployee();

        $this->zoneService->shouldReceive('getApplicableZoneIds')
            ->once()
            ->andReturn(collect([20]));

        $this->repository->shouldReceive('isLocationInZones')
            ->once()
            ->with([20], -6.200, 106.816, 10)
            ->andReturn(true);

        $overtime = new Overtime();
        $overtime->id = 5;
        $pivot = (object) [
            'status'    => 'Sedang Lembur',
            'check_in'  => Carbon::now()->subHours(2)->toDateTimeString(),
            'check_out' => null,
        ];
        $overtime->setRelation('pivot', $pivot);

        $this->repository->shouldReceive('findAssignedOvertime')
            ->once()
            ->with(1, 5)
            ->andReturn($overtime);

        $this->repository->shouldReceive('updatePivot')
            ->once()
            ->with(1, 5, Mockery::on(function (array $data): bool {
                return $data['status'] === 'Selesai'
                    && $data['check_out_latitude'] === -6.200
                    && $data['check_out_longitude'] === 106.816
                    && isset($data['check_out']);
            }))
            ->andReturn(true);

        $result = $this->service->clockOut($user, 5, -6.200, 106.816);

        $this->assertSame('ok', $result['status']);
        $this->assertSame('Clock Out Lembur Berhasil. Terima kasih atas kerja kerasnya!', $result['message']);
    }
}


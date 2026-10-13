<?php

declare(strict_types=1);

namespace Tests\Unit;

use App\Models\Employee;
use App\Models\Leave;
use App\Models\LeaveType;
use App\Models\User;
use App\Repositories\Contracts\LeaveRepositoryInterface;
use App\Services\LeaveService;
use Carbon\Carbon;
use Mockery;
use Tests\TestCase;
use RuntimeException;

class LeaveServiceTest extends TestCase
{
    protected function tearDown(): void
    {
        Mockery::close();
        parent::tearDown();
    }

    public function test_apply_leave_throws_exception_if_user_has_no_employee(): void
    {
        $repository = Mockery::mock(LeaveRepositoryInterface::class);
        $service = new LeaveService($repository);

        $user = new User();

        $this->expectException(RuntimeException::class);
        $this->expectExceptionMessage('Unauthorized or employee record not found');

        $service->applyLeave($user, [
            'leave_type_id' => 1,
            'start_date'    => '2026-10-15',
            'end_date'      => '2026-10-16',
            'apply_days'    => 2,
            'reason'        => 'Keperluan keluarga',
        ]);
    }

    public function test_apply_leave_delegates_to_repository(): void
    {
        $repository = Mockery::mock(LeaveRepositoryInterface::class);
        $service = new LeaveService($repository);

        $user = new User();
        $employee = new Employee();
        $employee->id = 5;
        $user->setRelation('employee', $employee);

        $expectedLeave = new Leave();
        $expectedLeave->id = 10;
        $expectedLeave->employee_id = 5;

        $repository->shouldReceive('create')
            ->once()
            ->with(Mockery::on(function (array $data): bool {
                return $data['employee_id'] === 5
                    && $data['leave_type_id'] === 1
                    && $data['start_date'] === '2026-10-15'
                    && $data['end_date'] === '2026-10-16'
                    && $data['apply_days'] === 2
                    && $data['reason'] === 'Keperluan keluarga'
                    && $data['status'] === 'Pending'
                    && $data['attachment'] === null;
            }))
            ->andReturn($expectedLeave);

        $result = $service->applyLeave($user, [
            'leave_type_id' => 1,
            'start_date'    => '2026-10-15',
            'end_date'      => '2026-10-16',
            'apply_days'    => 2,
            'reason'        => 'Keperluan keluarga',
        ]);

        $this->assertSame($expectedLeave, $result);
    }

    public function test_get_dashboard_data_calculates_balance_and_structures_data(): void
    {
        $repository = Mockery::mock(LeaveRepositoryInterface::class);
        $service = new LeaveService($repository);

        $user = new User();
        $employee = new Employee();
        $employee->id = 1;
        $employee->position = 'Staff';
        $employee->department_id = 2;
        $user->setRelation('employee', $employee);

        $repository->shouldReceive('getStatusCounts')
            ->once()
            ->with(1)
            ->andReturn(collect([
                'Approved' => 4,
                'Pending'  => 1,
                'Rejected' => 1,
            ]));

        $leave = new Leave();
        $leave->id = 101;
        $leave->start_date = Carbon::parse('2026-11-01');
        $leave->end_date = Carbon::parse('2026-11-03');
        $leave->apply_days = 3;
        $leave->reason = 'Liburan';
        $leave->status = 'Pending';
        $leaveType = new LeaveType();
        $leaveType->name = 'Cuti Tahunan';
        $leave->setRelation('leaveType', $leaveType);

        $repository->shouldReceive('getEmployeeLeaves')
            ->once()
            ->with(1, ['leaveType', 'approver'])
            ->andReturn(collect([$leave]));

        $repository->shouldReceive('getPendingTeamLeaves')
            ->once()
            ->with(1, 'staff', 2, ['employee.user', 'employee.department', 'leaveType'])
            ->andReturn(collect());

        $dashboard = $service->getDashboardData($user);

        // 12 - 4 = 8
        $this->assertSame('8', $dashboard['summary']['balance']);
        $this->assertSame('4', $dashboard['summary']['approved']);
        $this->assertSame('1', $dashboard['summary']['pending']);
        $this->assertSame('1', $dashboard['summary']['cancelled']);
        $this->assertCount(1, $dashboard['leaves']);
        $this->assertSame('8', $dashboard['leaves'][0]['balance']);
        $this->assertSame('Pending', $dashboard['leaves'][0]['status']);
        $this->assertEmpty($dashboard['team_leaves']);
    }

    public function test_process_leave_returns_404_when_not_found(): void
    {
        $repository = Mockery::mock(LeaveRepositoryInterface::class);
        $service = new LeaveService($repository);

        $user = new User();
        $repository->shouldReceive('findById')
            ->once()
            ->with(999, Mockery::any())
            ->andReturn(null);

        $result = $service->processLeave($user, 999, 'Approved');

        $this->assertFalse($result['success']);
        $this->assertSame(404, $result['code']);
        $this->assertSame('Leave not found', $result['message']);
    }

    public function test_process_leave_rejects_self_approval(): void
    {
        $repository = Mockery::mock(LeaveRepositoryInterface::class);
        $service = new LeaveService($repository);

        $user = new User();
        $employee = new Employee();
        $employee->id = 7;
        $employee->position = 'Manager';
        $user->setRelation('employee', $employee);

        $leave = new Leave();
        $leave->id = 50;
        $leave->employee_id = 7; // Same employee!
        $leave->status = 'Pending';
        $leaveApplicant = new Employee();
        $leaveApplicant->id = 7;
        $leave->setRelation('employee', $leaveApplicant);

        $repository->shouldReceive('findById')
            ->once()
            ->with(50, Mockery::any())
            ->andReturn($leave);

        $result = $service->processLeave($user, 50, 'Approved');

        $this->assertFalse($result['success']);
        $this->assertSame(403, $result['code']);
        $this->assertSame('Unauthorized to process this leave', $result['message']);
    }

    public function test_process_leave_rejects_non_manager_and_non_head(): void
    {
        $repository = Mockery::mock(LeaveRepositoryInterface::class);
        $service = new LeaveService($repository);

        $user = new User();
        $approver = new Employee();
        $approver->id = 8;
        $approver->position = 'Staff';
        $approver->department_id = 1;
        $user->setRelation('employee', $approver);

        $leave = new Leave();
        $leave->id = 50;
        $leave->employee_id = 9;
        $leave->status = 'Pending';
        $applicant = new Employee();
        $applicant->id = 9;
        $applicant->department_id = 1;
        $leave->setRelation('employee', $applicant);

        $repository->shouldReceive('findById')
            ->once()
            ->with(50, Mockery::any())
            ->andReturn($leave);

        $result = $service->processLeave($user, 50, 'Approved');

        $this->assertFalse($result['success']);
        $this->assertSame(403, $result['code']);
        $this->assertSame('Unauthorized to process this leave', $result['message']);
    }
}

<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\Attendance;
use App\Models\Leave;
use App\Models\User;
use App\Repositories\Contracts\LeaveRepositoryInterface;
use Carbon\Carbon;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use RuntimeException;
use Throwable;

class LeaveService
{
    private const ANNUAL_LEAVE_QUOTA = 12;

    public function __construct(
        private readonly LeaveRepositoryInterface $leaveRepository
    ) {}

    /**
     * Memproses pengajuan cuti baru oleh karyawan.
     *
     * @param array{
     *     leave_type_id: int|string,
     *     start_date: string,
     *     end_date: string,
     *     apply_days: int|string,
     *     reason: string
     * } $data
     */
    public function applyLeave(User $user, array $data, ?UploadedFile $attachment = null): Leave
    {
        $employee = $user->employee;

        if (!$employee) {
            throw new RuntimeException('Unauthorized or employee record not found');
        }

        $attachmentPath = null;
        if ($attachment !== null) {
            $attachmentPath = $attachment->store('leave_attachments', 'public');
        }

        return $this->leaveRepository->create([
            'employee_id'   => $employee->id,
            'leave_type_id' => $data['leave_type_id'],
            'start_date'    => $data['start_date'],
            'end_date'      => $data['end_date'],
            'apply_days'    => $data['apply_days'],
            'reason'        => $data['reason'],
            'attachment'    => $attachmentPath,
            'status'        => 'Pending',
            'approved_by'   => null,
        ]);
    }

    /**
     * Mengambil dan memformat data ringkasan dashboard cuti.
     *
     * @return array<string, mixed>
     */
    public function getDashboardData(User $user): array
    {
        $employee = $user->employee;

        if (!$employee) {
            throw new RuntimeException('Unauthorized or employee record not found');
        }

        $employeeId = (int) $employee->id;
        $summary = $this->leaveRepository->getStatusCounts($employeeId);

        $balance = self::ANNUAL_LEAVE_QUOTA;
        $approved = (int) ($summary['Approved'] ?? 0);
        $pending = (int) ($summary['Pending'] ?? 0);
        $cancelled = (int) ($summary['Rejected'] ?? 0);
        $currentBalance = $balance - $approved;

        $leaves = $this->leaveRepository->getEmployeeLeaves($employeeId, ['leaveType', 'approver'])
            ->map(function (Leave $leave) use ($currentBalance): array {
                $startDate = $leave->start_date instanceof Carbon ? $leave->start_date : Carbon::parse($leave->start_date);
                $endDate = $leave->end_date instanceof Carbon ? $leave->end_date : Carbon::parse($leave->end_date);

                return [
                    'id'          => $leave->id,
                    'date_range'  => $startDate->format('M d, Y') . ' - ' . $endDate->format('M d, Y'),
                    'start_date'  => $startDate->format('Y-m-d'),
                    'end_date'    => $endDate->format('Y-m-d'),
                    'apply_days'  => $leave->apply_days,
                    'balance'     => (string) $currentBalance,
                    'leave_type'  => $leave->leaveType ? $leave->leaveType->name : 'N/A',
                    'reason'      => $leave->reason,
                    'approved_by' => $leave->status === 'Pending'
                        ? '--'
                        : ($leave->approver ? $leave->approver->name : 'Admin'),
                    'status'      => ucfirst((string) $leave->status),
                    'is_past'     => $endDate->isPast(),
                ];
            });

        $currentPosition = strtolower(trim((string) $employee->position));

        $teamLeavesRaw = $this->leaveRepository->getPendingTeamLeaves(
            $employeeId,
            $currentPosition,
            $employee->department_id ? (int) $employee->department_id : null,
            ['employee.user', 'employee.department', 'leaveType']
        );

        $teamLeaves = $teamLeavesRaw->map(function (Leave $leave): array {
            $emp = $leave->employee;
            $fullName = $emp ? ($emp->full_name ?? ($emp->user ? $emp->user->name : 'Unknown')) : 'Unknown Employee';
            $rawAvatar = ($emp && $emp->user) ? $emp->user->avatar_url : null;
            $avatarUrl = $rawAvatar ? asset('storage/' . $rawAvatar) : null;

            $startDate = $leave->start_date instanceof Carbon ? $leave->start_date : Carbon::parse($leave->start_date);
            $endDate = $leave->end_date instanceof Carbon ? $leave->end_date : Carbon::parse($leave->end_date);

            return [
                'id'            => $leave->id,
                'employee_name' => $fullName,
                'date_range'    => $startDate->format('M d, Y') . ' - ' . $endDate->format('M d, Y'),
                'start_date'    => $startDate->format('Y-m-d'),
                'end_date'      => $endDate->format('Y-m-d'),
                'leave_type'    => $leave->leaveType ? $leave->leaveType->name : 'N/A',
                'apply_days'    => $leave->apply_days,
                'reason'        => $leave->reason,
                'avatar_url'    => $avatarUrl,
                'employee'      => [
                    'full_name'  => $fullName,
                    'position'   => $emp ? $emp->position : 'Staff Member',
                    'department' => $emp && $emp->department ? $emp->department->name : 'N/A',
                    'user'       => ['avatar_url' => $avatarUrl],
                ],
            ];
        });

        return [
            'summary' => [
                'balance'   => (string) $currentBalance,
                'approved'  => (string) $approved,
                'pending'   => (string) $pending,
                'cancelled' => (string) $cancelled,
            ],
            'leaves'      => $leaves->values()->all(),
            'team_leaves' => $teamLeaves->values()->all(),
        ];
    }

    /**
     * Memproses persetujuan atau penolakan pengajuan cuti.
     *
     * @return array{success: bool, code: int, message: string}
     */
    public function processLeave(User $user, int $leaveId, string $status): array
    {
        $leave = $this->leaveRepository->findById($leaveId, [
            'employee.department.attendanceZones',
            'leaveType',
        ]);

        if (!$leave) {
            return [
                'success' => false,
                'code'    => 404,
                'message' => 'Leave not found',
            ];
        }

        if ($leave->status === 'Approved' && $status === 'Approved') {
            return [
                'success' => false,
                'code'    => 200,
                'message' => 'Leave is already approved.',
            ];
        }

        $approverEmployee = $user->employee;

        if (!$leave->employee || !$approverEmployee) {
            return [
                'success' => false,
                'code'    => 403,
                'message' => 'Unauthorized to process this leave',
            ];
        }

        $approverPosition = strtolower(trim((string) $approverEmployee->position));
        $isManager = $approverPosition === 'manager';
        $isHeadInSameDepartment = $approverPosition === 'head' &&
            $leave->employee->department_id === $approverEmployee->department_id;
        $isOwnLeave = (int) $leave->employee_id === (int) $approverEmployee->id;

        if ($isOwnLeave || (!$isManager && !$isHeadInSameDepartment)) {
            return [
                'success' => false,
                'code'    => 403,
                'message' => 'Unauthorized to process this leave',
            ];
        }

        DB::beginTransaction();

        try {
            $leave->status = $status;
            $leave->approved_by = $user->id;
            $leave->approved_at = now();
            $leave->save();

            if ($status === 'Approved') {
                $this->generateLeaveAttendances($leave);
            }

            DB::commit();

            return [
                'success' => true,
                'code'    => 200,
                'message' => 'Leave ' . $status . ' successfully',
            ];
        } catch (Throwable $e) {
            DB::rollBack();

            return [
                'success' => false,
                'code'    => 500,
                'message' => 'Terjadi kesalahan sistem: ' . $e->getMessage(),
            ];
        }
    }

    /**
     * Membuat data absensi otomatis saat cuti disetujui (melewatkan hari libur/weekend).
     */
    public function generateLeaveAttendances(Leave $leave): void
    {
        $startDate = $leave->start_date instanceof Carbon ? $leave->start_date->copy() : Carbon::parse($leave->start_date);
        $endDate = $leave->end_date instanceof Carbon ? $leave->end_date->copy() : Carbon::parse($leave->end_date);

        for ($date = $startDate; $date->lte($endDate); $date->addDay()) {
            if ($date->isWeekend()) {
                continue;
            }

            Attendance::updateOrCreate(
                [
                    'employee_id' => $leave->employee_id,
                    'date'        => $date->toDateString(),
                ],
                [
                    'leave_id'    => $leave->id,
                    'status'      => 'Cuti',
                    'source'      => 'Sistem',
                ]
            );
        }
    }
}


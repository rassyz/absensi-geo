<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\Leave;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class LeaveController extends Controller
{
    public function store(Request $request)
    {
        $validated = $request->validate([
            'leave_type_id' => 'required|exists:leave_types,id',
            'start_date' => 'required|date',
            'end_date'   => 'required|date|after_or_equal:start_date',
            'apply_days' => 'required|integer|min:1',
            'reason'     => 'required|string',
            'attachment' => 'nullable|file|mimes:jpeg,png,jpg,pdf|max:10240',
        ]);

        $user = $request->user();
        if (!$user || !$user->employee) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized or employee record not found'
            ], 401);
        }
        $employee = $user->employee;

        $attachmentPath = null;
        if ($request->hasFile('attachment')) {
            $attachmentPath = $request->file('attachment')->store('leave_attachments', 'public');
        }

        $leave = Leave::create([
            'employee_id' => $employee->id,
            'leave_type_id'  => $validated['leave_type_id'],
            'start_date'  => $validated['start_date'],
            'end_date'    => $validated['end_date'],
            'apply_days'  => $validated['apply_days'],
            'reason'      => $validated['reason'],
            'attachment'  => $attachmentPath,
            'status'      => 'Pending',
            'approved_by' => null,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Leave applied successfully',
            'data' => $leave
        ], 201);
    }

    public function getLeaveDashboard(Request $request)
    {
        try {
            $user = $request->user();
            $employeeId = $user->employee->id;

            $summary = Leave::where('employee_id', $employeeId)
                ->select('status', DB::raw('count(*) as total'))
                ->groupBy('status')
                ->get()
                ->pluck('total', 'status');

            $balance = 20; // jatah cuti
            $approved = $summary['Approved'] ?? 0;
            $pending = $summary['Pending'] ?? 0;
            $cancelled = $summary['Rejected'] ?? 0;

            $currentBalance = $balance - $approved;

            $leaves = Leave::with(['leaveType', 'approver'])
                ->where('employee_id', $employeeId)
                ->orderBy('created_at', 'desc')
                ->get()
                ->map(function ($leave) use ($currentBalance) {
                    return [
                        'id'          => $leave->id,
                        'date_range'  => Carbon::parse($leave->start_date)->format('M d, Y') . ' - ' . Carbon::parse($leave->end_date)->format('M d, Y'),
                        'start_date'  => $leave->start_date,
                        'end_date'    => $leave->end_date,
                        'apply_days'  => $leave->apply_days,
                        'balance'     => (string) $currentBalance,

                        'leave_type'  => $leave->leaveType ? $leave->leaveType->name : 'N/A',

                        'reason'      => $leave->reason,
                        'approved_by' => $leave->status === 'Pending'
                            ? '--'
                            : ($leave->approver ? $leave->approver->name : 'Admin'),
                        'status'      => ucfirst($leave->status),
                        'is_past'     => Carbon::parse($leave->end_date)->isPast(),
                    ];
                });

            $currentPosition = strtolower(trim((string) $user->employee->position));

            $teamLeavesQuery = Leave::with(['employee.user', 'leaveType'])
                ->where('status', 'Pending');

            if ($currentPosition === 'manager') {
                $teamLeavesQuery->whereHas('employee', function ($employeeQuery) use ($employeeId) {
                    $employeeQuery->where('id', '!=', $employeeId);
                });
            } elseif ($currentPosition === 'head') {
                $teamLeavesQuery->whereHas('employee', function ($employeeQuery) use ($employeeId, $user) {
                    $employeeQuery
                        ->where('department_id', $user->employee->department_id)
                        ->where('id', '!=', $employeeId);
                });
            } else {
                $teamLeavesQuery->whereRaw('1 = 0');
            }

            $teamLeavesRaw = $teamLeavesQuery
                ->orderBy('created_at', 'desc')
                ->get();

            $teamLeaves = $teamLeavesRaw->map(function ($leave) {
                $emp = $leave->employee;
                $fullName = $emp ? ($emp->full_name ?? ($emp->user ? $emp->user->name : 'Unknown')) : 'Unknown Employee';
                $rawAvatar = ($emp && $emp->user) ? $emp->user->avatar_url : null;
                $avatarUrl = $rawAvatar ? asset('storage/' . $rawAvatar) : null;

                return [
                    'id'            => $leave->id,
                    'employee_name' => $fullName,
                    'date_range'    => \Carbon\Carbon::parse($leave->start_date)->format('M d, Y') . ' - ' . \Carbon\Carbon::parse($leave->end_date)->format('M d, Y'),
                    'start_date'    => $leave->start_date,
                    'end_date'      => $leave->end_date,

                    'leave_type'    => $leave->leaveType ? $leave->leaveType->name : 'N/A',

                    'apply_days'    => $leave->apply_days,
                    'reason'        => $leave->reason,
                    'avatar_url'    => $avatarUrl,
                    'employee'      => [
                        'full_name' => $fullName,
                        'position'  => $emp ? $emp->position : 'Staff Member',
                        'user'      => ['avatar_url' => $avatarUrl]
                    ]
                ];
            });

            return response()->json([
                'success' => true,
                'summary' => [
                    'balance'   => (string) $currentBalance,
                    'approved'  => (string) $approved,
                    'pending'   => (string) $pending,
                    'cancelled' => (string) $cancelled,
                ],
                'leaves'      => $leaves,
                'team_leaves' => $teamLeaves
            ]);
        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => 'Error fetching leaves: ' . $e->getMessage()], 500);
        }
    }

    public function process(Request $request, $id)
    {
        $request->validate([
            'status' => 'required|in:Approved,Rejected'
        ]);

        $leave = Leave::with(['employee.department.attendanceZones', 'leaveType'])->find($id);

        if (!$leave) {
            return response()->json(['success' => false, 'message' => 'Leave not found'], 404);
        }

        if ($leave->status === 'Approved' && $request->status === 'Approved') {
            return response()->json(['success' => false, 'message' => 'Leave is already approved.']);
        }

        try {
            DB::beginTransaction();

            $approverEmployee = $request->user()->employee;

            if (!$leave->employee || !$approverEmployee) {
                DB::rollBack();

                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized to process this leave',
                ], 403);
            }

            $approverPosition = strtolower(
                trim((string) $approverEmployee->position)
            );

            $isManager = $approverPosition === 'manager';

            $isHeadInSameDepartment =
                $approverPosition === 'head' &&
                $leave->employee->department_id === $approverEmployee->department_id;

            $isOwnLeave = $leave->employee_id === $approverEmployee->id;

            if (
                $isOwnLeave ||
                (!$isManager && !$isHeadInSameDepartment)
            ) {
                DB::rollBack();

                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized to process this leave',
                ], 403);
            }

            $leave->status = $request->status;
            $leave->approved_by = $request->user()->id;
            $leave->approved_at = now();
            $leave->save();

            if ($request->status === 'Approved') {
                $this->generateLeaveAttendances($leave);
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Leave ' . $request->status . ' successfully'
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan sistem: ' . $e->getMessage()
            ], 500);
        }
    }

    // Fungsi untuk membuat data absensi otomatis saat cuti disetujui
    private function generateLeaveAttendances(Leave $leave)
    {
        $startDate = Carbon::parse($leave->start_date);
        $endDate = Carbon::parse($leave->end_date);


        for ($date = $startDate; $date->lte($endDate); $date->addDay()) {

            // tidak hitung hari libur
            if ($date->isWeekend()) {
                continue;
            }

            Attendance::updateOrCreate(
                [
                    'employee_id' => $leave->employee_id,
                    'date'        => $date->toDateString(),
                ],
                [
                    'leave_id'           => $leave->id,
                    'status'             => 'Cuti',
                    'source'             => 'System',
                ]
            );
        }
    }
}

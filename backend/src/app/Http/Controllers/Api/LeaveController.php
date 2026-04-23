<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Leave;
use Illuminate\Http\Request;
use App\Models\Employee;
use Carbon\Carbon;

class LeaveController extends Controller
{
    public function store(Request $request)
    {
        // 1. Validate the incoming data
        $validated = $request->validate([
            'leave_type' => 'required|string',
            'start_date' => 'required|date',
            'end_date'   => 'required|date|after_or_equal:start_date',
            'apply_days' => 'required|integer|min:1',
            'reason'     => 'required|string',
            'attachment' => 'nullable|file|mimes:jpeg,png,jpg,pdf|max:10240', // max 10MB
        ]);

        // Get the authenticated user's employee record
        $user = $request->user();
        if (!$user || !$user->employee) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized or employee record not found'
            ], 401);
        }
        $employee = $user->employee;

        // 2. Upload Attachment (if provided)
        $attachmentPath = null;
        if ($request->hasFile('attachment')) {
            $attachmentPath = $request->file('attachment')->store('leave_attachments', 'public');
        }

        // 3. LOGIC: Find the Highest Ranking Manager in the same department
        $acceptableHeadTitles = ['head', 'Head', 'Manager', 'manager'];

        $departmentHead = Employee::where('department_id', $employee->department_id)
            ->whereIn('position', $acceptableHeadTitles)
            ->first();

        // 4. Insert into Database
        $leave = Leave::create([
            'employee_id' => $employee->id,
            'leave_type'  => $validated['leave_type'],
            'start_date'  => $validated['start_date'],
            'end_date'    => $validated['end_date'],
            'apply_days'  => $validated['apply_days'],
            'reason'      => $validated['reason'],
            'attachment'  => $attachmentPath,
            'status'      => 'Pending',
            // Auto-assign the approver
            'approved_by' => $departmentHead ? $departmentHead->user_id : null,
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

            // 1. Hitung Ringkasan (Summary)
            $balance = 20; // Misalnya jatah tahunan statis 20
            $approved = Leave::where('employee_id', $employeeId)->where('status', 'Approved')->count();
            $pending = Leave::where('employee_id', $employeeId)->where('status', 'Pending')->count();
            $cancelled = Leave::where('employee_id', $employeeId)->whereIn('status', ['Cancelled', 'Rejected'])->count();

            $currentBalance = $balance - $approved; // Sisa cuti

            // 2. Ambil Riwayat Cuti Pribadi (History)
            $leaves = Leave::where('employee_id', $employeeId)
                ->orderBy('created_at', 'desc')
                ->get()
                ->map(function ($leave) use ($currentBalance) {
                    return [
                        'id' => $leave->id,
                        'date_range' => Carbon::parse($leave->start_date)->format('M d, Y') . ' - ' . Carbon::parse($leave->end_date)->format('M d, Y'),
                        'start_date' => $leave->start_date,
                        'end_date' => $leave->end_date,
                        'apply_days' => $leave->apply_days,
                        'balance' => (string) $currentBalance,
                        'leave_type' => $leave->leave_type,
                        'reason' => $leave->reason,

                        'approved_by' => $leave->status === 'Pending'
                                            ? '--'
                                            : ($leave->approver ? $leave->approver->name : 'Manager'),

                        'status' => ucfirst($leave->status),
                        'is_past' => Carbon::parse($leave->end_date)->isPast(),
                    ];
                });

            // 3. Ambil Data Cuti Tim (Khusus Manager/Head)
            $teamLeavesRaw = Leave::with('employee.user')
                ->where('approved_by', $user->id)
                ->where('status', 'Pending')
                ->orderBy('created_at', 'desc')
                ->get();

            $teamLeaves = $teamLeavesRaw->map(function ($leave) {
                $emp = $leave->employee;
                $fullName = $emp ? ($emp->full_name ?? ($emp->user ? $emp->user->name : 'Unknown')) : 'Unknown Employee';
                $position = $emp ? $emp->position : 'Staff Member';
                $departmentName = $emp && $emp->department ? $emp->department->name : null;

                return [
                    'id' => $leave->id,
                    'employee_name' => $fullName,
                    'date_range' => Carbon::parse($leave->start_date)->format('M d, Y') . ' - ' . Carbon::parse($leave->end_date)->format('M d, Y'),
                    'start_date' => $leave->start_date,
                    'end_date' => $leave->end_date,
                    'leave_type' => $leave->leave_type,
                    'apply_days' => $leave->apply_days,
                    'reason' => $leave->reason,
                    'avatar_url' => null,
                    'employee' => [
                        'full_name' => $fullName,
                        'position' => $position,
                        'department' => $departmentName,
                    ]
                ];
            });

            return response()->json([
                'success' => true,
                'summary' => [
                    'balance' => (string) $currentBalance,
                    'approved' => (string) $approved,
                    'pending' => (string) $pending,
                    'cancelled' => (string) $cancelled,
                ],
                'leaves' => $leaves,
                'team_leaves' => $teamLeaves
            ]);
        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => 'Error fetching leaves: ' . $e->getMessage()], 500);
        }
    }

    // 4. TAMBAHAN BARU: Fungsi untuk memproses persetujuan/penolakan
    public function process(Request $request, $id)
    {
        $request->validate([
            'status' => 'required|in:Approved,Rejected'
        ]);

        $leave = Leave::find($id);

        if (!$leave) {
            return response()->json(['success' => false, 'message' => 'Leave not found'], 404);
        }

        // Keamanan: Pastikan hanya atasan yang ditunjuk yang bisa mengubah status ini
        if ($leave->approved_by !== $request->user()->id) {
            return response()->json(['success' => false, 'message' => 'Unauthorized to process this leave'], 403);
        }

        // Perbarui status
        $leave->status = $request->status;
        $leave->save();

        return response()->json([
            'success' => true,
            'message' => 'Leave ' . $request->status . ' successfully'
        ]);
    }
}

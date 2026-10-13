<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\ApplyLeaveRequest;
use App\Http\Requests\ProcessLeaveRequest;
use App\Services\LeaveService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Throwable;

class LeaveController extends Controller
{
    public function __construct(
        private readonly LeaveService $leaveService
    ) {}

    /**
     * Mengajukan cuti baru.
     */
    public function store(ApplyLeaveRequest $request): JsonResponse
    {
        try {
            $user = $request->user();
            $attachment = $request->file('attachment');

            $leave = $this->leaveService->applyLeave(
                $user,
                $request->validated(),
                $attachment
            );

            return response()->json([
                'success' => true,
                'message' => 'Leave applied successfully',
                'data'    => $leave,
            ], 201);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Mengambil data dashboard cuti untuk karyawan.
     */
    public function getLeaveDashboard(Request $request): JsonResponse
    {
        try {
            $user = $request->user();

            if (!$user || !$user->employee) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized or employee record not found',
                ], 401);
            }

            $dashboardData = $this->leaveService->getDashboardData($user);

            return response()->json(array_merge([
                'success' => true,
            ], $dashboardData));
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching leaves: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Memproses persetujuan atau penolakan pengajuan cuti.
     */
    public function process(ProcessLeaveRequest $request, int|string $id): JsonResponse
    {
        try {
            $user = $request->user();
            $status = (string) $request->validated('status');

            $result = $this->leaveService->processLeave($user, (int) $id, $status);

            $payload = [
                'success' => $result['success'],
                'message' => $result['message'],
            ];

            return response()->json($payload, $result['code']);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan sistem: ' . $e->getMessage(),
            ], 500);
        }
    }
}

<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\OvertimeActionRequest;
use App\Services\OvertimeService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use RuntimeException;
use Throwable;

class OvertimeController extends Controller
{
    public function __construct(
        private readonly OvertimeService $overtimeService
    ) {}

    /**
     * Mengambil daftar jadwal lembur yang ditugaskan kepada karyawan.
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $overtimes = $this->overtimeService->getEmployeeOvertimes($request->user());

            return response()->json([
                'success' => true,
                'data'    => $overtimes,
            ]);
        } catch (RuntimeException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 404);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan sistem: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Memproses Clock In lembur karyawan.
     */
    public function clockIn(OvertimeActionRequest $request): JsonResponse
    {
        try {
            $result = $this->overtimeService->clockIn(
                $request->user(),
                (int) $request->validated('overtime_id'),
                (float) $request->validated('latitude'),
                (float) $request->validated('longitude')
            );

            return match ($result['status']) {
                'outside_zone' => response()->json([
                    'success'    => false,
                    'message'    => $result['message'],
                    'is_in_zone' => false,
                ], 422),

                'not_assigned' => response()->json([
                    'success' => false,
                    'message' => $result['message'],
                ], 403),

                'already_clocked_in' => response()->json([
                    'success' => false,
                    'message' => $result['message'],
                ], 400),

                default => response()->json([
                    'success' => true,
                    'message' => $result['message'],
                ], 200),
            };
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan sistem: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Memproses Clock Out lembur karyawan.
     */
    public function clockOut(OvertimeActionRequest $request): JsonResponse
    {
        try {
            $result = $this->overtimeService->clockOut(
                $request->user(),
                (int) $request->validated('overtime_id'),
                (float) $request->validated('latitude'),
                (float) $request->validated('longitude')
            );

            return match ($result['status']) {
                'outside_zone' => response()->json([
                    'success'    => false,
                    'message'    => $result['message'],
                    'is_in_zone' => false,
                ], 422),

                'not_clocked_in', 'already_clocked_out' => response()->json([
                    'success' => false,
                    'message' => $result['message'],
                ], 400),

                default => response()->json([
                    'success' => true,
                    'message' => $result['message'],
                ], 200),
            };
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan sistem: ' . $e->getMessage(),
            ], 500);
        }
    }
}

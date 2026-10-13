<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\AttendanceCheckRequest;
use App\Http\Requests\MemberAttendanceRequest;
use App\Http\Requests\ValidateLocationRequest;
use App\Models\Employee;
use App\Services\AttendanceService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use RuntimeException;
use Throwable;

class AttendanceController extends Controller
{
    public function __construct(
        private readonly AttendanceService $attendanceService
    ) {}

    /**
     * Mengambil konfigurasi zona presensi aktif atau surat tugas luar karyawan.
     */
    public function getUserZone(Request $request): JsonResponse
    {
        try {
            $config = $this->attendanceService->getUserZoneConfig($request->user());

            return response()->json($config);
        } catch (RuntimeException $exception) {
            return response()->json([
                'success' => false,
                'message' => $exception->getMessage(),
            ], 404);
        } catch (Throwable $exception) {
            report($exception);

            return response()->json([
                'success' => false,
                'message' => 'Gagal mengambil konfigurasi presensi.',
            ], 500);
        }
    }

    /**
     * Endpoint validasi lokasi real-time sebelum kamera presensi dibuka.
     */
    public function validateLocationStatus(ValidateLocationRequest $request): JsonResponse
    {
        try {
            $result = $this->attendanceService->validateLocationStatus(
                $request->user(),
                (float) $request->validated('latitude'),
                (float) $request->validated('longitude')
            );

            return response()->json($result);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 404);
        }
    }

    /**
     * Memproses presensi masuk (Check-In).
     */
    public function checkIn(AttendanceCheckRequest $request): JsonResponse
    {
        try {
            $result = $this->attendanceService->checkIn(
                $request->user(),
                (float) $request->validated('latitude'),
                (float) $request->validated('longitude'),
                $request->file('photo')
            );

            return match ($result['status']) {
                'blocked' => response()->json([
                    'success'               => false,
                    'message'               => $result['message'],
                    'is_attendance_blocked' => true,
                    'attendance_status'     => $result['attendance_status'] ?? null,
                ], 422),

                'already_checked_in' => response()->json([
                    'success' => false,
                    'message' => $result['message'],
                ], 422),

                'outside_zone' => response()->json([
                    'success'         => false,
                    'message'         => $result['message'],
                    'is_in_zone'      => false,
                    'location_status' => $result['location_status'] ?? 'outside_area',
                ], 422),

                default => response()->json([
                    'success'         => true,
                    'message'         => $result['message'],
                    'location_status' => $result['location_status'] ?? null,
                    'work_assignment' => $result['work_assignment'] ?? null,
                    'data'            => $result['data'] ?? null,
                ]),
            };
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 404);
        }
    }

    /**
     * Memproses presensi keluar (Check-Out).
     */
    public function checkOut(AttendanceCheckRequest $request): JsonResponse
    {
        try {
            $result = $this->attendanceService->checkOut(
                $request->user(),
                (float) $request->validated('latitude'),
                (float) $request->validated('longitude'),
                $request->file('photo')
            );

            return match ($result['status']) {
                'blocked' => response()->json([
                    'success'               => false,
                    'message'               => $result['message'],
                    'is_attendance_blocked' => true,
                    'attendance_status'     => $result['attendance_status'] ?? null,
                ], 422),

                'outside_zone' => response()->json([
                    'success'         => false,
                    'message'         => $result['message'],
                    'is_in_zone'      => false,
                    'location_status' => $result['location_status'] ?? 'outside_area',
                ], 422),

                'not_checked_in' => response()->json([
                    'success' => false,
                    'message' => $result['message'],
                ], 404),

                default => response()->json([
                    'success'         => true,
                    'message'         => $result['message'],
                    'location_status' => $result['location_status'] ?? null,
                    'work_assignment' => $result['work_assignment'] ?? null,
                    'data'            => $result['data'] ?? null,
                ]),
            };
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan sistem: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Endpoint sementara untuk pengujian kuantitatif geofencing skripsi.
     */
    public function geofenceTest(ValidateLocationRequest $request): JsonResponse
    {
        try {
            $result = $this->attendanceService->testGeofence(
                $request->user(),
                (float) $request->validated('latitude'),
                (float) $request->validated('longitude')
            );

            if (!($result['found'] ?? false)) {
                return response()->json([
                    'success' => false,
                    'message' => $result['message'],
                ], 404);
            }

            return response()->json(array_merge([
                'success' => true,
            ], $result));
        } catch (RuntimeException $exception) {
            return response()->json([
                'success' => false,
                'message' => $exception->getMessage(),
            ], 404);
        } catch (Throwable $exception) {
            report($exception);

            return response()->json([
                'success' => false,
                'message' => 'Gagal melakukan pengujian geofencing.',
            ], 500);
        }
    }

    /**
     * Mengambil status presensi hari ini.
     */
    public function getTodayStatus(Request $request): JsonResponse
    {
        try {
            $status = $this->attendanceService->getTodayStatus($request->user());

            return response()->json($status);
        } catch (Throwable) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengambil status absensi.',
            ], 500);
        }
    }

    /**
     * Mengambil ringkasan statistik presensi bulanan di home screen.
     */
    public function getMonthlyStats(Request $request): JsonResponse
    {
        try {
            $stats = $this->attendanceService->getMonthlyStats($request->user());

            return response()->json($stats);
        } catch (Throwable) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengambil statistik absensi.',
            ], 500);
        }
    }

    /**
     * Mengambil 5 riwayat presensi terakhir.
     */
    public function getHistory(Request $request): JsonResponse
    {
        try {
            $history = $this->attendanceService->getHistory($request->user());

            return response()->json([
                'success' => true,
                'data'    => $history,
            ]);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengambil riwayat absensi: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Mengambil laporan presensi bulanan lengkap.
     */
    public function getMonthlyReport(Request $request): JsonResponse
    {
        try {
            $month = $request->query('month') !== null ? (int) $request->query('month') : null;
            $year = $request->query('year') !== null ? (int) $request->query('year') : null;

            $report = $this->attendanceService->getMonthlyReport($request->user(), $month, $year);

            return response()->json($report);
        } catch (Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengambil data laporan: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Mengambil data presensi anggota tim oleh atasan (Head/Manager).
     */
    public function getMemberAttendances(MemberAttendanceRequest $request, int|string $employeeId): JsonResponse
    {
        $employeeToView = Employee::findOrFail((int) $employeeId);

        if ($request->user()->cannot('viewMemberAttendances', $employeeToView)) {
            $authUserEmployee = $request->user()->employee;

            return response()->json([
                'message'    => 'Unauthorized',
                'debug_info' => [
                    'auth_posisi' => $authUserEmployee ? $authUserEmployee->position : 'NULL',
                    'auth_dept'   => $authUserEmployee ? $authUserEmployee->department_id : 'NULL',
                    'target_dept' => $employeeToView->department_id,
                ],
            ], 403);
        }

        $month = $request->validated('month') !== null ? (int) $request->validated('month') : null;
        $year = $request->validated('year') !== null ? (int) $request->validated('year') : null;

        $attendances = $this->attendanceService->getMemberAttendances(
            $employeeToView,
            $month,
            $year
        );

        return response()->json([
            'data' => $attendances,
        ]);
    }
}

<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\AttendanceZone;
use App\Models\Employee;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class AttendanceController extends Controller
{
    private const TOLERANCE_METERS = 10;

    public function getUserZone(Request $request)
    {
        try {
            $user = $request->user();

            $user->loadMissing('employee.department.attendanceZones');

            $employee = $user->employee;

            if (!$employee || !$employee->department) {
                return response()->json([
                    'success' => false,
                    'message' => 'Profil karyawan atau departemen tidak ditemukan.'
                ], 404);
            }

            $validZoneIds = $employee->department->attendanceZones->pluck('id');

            if ($validZoneIds->isEmpty()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Zona absensi tidak ditemukan untuk departemen ini.'
                ], 404);
            }

            $zones = DB::table('attendance_zones')
                ->whereIn('id', $validZoneIds)
                ->select(['id', 'name'])
                ->selectRaw('ST_AsText(area) as area')
                ->orderBy('id')
                ->get()
                ->map(function ($zone) {
                    return [
                        'id' => (int) $zone->id,
                        'name' => $zone->name,
                        'area' => $zone->area,
                    ];
                })
                ->values();

            return response()->json([
                'success' => true,
                'zones' => $zones,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan sistem: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Endpoint validasi lokasi real-time sebelum kamera dibuka.
     */
    public function validateLocationStatus(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => $validator->errors()->first(),
            ], 422);
        }

        try {
            $attendanceBlock = $this->getTodayAttendanceBlockResult(
                $request->user()
            );

            if ($attendanceBlock['is_blocked']) {
                return response()->json([
                    'success' => true,
                    'is_valid' => false,
                    'location_status' => 'attendance_blocked',
                    'message' => $attendanceBlock['message'],
                    'zone_id' => null,
                    'zone_name' => null,
                    'is_attendance_blocked' => true,
                    'attendance_status' => $attendanceBlock['status'],
                ]);
            }

            $result = $this->getLocationValidationResult(
                $request->user(),
                (float) $request->latitude,
                (float) $request->longitude
            );

            return response()->json([
                'success' => true,
                'is_valid' => $result['is_valid'],
                'location_status' => $result['location_status'],
                'message' => $result['message'],
                'zone_id' => $result['zone_id'],
                'zone_name' => $result['zone_name'],
                'is_attendance_blocked' => false,
                'attendance_status' => null,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 404);
        }
    }

    public function checkIn(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
            'photo' => 'required|image|mimes:jpeg,png,jpg|max:2048',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => $validator->errors()->first()
            ], 422);
        }

        try {
            $attendanceBlock = $this->getTodayAttendanceBlockResult(
                $request->user()
            );

            if ($attendanceBlock['is_blocked']) {
                return response()->json([
                    'success' => false,
                    'message' => $attendanceBlock['message'],
                    'is_attendance_blocked' => true,
                    'attendance_status' => $attendanceBlock['status'],
                ], 422);
            }

            if ($this->getTodayCheckedInAttendance($request->user())) {
                return response()->json([
                    'success' => false,
                    'message' => 'Anda sudah melakukan presensi masuk hari ini.',
                ], 422);
            }

            // Validasi final tetap dilakukan backend ketika data presensi dikirim.
            $locationResult = $this->getLocationValidationResult(
                $request->user(),
                (float) $request->latitude,
                (float) $request->longitude
            );

            if (!$locationResult['is_valid']) {
                return response()->json([
                    'success' => false,
                    'message' => $locationResult['message'],
                    'is_in_zone' => false,
                    'location_status' => $locationResult['location_status'],
                ], 422);
            }

            $photoPath = null;
            if ($request->hasFile('photo')) {
                $photoPath = $request->file('photo')->store('attendances', 'public');
            }

            $checkInTime = now();
            $workStart = \Carbon\Carbon::today()->setTime(9, 0, 0);
            $today = Carbon::today()->toDateString();
            $status = $checkInTime->gt($workStart) ? 'Telat' : 'Hadir';

            $attendance = Attendance::create([
                'employee_id' => $request->user()->employee->id,
                'attendance_zone_id' => $locationResult['zone_id'],
                'date' => $today,
                'check_in' => $checkInTime,
                'check_in_latitude' => $request->latitude,
                'check_in_longitude' => $request->longitude,
                'check_in_photo_path' => $photoPath,
                'status' => $status,
                'source' => 'Mobile',
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Presensi masuk berhasil.',
                'location_status' => $locationResult['location_status'],
                'data' => $attendance,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 404);
        }
    }

    public function checkOut(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
            'photo' => 'required|image|mimes:jpeg,png,jpg|max:2048',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => $validator->errors()->first()
            ], 422);
        }

        try {
            $attendanceBlock = $this->getTodayAttendanceBlockResult(
                $request->user()
            );

            if ($attendanceBlock['is_blocked']) {
                return response()->json([
                    'success' => false,
                    'message' => $attendanceBlock['message'],
                    'is_attendance_blocked' => true,
                    'attendance_status' => $attendanceBlock['status'],
                ], 422);
            }

            // Validasi final tetap dilakukan backend ketika data presensi dikirim.
            $locationResult = $this->getLocationValidationResult(
                $request->user(),
                (float) $request->latitude,
                (float) $request->longitude
            );

            if (!$locationResult['is_valid']) {
                return response()->json([
                    'success' => false,
                    'message' => $locationResult['message'],
                    'is_in_zone' => false,
                    'location_status' => $locationResult['location_status'],
                ], 422);
            }

            $attendance = Attendance::where(
                'employee_id',
                $request->user()->employee->id
            )
                ->whereDate('check_in', today())
                ->firstOrFail();

            $photoPath = null;
            if ($request->hasFile('photo')) {
                $photoPath = $request->file('photo')->store('attendances', 'public');
            }

            $attendance->update([
                'check_out' => now(),
                'check_out_latitude' => $request->latitude,
                'check_out_longitude' => $request->longitude,
                'check_out_photo_path' => $photoPath,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Presensi keluar berhasil. Hati-hati di jalan!',
                'location_status' => $locationResult['location_status'],
                'data' => $attendance,
            ]);
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Anda belum melakukan presensi masuk hari ini.'
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan sistem: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Menghasilkan status lokasi yang sama untuk validasi real-time,
     * validasi sebelum kamera, dan validasi final ketika menyimpan presensi.
     */
    private function getLocationValidationResult(
        User $user,
        float $latitude,
        float $longitude
    ): array {
        $user->loadMissing('employee.department.attendanceZones');
        $employee = $user->employee;

        if (!$employee) {
            throw new \Exception('Profil karyawan tidak ditemukan.');
        }

        if (!$employee->department) {
            throw new \Exception('Karyawan tidak terdaftar di departemen manapun.');
        }

        $validZoneIds = $employee->department->attendanceZones->pluck('id');

        if ($validZoneIds->isEmpty()) {
            throw new \Exception('Departemen Anda tidak memiliki zona absensi.');
        }

        // Prioritas pertama: titik benar-benar berada di dalam polygon utama.
        $insideZone = AttendanceZone::whereIn('id', $validZoneIds)
            ->whereRaw(
                'ST_Covers(area, ST_SetSRID(ST_MakePoint(?, ?), 4326))',
                [$longitude, $latitude]
            )
            ->first();

        if ($insideZone) {
            return [
                'is_valid' => true,
                'location_status' => 'inside_area',
                'message' => 'Lokasi berada di area presensi.',
                'zone_id' => $insideZone->id,
                'zone_name' => $insideZone->name,
            ];
        }

        // Prioritas kedua: titik berada di luar polygon, tetapi masih dalam toleransi.
        $toleranceZone = AttendanceZone::whereIn('id', $validZoneIds)
            ->whereRaw(
                'ST_DWithin(area::geography, ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography, ?)',
                [$longitude, $latitude, self::TOLERANCE_METERS]
            )
            ->first();

        if ($toleranceZone) {
            return [
                'is_valid' => true,
                'location_status' => 'tolerance_zone',
                'message' => 'Lokasi berada di zona toleransi.',
                'zone_id' => $toleranceZone->id,
                'zone_name' => $toleranceZone->name,
            ];
        }

        return [
            'is_valid' => false,
            'location_status' => 'outside_area',
            'message' => 'Lokasi berada di luar area presensi.',
            'zone_id' => null,
            'zone_name' => null,
        ];
    }

    // Mengambil data presensi karyawan pada tanggal hari ini.
    private function getTodayAttendance(User $user): ?Attendance
    {
        $user->loadMissing('employee');

        if (!$user->employee) {
            throw new \Exception('Profil karyawan tidak ditemukan.');
        }

        return Attendance::where('employee_id', $user->employee->id)
            ->whereDate('date', Carbon::today())
            ->orderByDesc('id')
            ->first();
    }

    // Menentukan apakah fitur presensi hari ini harus dikunci.
    private function getAttendanceBlockResult(
        ?Attendance $attendance
    ): array {
        if (!$attendance || $attendance->check_in !== null) {
            return [
                'is_blocked' => false,
                'status' => null,
                'message' => null,
            ];
        }

        $status = trim((string) $attendance->status);
        $normalizedStatus = strtolower($status);

        if (!in_array($normalizedStatus, ['cuti', 'alpa'], true)) {
            return [
                'is_blocked' => false,
                'status' => $status !== '' ? $status : null,
                'message' => null,
            ];
        }

        $message = $normalizedStatus === 'cuti'
            ? 'Presensi tidak dapat dilakukan karena Anda sedang cuti hari ini.'
            : 'Presensi tidak dapat dilakukan karena status kehadiran hari ini adalah alpa.';

        return [
            'is_blocked' => true,
            'status' => ucfirst($normalizedStatus),
            'message' => $message,
        ];
    }

    private function getTodayAttendanceBlockResult(User $user): array
    {
        $user->loadMissing('employee');

        if (!$user->employee) {
            throw new \Exception('Profil karyawan tidak ditemukan.');
        }

        $blockedAttendance = Attendance::where(
            'employee_id',
            $user->employee->id
        )
            ->whereDate('date', Carbon::today())
            ->whereNull('check_in')
            ->whereRaw(
                'LOWER(TRIM(status)) IN (?, ?)',
                ['cuti', 'alpa']
            )
            ->orderByDesc('id')
            ->first();

        return $this->getAttendanceBlockResult($blockedAttendance);
    }

    private function getTodayCheckedInAttendance(
        User $user
    ): ?Attendance {
        $user->loadMissing('employee');

        if (!$user->employee) {
            throw new \Exception('Profil karyawan tidak ditemukan.');
        }

        return Attendance::where('employee_id', $user->employee->id)
            ->whereDate('date', Carbon::today())
            ->whereNotNull('check_in')
            ->orderByDesc('id')
            ->first();
    }

    public function getTodayStatus(Request $request)
    {
        try {
            $attendanceBlock = $this->getTodayAttendanceBlockResult(
                $request->user()
            );
            $attendance = $this->getTodayCheckedInAttendance(
                $request->user()
            ) ?? $this->getTodayAttendance($request->user());

            if ($attendanceBlock['is_blocked']) {
                return response()->json([
                    'success' => true,
                    'has_checked_in' => false,
                    'has_checked_out' => false,
                    'check_in_time' => '-- : -- : --',
                    'check_out_time' => '-- : -- : --',
                    'is_attendance_blocked' => true,
                    'attendance_status' => $attendanceBlock['status'],
                    'attendance_message' => $attendanceBlock['message'],
                ]);
            }

            if ($attendance && $attendance->check_in !== null) {
                return response()->json([
                    'success' => true,
                    'has_checked_in' => true,

                    // Convert UTC to WIB.
                    'check_in_time' => \Carbon\Carbon::parse($attendance->check_in)
                        ->timezone('Asia/Jakarta')
                        ->format('H : i : s'),

                    'has_checked_out' => $attendance->check_out !== null,

                    // Convert UTC to WIB.
                    'check_out_time' => $attendance->check_out
                        ? \Carbon\Carbon::parse($attendance->check_out)
                        ->timezone('Asia/Jakarta')
                        ->format('H : i : s')
                        : '-- : -- : --',

                    'is_attendance_blocked' => false,
                    'attendance_status' => $attendance->status,
                    'attendance_message' => null,
                ]);
            }

            return response()->json([
                'success' => true,
                'has_checked_in' => false,
                'has_checked_out' => false,
                'check_in_time' => '-- : -- : --',
                'check_out_time' => '-- : -- : --',
                'is_attendance_blocked' => false,
                'attendance_status' => $attendance?->status,
                'attendance_message' => null,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengambil status absensi.'
            ], 500);
        }
    }

    public function getMonthlyStats(Request $request)
    {
        try {
            $employeeId = $request->user()->employee->id;
            $currentMonth = \Carbon\Carbon::now()->month;
            $currentYear = \Carbon\Carbon::now()->year;

            $totalAttendance = Attendance::where('employee_id', $employeeId)
                ->whereMonth('check_in', $currentMonth)
                ->whereYear('check_in', $currentYear)
                ->whereNotNull('check_in')
                ->count();

            $lateClockIn = Attendance::where('employee_id', $employeeId)
                ->whereMonth('check_in', $currentMonth)
                ->whereYear('check_in', $currentYear)
                ->whereTime('check_in', '>', '09:00:00')
                ->count();

            $noClockIn = Attendance::where('employee_id', $employeeId)
                ->whereMonth('date', $currentMonth)
                ->whereYear('date', $currentYear)
                ->whereNull('check_in')
                ->count();

            return response()->json([
                'success' => true,
                'total_attendance' => str_pad($totalAttendance, 2, '0', STR_PAD_LEFT),
                'late_clock_in' => str_pad($lateClockIn, 2, '0', STR_PAD_LEFT),
                'no_clock_in' => str_pad($noClockIn, 2, '0', STR_PAD_LEFT),
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengambil statistik absensi.'
            ], 500);
        }
    }

    // History presensi di home screen.
    public function getHistory(Request $request)
    {
        try {
            $employeeId = $request->user()->employee->id;

            $attendances = Attendance::where('employee_id', $employeeId)
                ->orderBy('date', 'desc')
                ->take(5)
                ->get()
                ->map(function ($att) {
                    $actualDate = \Carbon\Carbon::parse($att->date)
                        ->timezone('Asia/Jakarta');

                    $checkInTime = $att->check_in
                        ? \Carbon\Carbon::parse($att->check_in)->timezone('Asia/Jakarta')
                        : null;

                    $checkOutTime = $att->check_out
                        ? \Carbon\Carbon::parse($att->check_out)->timezone('Asia/Jakarta')
                        : null;

                    $status = ucfirst($att->status ?? 'Absent');

                    if ($checkInTime && $checkInTime->format('H : i : s') > '09:00:00') {
                        $status = 'Telat';
                    }

                    return [
                        'date' => $actualDate->translatedFormat('j F Y'),
                        'status' => $status,
                        'check_in' => $checkInTime
                            ? $checkInTime->format('H : i : s')
                            : null,
                        'check_out' => $checkOutTime
                            ? $checkOutTime->format('H : i : s')
                            : null,
                    ];
                });

            return response()->json([
                'success' => true,
                'data' => $attendances
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengambil riwayat absensi: ' . $e->getMessage()
            ], 500);
        }
    }

    // Laporan bulanan lengkap untuk halaman laporan.
    public function getMonthlyReport(Request $request)
    {
        try {
            $employeeId = $request->user()->employee->id;

            $month = $request->query('month', \Carbon\Carbon::now()->month);
            $year = $request->query('year', \Carbon\Carbon::now()->year);

            $totalAttendance = Attendance::where('employee_id', $employeeId)
                ->whereMonth('date', $month)
                ->whereYear('date', $year)
                ->whereNotNull('check_in')
                ->count();

            $lateClockIn = Attendance::where('employee_id', $employeeId)
                ->whereMonth('date', $month)
                ->whereYear('date', $year)
                ->whereNotNull('check_in')
                ->whereTime('check_in', '>', '09:00:00')
                ->count();

            $noClockIn = Attendance::where('employee_id', $employeeId)
                ->whereMonth('date', $month)
                ->whereYear('date', $year)
                ->whereNull('check_in')
                ->count();

            $attendances = Attendance::where('employee_id', $employeeId)
                ->whereMonth('date', $month)
                ->whereYear('date', $year)
                ->orderBy('date', 'desc')
                ->get()
                ->map(function ($att) {
                    $actualDate = \Carbon\Carbon::parse($att->date)
                        ->timezone('Asia/Jakarta');

                    $checkInTime = $att->check_in
                        ? \Carbon\Carbon::parse($att->check_in)->timezone('Asia/Jakarta')
                        : null;

                    $checkOutTime = $att->check_out
                        ? \Carbon\Carbon::parse($att->check_out)->timezone('Asia/Jakarta')
                        : null;

                    $status = ucfirst($att->status ?? 'Absent');

                    if ($checkInTime && $checkInTime->format('H : i : s') > '09:00:00') {
                        $status = 'Telat';
                    }

                    return [
                        'raw_date' => $actualDate->format('Y-m-d'),
                        'date' => $actualDate->translatedFormat('j F Y'),
                        'status' => $status,
                        'check_in' => $checkInTime
                            ? $checkInTime->format('H : i : s')
                            : null,
                        'check_out' => $checkOutTime
                            ? $checkOutTime->format('H : i : s')
                            : null,
                    ];
                });

            return response()->json([
                'success' => true,
                'stats' => [
                    'total_attendance' => str_pad($totalAttendance, 2, '0', STR_PAD_LEFT),
                    'late_clock_in' => str_pad($lateClockIn, 2, '0', STR_PAD_LEFT),
                    'no_clock_in' => str_pad($noClockIn, 2, '0', STR_PAD_LEFT),
                ],
                'history' => $attendances
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengambil data laporan: ' . $e->getMessage()
            ], 500);
        }
    }

    // Fitur tambahan untuk atasan melihat laporan anggota.
    public function getMemberAttendances(Request $request, $employeeId)
    {
        $employeeToView = Employee::findOrFail($employeeId);
        $authUserEmployee = $request->user()->employee;

        if ($request->user()->cannot(
            'viewMemberAttendances',
            $employeeToView
        )) {
            return response()->json([
                'message' => 'Unauthorized',
                'debug_info' => [
                    'auth_posisi' => $authUserEmployee
                        ? $authUserEmployee->position
                        : 'NULL',

                    'auth_dept' => $authUserEmployee
                        ? $authUserEmployee->department_id
                        : 'NULL',

                    'target_dept' => $employeeToView->department_id,
                ],
            ], 403);
        }

        $validated = $request->validate([
            'month' => 'nullable|integer|between:1,12',
            'year' => 'nullable|integer|min:2000|max:2100',
        ]);

        $month = (int) (
            $validated['month']
            ?? \Carbon\Carbon::now()->month
        );

        $year = (int) (
            $validated['year']
            ?? \Carbon\Carbon::now()->year
        );

        $startDate = \Carbon\Carbon::create(
            $year,
            $month,
            1
        )->startOfMonth();

        $endDate = $startDate
            ->copy()
            ->endOfMonth();

        $attendances = $employeeToView
            ->attendances()
            ->select([
                'id',
                'employee_id',
                'date',
                'check_in',
                'check_out',
                'status',
            ])
            ->whereBetween('date', [
                $startDate->toDateString(),
                $endDate->toDateString(),
            ])
            ->orderByDesc('date')
            ->get();

        return response()->json([
            'data' => $attendances,
        ]);
    }
}

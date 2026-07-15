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

            $zone = $employee->department->attendanceZones->first();

            if (!$zone) {
                return response()->json([
                    'success' => false,
                    'message' => 'Zona absensi tidak ditemukan untuk departemen ini.'
                ], 404);
            }

            // ekstrak data GEOMETRY menjadi string WKT (Well-Known Text) menggunakan PostGIS
            $areaData = DB::selectOne(
                "SELECT ST_AsText(area) as wkt FROM attendance_zones WHERE id = ?",
                [$zone->id]
            );

            return response()->json([
                'success' => true,
                'name'    => $zone->name,
                'area'    => $areaData->wkt,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan sistem: ' . $e->getMessage()
            ], 500);
        }
    }

    public function checkIn(Request $request)
    {
        // validasi input
        $validator = Validator::make($request->all(), [
            'latitude'  => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
            'photo'     => 'required|image|mimes:jpeg,png,jpg|max:2048',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => $validator->errors()->first()
            ], 422);
        }

        try {
            // panggil validasi lokasi
            $isValidLocation = $this->validateLocation(
                $request->user(),
                $request->latitude,
                $request->longitude
            );

            if ($isValidLocation) {
                $photoPath = null;
                if ($request->hasFile('photo')) {
                    $photoPath = $request->file('photo')->store('attendances', 'public');
                }

                $checkInTime = now();
                $workStart = \Carbon\Carbon::today()->setTime(9, 0, 0);

                $today = Carbon::today()->toDateString();

                $status = $checkInTime->gt($workStart) ? 'Telat' : 'Hadir';

                $attendance = Attendance::create([
                    'employee_id'           => $request->user()->employee->id,
                    'attendance_zone_id'    => $this->getZoneId($request->user()),
                    'date'                  => $today,
                    'check_in'              => $checkInTime ?? 'N/A',
                    'check_in_latitude'     => $request->latitude,
                    'check_in_longitude'    => $request->longitude,
                    'check_in_photo_path'   => $photoPath,
                    'status'                => $status,
                    'source'                => 'Mobile',
                ]);

                return response()->json([
                    'success' => true,
                    'message' => 'Check-in berhasil. Anda berada di dalam area absensi.',
                    'data' => $attendance,
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Anda berada di luar area absensi.',
                    'is_in_zone' => false,
                ], 422);
            }
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 404);
        }
    }

    public function checkOut(Request $request)
    {
        // validasi input
        $validator = Validator::make($request->all(), [
            'latitude'  => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
            'photo'     => 'required|image|mimes:jpeg,png,jpg|max:2048',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => $validator->errors()->first()
            ], 422);
        }

        try {
            // panggil validasi lokasi
            $isValidLocation = $this->validateLocation(
                $request->user(),
                $request->latitude,
                $request->longitude
            );

            if ($isValidLocation) {
                $attendance = Attendance::where('employee_id', $request->user()->employee->id)
                    ->whereDate('check_in', today())
                    ->firstOrFail();

                $photoPath = null;
                if ($request->hasFile('photo')) {
                    $photoPath = $request->file('photo')->store('attendances', 'public');
                }

                // update absensi check-out
                $attendance->update([
                    'check_out'             => now() ?? 'N/A',
                    'check_out_latitude'    => $request->latitude,
                    'check_out_longitude'   => $request->longitude,
                    'check_out_photo_path'  => $photoPath,
                ]);

                return response()->json([
                    'success' => true,
                    'message' => 'Check-out berhasil. Hati-hati di jalan!',
                    'data' => $attendance,
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Anda berada di luar area absensi.',
                    'is_in_zone' => false,
                ], 422);
            }
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Anda belum melakukan check-in hari ini.'
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan sistem: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Metode private untuk memvalidasi lokasi user.
     * Menggunakan arsitektur User -> Employee -> Department -> Zones.
     *
     * @param \App\Models\User $user
     * @param float $latitude
     * @param float $longitude
     * @return bool
     * @throws \Exception
     */
    private function validateLocation(User $user, float $latitude, float $longitude): bool
    {
        $user->loadMissing('employee.department.attendanceZones');
        $employee = $user->employee;

        // validasi apakah user punya profil & departemen
        if (!$employee) {
            throw new \Exception('Profil karyawan tidak ditemukan.');
        }

        if (!$employee->department) {
            throw new \Exception('Karyawan tidak terdaftar di departemen manapun.');
        }

        // ambil ID zona yang valid
        $validZoneIds = $employee->department->attendanceZones->pluck('id');

        if ($validZoneIds->isEmpty()) {
            throw new \Exception('Departemen Anda tidak memiliki zona absensi.');
        }

        // cek apakah koordinat user berada dalam radius 10 meter dari salah satu zona yang valid
        return AttendanceZone::whereIn('id', $validZoneIds)
            ->whereRaw(
                'ST_DWithin(area::geography, ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography, 10)',
                [$longitude, $latitude]
            )
            ->exists();
    }

    private function getZoneId(User $user): ?int
    {
        $employee = $user->employee;
        // Ambil ID zona pertama yang valid
        return $employee->department->attendanceZones->first()->id ?? null;
    }

    public function getTodayStatus(Request $request)
    {
        try {
            $attendance = Attendance::where('employee_id', $request->user()->employee->id)
                ->whereDate('check_in', today())
                ->first();

            if ($attendance) {
                return response()->json([
                    'success' => true,
                    'has_checked_in'  => true,

                    // convert UTC to WIB
                    'check_in_time'   => \Carbon\Carbon::parse($attendance->check_in)
                        ->timezone('Asia/Jakarta')
                        ->format('H : i : s'),

                    'has_checked_out' => $attendance->check_out !== null,

                    // convert UTC to WIB
                    'check_out_time'  => $attendance->check_out
                        ? \Carbon\Carbon::parse($attendance->check_out)
                        ->timezone('Asia/Jakarta')
                        ->format('H : i : s')
                        : '-- : -- : --',
                ]);
            }

            return response()->json([
                'success' => true,
                'has_checked_in'  => false,
                'has_checked_out' => false,
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
                'late_clock_in'    => str_pad($lateClockIn, 2, '0', STR_PAD_LEFT),
                'no_clock_in'      => str_pad($noClockIn, 2, '0', STR_PAD_LEFT),
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengambil statistik absensi.'
            ], 500);
        }
    }

    // history presensi di home screen
    public function getHistory(Request $request)
    {
        try {
            $employeeId = $request->user()->employee->id;

            // Ambil 5 data absensi terbaru
            $attendances = Attendance::where('employee_id', $employeeId)
                ->orderBy('date', 'desc')
                ->take(5)
                ->get()
                ->map(function ($att) {
                    $actualDate = \Carbon\Carbon::parse($att->date)->timezone('Asia/Jakarta');

                    $checkInTime = $att->check_in ? \Carbon\Carbon::parse($att->check_in)->timezone('Asia/Jakarta') : null;
                    $checkOutTime = $att->check_out ? \Carbon\Carbon::parse($att->check_out)->timezone('Asia/Jakarta') : null;

                    $status = ucfirst($att->status ?? 'Absent');

                    if ($checkInTime && $checkInTime->format('H : i : s') > '09:00:00') {
                        $status = 'Telat';
                    }

                    return [
                        'date'      => $actualDate->translatedFormat('j F Y'),
                        'status'    => $status,
                        'check_in'  => $checkInTime ? $checkInTime->format('H : i : s') : null,
                        'check_out' => $checkOutTime ? $checkOutTime->format('H : i : s') : null,
                    ];
                });

            return response()->json([
                'success' => true,
                'data'    => $attendances
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengambil riwayat absensi: ' . $e->getMessage()
            ], 500);
        }
    }

    // laporan bulanan lengkap untuk halaman laporan
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
                    $actualDate = \Carbon\Carbon::parse($att->date)->timezone('Asia/Jakarta');
                    $checkInTime = $att->check_in ? \Carbon\Carbon::parse($att->check_in)->timezone('Asia/Jakarta') : null;
                    $checkOutTime = $att->check_out ? \Carbon\Carbon::parse($att->check_out)->timezone('Asia/Jakarta') : null;
                    $status = ucfirst($att->status ?? 'Absent');
                    if ($checkInTime && $checkInTime->format('H : i : s') > '09:00:00') {
                        $status = 'Telat';
                    }

                    return [
                        'raw_date'  => $actualDate->format('Y-m-d'),
                        'date'      => $actualDate->translatedFormat('j F Y'),
                        'status'    => $status,
                        'check_in'  => $checkInTime ? $checkInTime->format('H : i : s') : null,
                        'check_out' => $checkOutTime ? $checkOutTime->format('H : i : s') : null,
                    ];
                });

            return response()->json([
                'success' => true,
                'stats' => [
                    'total_attendance' => str_pad($totalAttendance, 2, '0', STR_PAD_LEFT),
                    'late_clock_in'    => str_pad($lateClockIn, 2, '0', STR_PAD_LEFT),
                    'no_clock_in'      => str_pad($noClockIn, 2, '0', STR_PAD_LEFT),
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

    // fitur tambahan untuk atasan melihat laporan anggota
    public function getMemberAttendances(Request $request, $employeeId)
    {
        $employeeToView = \App\Models\Employee::findOrFail($employeeId);
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

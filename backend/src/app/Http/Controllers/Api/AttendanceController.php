<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Attendance;
use App\Models\AttendanceZone;
use App\Models\User;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB; // Added for ST_AsText query

class AttendanceController extends Controller
{
    /**
     * Mengambil data zona absensi user untuk ditampilkan di Peta Flutter.
     */
    public function getUserZone(Request $request)
    {
        try {
            $user = $request->user();

            // Menggunakan relasi berantai: User -> Employee -> Department -> Zones
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

            // Ekstrak data GEOMETRY menjadi string WKT (Well-Known Text) menggunakan PostGIS
            $areaData = DB::selectOne(
                "SELECT ST_AsText(area) as wkt FROM attendance_zones WHERE id = ?",
                [$zone->id]
            );

            return response()->json([
                'success' => true,
                'name'    => $zone->name, // Contoh: "HR" atau "Marketing"
                'area'    => $areaData->wkt, // Contoh: "POLYGON((106... -6...))"
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan sistem: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Merekam absensi masuk (Check-In).
     */
    public function checkIn(Request $request)
    {
        // 1. Validasi input (Tambahkan validasi untuk foto)
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
            // 2. Panggil validasi lokasi
            $isValidLocation = $this->validateLocation(
                $request->user(),
                $request->latitude,
                $request->longitude
            );

            if ($isValidLocation) {
                // 3. Proses simpan file foto ke server (storage/app/public/attendances)
                $photoPath = null;
                if ($request->hasFile('photo')) {
                    // Menyimpan file dan mengembalikan path-nya (misal: "attendances/xyz.jpg")
                    $photoPath = $request->file('photo')->store('attendances', 'public');
                }

                // 4. Simpan record absensi check-in
                $attendance = Attendance::create([
                    'employee_id'           => $request->user()->employee->id,
                    'attendance_zone_id'    => $this->getZoneId($request->user()),
                    'check_in'              => now(),
                    'check_in_latitude'     => $request->latitude,
                    'check_in_longitude'    => $request->longitude,
                    'check_in_photo_path'   => $photoPath, // Simpan path foto di sini
                    'check_out'             => null,
                    'check_out_latitude'    => null,
                    'check_out_longitude'   => null,
                    'check_out_photo_path'  => null,
                    'status'                => 'hadir',
                ]);

                return response()->json([
                    'success' => true,
                    'message' => 'Check-in berhasil. Anda berada di dalam area absensi.',
                    'data' => $attendance,
                ]);
            } else {
                // LOKASI TIDAK VALID
                return response()->json([
                    'success' => false,
                    'message' => 'Anda berada di luar area absensi.',
                    'is_in_zone' => false,
                ], 422);
            }
        } catch (\Exception $e) {
            // 5. Tangani error
            return response()->json([
                'success' => false,
                'message' => $e->getMessage()
            ], 404);
        }
    }

    /**
     * Merekam absensi keluar (Check-Out).
     */
    public function checkOut(Request $request)
    {
        // 1. Validasi input
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
            // 2. Panggil validasi lokasi
            $isValidLocation = $this->validateLocation(
                $request->user(),
                $request->latitude,
                $request->longitude
            );

            if ($isValidLocation) {
                // LOKASI VALID
                // 3. Ambil absensi hari ini
                $attendance = Attendance::where('employee_id', $request->user()->employee->id)
                    ->whereDate('check_in', today())
                    ->firstOrFail();

                // 4. Proses simpan file foto ke server (storage/app/public/attendances)
                $photoPath = null;
                if ($request->hasFile('photo')) {
                    // Menyimpan file dan mengembalikan path-nya
                    $photoPath = $request->file('photo')->store('attendances', 'public');
                }

                // 5. Update record absensi check-out
                $attendance->update([
                    'check_out'             => now(),
                    'check_out_latitude'    => $request->latitude,
                    'check_out_longitude'   => $request->longitude,
                    'check_out_photo_path'  => $photoPath,
                    'status'                => 'hadir',
                ]);

                return response()->json([
                    'success' => true,
                    'message' => 'Check-out berhasil. Hati-hati di jalan!',
                    'data' => $attendance,
                ]);
            } else {
                // LOKASI TIDAK VALID
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
            // Tangani error umum lainnya
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
        // 1. Ambil data berantai: User -> Employee -> Department -> Zones
        $user->loadMissing('employee.department.attendanceZones');

        $employee = $user->employee;

        // 2. Validasi apakah user punya profil & departemen
        if (!$employee) {
            throw new \Exception('Profil karyawan tidak ditemukan.');
        }

        if (!$employee->department) {
            throw new \Exception('Karyawan tidak terdaftar di departemen manapun.');
        }

        // 3. Ambil ID zona yang valid
        $validZoneIds = $employee->department->attendanceZones->pluck('id');

        if ($validZoneIds->isEmpty()) {
            throw new \Exception('Departemen Anda tidak memiliki zona absensi.');
        }

        // 4. Buat Titik (POINT) PostGIS dari lokasi user
        return AttendanceZone::whereIn('id', $validZoneIds)
            ->whereRaw('ST_Contains(area, ST_SetSRID(ST_MakePoint(?, ?), 4326))', [$longitude, $latitude])
            ->exists();
    }

    /**
     * Metode private untuk mendapatkan ID zona absensi berdasarkan user.
     *
     * @param \App\Models\User $user
     * @return int|null
     */
    private function getZoneId(User $user): ?int
    {
        $employee = $user->employee;
        // Ambil ID zona pertama yang valid
        return $employee->department->attendanceZones->first()->id ?? null;
    }

    /**
     * Cek status absensi hari ini.
     */
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

                    // FIXED: Added ->timezone('Asia/Jakarta') to convert UTC to WIB
                    'check_in_time'   => \Carbon\Carbon::parse($attendance->check_in)
                                            ->timezone('Asia/Jakarta')
                                            ->format('H : i : s'),

                    'has_checked_out' => $attendance->check_out !== null,

                    // FIXED: Added ->timezone('Asia/Jakarta') here as well
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

    /**
     * Get monthly attendance statistics for the user.
     */
    public function getMonthlyStats(Request $request)
    {
        try {
            $employeeId = $request->user()->employee->id;
            $currentMonth = \Carbon\Carbon::now()->month;
            $currentYear = \Carbon\Carbon::now()->year;

            // 1. Total Present (Count records where check_in is not null this month)
            $totalAttendance = Attendance::where('employee_id', $employeeId)
                ->whereMonth('check_in', $currentMonth)
                ->whereYear('check_in', $currentYear)
                ->count();

            // 2. Late Clock In (Assuming late is after 09:00:00)
            $lateClockIn = Attendance::where('employee_id', $employeeId)
                ->whereMonth('check_in', $currentMonth)
                ->whereYear('check_in', $currentYear)
                ->whereTime('check_in', '>', '09:00:00')
                ->count();

            // 3. No Clock In (This depends on your DB logic. If you generate empty rows
            // for absences, check for null check_ins. Otherwise, this might query an 'absences' table).
            // Example:
            $noClockIn = Attendance::where('employee_id', $employeeId)
                ->whereMonth('created_at', $currentMonth)
                ->whereYear('created_at', $currentYear)
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

    /**
     * Get recent attendance history for the home screen.
     */
    public function getHistory(Request $request)
    {
        try {
            $employeeId = $request->user()->employee->id;

            // Ambil 3 data absensi terbaru
            $attendances = Attendance::where('employee_id', $employeeId)
                ->orderBy('check_in', 'desc')
                ->take(3)
                ->get()
                ->map(function ($att) {
                    return [
                        'date'      => \Carbon\Carbon::parse($att->check_in)->timezone('Asia/Jakarta')->format('j F Y'),
                        // Pastikan status diformat rapi (misal: "hadir" jadi "Hadir")
                        'status'    => ucfirst($att->status ?? 'Reguler'),
                        'check_in'  => $att->check_in
                                        ? \Carbon\Carbon::parse($att->check_in)->timezone('Asia/Jakarta')->format('H : i : s')
                                        : '-- : -- : --',
                        'check_out' => $att->check_out
                                        ? \Carbon\Carbon::parse($att->check_out)->timezone('Asia/Jakarta')->format('H : i : s')
                                        : '-- : -- : --',
                    ];
                });

            return response()->json([
                'success' => true,
                'data'    => $attendances
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Gagal mengambil riwayat absensi.'
            ], 500);
        }
    }
}

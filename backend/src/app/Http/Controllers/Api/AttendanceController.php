<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Attendance;
use App\Models\AttendanceZone;
use App\Models\User;
use Illuminate\Support\Facades\Validator;

class AttendanceController extends Controller
{
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
                'status' => 'failed',
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
                    'message' => 'Check-in berhasil. Anda berada di dalam area absensi.',
                    'data' => $attendance,
                ]);
            } else {
                // LOKASI TIDAK VALID
                return response()->json([
                    'message' => 'Anda berada di luar area absensi.',
                    'is_in_zone' => false,
                ], 422);
            }
        } catch (\Exception $e) {
            // 5. Tangani error
            return response()->json([
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
                'status' => 'failed',
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
                    'message' => 'Check-out berhasil. Hati-hati di jalan!',
                    'data' => $attendance,
                ]);
            } else {
                // LOKASI TIDAK VALID
                return response()->json([
                    'message' => 'Anda berada di luar area absensi.',
                    'is_in_zone' => false,
                ], 422);
            }
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'message' => 'Anda belum melakukan check-in hari ini.'
            ], 404);
        } catch (\Exception $e) {
            // Tangani error umum lainnya
            return response()->json([
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
}

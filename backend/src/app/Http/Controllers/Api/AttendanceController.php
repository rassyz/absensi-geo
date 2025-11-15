<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\AttendanceZone;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class AttendanceController extends Controller
{
    /**
     * Merekam absensi masuk (Check-In).
     */
    public function checkIn(Request $request)
    {
        // 1. Validasi input (hanya lat/lng)
        $validator = Validator::make($request->all(), [
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
        ]);

        if ($validator->fails()) {
            return response()->json(['status' => 'failed', 'message' => $validator->errors()->first()], 422);
        }

        try {
            // 2. Panggil validasi lokasi
            $isValidLocation = $this->validateLocation(
                $request->user(),
                $request->latitude,
                $request->longitude
            );

            if ($isValidLocation) {
                // 3. LOKASI VALID
                // --- DI SINI LOGIKA ANDA UNTUK MENYIMPAN RECORD ABSEN MASUK ---
                // Contoh:
                // Attendance::create([
                //     'employee_id' => $request->user()->employee->id,
                //     'check_in_time' => now(),
                //     'check_in_lat' => $request->latitude,
                //     'check_in_lng' => $request->longitude,
                // ]);
                // -----------------------------------------------------------

                return response()->json([
                    'status' => 'success',
                    'message' => 'Check-in berhasil. Anda berada di dalam area absensi.',
                    'is_in_zone' => true,
                ]);

            } else {
                // 4. LOKASI TIDAK VALID
                return response()->json([
                    'status' => 'failed',
                    'message' => 'Anda berada di luar area absensi.',
                    'is_in_zone' => false,
                ], 422); // 422 Unprocessable Entity
            }

        } catch (\Exception $e) {
            // 5. Tangani error (misal: user tidak punya departemen, departemen tidak punya zona)
             return response()->json([
                'status' => 'failed',
                'message' => $e->getMessage()
            ], 404);
        }
    }

    /**
     * Merekam absensi keluar (Check-Out).
     */
    public function checkOut(Request $request)
    {
        // 1. Validasi input (hanya lat/lng)
         $validator = Validator::make($request->all(), [
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
        ]);

        if ($validator->fails()) {
            return response()->json(['status' => 'failed', 'message' => $validator->errors()->first()], 422);
        }

        try {
            // 2. Panggil validasi lokasi
            $isValidLocation = $this->validateLocation(
                $request->user(),
                $request->latitude,
                $request->longitude
            );

            if ($isValidLocation) {
                // 3. LOKASI VALID
                // --- DI SINI LOGIKA ANDA UNTUK MENYIMPAN RECORD ABSEN KELUAR ---
                // Contoh:
                // $attendance = Attendance::where('employee_id', $request->user()->employee->id)
                //                         ->whereDate('check_in_time', today())
                //                         ->firstOrFail();
                // $attendance->update([
                //     'check_out_time' => now(),
                //     'check_out_lat' => $request->latitude,
                //     'check_out_lng' => $request->longitude,
                // ]);
                // -------------------------------------------------------------

                return response()->json([
                    'status' => 'success',
                    'message' => 'Check-out berhasil. Anda berada di dalam area absensi.',
                    'is_in_zone' => true,
                ]);

            } else {
                // 4. LOKASI TIDAK VALID
                return response()->json([
                    'status' => 'failed',
                    'message' => 'Anda berada di luar area absensi.',
                    'is_in_zone' => false,
                ], 422); // 422 Unprocessable Entity
            }

        } catch (\Exception $e) {
            // 5. Tangani error
             return response()->json([
                'status' => 'failed',
                'message' => $e->getMessage()
            ], 404);
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
        // Penting: PostGIS menggunakan (Longitude, Latitude)
        $userLocation = DB::raw("ST_SetSRID(ST_MakePoint($longitude, $latitude), 4326)");

        // 5. Kueri Spasial Inti
        // Cek: Apakah lokasi user 'ST_Contains' (terkandung) di *salah satu* zona?
        return AttendanceZone::whereIn('id', $validZoneIds)
            ->whereRaw('ST_Contains(area, ?)', [$userLocation])
            ->exists();
    }
}

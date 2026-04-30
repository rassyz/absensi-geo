<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use App\Models\AttendanceZone;
use Carbon\Carbon;
use Illuminate\Support\Facades\Validator;

class OvertimeController extends Controller
{
    /**
     * 1. Mengambil Daftar Tugas Lembur untuk Karyawan (Hari Ini & Mendatang)
     */
    public function index(Request $request)
    {
        $user = $request->user();

        if (!$user->employee) {
            return response()->json(['success' => false, 'message' => 'Data karyawan tidak ditemukan.'], 404);
        }

        $overtimes = $user->employee->overtimes()
            ->orderBy('date', 'asc')
            ->get()
            ->map(function ($overtime) {
                return [
                    'id' => $overtime->id,
                    'title' => $overtime->title,
                    'date' => Carbon::parse($overtime->date)->translatedFormat('d M Y'),
                    'raw_date' => Carbon::parse($overtime->date)->format('Y-m-d'),
                    'planned_start_time' => Carbon::parse($overtime->planned_start_time)->format('H:i'),
                    'planned_end_time' => Carbon::parse($overtime->planned_end_time)->format('H:i'),
                    'notes' => $overtime->notes,
                    'status' => $overtime->pivot->status,
                    'check_in' => $overtime->pivot->check_in,
                    'check_out' => $overtime->pivot->check_out,
                ];
            });

        return response()->json([
            'success' => true,
            'data' => $overtimes
        ]);
    }

    /**
     * 2. Clock-In Lembur (Masuk Lembur)
     */
    public function clockIn(Request $request)
    {
        // 1. Validasi Input (Foto dihapus)
        $validator = Validator::make($request->all(), [
            'overtime_id' => 'required|exists:overtimes,id',
            'latitude'    => 'required|numeric|between:-90,90',
            'longitude'   => 'required|numeric|between:-180,180',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => $validator->errors()->first()
            ], 422);
        }

        try {
            $user = $request->user();
            $employee = $user->employee;

            // 2. Validasi Lokasi menggunakan Geofencing PostGIS
            $isValidLocation = $this->validateLocation(
                $user,
                $request->latitude,
                $request->longitude
            );

            if (!$isValidLocation) {
                return response()->json([
                    'success' => false,
                    'message' => 'Gagal memcatat lembur. Anda berada di luar area absensi kantor.',
                    'is_in_zone' => false,
                ], 422);
            }

            // 3. Cek apakah karyawan ditugaskan
            $overtime = $employee->overtimes()->where('overtimes.id', $request->overtime_id)->first();
            if (!$overtime) {
                return response()->json(['success' => false, 'message' => 'Anda tidak ditugaskan untuk lembur ini.'], 403);
            }

            // 4. Cek apakah sudah clock-in
            if ($overtime->pivot->check_in) {
                return response()->json(['success' => false, 'message' => 'Anda sudah melakukan clock-in lembur.'], 400);
            }

            // 5. Update pivot table (Tanpa menyimpan path foto)
            $employee->overtimes()->updateExistingPivot($overtime->id, [
                'check_in' => Carbon::now(),
                'check_in_latitude' => $request->latitude,
                'check_in_longitude' => $request->longitude,
                'status' => 'Sedang Lembur'
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Clock In Lembur Berhasil. Anda berada di dalam area.'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan sistem: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * 3. Clock-Out Lembur (Selesai Lembur)
     */
    public function clockOut(Request $request)
    {
        // 1. Validasi Input (Foto dihapus)
        $validator = Validator::make($request->all(), [
            'overtime_id' => 'required|exists:overtimes,id',
            'latitude'    => 'required|numeric|between:-90,90',
            'longitude'   => 'required|numeric|between:-180,180',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => $validator->errors()->first()
            ], 422);
        }

        try {
            $user = $request->user();
            $employee = $user->employee;

            // 2. Validasi Lokasi menggunakan Geofencing PostGIS
            $isValidLocation = $this->validateLocation(
                $user,
                $request->latitude,
                $request->longitude
            );

            if (!$isValidLocation) {
                return response()->json([
                    'success' => false,
                    'message' => 'Anda berada di luar area absensi kantor.',
                    'is_in_zone' => false,
                ], 422);
            }

            // 3. Cari data lembur
            $overtime = $employee->overtimes()->where('overtimes.id', $request->overtime_id)->first();

            // 4. Validasi alur absensi
            if (!$overtime || !$overtime->pivot->check_in) {
                return response()->json(['success' => false, 'message' => 'Anda belum melakukan clock-in lembur.'], 400);
            }

            if ($overtime->pivot->check_out) {
                return response()->json(['success' => false, 'message' => 'Anda sudah melakukan clock-out lembur.'], 400);
            }

            // 5. Update pivot table (Tanpa menyimpan path foto)
            $employee->overtimes()->updateExistingPivot($overtime->id, [
                'check_out' => Carbon::now(),
                'check_out_latitude' => $request->latitude,
                'check_out_longitude' => $request->longitude,
                'status' => 'Selesai'
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Clock Out Lembur Berhasil. Terima kasih atas kerja kerasnya!'
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Terjadi kesalahan sistem: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Metode private untuk memvalidasi lokasi user (Sama persis dengan AttendanceController).
     */
    private function validateLocation(User $user, float $latitude, float $longitude): bool
    {
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

        // Buat Titik (POINT) PostGIS dari lokasi user
        return AttendanceZone::whereIn('id', $validZoneIds)
            ->whereRaw('ST_Contains(area, ST_SetSRID(ST_MakePoint(?, ?), 4326))', [$longitude, $latitude])
            ->exists();
    }
}

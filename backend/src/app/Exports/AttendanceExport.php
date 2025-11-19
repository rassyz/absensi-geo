<?php

namespace App\Exports;

use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Carbon\Carbon; // Import Carbon untuk manajemen waktu

class AttendanceExport implements FromCollection, WithHeadings
{
    protected $data;

    public function __construct($data)
    {
        $this->data = $data; // Data yang akan diekspor
    }

    public function collection()
    {
        // Mengonversi data ke dalam format yang diperlukan untuk diekspor
        return collect($this->data)->map(function ($attendance) {
            return [
                'nama_karyawan' => $attendance->employee->full_name, // Ambil nama karyawan
                'zona_absensi' => $attendance->attendanceZone->name, // Ambil nama zona absensi
                'check_in' => Carbon::parse($attendance->check_in)->setTimezone('Asia/Jakarta')->format('d M Y - H:i'), // Konversi ke zona waktu Asia/Jakarta
                'check_out' => Carbon::parse($attendance->check_out)->setTimezone('Asia/Jakarta')->format('d M Y - H:i'), // Konversi ke zona waktu Asia/Jakarta
                'latitude_check_in' => $attendance->check_in_latitude, // Ambil dari database
                'longitude_check_in' => $attendance->check_in_longitude, // Ambil dari database
                'latitude_check_out' => $attendance->check_out_latitude, // Ambil dari database
                'longitude_check_out' => $attendance->check_out_longitude, // Ambil dari database
                'status' => $attendance->status,
            ];
        });
    }

    public function headings(): array
    {
        return [
            'Nama Karyawan',
            'Zona Absensi',
            'Check-In',
            'Check-Out',
            'Latitude Check-In',
            'Longitude Check-In',
            'Latitude Check-Out',
            'Longitude Check-Out',
            'Status',
        ];
    }
}

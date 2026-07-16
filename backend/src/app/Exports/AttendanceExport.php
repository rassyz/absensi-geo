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
                'nama_karyawan' => $attendance->employee->full_name,
                'departemen' => $attendance->employee->department->name,
                'zona_absensi' => $attendance->attendanceZone->name,
                'date' => $attendance->date->setTimezone('Asia/Jakarta')->format('d M Y'),
                'check_in' => $attendance->check_in->setTimezone('Asia/Jakarta')->format('H:i'),
                'check_out' => $attendance->check_out->setTimezone('Asia/Jakarta')->format('H:i'),
                'latitude_check_in' => $attendance->check_in_latitude,
                'longitude_check_in' => $attendance->check_in_longitude,
                'latitude_check_out' => $attendance->check_out_latitude,
                'longitude_check_out' => $attendance->check_out_longitude,
                'status' => $attendance->status,
            ];
        });
    }

    public function headings(): array
    {
        return [
            'Nama Karyawan',
            'Departemen',
            'Zona Absensi',
            'Tanggal',
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

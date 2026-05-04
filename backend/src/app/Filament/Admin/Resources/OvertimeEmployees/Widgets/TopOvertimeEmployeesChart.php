<?php

namespace App\Filament\Resources\OvertimeEmployeeResource\Widgets;

use Filament\Widgets\ChartWidget;
use App\Models\OvertimeEmployee;
use Illuminate\Support\Facades\DB;

class TopOvertimeEmployeesChart extends ChartWidget
{
    public function getHeading(): ?string
    {
        return 'Top 5 Karyawan Paling Sering Lembur';
    }

    protected function getData(): array
    {
        // Mengambil 5 karyawan teratas yang paling sering berhasil clock-in
        $topEmployees = OvertimeEmployee::select('employee_id', DB::raw('count(*) as total'))
            ->whereNotNull('check_in') // Hanya hitung yang benar-benar absen masuk
            ->groupBy('employee_id')
            ->orderByDesc('total')
            ->limit(5)
            ->with('employee') // Pastikan relasi 'employee' ada di model OvertimeEmployee Anda
            ->get();

        $labels = [];
        $data = [];

        foreach ($topEmployees as $row) {
            // Memasukkan nama karyawan (jika berelasi ke user, sesuaikan: $row->employee->user->name)
            $labels[] = $row->employee->full_name;
            $data[] = $row->total;
        }

        return [
            'datasets' => [
                [
                    'label' => 'Total Presensi Lembur',
                    'data' => $data,
                    'backgroundColor' => '#3b82f6', // Biru solid
                    'borderColor' => '#2563eb',
                    'borderWidth' => 1,
                    'borderRadius' => 4,
                ],
            ],
            'labels' => $labels,
        ];
    }

    protected function getType(): string
    {
        return 'bar';
    }

    protected function getOptions(): array
    {
        return [
            'maintainAspectRatio' => false,
            'indexAxis' => 'y', // 👇 TRIK: Mengubah grafik bar vertikal menjadi HORIZONTAL
            'scales' => [
                'x' => [ // Karena posisinya horizontal, sumbu X yang memegang angka
                    'beginAtZero' => true,
                    'ticks' => ['stepSize' => 1],
                ],
            ],
            'plugins' => [
                'legend' => ['display' => false],
            ],
        ];
    }
}

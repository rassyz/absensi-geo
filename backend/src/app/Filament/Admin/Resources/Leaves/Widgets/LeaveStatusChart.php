<?php

namespace App\Filament\Resources\LeaveResource\Widgets;

use Filament\Widgets\ChartWidget;
use App\Models\Leave; // Sesuaikan dengan model Cuti Anda

class LeaveStatusChart extends ChartWidget
{
    public function getHeading(): ?string
    {
        return 'Distribusi Status Cuti';
    }

    protected function getData(): array
    {
        // Sesuaikan string 'Pending', 'Disetujui', 'Ditolak' dengan data di database Anda
        $pending = Leave::where('status', 'Pending')->count();
        $approved = Leave::where('status', 'Approved')->count(); // Atau 'Approved'
        $rejected = Leave::where('status', 'Rejected')->count(); // Atau 'Rejected'

        return [
            'datasets' => [
                [
                    'label' => 'Total Cuti',
                    'data' => [$pending, $approved, $rejected],
                    'backgroundColor' => [
                        '#eab308', // Kuning (Pending)
                        '#22c55e', // Hijau (Disetujui)
                        '#ef4444', // Merah (Ditolak)
                    ],
                    'borderColor' => '#18181b', // Border dark mode
                    'borderWidth' => 2,
                ],
            ],
            'labels' => [
                "Menunggu Persetujuan ($pending)",
                "Disetujui ($approved)",
                "Ditolak ($rejected)"
            ],
        ];
    }

    protected function getType(): string
    {
        return 'pie'; // Grafik bentuk Pie / Kue
    }

    protected function getOptions(): array
    {
        return [
            'maintainAspectRatio' => false,
            'plugins' => [
                'legend' => [
                    'position' => 'right', // Taruh keterangan di sebelah kanan agar rapi
                    'labels' => ['font' => ['weight' => 'bold']],
                ],
            ],
        ];
    }
}

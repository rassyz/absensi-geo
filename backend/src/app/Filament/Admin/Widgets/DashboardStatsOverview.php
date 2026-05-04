<?php

namespace App\Filament\Widgets;

use App\Models\Attendance;
use App\Models\Leave;
use App\Models\OvertimeEmployee;
use Carbon\Carbon;
use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class DashboardStatsOverview extends BaseWidget
{
    // Mengatur urutan widget (angka 1 berarti paling atas)
    protected static ?int $sort = 1;

    protected function getStats(): array
    {
        $today = Carbon::today();

        // 1. Hitung Presensi Hari Ini (Contoh asumsi nama model presensi Anda adalah 'Attendance')
        // Ganti 'Attendance' dengan nama model presensi Anda yang sebenarnya jika berbeda
        $totalPresensi = Attendance::whereDate('date', $today)->count();

        // 2. Hitung Lembur Aktif Hari Ini
        $lemburAktif = OvertimeEmployee::whereDate('check_in', $today)
            ->whereNull('check_out')
            ->count();

        // 3. Hitung Cuti Tertunda
        $cutiTertunda = Leave::where('status', 'Pending')->count();

        return [
            Stat::make('Presensi Hari Ini', $totalPresensi)
                ->description('Total karyawan hadir')
                ->descriptionIcon('heroicon-m-user-group')
                ->color('success')
                ->chart([7, 2, 10, 3, 15, 4, 17]), // Grafik mini (sparkline) ilustrasi

            Stat::make('Sedang Lembur', $lemburAktif)
                ->description('Karyawan di lokasi saat ini')
                ->descriptionIcon('heroicon-m-clock')
                ->color('warning'),

            Stat::make('Menunggu Persetujuan Cuti', $cutiTertunda)
                ->description('Butuh tindakan segera')
                ->descriptionIcon('heroicon-m-document-text')
                ->color('danger'),
        ];
    }
}

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
    /**
     * Mengatur urutan widget pada dashboard.
     */
    protected static ?int $sort = 1;

    protected function getStats(): array
    {
        $today = Carbon::today();


        $totalPresensi = Attendance::query()
            ->whereDate('date', $today)
            ->whereNotNull('check_in')
            ->count();

        $totalTidakHadir = Attendance::query()
            ->whereDate('date', $today)
            ->whereNull('check_in')
            ->count();

        $lemburAktif = OvertimeEmployee::query()
            ->whereDate('check_in', $today)
            ->whereNotNull('check_in')
            ->whereNull('check_out')
            ->count();

        $cutiTertunda = Leave::query()
            ->where('status', 'Pending')
            ->count();

        return [
            Stat::make('Presensi Hari Ini', $totalPresensi)
                ->description('Karyawan hadir dan terlambat')
                ->descriptionIcon('heroicon-m-user-group')
                ->color('success')
                ->chart([7, 2, 10, 3, 15, 4, 17]),

            Stat::make('Tidak Hadir Hari Ini', $totalTidakHadir)
                ->description('Karyawan cuti, izin, sakit, atau alpa')
                ->descriptionIcon('heroicon-m-user-minus')
                ->color('danger'),

            Stat::make('Sedang Lembur', $lemburAktif)
                ->description('Karyawan lembur di lokasi saat ini')
                ->descriptionIcon('heroicon-m-clock')
                ->color('warning'),

            Stat::make('Menunggu Persetujuan Cuti', $cutiTertunda)
                ->description('Butuh tindakan segera')
                ->descriptionIcon('heroicon-m-document-text')
                ->color('danger'),
        ];
    }
}

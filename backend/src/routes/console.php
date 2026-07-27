<?php

declare(strict_types=1);

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

Schedule::command('attendance:mark-absences')->dailyAt('17:59');

Schedule::command('sanctum:prune-expired --hours=24')
    ->dailyAt('02:00')
    ->withoutOverlapping();




// Pengingat Absensi
$timezone = config(
    'attendance.timezone',
    'Asia/Jakarta'
);

$workDays = config(
    'attendance.work_days',
    [1, 2, 3, 4, 5, 6]
);

Schedule::command(
    'attendance:send-reminder check-in'
)
    ->dailyAt(
        config(
            'attendance.check_in_reminder',
            '08:45'
        )
    )
    ->timezone($timezone)
    ->days($workDays)
    ->withoutOverlapping();

Schedule::command(
    'attendance:send-reminder check-out'
)
    ->dailyAt(
        config(
            'attendance.check_out_reminder',
            '17:00'
        )
    )
    ->timezone($timezone)
    ->days($workDays)
    ->withoutOverlapping();

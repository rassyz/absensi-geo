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

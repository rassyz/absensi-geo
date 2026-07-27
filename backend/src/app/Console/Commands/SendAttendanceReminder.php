<?php

namespace App\Console\Commands;

use App\Models\Attendance;
use App\Models\Employee;
use App\Services\FcmNotificationService;
use Carbon\Carbon;
use Illuminate\Console\Command;
use Illuminate\Database\Eloquent\Builder;

class SendAttendanceReminder extends Command
{
    protected $signature = 'attendance:send-reminder
                            {type : Jenis pengingat: check-in atau check-out}';

    protected $description =
    'Mengirim notifikasi pengingat presensi masuk atau keluar.';

    public function handle(
        FcmNotificationService $notificationService
    ): int {
        $type = strtolower(
            trim((string) $this->argument('type'))
        );

        if (! in_array($type, ['check-in', 'check-out'], true)) {
            $this->error(
                'Jenis pengingat harus check-in atau check-out.'
            );

            return self::FAILURE;
        }

        $timezone = config(
            'attendance.timezone',
            'Asia/Jakarta'
        );

        $today = Carbon::now($timezone)->toDateString();

        if ($type === 'check-in') {
            return $this->sendCheckInReminders(
                $today,
                $notificationService
            );
        }

        return $this->sendCheckOutReminders(
            $today,
            $notificationService
        );
    }

    /**
     * Mengirim pengingat presensi masuk.
     *
     * Notifikasi hanya dikirim kepada karyawan yang:
     * - Memiliki token perangkat.
     * - Belum melakukan check-in hari ini.
     * - Tidak sedang cuti, izin, atau sakit.
     */
    private function sendCheckInReminders(
        string $today,
        FcmNotificationService $notificationService
    ): int {
        $employees = Employee::query()
            ->with([
                'user.deviceTokens',
            ])
            ->whereHas('user.deviceTokens')

            /*
             * Jangan kirim notifikasi jika sudah terdapat:
             * - check_in hari ini; atau
             * - presensi berstatus cuti, izin, atau sakit.
             */
            ->whereDoesntHave(
                'attendances',
                function (Builder $query) use ($today) {
                    $query
                        ->whereDate(
                            'attendances.date',
                            $today
                        )
                        ->where(
                            function (Builder $attendanceQuery) {
                                $attendanceQuery
                                    ->whereNotNull(
                                        'attendances.check_in'
                                    )
                                    ->orWhereRaw(
                                        'LOWER(attendances.status) IN (?, ?, ?)',
                                        [
                                            'cuti',
                                            'izin',
                                            'sakit',
                                        ]
                                    );
                            }
                        );
                }
            )

            /*
             * Jangan kirim apabila terdapat pengajuan cuti
             * yang disetujui dan mencakup tanggal hari ini.
             */
            ->whereDoesntHave(
                'leaves',
                function (Builder $query) use ($today) {
                    $query
                        ->whereDate(
                            'leaves.start_date',
                            '<=',
                            $today
                        )
                        ->whereDate(
                            'leaves.end_date',
                            '>=',
                            $today
                        )
                        ->whereRaw(
                            'LOWER(leaves.status) IN (?, ?)',
                            [
                                'approved',
                                'disetujui',
                            ]
                        );
                }
            )
            ->get();

        $totalSent = 0;
        $totalFailed = 0;
        $totalEmployees = 0;

        foreach ($employees as $employee) {
            $user = $employee->user;

            if ($user === null) {
                continue;
            }

            $tokens = $user->deviceTokens
                ->pluck('token')
                ->filter(
                    fn($token) => is_string($token)
                        && trim($token) !== ''
                )
                ->unique()
                ->values();

            if ($tokens->isEmpty()) {
                continue;
            }

            $result = $notificationService->sendToTokens(
                $tokens,
                'Pengingat Presensi Masuk',
                'Jam kerja akan segera dimulai. '
                    . 'Silakan lakukan presensi masuk '
                    . 'agar tidak tercatat terlambat.',
                [
                    'route' => 'attendance',
                    'type' => 'check_in_reminder',
                    'employee_id' => $employee->id,
                    'date' => $today,
                ]
            );

            $totalEmployees++;
            $totalSent += $result['sent'];
            $totalFailed += $result['failed'];
        }

        $this->newLine();
        $this->info('Pengingat presensi masuk selesai.');
        $this->line("Tanggal        : {$today}");
        $this->line("Karyawan       : {$totalEmployees}");
        $this->line("Berhasil kirim : {$totalSent}");
        $this->line("Gagal kirim    : {$totalFailed}");

        return self::SUCCESS;
    }

    /**
     * Mengirim pengingat presensi keluar.
     *
     * Notifikasi hanya dikirim apabila:
     * - check_in sudah terisi.
     * - check_out masih kosong.
     * - Karyawan memiliki token perangkat.
     */
    private function sendCheckOutReminders(
        string $today,
        FcmNotificationService $notificationService
    ): int {
        $attendances = Attendance::query()
            ->with([
                'employee.user.deviceTokens',
            ])
            ->whereDate(
                'attendances.date',
                $today
            )
            ->whereNotNull(
                'attendances.check_in'
            )
            ->whereNull(
                'attendances.check_out'
            )
            ->get();

        $totalSent = 0;
        $totalFailed = 0;
        $totalEmployees = 0;

        foreach ($attendances as $attendance) {
            $employee = $attendance->employee;
            $user = $employee?->user;

            if ($employee === null || $user === null) {
                continue;
            }

            $tokens = $user->deviceTokens
                ->pluck('token')
                ->filter(
                    fn($token) => is_string($token)
                        && trim($token) !== ''
                )
                ->unique()
                ->values();

            if ($tokens->isEmpty()) {
                continue;
            }

            $result = $notificationService->sendToTokens(
                $tokens,
                'Jangan Lupa Presensi Keluar',
                'Jam kerja telah selesai. '
                    . 'Silakan lakukan presensi keluar '
                    . 'agar waktu kepulangan Anda tercatat '
                    . 'dan tidak tampil N/A.',
                [
                    'route' => 'attendance',
                    'type' => 'check_out_reminder',
                    'attendance_id' => $attendance->id,
                    'employee_id' => $employee->id,
                    'date' => $today,
                ]
            );

            $totalEmployees++;
            $totalSent += $result['sent'];
            $totalFailed += $result['failed'];
        }

        $this->newLine();
        $this->info('Pengingat presensi keluar selesai.');
        $this->line("Tanggal        : {$today}");
        $this->line("Karyawan       : {$totalEmployees}");
        $this->line("Berhasil kirim : {$totalSent}");
        $this->line("Gagal kirim    : {$totalFailed}");

        return self::SUCCESS;
    }
}

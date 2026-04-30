<?php

use App\Http\Controllers\Api\AttendanceController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\LeaveController;
use App\Http\Controllers\Api\OvertimeController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::post('/register', [AuthController::class, 'register'])->name('api.register');
Route::post('/login', [AuthController::class, 'login'])->name('api.login');

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me', [AuthController::class, 'me'])->name('api.me');
    Route::post('/logout', [AuthController::class, 'logout'])->name('api.logout');
});

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');


// API Absensi
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/attendance/check-in', [AttendanceController::class, 'checkIn'])->name('api.attendance.checkin');
    Route::post('/attendance/check-out', [AttendanceController::class, 'checkOut'])->name('api.attendance.checkout');
    Route::get('/attendance/user-zone', [AttendanceController::class, 'getUserZone'])->name('api.attendance.userzone');
    Route::get('/attendance/today', [AttendanceController::class, 'getTodayStatus'])->name('api.attendance.today');
    Route::get('/attendance/monthly-stats', [AttendanceController::class, 'getMonthlyStats'])->name('api.attendance.monthlystats');
    Route::get('/attendance/history', [AttendanceController::class, 'getHistory'])->name('api.attendance.history');
    Route::get('/attendance/report', [AttendanceController::class, 'getMonthlyReport'])->name('api.attendance.report');
    Route::get('/leaves/dashboard', [LeaveController::class, 'getLeaveDashboard'])->name('api.leaves.dashboard');
    Route::post('/leaves/apply', [LeaveController::class, 'store'])->name('api.leaves.apply');
    Route::post('/leaves/{id}/process', [LeaveController::class, 'process'])->name('api.leaves.process');
    Route::get('/overtimes', [OvertimeController::class, 'index'])->name('api.overtimes.index');
    Route::post('/overtimes/clock-in', [OvertimeController::class, 'clockIn'])->name('api.overtimes.clockin');
    Route::post('/overtimes/clock-out', [OvertimeController::class, 'clockOut'])->name('api.overtimes.clockout');
});

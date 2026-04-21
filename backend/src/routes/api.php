<?php

use App\Http\Controllers\Api\AuthController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AttendanceController;

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
});

<?php

declare(strict_types=1);

use App\Models\Employee;
use App\Models\User;
use Laravel\Sanctum\Sanctum;


test('endpoint zona presensi mengembalikan 401 jika unauthenticated', function () {
    /** @var \Tests\TestCase $this */
    $response = $this->getJson('/api/attendance/user-zone');

    $response->assertStatus(401);
});

test('endpoint validasi lokasi mengembalikan 401 jika unauthenticated', function () {
    /** @var \Tests\TestCase $this */
    $response = $this->postJson('/api/attendance/validate-location', [
        'latitude'  => -6.200,
        'longitude' => 106.816,
    ]);

    $response->assertStatus(401);
});

test('validasi lokasi mengembalikan 404 jika user tidak memiliki profil employee', function () {
    /** @var \Tests\TestCase $this */
    $user = new User();
    $user->id = 99;
    $user->setRelation('employee', null);
    Sanctum::actingAs($user);

    $response = $this->postJson('/api/attendance/validate-location', [
        'latitude'  => -6.200,
        'longitude' => 106.816,
    ]);

    $response->assertStatus(404)
        ->assertJson([
            'success' => false,
            'message' => 'Profil karyawan tidak ditemukan.',
        ]);
});

test('validasi lokasi mengembalikan 422 jika koordinat tidak valid', function () {
    /** @var \Tests\TestCase $this */
    $user = new User();
    $user->id = 1;
    $employee = new Employee();
    $employee->id = 1;
    $user->setRelation('employee', $employee);
    Sanctum::actingAs($user);

    $response = $this->postJson('/api/attendance/validate-location', [
        'latitude'  => 199.0, // di luar batas -90 s/d 90
        'longitude' => 'invalid',
    ]);

    $response->assertStatus(422)
        ->assertJsonStructure(['success', 'message'])
        ->assertJson(['success' => false]);
});

test('check-in mengembalikan 422 jika foto atau koordinat kosong', function () {
    /** @var \Tests\TestCase $this */
    $user = new User();
    $user->id = 2;
    $employee = new Employee();
    $employee->id = 2;
    $user->setRelation('employee', $employee);
    Sanctum::actingAs($user);

    $response = $this->postJson('/api/attendance/check-in', [
        'latitude' => -6.200,
    ]);

    $response->assertStatus(422)
        ->assertJson(['success' => false]);
});

test('status absensi hari ini mengembalikan 401 jika unauthenticated', function () {
    /** @var \Tests\TestCase $this */
    $response = $this->getJson('/api/attendance/today');

    $response->assertStatus(401);
});

test('riwayat absensi mengembalikan 401 jika unauthenticated', function () {
    /** @var \Tests\TestCase $this */
    $response = $this->getJson('/api/attendance/history');

    $response->assertStatus(401);
});

test('laporan absensi bulanan mengembalikan 401 jika unauthenticated', function () {
    /** @var \Tests\TestCase $this */
    $response = $this->getJson('/api/attendance/report');

    $response->assertStatus(401);
});

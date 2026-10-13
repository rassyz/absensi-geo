<?php

declare(strict_types=1);

use App\Models\Employee;
use App\Models\User;
use Laravel\Sanctum\Sanctum;

test('daftar lembur mengembalikan 401 jika unauthenticated', function () {
    $response = $this->getJson('/api/overtimes');

    $response->assertStatus(401);
});

test('daftar lembur mengembalikan 404 jika user tidak memiliki profil employee', function () {
    $user = new User();
    $user->id = 15;
    $user->setRelation('employee', null);
    Sanctum::actingAs($user);

    $response = $this->getJson('/api/overtimes');

    $response->assertStatus(404)
        ->assertJson([
            'success' => false,
            'message' => 'Data karyawan tidak ditemukan.',
        ]);
});

test('clock-in lembur mengembalikan 401 jika unauthenticated', function () {
    $response = $this->postJson('/api/overtimes/clock-in', [
        'overtime_id' => 1,
        'latitude'    => -6.200,
        'longitude'   => 106.816,
    ]);

    $response->assertStatus(401);
});

test('clock-in lembur mengembalikan 404 jika user tidak memiliki profil employee', function () {
    $user = new User();
    $user->id = 16;
    $user->setRelation('employee', null);
    Sanctum::actingAs($user);

    $response = $this->postJson('/api/overtimes/clock-in', [
        'overtime_id' => 1,
        'latitude'    => -6.200,
        'longitude'   => 106.816,
    ]);

    $response->assertStatus(404)
        ->assertJson([
            'success' => false,
            'message' => 'Data karyawan tidak ditemukan.',
        ]);
});

test('clock-in lembur mengembalikan 422 jika input tidak valid', function () {
    $user = new User();
    $user->id = 17;
    $employee = new Employee();
    $employee->id = 17;
    $user->setRelation('employee', $employee);
    Sanctum::actingAs($user);

    $response = $this->postJson('/api/overtimes/clock-in', [
        'overtime_id' => null,
        'latitude'    => 180.0,
    ]);

    $response->assertStatus(422)
        ->assertJsonStructure(['success', 'message'])
        ->assertJson(['success' => false]);
});

test('clock-out lembur mengembalikan 401 jika unauthenticated', function () {
    $response = $this->postJson('/api/overtimes/clock-out', [
        'overtime_id' => 1,
        'latitude'    => -6.200,
        'longitude'   => 106.816,
    ]);

    $response->assertStatus(401);
});

test('clock-out lembur mengembalikan 404 jika user tidak memiliki profil employee', function () {
    $user = new User();
    $user->id = 18;
    $user->setRelation('employee', null);
    Sanctum::actingAs($user);

    $response = $this->postJson('/api/overtimes/clock-out', [
        'overtime_id' => 1,
        'latitude'    => -6.200,
        'longitude'   => 106.816,
    ]);

    $response->assertStatus(404)
        ->assertJson([
            'success' => false,
            'message' => 'Data karyawan tidak ditemukan.',
        ]);
});

test('clock-out lembur mengembalikan 422 jika input tidak valid', function () {
    $user = new User();
    $user->id = 19;
    $employee = new Employee();
    $employee->id = 19;
    $user->setRelation('employee', $employee);
    Sanctum::actingAs($user);

    $response = $this->postJson('/api/overtimes/clock-out', [
        'overtime_id' => null,
    ]);

    $response->assertStatus(422)
        ->assertJsonStructure(['success', 'message'])
        ->assertJson(['success' => false]);
});


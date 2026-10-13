<?php

declare(strict_types=1);

use App\Models\Employee;
use App\Models\User;
use Laravel\Sanctum\Sanctum;

test('pengajuan cuti mengembalikan 401 jika unauthenticated', function () {
    /** @var \Tests\TestCase $this */
    $response = $this->postJson('/api/leaves/apply', []);

    $response->assertStatus(401);
});

test('pengajuan cuti mengembalikan 401 jika user tidak memiliki profil employee', function () {
    /** @var \Tests\TestCase $this */
    $user = new User();
    $user->id = 1;
    $user->setRelation('employee', null);
    Sanctum::actingAs($user);

    $response = $this->postJson('/api/leaves/apply', [
        'leave_type_id' => 1,
        'start_date'    => '2026-10-20',
        'end_date'      => '2026-10-21',
        'apply_days'    => 2,
        'reason'        => 'Keperluan pribadi',
    ]);

    $response->assertStatus(401)
        ->assertJson([
            'success' => false,
            'message' => 'Unauthorized or employee record not found',
        ]);
});

test('dashboard cuti mengembalikan 401 jika unauthenticated', function () {
    /** @var \Tests\TestCase $this */
    $response = $this->getJson('/api/leaves/dashboard');

    $response->assertStatus(401);
});

test('dashboard cuti mengembalikan 401 jika user tidak memiliki profil employee', function () {
    /** @var \Tests\TestCase $this */
    $user = new User();
    $user->id = 3;
    $user->setRelation('employee', null);
    Sanctum::actingAs($user);

    $response = $this->getJson('/api/leaves/dashboard');

    $response->assertStatus(401)
        ->assertJson([
            'success' => false,
            'message' => 'Unauthorized or employee record not found',
        ]);
});

test('proses cuti mengembalikan 401 jika unauthenticated', function () {
    /** @var \Tests\TestCase $this */
    $response = $this->postJson('/api/leaves/1/process', [
        'status' => 'Approved',
    ]);

    $response->assertStatus(401);
});

test('proses cuti mengembalikan 403 jika user tidak memiliki profil employee', function () {
    /** @var \Tests\TestCase $this */
    $user = new User();
    $user->id = 4;
    $user->setRelation('employee', null);
    Sanctum::actingAs($user);

    $response = $this->postJson('/api/leaves/1/process', [
        'status' => 'Approved',
    ]);

    $response->assertStatus(403)
        ->assertJson([
            'success' => false,
            'message' => 'Unauthorized to process this leave',
        ]);
});

test('proses cuti mengembalikan 422 jika status tidak valid', function () {
    /** @var \Tests\TestCase $this */
    $user = new User();
    $user->id = 5;
    $employee = new Employee();
    $employee->id = 5;
    $user->setRelation('employee', $employee);
    Sanctum::actingAs($user);

    $response = $this->postJson('/api/leaves/1/process', [
        'status' => 'InvalidStatus',
    ]);

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['status']);
});

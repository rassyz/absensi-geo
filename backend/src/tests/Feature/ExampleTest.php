<?php

declare(strict_types=1);

test('the application returns a successful response', function () {
    /** @var \Tests\TestCase $this */
    $response = $this->get('/');

    $response->assertStatus(200);
});

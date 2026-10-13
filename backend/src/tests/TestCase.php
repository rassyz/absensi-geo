<?php

namespace Tests;

use Illuminate\Contracts\Console\Kernel;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Testing\CachedState;
use Illuminate\Foundation\Testing\TestCase as BaseTestCase;
use Illuminate\Foundation\Testing\WithCachedConfig;
use Illuminate\Foundation\Testing\WithCachedRoutes;

/**
 * @method void markConfigCached(Application $app)
 */
abstract class TestCase extends BaseTestCase
{
    public function createApplication()
    {
        $app = require Application::inferBasePath() . '/bootstrap/app.php';

        $storagePath = sys_get_temp_dir() . '/absensigeo_test_storage';
        if (!is_dir($storagePath)) {
            mkdir($storagePath, 0777, true);
        }
        foreach (['framework/cache', 'framework/views', 'framework/sessions', 'logs'] as $dir) {
            if (!is_dir($storagePath . '/' . $dir)) {
                mkdir($storagePath . '/' . $dir, 0777, true);
            }
        }
        $app->useStoragePath($storagePath);

        $this->traitsUsedByTest = array_flip(class_uses_recursive(static::class));

        if (
            isset(CachedState::$cachedConfig) &&
            isset($this->traitsUsedByTest[WithCachedConfig::class])
        ) {
            $this->markConfigCached($app);
        }

        if (
            isset(CachedState::$cachedRoutes) &&
            isset($this->traitsUsedByTest[WithCachedRoutes::class])
        ) {
            $app->booting(fn() => $this->markRoutesCached($app));
        }

        $app->make(Kernel::class)->bootstrap();

        return $app;
    }
}

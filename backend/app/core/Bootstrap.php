<?php

namespace App\Core;

use App\Core\Router;
use Dotenv\Dotenv;
use Exception;

class Bootstrap
{
    public function run(): void
    {
        // 1. Set error reporting based on environment
        if (getenv('APP_ENV') === 'production') {
            error_reporting(0);
            ini_set('display_errors', '0');
        } else {
            error_reporting(E_ALL);
            ini_set('display_errors', '1');
        }

        // 2. Load environment variables
        $this->loadEnvironment();

        // 3. Set default timezone (important for logs, tokens, etc.)
        date_default_timezone_set(getenv('APP_TIMEZONE') ?: 'UTC');

        // 4. Start output buffering (clean output, prevent header issues)
        ob_start();

        // 5. Include routes and dispatch
        try {
            require_once __DIR__ . '/../../config/routes.php';

            $router = new Router();
            $router->dispatch();
        } catch (Exception $e) {
            // Global exception fallback
            http_response_code(500);
            if (getenv('APP_DEBUG') === 'true') {
                echo json_encode([
                    'error'   => 'Internal Server Error',
                    'message' => $e->getMessage(),
                    'trace'   => $e->getTraceAsString()
                ]);
            } else {
                echo json_encode(['error' => 'Something went wrong. Please try again later.']);
            }
            error_log($e->getMessage() . ' in ' . $e->getFile() . ':' . $e->getLine());
        } finally {
            ob_end_flush();
        }
    }

    private function loadEnvironment(): void
    {
        $basePath = __DIR__ . '/../../';

        try {
            $dotenv = Dotenv::createImmutable($basePath, ['.env', '.env.local']);
            $dotenv->load();

            // Required variables
            $dotenv->required([
                'APP_ENV',
                'JWT_SECRET',
                'DB_HOST',
                'DB_DATABASE',
                'DB_USERNAME'
            ]);

            // Optional with defaults
            $dotenv->ifPresent('APP_DEBUG')->isBoolean();
            $dotenv->ifPresent('APP_URL')->notEmpty();

        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode([
                'error' => 'Configuration Error',
                'message' => 'Failed to load environment variables: ' . $e->getMessage()
            ]);
            error_log('Dotenv Error: ' . $e->getMessage());
            exit;
        }
    }
}

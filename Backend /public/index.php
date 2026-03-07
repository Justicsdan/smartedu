<?php
/**
 * SmartEdu - Bootstrap File
 * 
 * Handles Environment loading, Error Reporting, and Application execution.
 * Designed for High Performance & Security.
 */

// ============================================
// 1. Output Buffering (Prevents whitespace errors in JSON)
// ============================================
ob_start();

// ============================================
// 2. Set Headers (CRITICAL for API Performance)
// ============================================
// Allow all origins (Adjust '*' to your frontend domain in production)
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Content-Type: application/json; charset=UTF-8");

// Handle Preflight OPTIONS requests immediately
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// ============================================
// 3. Timezone & Error Reporting
// ============================================
// Set Timezone (Matches your DB location, e.g., Lagos/Jos)
date_default_timezone_set('Africa/Lagos');

// Check if APP_DEBUG is set, default to false
 $appDebug = filter_var(getenv('APP_DEBUG'), FILTER_VALIDATE_BOOLEAN);

// Show errors only if Debug mode is ON
if ($appDebug) {
    ini_set('display_errors', 1);
    error_reporting(E_ALL);
} else {
    ini_set('display_errors', 0); // Hide errors in production
    error_reporting(0); // Log errors instead of displaying them
}

// ============================================
// 4. Load Composer Autoloader
// ============================================
if (file_exists(__DIR__ . '/../vendor/autoload.php')) {
    require_once __DIR__ . '/../vendor/autoload.php';
} else {
    http_response_code(500);
    echo json_encode(['error' => 'Composer dependencies not found. Run `composer install`.']);
    exit;
}

// ============================================
// 5. Load Environment Variables (.env)
// ============================================
use Dotenv\Dotenv;

try {
    // CreateImmutable loads .env into getenv() and $_ENV
    $dotenv = Dotenv::createImmutable(__DIR__ . '/..');
    
    // safeLoad() prevents crashing if .env is missing during development
    $dotenv->safeLoad();
    
    // Optional: Force specific variables to exist
    // $dotenv->required(['DB_HOST', 'DB_NAME', 'DB_USER']);
    
} catch (\Dotenv\Exception\InvalidPathException $e) {
    // .env file not found
    http_response_code(500);
    echo json_encode(['error' => 'Environment configuration missing (.env file).']);
    exit;
} catch (\Dotenv\Exception\ValidationException $e) {
    // .env found, but variables are missing
    http_response_code(500);
    echo json_encode(['error' => 'Required environment variables are missing in .env.']);
    exit;
}

// ============================================
// 6. Start Session (Required for Login System)
// ============================================
// Only start if headers haven't been sent yet
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

// ============================================
// 7. Load Helper Functions
// ============================================
// Efficiently load all files in the helpers folder
 $helpers = glob(__DIR__ . '/../helpers/*.php');
if ($helpers !== false) {
    foreach ($helpers as $helperFile) {
        require_once $helperFile;
    }
}

// ============================================
// 8. Bootstrap & Run Application
// ============================================
use App\Core\Bootstrap;

try {
    // Instantiate the Application Core
    $app = new Bootstrap();
    
    // Run the Application (Router -> Controller -> Response)
    $app->run();

} catch (\Throwable $e) {
    // ============================================
    // 9. Global Exception Handler (JSON Response)
    // ============================================
    
    // Determine HTTP Code
    $code = ($e instanceof Error) ? 500 : 500;
    if (method_exists($e, 'getStatusCode')) {
        $code = $e->getStatusCode();
    }
    
    http_response_code($code);

    // Prepare Error Response
    $errorData = [
        'success' => false,
        'error'   => 'Internal Server Error',
        'message' => 'An unexpected error occurred. Please contact support.'
    ];

    // Include detailed stack trace ONLY in Debug Mode
    if ($appDebug) {
        $errorData['exception'] = $e->getMessage();
        $errorData['file']       = $e->getFile();
        $errorData['line']       = $e->getLine();
        $errorData['trace']      = $e->getTraceAsString();
    }

    // Clean Output Buffer to ensure valid JSON
    ob_clean();
    
    echo json_encode($errorData);
}

// ============================================
// 10. End Script
// ============================================
// Output Buffer automatically flushed here
exit;

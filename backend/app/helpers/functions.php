<?php

if (!function_exists('get_base_url')) {
    /**
     * Get the base URL of the application (e.g., http://localhost/myschool/public)
     */
    function get_base_url(string $path = ''): string
    {
        // Check if behind a proxy (optional)
        $protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? "https://" : "http://";
        $domainName = $_SERVER['HTTP_HOST'];
        
        // Get the directory of the entry script (e.g., /myschool/public/index.php -> /myschool/public)
        $baseDir = str_replace('\\', '/', dirname($_SERVER['SCRIPT_NAME']));
        
        return $protocol . $domainName . $baseDir . '/' . ltrim($path, '/');
    }
}

if (!function_exists('asset_url')) {
    /**
     * Helper to link to assets (css, js, images)
     */
    function asset_url(string $path): string
    {
        return get_base_url('assets/' . ltrim($path, '/'));
    }
}

if (!function_exists('redirect')) {
    /**
     * Redirect to a specific URL
     */
    function redirect(string $url): void
    {
        header("Location: " . $url);
        exit;
    }
}

if (!function_exists('json_response')) {
    /**
     * Return JSON response (for AJAX/API)
     */
    function json_response(array $data, int $statusCode = 200): void
    {
        http_response_code($statusCode);
        header('Content-Type: application/json');
        echo json_encode($data);
        exit;
    }
}

if (!function_exists('old')) {
    /**
     * Helper to keep input values in form after validation failure
     */
    function old(string $key, mixed $default = ''): mixed
    {
        // Assumes you store flashed input data in $_SESSION['_old_input']
        if (isset($_SESSION['_old_input'][$key])) {
            return htmlspecialchars($_SESSION['_old_input'][$key]);
        }
        return $default;
    }
}

if (!function_exists('sanitize')) {
    /**
     * Basic XSS sanitization for string output
     */
    function sanitize(string $value): string
    {
        return htmlspecialchars($value, ENT_QUOTES, 'UTF-8');
    }
}

if (!function_exists('dd')) {
    /**
     * Dump and Die (Debugging helper)
     */
    function dd(mixed $var): void
    {
        echo '<pre>';
        var_dump($var);
        echo '</pre>';
        die();
    }
}

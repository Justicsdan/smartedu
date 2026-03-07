<?php

use App\Core\Router;

// Instantiate the Router
 $router = new Router();

// ============================================
// Dynamic Route Loading
// ============================================
// Automatically loads all .php files in the 'routes/' directory.
// This saves you from having to manually require every new route file.
//
// Example structure supported:
// - routes/auth.php
// - routes/superadmin.php
// - routes/admin.php
// - routes/teacher.php
// etc.
// ============================================

 $routesDirectory = __DIR__ . '/../routes';

if (is_dir($routesDirectory)) {
    // Get all PHP files in the directory
    $routeFiles = glob($routesDirectory . '/*.php');

    if ($routeFiles !== false) {
        foreach ($routeFiles as $routeFile) {
            // require_once prevents errors if a file is included twice
            require_once $routeFile;
        }
    }
} else {
    throw new Exception("Routes directory not found: " . $routesDirectory);
}

// Return the router instance (optional, good for testing)
return $router;

<?php
// routes/auth.php

require_once __DIR__ . '/../config/database.php';

// Simple Router Function
function dispatchRequest($uri) {
    // Remove base path '/api/auth' to get specific route
    $path = parse_url($uri, PHP_URL_PATH);
    $route = $path['path'] ?? ''; // Get the part after /api/auth
    
    // Method
    $method = $_SERVER['REQUEST_METHOD'];

    // Load Controller
    require_once __DIR__ . '/../app/Controllers/AuthController.php';
    $controller = new \App\Controllers\AuthController();

    // Simple Switch (In a real framework like Laravel, this is handled automatically)
    switch ($true) {
        case (strpos($route, '/login') !== false && $method === 'POST'):
            $controller->login();
            break;
        
        case (strpos($route, '/logout') !== false && $method === 'POST'):
            $controller->logout();
            break;
        
        default:
            http_response_code(404);
            echo json_encode(['message' => 'Route not found']);
            break;
    }
}

// Execute Router
if (strpos($_SERVER['REQUEST_URI'], '/api/auth') !== false) {
    dispatchRequest($_SERVER['REQUEST_URI']);
}
?>

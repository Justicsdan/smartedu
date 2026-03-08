<?php

/**
 * Application Configuration
 * Returns an array of application settings
 */

return [
    // ============================================
    // Application Core Settings
    // ============================================
    'app' => [
        'name'        => $_ENV['APP_NAME'] ?? 'SmartEdu',
        'version'     => '1.0.0',
        'description' => 'Modern School Management Platform',
        
        // Environment: 'local', 'staging', or 'production'
        'env'         => $_ENV['APP_ENV'] ?? 'production',
        
        // Debug Mode: Converts string "true"/"false" to actual boolean
        'debug'       => filter_var($_ENV['APP_DEBUG'] ?? false, FILTER_VALIDATE_BOOLEAN),
        
        // Timezone (Matches index.php)
        'timezone'    => $_ENV['APP_TIMEZONE'] ?? 'Africa/Lagos',
    ],

    // ============================================
    // URL Configuration
    // ============================================
    'url' => [
        // Base URL of the application
        'app' => $_ENV['APP_URL'] ?? 'http://localhost',
        
        // Force HTTPS on non-local environments (Security measure)
        'force_https' => ($_ENV['APP_ENV'] ?? 'production') !== 'local',
    ],

    // ============================================
    // File Upload Settings
    // ============================================
    'upload' => [
        'max_size'       => 5 * 1024 * 1024, // 5MB in bytes
        'allowed_types'  => ['image/jpeg', 'image/png', 'image/gif', 'image/webp'],
        'directory'      => 'uploads',
    ],

    // ============================================
    // Security Settings
    // ============================================
    'security' => [
        // Password hashing algorithm (PASSWORD_BCRYPT, PASSWORD_ARGON2I)
        'password_algo' => PASSWORD_DEFAULT,
    ]
];

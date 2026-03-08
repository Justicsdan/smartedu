<?php

/**
 * Database Configuration
 */

return [
    'driver' => 'mysql',

    'host' => env('DB_HOST', '127.0.0.1'),
    'port' => env('DB_PORT', '3306'),
    'database' => env('DB_DATABASE', 'smarted'),
    'username' => env('DB_USERNAME', 'root'),
    'password' => env('DB_PASSWORD', ''),
    
    // Character Set and Collation
    // utf8mb4 supports full unicode (emojis, Asian characters)
    'charset' => 'utf8mb4',
    'collation' => 'utf8mb4_unicode_ci', 

    // Optional Table Prefix (e.g., 'sm_') to avoid table name conflicts
    'prefix' => env('DB_PREFIX', ''),

    // MySQL Strict Mode ensures data integrity (rejects invalid dates)
    'strict' => true,

    // Default Storage Engine
    'engine' => 'InnoDB',

    // PDO Options passed to constructor
    'options' => [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION, // Throw exceptions on SQL errors
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,    // Return arrays by default
        PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci"
    ]
];

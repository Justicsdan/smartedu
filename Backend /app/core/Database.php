<?php

namespace App\Core;

use PDO;
use PDOException;
use Exception;

class Database
{
    private static ?Database $instance = null;
    private PDO $pdo;

    private function __construct()
    {
        try {
            // Load config
            $config = require __DIR__ . '/../../config/database.php';

            // Build DSN with validation
            $host = $config['host'] ?? '127.0.0.1';
            $port = $config['port'] ?? '3306';
            $dbname = $config['database'] ?? null;
            $charset = $config['charset'] ?? 'utf8mb4';

            if (!$dbname) {
                throw new Exception('Database name is required in config.');
            }

            $dsn = "mysql:host={$host};port={$port};dbname={$dbname};charset={$charset}";

            $username = $config['username'] ?? null;
            $password = $config['password'] ?? '';

            if (!$username) {
                throw new Exception('Database username is required.');
            }

            $options = [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES   => false, // Important for security
                PDO::ATTR_STRINGIFY_FETCHES  => false,
                PDO::MYSQL_ATTR_SSL_CA       => $config['ssl_ca'] ?? null, // For secure connections
                PDO::MYSQL_ATTR_SSL_VERIFY_SERVER_CERT => false, // Set true in prod with proper cert
            ];

            $this->pdo = new PDO($dsn, $username, $password, $options);

            // Optional: Test connection
            $this->pdo->query('SELECT 1');

        } catch (PDOException $e) {
            // Log but don't expose details in production
            error_log('Database Connection Failed: ' . $e->getMessage());

            if (getenv('APP_DEBUG') === 'true') {
                throw new Exception('Database connection failed: ' . $e->getMessage());
            }

            throw new Exception('Unable to connect to the database. Please try again later.');
        }
    }

    /**
     * Get the singleton instance
     */
    public static function getInstance(): self
    {
        if (self::$instance === null) {
            self::$instance = new self();
        }

        return self::$instance;
    }

    /**
     * Get the PDO connection
     */
    public function getConnection(): PDO
    {
        return $this->pdo;
    }

    /**
     * Prevent cloning
     */
    private function __clone() {}

    /**
     * Prevent unserialization
     */
    public function __wakeup()
    {
        throw new Exception("Cannot unserialize singleton");
    }

    /**
     * Optional: Close connection on shutdown (not strictly needed in PHP)
     */
    public function close(): void
    {
        $this->pdo = null;
        self::$instance = null;
    }
}

<?php
/**
 * SmartEdu Database Seed Script
 * 
 * Creates the required tables (if missing) and seeds the first Super Admin user.
 * 
 * Usage: php scripts/seed.php
 * 
 * SECURITY: Only executable via CLI
 */

if (php_sapi_name() !== 'cli') {
    http_response_code(403);
    die("Access denied. This script can only be run from the command line.\n");
}

require_once __DIR__ . '/../vendor/autoload.php';

use App\Core\Database;
use App\Models\User;
use App\Models\School;

echo "\n=== SmartEdu Database Seed ===\n\n";

try {
    $pdo = Database::getInstance()->getConnection();

    // 1. Create schools table (required for foreign key in users)
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS schools (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(255) NOT NULL,
            code VARCHAR(50) UNIQUE NOT NULL,
            email VARCHAR(255) NULL,
            phone VARCHAR(20) NULL,
            address TEXT NULL,
            motto TEXT NULL,
            logo_path VARCHAR(255) NULL,
            school_type ENUM('day', 'boarding') DEFAULT 'day',
            grading_scale JSON NULL DEFAULT '{
                \"A+\": [90,100], \"A\": [80,89], \"B\": [70,79],
                \"C\": [60,69], \"D\": [50,59], \"E\": [40,49], \"F\": [0,39]
            }',
            status ENUM('active', 'inactive') DEFAULT 'active',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ");
    echo "[✓] Schools table ready.\n";

    // 2. Create users table
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS users (
            id INT AUTO_INCREMENT PRIMARY KEY,
            school_id INT NULL,
            name VARCHAR(255) NOT NULL,
            email VARCHAR(255) UNIQUE NOT NULL,
            password VARCHAR(255) NOT NULL,
            role ENUM('super_admin', 'admin', 'teacher', 'student', 'parent') NOT NULL DEFAULT 'student',
            profile_photo VARCHAR(255) NULL,
            phone VARCHAR(20) NULL,
            status ENUM('active', 'inactive') DEFAULT 'active',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

            FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE SET NULL,
            INDEX idx_role (role),
            INDEX idx_school_role (school_id, role)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ");
    echo "[✓] Users table ready.\n";

    // 3. Seed Super Admin
    $userModel = new User();
    $existing = $userModel->findByEmail('superadmin@smartedu.com');

    if ($existing) {
        echo "[i] Super Admin already exists: superadmin@smartedu.com\n";
        echo "    No new user created.\n";
    } else {
        $userModel->create([
            'name'       => 'Super Administrator',
            'email'      => 'superadmin@smartedu.com',
            'password'   => password_hash('admin123', PASSWORD_DEFAULT),
            'role'       => 'super_admin',     // matches your enum
            'status'     => 'active'
            // school_id left NULL for super_admin
        ]);

        echo "[✓] Super Admin created successfully!\n";
        echo "    Email: superadmin@smartedu.com\n";
        echo "    Password: admin123\n";
        echo "    ⚠️  CHANGE THIS PASSWORD IMMEDIATELY AFTER FIRST LOGIN!\n";
    }

    echo "\n=== Seed Complete ===\n";
    echo "SmartEdu is ready. Log in as Super Admin and create your first school.\n\n";

} catch (PDOException $e) {
    echo "[✗] Database Error: " . $e->getMessage() . "\n";
    echo "Check your database connection in config/database.php\n";
    exit(1);
} catch (Exception $e) {
    echo "[✗] Error: " . $e->getMessage() . "\n";
    exit(1);
}

<?php

// migrations/2026_01_08_add_branding_to_schools.php

require_once __DIR__ . '/../app/Core/Database.php';

$pdo = \App\Core\Database::getInstance()->getConnection();

try {
    $pdo->exec("
        ALTER TABLE schools
        ADD COLUMN logo_path VARCHAR(255) NULL AFTER code,
        ADD COLUMN motto TEXT NULL AFTER logo_path,
        ADD COLUMN address TEXT NULL AFTER motto,
        ADD COLUMN phone VARCHAR(20) NULL AFTER address,
        ADD COLUMN school_type ENUM('day', 'boarding') DEFAULT 'day' AFTER phone,
        ADD COLUMN grading_scale JSON NULL DEFAULT '{
            \"A+\": [90, 100],
            \"A\": [80, 89],
            \"B\": [70, 79],
            \"C\": [60, 69],
            \"D\": [50, 59],
            \"E\": [40, 49],
            \"F\": [0, 39]
        }' AFTER school_type
    ");

    echo "Migration successful: branding and school_type added to schools table.\n";

} catch (PDOException $e) {
    echo "Migration failed: " . $e->getMessage() . "\n";
}

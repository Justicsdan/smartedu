<?php
// api/upload_school_logo.php

header('Content-Type: application/json');
require_once __DIR__ . '/../vendor/autoload.php';

use App\Core\Auth;
use App\Models\School;
use App\Helpers\upload_file; // Your secure upload helper

// Authenticate user
$currentUser = Auth::user();
if (!$currentUser) {
    http_response_code(401);
    echo json_encode(['error' => 'Unauthorized']);
    exit;
}

// Determine allowed school_id
if ($currentUser['role'] === 'super_admin') {
    $school_id = $_POST['school_id'] ?? null; // Super admin can choose any school
} else {
    $school_id = $currentUser['school_id']; // Regular admin can only edit own school
}

if (!$school_id) {
    http_response_code(400);
    echo json_encode(['error' => 'school_id is required']);
    exit;
}

// Verify access
$schoolModel = new School();
$school = $schoolModel->find($school_id);

if (!$school) {
    http_response_code(404);
    echo json_encode(['error' => 'School not found']);
    exit;
}

if ($currentUser['role'] !== 'super_admin' && $school['id'] != $currentUser['school_id']) {
    http_response_code(403);
    echo json_encode(['error' => 'Forbidden: You can only upload logo for your school']);
    exit;
}

// Check if file was uploaded
if (!isset($_FILES['logo']) || $_FILES['logo']['error'] === UPLOAD_ERR_NO_FILE) {
    http_response_code(400);
    echo json_encode(['error' => 'No logo file uploaded']);
    exit;
}

// Validate and upload
$allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
$upload = upload_file('logo', 'schools/logos', $allowedTypes, 2 * 1024 * 1024); // Max 2MB

if (!$upload['success']) {
    http_response_code(400);
    echo json_encode(['error' => $upload['error'] ?? 'Upload failed']);
    exit;
}

// Delete old logo if exists
if (!empty($school['logo_path']) && file_exists(__DIR__ . '/../public/' . $school['logo_path'])) {
    unlink(__DIR__ . '/../public/' . $school['logo_path']);
}

// Save new path to database
$schoolModel->update($school_id, [
    'logo_path' => $upload['path'] // e.g., /uploads/schools/logos/grace-high.png
]);

echo json_encode([
    'message' => 'Logo uploaded successfully',
    'logo_url' => get_base_url() . $upload['path'],
    'logo_path' => $upload['path']
]);

<?php
// api/register_school.php

header('Content-Type: application/json');
require_once __DIR__ . '/../vendor/autoload.php';

use App\Core\Auth;
use App\Models\School;
use App\Models\User;
use App\Helpers\validator;

$currentUser = Auth::user();

if (!$currentUser || $currentUser['role'] !== 'super_admin') {
    http_response_code(403);
    echo json_encode(['error' => 'Forbidden: Super Admin access required']);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);

if (empty($input)) {
    http_response_code(400);
    echo json_encode(['error' => 'No data provided']);
    exit;
}

// Validation
$rules = [
    'name'         => 'required|max:150',
    'code'         => 'required|max:20',
    'email'        => 'required|email',
    'phone'        => 'max:20',
    'address'      => 'max:255',
    'motto'        => 'max:255',
    'school_type'  => 'in:day,boarding',
    'admin_name'   => 'required|max:100',
    'admin_email'  => 'required|email',
    'admin_password' => 'min:8'
];

if ($errors = validator($input, $rules)) {
    http_response_code(422);
    echo json_encode(['error' => 'Validation failed', 'details' => $errors]);
    exit;
}

// Normalize code
$code = strtoupper(trim(str_replace(' ', '', $input['code'])));

$schoolModel = new School();
if ($schoolModel->findBy('code', $code)) {
    http_response_code(409);
    echo json_encode(['error' => 'School code already exists']);
    exit;
}

// Create school
$schoolId = $schoolModel->create([
    'name'         => $input['name'],
    'code'         => $code,
    'email'        => $input['email'],
    'phone'        => $input['phone'] ?? null,
    'address'      => $input['address'] ?? null,
    'motto'        => $input['motto'] ?? null,
    'school_type'  => $input['school_type'] ?? 'day',
    'logo_path'    => null, // Will be uploaded later
    'grading_scale'=> $input['grading_scale'] ?? null,
    'status'       => 'active'
]);

// Create first school admin
$userModel = new User();
$userModel->create([
    'name'       => $input['admin_name'],
    'email'      => $input['admin_email'],
    'password'   => password_hash($input['admin_password'], PASSWORD_DEFAULT),
    'role'       => 'admin',
    'school_id'  => $schoolId,
    'status'     => 'active'
]);

echo json_encode([
    'message'   => 'School registered successfully',
    'school_id' => $schoolId,
    'admin_credentials' => [
        'email'    => $input['admin_email'],
        'password' => $input['admin_password'] // Send only once!
    ]
]);

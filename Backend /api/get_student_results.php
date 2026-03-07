<?php
// api/get_student_results.php

header('Content-Type: application/json');
require_once __DIR__ . '/../vendor/autoload.php';

use App\Core\Auth;
use App\Models\Result;
use App\Models\School;
use App\Models\User;

$currentUser = Auth::user();
if (!$currentUser) {
    http_response_code(401);
    echo json_encode(['error' => 'Unauthorized']);
    exit;
}

$student_id = $_GET['student_id'] ?? null;
$academic_year = $_GET['year'] ?? null;

if (!$student_id) {
    http_response_code(400);
    echo json_encode(['error' => 'student_id required']);
    exit;
}

// Access check (student own, teacher/admin of school, parent later)
$student = (new User())->find($student_id);
if (!$student) {
    http_response_code(404);
    echo json_encode(['error' => 'Student not found']);
    exit;
}

// Simple access: same school or own
if ($currentUser['role'] !== 'super_admin' &&
    $student['school_id'] != ($currentUser['school_id'] ?? null) &&
    $currentUser['user_id'] != $student_id) {
    http_response_code(403);
    echo json_encode(['error' => 'Access denied']);
    exit;
}

// Get report + branding
$resultModel = new Result();
$report = $resultModel->generateReportCard($student_id, $academic_year);

$schoolModel = new School();
$branding = $schoolModel->getBranding($student['school_id']);

echo json_encode([
    'student' => [
        'name'  => $student['name'],
        'id'    => $student['id']
    ],
    'school' => $branding,
    'report' => $report
]);

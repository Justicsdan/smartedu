<?php
// api/get_class_students.php

header('Content-Type: application/json');
require_once __DIR__ . '/../vendor/autoload.php';

use App\Core\Auth;
use App\Models\Enrollment;

$currentUser = Auth::user();
if (!$currentUser) {
    http_response_code(401);
    echo json_encode(['error' => 'Unauthorized']);
    exit;
}

$class_subject_id = $_GET['class_subject_id'] ?? null;
if (!$class_subject_id) {
    http_response_code(400);
    echo json_encode(['error' => 'class_subject_id required']);
    exit;
}

$enrollmentModel = new Enrollment();
$students = $enrollmentModel->getStudentsByClassSubjectPaginated($class_subject_id);

echo json_encode([
    'students' => $students
]);

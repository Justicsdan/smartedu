<?php
// api/mark_attendance.php

header('Content-Type: application/json');
require_once __DIR__ . '/../vendor/autoload.php';

use App\Core\Auth;
use App\Models\Attendance;
use App\Models\ClassModel;
use App\Models\Enrollment;

$currentUser = Auth::user();
if (!$currentUser || !in_array($currentUser['role'], ['teacher', 'admin'])) {
    http_response_code(403);
    echo json_encode(['error' => 'Unauthorized']);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);

if (empty($input['class_id']) || empty($input['date']) || empty($input['attendance'])) {
    http_response_code(400);
    echo json_encode(['error' => 'Missing required fields']);
    exit;
}

$class_id = $input['class_id'];
$date = $input['date']; // YYYY-MM-DD
$attendanceList = $input['attendance']; // [{enrollment_id: 123, status: 'present', remarks: '...'}]

// Verify teacher can mark this class
$classModel = new ClassModel();
$class = $classModel->find($class_id);

if (!$class) {
    http_response_code(404);
    echo json_encode(['error' => 'Class not found']);
    exit;
}

$isFormTeacher = $class['teacher_id'] == $currentUser['user_id'];
$isAdmin = $currentUser['role'] === 'admin';
$isSuperAdmin = $currentUser['role'] === 'super_admin';

if (!$isSuperAdmin && !$isAdmin && !$isFormTeacher) {
    http_response_code(403);
    echo json_encode(['error' => 'You are not authorized to mark attendance for this class']);
    exit;
}

// Validate all enrollment_ids belong to this class
$enrollmentModel = new Enrollment();
$validEnrollments = array_column($enrollmentModel->getByClass($class_id), 'id');

$records = [];
foreach ($attendanceList as $item) {
    if (!in_array($item['enrollment_id'], $validEnrollments)) {
        continue; // Skip invalid
    }

    $records[] = [
        'enrollment_id' => $item['enrollment_id'],
        'date'          => $date,
        'status'        => $item['status'] ?? 'present',
        'remarks'       => $item['remarks'] ?? null,
        'marked_by'     => $currentUser['user_id']
    ];
}

$attendanceModel = new Attendance();
$result = $attendanceModel->markBulk($records);

echo json_encode([
    'message' => 'Attendance marked successfully',
    'saved'   => $result['saved'],
    'failed'  => $result['failed']
]);

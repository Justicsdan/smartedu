<?php
// api/get_attendance.php

header('Content-Type: application/json');
require_once __DIR__ . '/../vendor/autoload.php';

use App\Core\Auth;
use App\Models\Attendance;

$currentUser = Auth::user();
if (!$currentUser) {
    http_response_code(401);
    echo json_encode(['error' => 'Unauthorized']);
    exit;
}

$class_id = $_GET['class_id'] ?? null;
$date = $_GET['date'] ?? date('Y-m-d');

if (!$class_id) {
    http_response_code(400);
    echo json_encode(['error' => 'class_id required']);
    exit;
}

$attendanceModel = new Attendance();
$records = $attendanceModel->getByClassAndDate($class_id, $date);

echo json_encode([
    'date' => $date,
    'attendance' => $records
]);

<?php
// api/get_dashboard_stats.php

header('Content-Type: application/json');
require_once __DIR__ . '/../vendor/autoload.php';

use App\Core\Auth;
use App\Models\School;
use App\Models\User;
use App\Models\ClassModel;

$currentUser = Auth::user();
if (!$currentUser) {
    http_response_code(401);
    echo json_encode(['error' => 'Unauthorized']);
    exit;
}

$role = $currentUser['role'];
$stats = [];

if ($role === 'super_admin') {
    $schoolModel = new School();
    $stats = [
        'total_schools' => $schoolModel->countAll(),
        'active_schools' => $schoolModel->countByStatus('active')
    ];
} elseif ($role === 'admin') {
    $stats = [
        'total_teachers' => (new User())->countByRoleAndSchool('teacher', $currentUser['school_id']),
        'total_students' => (new User())->countByRoleAndSchool('student', $currentUser['school_id']),
        'total_classes' => (new ClassModel())->countBySchool($currentUser['school_id'])
    ];
} elseif ($role === 'teacher') {
    $stats = [
        'classes_taught' => (new ClassSubject())->countByTeacher($currentUser['user_id']),
        'total_students' => (new Enrollment())->countStudentsTaughtByTeacher($currentUser['user_id'])
    ];
}

echo json_encode(['stats' => $stats]);

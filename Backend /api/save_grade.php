<?php

header('Content-Type: application/json');
require_once __DIR__ . '/../../vendor/autoload.php'; // Adjust path if needed

use App\Core\Auth;
use App\Models\Result;
use App\Models\ClassSubject;
use App\Models\School;
use App\Helpers\validator;

// Authenticate and get current user
$userPayload = Auth::user();
if (!$userPayload || $userPayload['role'] !== 'teacher') {
    http_response_code(401);
    echo json_encode(['error' => 'Unauthorized access']);
    exit;
}

$teacher_id = $userPayload['user_id'];
$school_id = $userPayload['school_id'] ?? null;

if (!$school_id) {
    http_response_code(400);
    echo json_encode(['error' => 'School context missing']);
    exit;
}

// Read JSON input
$input = json_decode(file_get_contents('php://input'), true);

if (!is_array($input) || empty($input)) {
    http_response_code(400);
    echo json_encode(['error' => 'Invalid or empty data']);
    exit;
}

// Validation rules (customizable per school later)
$rules = [
    'class_subject_id' => 'required|integer',
    'exam_name'        => 'required|max:50',
    'academic_year'    => 'required|max:20',
    'scores'           => 'required|array',
    'scores.*.student_id' => 'required|integer',
    'scores.*.ca1'         => 'numeric|min:0',
    'scores.*.ca2'         => 'numeric|min:0',
    'scores.*.exam'        => 'required|numeric|min:0',
    // Add more components like project, test, etc. if needed
];

if ($errors = validator($input, $rules)) {
    http_response_code(422);
    echo json_encode(['error' => 'Validation failed', 'details' => $errors]);
    exit;
}

$class_subject_id = $input['class_subject_id'];
$exam_name        = $input['exam_name'];
$academic_year    = $input['academic_year'];
$scores           = $input['scores'];

// Security: Verify teacher is assigned to this class-subject
$csModel = new ClassSubject();
$assignment = $csModel->find($class_subject_id);

if (!$assignment || $assignment['teacher_id'] != $teacher_id) {
    http_response_code(403);
    echo json_encode(['error' => 'You are not assigned to teach this subject']);
    exit;
}

// Get school-specific score weights and grading scale
$schoolModel = new School();
$school = $schoolModel->find($school_id);

$gradingScale = json_decode($school['grading_scale'] ?? '', true) ?: [
    'A+' => [90,100], 'A' => [80,89], 'B' => [70,79],
    'C' => [60,69], 'D' => [50,59], 'E' => [40,49], 'F' => [0,39]
];

// Default weights (can be made customizable later)
$weights = [
    'ca1'  => 30,
    'ca2'  => 20,
    'exam' => 50
];
$totalPossible = array_sum($weights);

$resultModel = new Result();

$saved = 0;
$failed = [];

foreach ($scores as $score) {
    $student_id = $score['student_id'];
    $ca1 = $score['ca1'] ?? 0;
    $ca2 = $score['ca2'] ?? 0;
    $exam = $score['exam'] ?? 0;

    // Calculate total
    $total_obtained = ($ca1 / $weights['ca1'] * 30) + ($ca2 / $weights['ca2'] * 20) + ($exam / $weights['exam'] * 50);
    $total_obtained = round($total_obtained, 2);

    // Calculate percentage
    $percentage = $totalPossible > 0 ? round(($total_obtained / $totalPossible) * 100, 2) : 0;

    // Determine grade using school-specific scale
    $grade = 'F';
    foreach ($gradingScale as $g => $range) {
        if ($percentage >= $range[0] && $percentage <= $range[1]) {
            $grade = $g;
            break;
        }
    }

    try {
        $resultModel->upsertResult(
            $student_id,
            $class_subject_id,
            $exam_name,
            $total_obtained,
            $academic_year
        );

        // Optional: Update individual components if you have separate columns
        // Or store as JSON in remarks

        $saved++;
    } catch (\Exception $e) {
        $failed[] = [
            'student_id' => $student_id,
            'error'      => $e->getMessage()
        ];
    }
}

echo json_encode([
    'message'       => 'Grade entry completed',
    'saved_count'   => $saved,
    'failed_count'  => count($failed),
    'failed'        => $failed,
    'summary'       => [
        'exam_name'     => $exam_name,
        'total_possible'=> $totalPossible,
        'grading_used'  => $gradingScale
    ]
]);

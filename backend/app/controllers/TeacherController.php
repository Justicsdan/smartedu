<?php

namespace App\Controllers;

use App\Core\Controller;
use App\Models\ClassModel;
use App\Models\ClassSubject;
use App\Models\Enrollment;
use App\Models\Result;
use App\Models\User;
use App\Helpers\validator;

class TeacherController extends Controller
{
    private $classModel;
    private $classSubjectModel;
    private $enrollmentModel;
    private $resultModel;

    private $currentUser;
    private $teacher_id;
    private $school_id;

    public function __construct()
    {
        $this->currentUser = $_SERVER['user'] ?? null;

        if (!$this->currentUser) {
            $this->error('Unauthorized', 401);
            exit;
        }

        // Enforce teacher role only
        if ($this->currentUser['role'] !== 'teacher') {
            $this->error('Access denied: Teacher role required', 403);
            exit;
        }

        $this->teacher_id = $this->currentUser['user_id'];
        $this->school_id  = $this->currentUser['school_id'] ?? null;

        if (!$this->school_id) {
            $this->error('School context missing', 400);
            exit;
        }

        $this->classModel         = new ClassModel();
        $this->classSubjectModel  = new ClassSubject();
        $this->enrollmentModel    = new Enrollment();
        $this->resultModel        = new Result();
    }

    /**
     * Get all classes and subjects assigned to this teacher
     */
    public function myClasses()
    {
        $assignments = $this->classSubjectModel->getByTeacherWithDetails($this->teacher_id);

        if (empty($assignments)) {
            return $this->json([
                'message' => 'No classes or subjects assigned yet',
                'data'    => []
            ]);
        }

        // Group by class for better frontend structure
        $grouped = [];
        foreach ($assignments as $assign) {
            $classId = $assign['class_id'];
            if (!isset($grouped[$classId])) {
                $grouped[$classId] = [
                    'class_id'      => $assign['class_id'],
                    'class_name'    => $assign['class_name'],
                    'level_year'    => $assign['level_year'],
                    'section'       => $assign['section'] ?? 'A',
                    'total_students' => $assign['student_count'],
                    'subjects'      => []
                ];
            }

            $grouped[$classId]['subjects'][] = [
                'class_subject_id' => $assign['class_subject_id'],
                'subject_id'       => $assign['subject_id'],
                'subject_name'     => $assign['subject_name'],
                'subject_code'     => $assign['subject_code']
            ];
        }

        return $this->json([
            'message' => 'Assigned classes retrieved successfully',
            'classes' => array_values($grouped)
        ]);
    }

    /**
     * Get list of students for a specific class-subject (that teacher is assigned to)
     */
    public function getStudents($class_subject_id)
    {
        // Verify teacher is assigned to this class-subject
        if (!$this->isTeacherAssignedToClassSubject($class_subject_id)) {
            return $this->error('You are not assigned to teach this subject/class', 403);
        }

        $page = max(1, (int)($_GET['page'] ?? 1));
        $limit = min(50, (int)($_GET['limit'] ?? 30));
        $offset = ($page - 1) * $limit;

        $students = $this->enrollmentModel->getStudentsByClassSubjectPaginated(
            $class_subject_id,
            $limit,
            $offset
        );

        $total = $this->enrollmentModel->countStudentsByClassSubject($class_subject_id);

        return $this->json([
            'data' => $students,
            'summary' => [
                'total_students' => $total,
                'class_subject_id' => $class_subject_id
            ],
            'pagination' => [
                'page'   => $page,
                'limit'  => $limit,
                'total'  => $total,
                'pages'  => ceil($total / $limit)
            ]
        ]);
    }

    /**
     * Enter or update results for students in a class-subject-exam
     */
    public function saveResults()
    {
        $input = json_decode(file_get_contents('php://input'), true);

        if (empty($input['class_subject_id'])) {
            return $this->error('class_subject_id is required', 400);
        }

        $class_subject_id = $input['class_subject_id'];

        // Critical: Verify teacher owns this class-subject
        if (!$this->isTeacherAssignedToClassSubject($class_subject_id)) {
            return $this->error('You are not authorized to enter results for this subject', 403);
        }

        if (empty($input['exam_name'])) {
            return $this->error('exam_name is required', 400);
        }

        if (empty($input['results']) || !is_array($input['results'])) {
            return $this->error('Results array is required and must contain student data', 422);
        }

        $exam_name     = $input['exam_name'];
        $academic_year = $input['academic_year'] ?? date('Y');
        $exam_date     = $input['exam_date'] ?? date('Y-m-d');
        $total_marks   = $input['total_marks'] ?? 100;

        $rules = [
            '*.enrollment_id'   => 'required|integer',
            '*.marks_obtained'  => 'required|numeric|min:0|max:' . $total_marks,
            '*.grade'           => 'max:10',
            '*.remarks'         => 'max:255'
        ];

        if ($errors = validator($input['results'], $rules, true)) {
            return $this->error(['errors' => $errors], 422);
        }

        $saved = [];
        $updated = [];
        $failed = [];

        foreach ($input['results'] as $res) {
            $enrollment_id = $res['enrollment_id'];

            // Extra security: ensure enrollment belongs to this class_subject
            if (!$this->enrollmentBelongsToClassSubject($enrollment_id, $class_subject_id)) {
                $failed[] = ['enrollment_id' => $enrollment_id, 'error' => 'Student not in this class'];
                continue;
            }

            $data = [
                'enrollment_id'    => $enrollment_id,
                'class_subject_id' => $class_subject_id,
                'exam_name'        => $exam_name,
                'marks_obtained'   => $res['marks_obtained'],
                'total_marks'      => $total_marks,
                'grade'            => $res['grade'] ?? $this->calculateGrade($res['marks_obtained'], $total_marks),
                'remarks'          => $res['remarks'] ?? null,
                'academic_year'    => $academic_year,
                'exam_date'        => $exam_date
            ];

            // Check if result already exists
            $existing = $this->resultModel->findByUnique(
                $enrollment_id,
                $class_subject_id,
                $exam_name,
                $academic_year
            );

            if ($existing) {
                $this->resultModel->update($existing['id'], $data);
                $updated[] = $existing['id'];
            } else {
                $newId = $this->resultModel->create($data);
                $saved[] = $newId;
            }
        }

        return $this->json([
            'message' => 'Results processed successfully',
            'summary' => [
                'new_results'   => count($saved),
                'updated_results' => count($updated),
                'failed'        => count($failed)
            ],
            'saved_ids'   => $saved,
            'updated_ids' => $updated,
            'failed'      => $failed
        ]);
    }

    /**
     * Get existing results for a class-subject and exam (for editing)
     */
    public function getResults($class_subject_id)
    {
        if (!$this->isTeacherAssignedToClassSubject($class_subject_id)) {
            return $this->error('Unauthorized access to this class-subject', 403);
        }

        $exam_name = $_GET['exam'] ?? null;
        if (!$exam_name) {
            return $this->error('exam parameter is required', 400);
        }

        $results = $this->resultModel->getByClassSubjectAndExam($class_subject_id, $exam_name);

        return $this->json([
            'exam_name'        => $exam_name,
            'class_subject_id' => $class_subject_id,
            'results'          => $results
        ]);
    }

    /**
     * Teacher dashboard summary
     */
    public function dashboard()
    {
        $totalClasses = $this->classSubjectModel->countDistinctClassesByTeacher($this->teacher_id);
        $totalSubjects = $this->classSubjectModel->countByTeacher($this->teacher_id);
        $totalStudents = $this->enrollmentModel->countStudentsTaughtByTeacher($this->teacher_id);

        return $this->json([
            'message' => 'Teacher dashboard',
            'stats' => [
                'classes_taught'    => $totalClasses,
                'subjects_taught'   => $totalSubjects,
                'total_students'    => $totalStudents
            ],
            'recent_classes' => $this->classSubjectModel->getRecentByTeacher($this->teacher_id, 5)
        ]);
    }

    // ========================
    // Security & Helper Methods
    // ========================

    private function isTeacherAssignedToClassSubject(int $class_subject_id): bool
    {
        $assignment = $this->classSubjectModel->find($class_subject_id);
        if (!$assignment) return false;

        $class = $this->classModel->find($assignment['class_id']);
        if (!$class || $class['school_id'] != $this->school_id) return false;

        return $assignment['teacher_id'] == $this->teacher_id;
    }

    private function enrollmentBelongsToClassSubject(int $enrollment_id, int $class_subject_id): bool
    {
        $enrollment = $this->enrollmentModel->find($enrollment_id);
        if (!$enrollment) return false;

        $cs = $this->classSubjectModel->find($class_subject_id);
        return $cs && $enrollment['class_id'] == $cs['class_id'];
    }

    private function calculateGrade(float $obtained, int $total): string
    {
        $percentage = ($obtained / $total) * 100;

        if ($percentage >= 90) return 'A+';
        if ($percentage >= 80) return 'A';
        if ($percentage >= 70) return 'B';
        if ($percentage >= 60) return 'C';
        if ($percentage >= 50) return 'D';
        if ($percentage >= 40) return 'E';
        return 'F';
    }
}

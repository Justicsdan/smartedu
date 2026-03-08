<?php

namespace App\Controllers;

use App\Core\Controller;
use App\Models\Enrollment;
use App\Models\Result;
use App\Models\ClassModel;
use App\Models\ClassSubject;
use App\Models\User;

class StudentController extends Controller
{
    private $enrollmentModel;
    private $resultModel;
    private $currentUser;
    private $student_id;
    private $school_id;

    public function __construct()
    {
        $this->currentUser = $_SERVER['user'] ?? null;

        if (!$this->currentUser) {
            $this->error('Unauthorized', 401);
            exit;
        }

        // Strictly enforce: only students can access this controller
        if ($this->currentUser['role'] !== 'student') {
            $this->error('Access denied: Student role required', 403);
            exit;
        }

        $this->student_id = $this->currentUser['user_id'];
        $this->school_id  = $this->currentUser['school_id'] ?? null;

        $this->enrollmentModel = new Enrollment();
        $this->resultModel     = new Result();
    }

    /**
     * Get student's current active enrollment (class, section, subjects)
     */
    public function myClass()
    {
        $enrollment = $this->enrollmentModel->getCurrentByStudent($this->student_id);

        if (!$enrollment) {
            return $this->error('You are not currently enrolled in any class', 404);
        }

        // Enrich with class and section details
        $classModel = new ClassModel();
        $class = $classModel->find($enrollment['class_id']);

        if (!$class || $class['school_id'] != $this->school_id) {
            return $this->error('Class information not available', 404);
        }

        // Get assigned subjects for this class
        $csModel = new ClassSubject();
        $subjects = $csModel->getSubjectsWithTeachersByClass($enrollment['class_id']);

        $response = [
            'enrollment_id' => $enrollment['id'],
            'academic_year' => $enrollment['academic_year'],
            'class' => [
                'id'         => $class['id'],
                'name'       => $class['name'],
                'level_year' => $class['level_year'],
                'section'    => $class['section'] ?? 'A'
            ],
            'subjects' => $subjects, // includes subject name, code, teacher name
            'enrolled_at' => $enrollment['created_at']
        ];

        return $this->json([
            'message' => 'Current class retrieved successfully',
            'data'    => $response
        ]);
    }

    /**
     * Get all results for the student across all years/exams
     */
    public function myResults()
    {
        $page = max(1, (int)($_GET['page'] ?? 1));
        $limit = min(50, (int)($_GET['limit'] ?? 20));
        $offset = ($page - 1) * $limit;

        $results = $this->resultModel->getByStudentPaginated(
            $this->student_id,
            $limit,
            $offset
        );

        $total = $this->resultModel->countByStudent($this->student_id);

        return $this->json([
            'data' => $results,
            'summary' => [
                'total_results' => $total,
                'subjects_covered' => $this->resultModel->countDistinctSubjectsByStudent($this->student_id)
            ],
            'pagination' => [
                'page'  => $page,
                'limit' => $limit,
                'total' => $total,
                'pages' => ceil($total / $limit)
            ]
        ]);
    }

    /**
     * Get results filtered by exam name (e.g., "First Term", "Mid Term Exam")
     */
    public function myResultsByExam($exam_name = null)
    {
        $exam = $exam_name ?: $_GET['exam'] ?? null;

        if (!$exam) {
            return $this->error('Exam name is required', 400);
        }

        $results = $this->resultModel->getByStudentAndExam($this->student_id, $exam);

        if (empty($results)) {
            return $this->error("No results found for exam: {$exam}", 404);
        }

        // Calculate performance summary for this exam
        $totalScore = 0;
        $subjectCount = count($results);

        foreach ($results as $res) {
            $totalScore += $res['score'] ?? 0;
        }

        $average = $subjectCount > 0 ? round($totalScore / $subjectCount, 2) : 0;
        $grade = $this->scoreToGrade($average);

        return $this->json([
            'exam' => $exam,
            'results' => $results,
            'summary' => [
                'total_subjects' => $subjectCount,
                'average_score'  => $average,
                'grade'          => $grade,
                'remark'         => $this->gradeToRemark($grade)
            ]
        ]);
    }

    /**
     * Get full report card for a specific academic year
     */
    public function myReportCard($academic_year = null)
    {
        $year = $academic_year ?: $_GET['year'] ?? date('Y');

        $report = $this->resultModel->generateReportCard($this->student_id, $year);

        if (!$report || empty($report['subjects'])) {
            return $this->error("No results found for academic year {$year}", 404);
        }

        // Add overall performance
        $overall = $this->calculateOverallGrade($report['subjects']);
        $report['overall'] = $overall;

        // Optional: Class position (if implemented in model)
        $position = $this->resultModel->getStudentPositionInClass($this->student_id, $year);
        if ($position) {
            $report['class_position'] = $position;
        }

        // Add student info
        $userModel = new User();
        $student = $userModel->find($this->student_id);

        return $this->json([
            'message'       => 'Report card generated successfully',
            'academic_year' => $year,
            'student'       => [
                'id'    => $student['id'],
                'name'  => $student['name'],
                'email' => $student['email']
            ],
            'report'        => $report
        ]);
    }

    /**
     * Get list of all academic years the student has results for
     */
    public function myAcademicYears()
    {
        $years = $this->resultModel->getAcademicYearsByStudent($this->student_id);

        return $this->json([
            'academic_years' => $years,
            'current_year'   => date('Y')
        ]);
    }

    // ========================
    // Helper Methods
    // ========================

    private function calculateOverallGrade(array $subjects): array
    {
        $total = 0;
        $count = count($subjects);

        foreach ($subjects as $sub) {
            $total += $sub['average'] ?? $sub['score'] ?? 0;
        }

        $average = $count > 0 ? round($total / $count, 2) : 0;
        $grade = $this->scoreToGrade($average);

        return [
            'average_score' => $average,
            'grade'         => $grade,
            'remark'        => $this->gradeToRemark($grade)
        ];
    }

    private function scoreToGrade(float $score): string
    {
        if ($score >= 90) return 'A+';
        if ($score >= 80) return 'A';
        if ($score >= 70) return 'B';
        if ($score >= 60) return 'C';
        if ($score >= 50) return 'D';
        if ($score >= 40) return 'E';
        return 'F';
    }

    private function gradeToRemark(string $grade): string
    {
        return match ($grade) {
            'A+', 'A' => 'Outstanding Performance',
            'B'       => 'Good Performance',
            'C'       => 'Credit Pass',
            'D'       => 'Average',
            'E'       => 'Below Average',
            'F'       => 'Fail',
            default   => 'No Grade'
        };
    }
}

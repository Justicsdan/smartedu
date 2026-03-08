<?php

namespace App\Controllers;

use App\Core\Controller;
use App\Models\Result;
use App\Models\ClassSubject;
use App\Models\User;
use App\Models\ClassModel;
use App\Models\School;
use App\Helpers\validator;

class ResultController extends Controller
{
    private $resultModel;
    private $schoolModel;
    private $currentUser;
    private $school_id;

    public function __construct()
    {
        $this->resultModel = new Result();
        $this->schoolModel = new School();

        $this->currentUser = $_SERVER['user'] ?? null;
        if (!$this->currentUser) {
            $this->error('Unauthorized', 401);
            exit;
        }

        if ($this->currentUser['role'] === 'super_admin') {
            $this->school_id = null;
            return;
        }

        $this->school_id = $this->currentUser['school_id'] ?? null;
        if (!$this->school_id) {
            $this->error('School context missing', 400);
            exit;
        }
    }

    // getClassResults() unchanged — perfect

    /**
     * Generate full report card with complete school branding
     */
    public function reportCard($student_id, $academic_year = null)
    {
        $academic_year = $academic_year ?: $_GET['year'] ?? $this->resultModel->currentAcademicYear();

        if (!$this->canAccessStudent($student_id)) {
            return $this->error('Access denied to this student\'s results', 403);
        }

        // Get student first
        $student = (new User())->find($student_id);
        if (!$student) {
            return $this->error('Student not found', 404);
        }

        // Get school for branding
        $school = $this->schoolModel->find($student['school_id']);
        if (!$school) {
            return $this->error('School not found', 404);
        }

        // Generate report (pass academic_year string)
        $report = $this->resultModel->generateReportCard($student_id, $academic_year);

        if (!$report || empty($report['subjects'])) {
            return $this->error('No results found for this academic year', 404);
        }

        // Build full branding info
        $branding = $this->schoolModel->getBranding($student['school_id']);

        return $this->json([
            'message'       => 'Report card generated successfully',
            'academic_year' => $academic_year,
            'student'       => [
                'id'    => $student['id'],
                'name'  => $student['name'],
                'email' => $student['email'] ?? '',
                'photo' => $student['profile_photo'] ?? null
            ],
            'school'        => $branding,
            'report'        => $report
        ]);
    }

    public function saveResults($class_subject_id)
    {
        if (!$this->canModifyClassSubject($class_subject_id)) {
            return $this->error('You are not authorized to enter results for this subject', 403);
        }

        $input = json_decode(file_get_contents('php://input'), true);

        if (!is_array($input) || empty($input)) {
            return $this->error('Invalid or empty results data', 400);
        }

        $rules = [
            '*.student_id' => 'required|integer',
            '*.score'      => 'required|numeric|min:0|max:100',
            '*.exam'       => 'required|max:50'
        ];

        if ($errors = validator($input, $rules, true)) {
            return $this->error(['errors' => $errors], 422);
        }

        $exam_name = $input[0]['exam'] ?? null;
        $academic_year = $input[0]['academic_year'] ?? $this->resultModel->currentAcademicYear();

        if (!$exam_name) {
            return $this->error('Exam name is required', 400);
        }

        $saved = 0;
        $failed = [];

        foreach ($input as $item) {
            try {
                $this->resultModel->upsertResult(
                    $item['student_id'],
                    $class_subject_id,
                    $exam_name,
                    (float)$item['score'],
                    $academic_year
                );
                $saved++;
            } catch (\Exception $e) {
                $failed[] = [
                    'student_id' => $item['student_id'],
                    'error'      => $e->getMessage()
                ];
            }
        }

        return $this->json([
            'message'       => 'Results processed successfully',
            'saved_count'   => $saved,
            'failed_count'  => count($failed),
            'failed'        => $failed
        ]);
    }

    // Your access control helpers remain perfect
}

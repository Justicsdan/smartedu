<?php

namespace App\Models;

use App\Core\Model;
use PDO;

/**
 * Represents an individual exam result for a student in a specific subject.
 *
 * Links to enrollment and class_subject to provide full context.
 * Central to report card generation, teacher result entry, and student performance tracking.
 *
 * @property int         $id
 * @property int         $enrollment_id         Foreign key to enrollments table
 * @property int         $class_subject_id      Foreign key to class_subjects table
 * @property string      $exam_name             e.g., "First Term", "Mid Term Exam"
 * @property float       $marks_obtained
 * @property int         $total_marks           Usually 100, but can vary
 * @property string      $grade                 e.g., "A", "B+", "F"
 * @property string|null $remarks               Teacher comments
 * @property string      $academic_year         Format: "2025-2026"
 * @property string|null $exam_date             Date of the exam
 * @property string      $created_at
 * @property string      $updated_at
 */
class Result extends Model
{
    protected string $table = 'results';
    protected string $primaryKey = 'id';

    /**
     * Get all results for a student in a specific academic year.
     *
     * Includes subject name, code, class, teacher, and exam details.
     *
     * @param int         $student_id     The student ID
     * @param string|null $academic_year  Optional — defaults to current academic year (e.g., "2025-2026")
     *
     * @return array List of results with enriched subject/class/teacher data
     */
    public function getByStudent(int $student_id, ?string $academic_year = null): array
    {
        $academic_year = $academic_year ?? $this->currentAcademicYear();

        $sql = "
            SELECT 
                r.*,
                s.name AS subject_name,
                s.code AS subject_code,
                c.name AS class_name,
                c.level_year,
                c.section,
                u.name AS teacher_name
            FROM {$this->table} r
            JOIN enrollments e ON r.enrollment_id = e.id
            JOIN class_subjects cs ON r.class_subject_id = cs.id
            JOIN subjects s ON cs.subject_id = s.id
            JOIN classes c ON cs.class_id = c.id
            LEFT JOIN users u ON cs.teacher_id = u.id
            WHERE e.student_id = :student_id
              AND r.academic_year = :academic_year
            ORDER BY r.exam_name ASC, s.name ASC
        ";

        $stmt = $this->pdo->prepare($sql);
        $stmt->execute([
            ':student_id'    => $student_id,
            ':academic_year' => $academic_year
        ]);

        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    /**
     * Generate a comprehensive report card for a student.
     *
     * Calculates per-subject and overall averages, grades, percentages, and remarks.
     * Groups results by subject and exam.
     *
     * @param int         $student_id     The student ID
     * @param string|null $academic_year  Optional — defaults to current academic year
     *
     * @return array Structured report card with subjects, exams, averages, overall performance
     */
    public function generateReportCard(int $student_id, ?string $academic_year = null): array
    {
        $academic_year = $academic_year ?? $this->currentAcademicYear();
        $rawResults = $this->getByStudent($student_id, $academic_year);

        if (empty($rawResults)) {
            return [
                'student_id'    => $student_id,
                'academic_year' => $academic_year,
                'message'       => 'No results found for this academic year'
            ];
        }

        // Get school for custom grading
        $enrollment = (new \App\Models\Enrollment())->getCurrentByStudent($student_id, $academic_year);
        $school_id = null;
        if ($enrollment) {
            $class = (new \App\Models\ClassModel())->find($enrollment['class_id']);
            $school_id = $class['school_id'] ?? null;
        }

        $schoolModel = new \App\Models\School();
        $gradingScale = $schoolModel->getGradingScale($school_id);

        $report = [
            'student_id'     => $student_id,
            'academic_year'  => $academic_year,
            'subjects'       => [],
            'total_obtained' => 0,
            'total_possible' => 0,
            'overall_average' => 0,
            'overall_grade'   => '',
            'remark'          => ''
        ];

        $subjectData = [];

        foreach ($rawResults as $res) {
            $subject = $res['subject_name'];

            if (!isset($subjectData[$subject])) {
                $subjectData[$subject] = [
                    'subject_code'  => $res['subject_code'],
                    'teacher_name'  => $res['teacher_name'],
                    'class_name'    => $res['class_name'],
                    'exams'         => [],
                    'total_obtained'=> 0,
                    'total_possible'=> 0
                ];
            }

            $percentage = $res['total_marks'] > 0 
                ? round(($res['marks_obtained'] / $res['total_marks']) * 100, 2) 
                : 0;

            $grade = $this->calculateGradeFromScale($percentage, $gradingScale);

            $subjectData[$subject]['exams'][] = [
                'exam_name'     => $res['exam_name'],
                'marks_obtained'=> (float)$res['marks_obtained'],
                'total_marks'   => (int)$res['total_marks'],
                'percentage'    => $percentage,
                'grade'         => $grade
            ];

            $subjectData[$subject]['total_obtained'] += $res['marks_obtained'];
            $subjectData[$subject]['total_possible'] += $res['total_marks'];

            $report['total_obtained'] += $res['marks_obtained'];
            $report['total_possible'] += $res['total_marks'];
        }

        // Calculate subject averages
        foreach ($subjectData as $name => $data) {
            $avg = $data['total_possible'] > 0 
                ? round(($data['total_obtained'] / $data['total_possible']) * 100, 2) 
                : 0;

            $report['subjects'][$name] = array_merge($data, [
                'average_percentage' => $avg,
                'average_grade'      => $this->calculateGradeFromScale($avg, $gradingScale)
            ]);
        }

        // Overall
        if ($report['total_possible'] > 0) {
            $report['overall_average'] = round(($report['total_obtained'] / $report['total_possible']) * 100, 2);
            $report['overall_grade'] = $this->calculateGradeFromScale($report['overall_average'], $gradingScale);
            $report['remark'] = $this->getRemark($report['overall_grade']);
        }

        return $report;
    }

    /**
     * Safely upsert (insert or update) a single result.
     *
     * Used primarily by teachers during result entry.
     *
     * @param int         $student_id       The student ID
     * @param int         $class_subject_id The class-subject assignment ID
     * @param string      $exam_name        Name of the exam
     * @param float       $marks_obtained   Score achieved
     * @param string|null $academic_year    Optional — defaults to current
     *
     * @return int The result record ID (new or existing)
     *
     * @throws \Exception If student not enrolled
     */
    public function upsertResult(
        int $student_id,
        int $class_subject_id,
        string $exam_name,
        float $marks_obtained,
        ?string $academic_year = null
    ): int {
        $academic_year = $academic_year ?? $this->currentAcademicYear();

        // Find current enrollment
        $enrollmentModel = new \App\Models\Enrollment();
        $enrollment = $enrollmentModel->getCurrentByStudent($student_id, $academic_year);

        if (!$enrollment) {
            throw new \Exception('Student not enrolled in current academic year');
        }

        // Find existing result
        $existing = $this->where([
            'enrollment_id'    => $enrollment['id'],
            'class_subject_id' => $class_subject_id,
            'exam_name'        => $exam_name,
            'academic_year'    => $academic_year
        ]);

        // Get school grading scale
        $class = (new \App\Models\ClassModel())->find($enrollment['class_id']);
        $schoolModel = new \App\Models\School();
        $gradingScale = $schoolModel->getGradingScale($class['school_id'] ?? null);

        $percentage = 100.0; // assuming out of 100
        $grade = $this->calculateGradeFromScale($percentage, $gradingScale);

        $data = [
            'enrollment_id'    => $enrollment['id'],
            'class_subject_id' => $class_subject_id,
            'exam_name'        => $exam_name,
            'marks_obtained'   => $marks_obtained,
            'total_marks'      => 100,
            'grade'            => $grade,
            'academic_year'    => $academic_year,
            'exam_date'        => date('Y-m-d')
        ];

        if (!empty($existing)) {
            $this->update($existing[0]['id'], $data);
            return $existing[0]['id'];
        }

        return $this->create($data);
    }

    // Helper methods
    private function currentAcademicYear(): string
    {
        $month = (int) date('n');
        $year = (int) date('Y');
        return $month >= 9 ? "$year-" . ($year + 1) : ($year - 1) . "-$year";
    }

    private function calculateGradeFromScale(float $percentage, array $scale): string
    {
        foreach ($scale as $grade => $range) {
            if ($percentage >= $range[0] && $percentage <= $range[1]) {
                return $grade;
            }
        }
        return 'F';
    }

    private function getRemark(string $grade): string
    {
        return match ($grade) {
            'A+', 'A' => 'Outstanding Performance',
            'B'       => 'Very Good',
            'C'       => 'Good',
            'D'       => 'Average',
            'E'       => 'Below Average',
            'F'       => 'Fail',
            default   => 'No Grade'
        };
    }
}

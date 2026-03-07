<?php

namespace App\Models;

use App\Core\Model;

/**
 * Represents a student's enrollment in a class for a specific academic year.
 *
 * Handles current year logic, status (active/dropped), and links student to class.
 *
 * @property int    $id
 * @property int    $student_id
 * @property int    $class_id
 * @property string $academic_year  Format: "2025-2026"
 * @property string $status         'active', 'dropped', etc.
 * @property string $enrolled_at
 * @property string $created_at
 * @property string $updated_at
 */
class Enrollment extends Model
{
    protected string $table = 'enrollments';

    /**
     * Get the current (active) enrollment for a student.
     *
     * @param int         $student_id     The student ID
     * @param string|null $academic_year  Optional override year
     *
     * @return array|null Enrollment with class and teacher details
     */
    public function getCurrentByStudent(int $student_id, ?string $academic_year = null): ?array
    {
        // ... your code
    }

    /**
     * Get all active students enrolled in a class for the current academic year.
     *
     * @param int         $class_id       The class ID
     * @param string|null $academic_year  Optional override year
     *
     * @return array List of students with enrollment details
     */
    public function getByClass(int $class_id, ?string $academic_year = null): array
    {
        // ... your code
    }

    /**
     * Enroll a student in a class with duplicate prevention.
     *
     * @param array $data Enrollment data
     *
     * @return int|string Inserted ID
     *
     * @throws \Exception If already enrolled in the same class/year
     */
    public function enroll(array $data): int|string
    {
        // ... your code
    }
}

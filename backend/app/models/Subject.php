<?php

namespace App\Models;

use App\Core\Model;

/**
 * Represents an academic subject in the school curriculum.
 *
 * Subjects are school-specific and can be assigned to multiple classes
 * through the ClassSubject pivot table. The subject code must be unique
 * within each school.
 *
 * @property int    $id
 * @property string $name         Subject name (e.g., "Mathematics")
 * @property string $code         Unique code within the school (e.g., "MATH101")
 * @property int    $school_id    Foreign key to schools table
 * @property string $created_at
 * @property string $updated_at
 */
class Subject extends Model
{
    protected string $table = 'subjects';

    /**
     * Get all subjects belonging to a specific school.
     *
     * Includes a count of how many classes the subject is currently assigned to.
     *
     * @param int $school_id The school ID
     *
     * @return array List of subjects with assigned_classes_count
     */
    public function getBySchool(int $school_id): array
    {
        // ... your code
    }

    /**
     * Get all subjects assigned to a specific class, including teacher details.
     *
     * @param int $class_id The class ID
     *
     * @return array Subjects with teacher name, email, and class_subject_id
     */
    public function getByClass(int $class_id): array
    {
        // ... your code
    }

    /**
     * Override create to enforce unique subject code per school.
     *
     * @param array $data Subject data (name, code, school_id)
     *
     * @return int|string The inserted record ID
     *
     * @throws \Exception If the subject code already exists in the school
     */
    public function create(array $data): int|string
    {
        // ... your code
    }
}

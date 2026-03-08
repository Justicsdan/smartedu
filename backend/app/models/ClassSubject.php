<?php

namespace App\Models;

use App\Core\Model;

/**
 * Pivot model representing the assignment of a Subject to a Class.
 *
 * Also stores which Teacher (if any) is assigned to teach that subject
 * in that class. This is the many-to-many relationship table with extra data.
 *
 * @property int $id
 * @property int $class_id
 * @property int $subject_id
 * @property int|null $teacher_id  Nullable – subject may be unassigned
 * @property string $created_at
 * @property string $updated_at
 */
class ClassSubject extends Model
{
    protected string $table = 'class_subjects';

    /**
     * Get all class-subject assignments for a specific teacher.
     *
     * Includes class name, level, section, subject name, and student count.
     *
     * @param int $teacher_id The teacher ID
     *
     * @return array List of assignments with enriched data
     */
    public function getByTeacher(int $teacher_id): array
    {
        // ... your code
    }

    /**
     * Get all subjects assigned to a specific class with teacher information.
     *
     * @param int $class_id The class ID
     *
     * @return array Subjects with teacher details
     */
    public function getByClass(int $class_id): array
    {
        // ... your code
    }

    /**
     * Find a specific class-subject assignment to prevent duplicates.
     *
     * @param int $class_id   The class ID
     * @param int $subject_id The subject ID
     *
     * @return array|null The assignment record or null if not found
     */
    public function findByClassAndSubject(int $class_id, int $subject_id): ?array
    {
        // ... your code
    }
}

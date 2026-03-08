<?php

namespace App\Models;

use App\Core\Model;
use PDO;

class ClassModel extends Model
{
    protected string $table = 'classes';
    protected string $primaryKey = 'id';

    /**
     * Get all classes for a specific school with teacher name and student count
     */
    public function getBySchool(int $school_id): array
    {
        $sql = "
            SELECT 
                c.*,
                u.name AS teacher_name,
                COUNT(e.id) AS students_count
            FROM {$this->table} c
            LEFT JOIN users u ON c.teacher_id = u.id
            LEFT JOIN enrollments e ON e.class_id = c.id AND e.status = 'active'
            WHERE c.school_id = :school_id
            GROUP BY c.id
            ORDER BY c.level_year ASC, c.name ASC, c.section ASC
        ";

        $stmt = $this->pdo->prepare($sql);
        $stmt->execute([':school_id' => $school_id]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    /**
     * Get paginated classes for a school (for large schools)
     */
    public function getBySchoolPaginated(int $school_id, int $limit = 20, int $offset = 0): array
    {
        $sql = "
            SELECT 
                c.*,
                u.name AS teacher_name,
                COUNT(e.id) AS students_count
            FROM {$this->table} c
            LEFT JOIN users u ON c.teacher_id = u.id
            LEFT JOIN enrollments e ON e.class_id = c.id AND e.status = 'active'
            WHERE c.school_id = :school_id
            GROUP BY c.id
            ORDER BY c.level_year ASC, c.name ASC, c.section ASC
            LIMIT :limit OFFSET :offset
        ";

        $stmt = $this->pdo->prepare($sql);
        $stmt->bindValue(':school_id', $school_id, PDO::PARAM_INT);
        $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
        $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
        $stmt->execute();

        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    /**
     * Count total classes in a school
     */
    public function countBySchool(int $school_id): int
    {
        return $this->count(['school_id' => $school_id]);
    }

    /**
     * Get detailed class info with stats
     */
    public function findWithStats(int $id): ?array
    {
        $sql = "
            SELECT 
                c.*,
                u.name AS teacher_name,
                COUNT(e.id) AS students_count
            FROM {$this->table} c
            LEFT JOIN users u ON c.teacher_id = u.id
            LEFT JOIN enrollments e ON e.class_id = c.id AND e.status = 'active'
            WHERE c.id = :id
            GROUP BY c.id
        ";

        $stmt = $this->pdo->prepare($sql);
        $stmt->execute([':id' => $id]);
        $result = $stmt->fetch(PDO::FETCH_ASSOC);

        return $result ?: null;
    }

    /**
     * Get all classes assigned to a teacher (as class teacher)
     */
    public function getByTeacher(int $teacher_id): array
    {
        return $this->where([
            'teacher_id' => $teacher_id
        ]);
    }

    /**
     * Count classes with no assigned subjects (optional dashboard stat)
     */
    public function countUnassignedSubjects(int $school_id): int
    {
        $sql = "
            SELECT COUNT(*) 
            FROM {$this->table} c
            LEFT JOIN class_subjects cs ON cs.class_id = c.id
            WHERE c.school_id = :school_id
            GROUP BY c.id
            HAVING COUNT(cs.id) = 0
        ";

        $stmt = $this->pdo->prepare($sql);
        $stmt->execute([':school_id' => $school_id]);
        return count($stmt->fetchAll());
    }

    /**
     * Override create to enforce unique class name per school + level_year
     */
    public function create(array $data): int|string
    {
        // Optional: Add unique constraint check
        $existing = $this->where([
            'school_id'  => $data['school_id'],
            'level_year' => $data['level_year'],
            'name'       => $data['name'],
            'section'    => $data['section'] ?? 'A'
        ]);

        if (!empty($existing)) {
            throw new \Exception('A class with this name, level, and section already exists in the school.');
        }

        return parent::create($data);
    }
}

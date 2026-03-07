<?php

namespace App\Models;

use App\Core\Model;

class Attendance extends Model
{
    protected string $table = 'attendance';

    /**
     * Mark attendance for multiple students
     */
    public function markBulk(array $records): array
    {
        $saved = 0;
        $failed = [];

        foreach ($records as $record) {
            try {
                // Upsert: update if exists, insert if not
                $existing = $this->where([
                    'enrollment_id' => $record['enrollment_id'],
                    'date'          => $record['date']
                ]);

                $data = [
                    'enrollment_id' => $record['enrollment_id'],
                    'date'          => $record['date'],
                    'status'        => $record['status'] ?? 'present',
                    'remarks'       => $record['remarks'] ?? null,
                    'marked_by'     => $record['marked_by']
                ];

                if (!empty($existing)) {
                    $this->update($existing[0]['id'], $data);
                } else {
                    $this->create($data);
                }
                $saved++;
            } catch (\Exception $e) {
                $failed[] = [
                    'enrollment_id' => $record['enrollment_id'],
                    'error'         => $e->getMessage()
                ];
            }
        }

        return ['saved' => $saved, 'failed' => $failed];
    }

    /**
     * Get attendance for a class on a date
     */
    public function getByClassAndDate(int $class_id, string $date): array
    {
        $sql = "
            SELECT 
                a.*,
                u.name AS student_name,
                u.profile_photo
            FROM {$this->table} a
            JOIN enrollments e ON a.enrollment_id = e.id
            JOIN users u ON e.student_id = u.id
            WHERE e.class_id = :class_id
              AND a.date = :date
            ORDER BY u.name
        ";

        $stmt = $this->pdo->prepare($sql);
        $stmt->execute([':class_id' => $class_id, ':date' => $date]);
        return $stmt->fetchAll(\PDO::FETCH_ASSOC);
    }

    /**
     * Get attendance summary for student
     */
    public function getSummary(int $student_id, ?string $academic_year = null): array
    {
        $academic_year = $academic_year ?? date('Y');

        $sql = "
            SELECT 
                status,
                COUNT(*) AS count
            FROM {$this->table} a
            JOIN enrollments e ON a.enrollment_id = e.id
            WHERE e.student_id = :student_id
              AND YEAR(a.date) = :year
            GROUP BY status
        ";

        $stmt = $this->pdo->prepare($sql);
        $stmt->execute([':student_id' => $student_id, ':year' => $academic_year]);
        $raw = $stmt->fetchAll(\PDO::FETCH_KEY_PAIR);

        return [
            'present' => $raw['present'] ?? 0,
            'absent'  => $raw['absent'] ?? 0,
            'late'    => $raw['late'] ?? 0,
            'excused' => $raw['excused'] ?? 0,
            'total_days' => array_sum($raw)
        ];
    }
}

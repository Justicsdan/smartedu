<?php

namespace App\Core;

use PDO;
use PDOException;
use App\Core\Database;

class Model
{
    protected string $table;
    protected string $primaryKey = 'id';
    protected PDO $pdo;

    public function __construct()
    {
        $this->pdo = Database::getInstance()->getConnection();
    }

    /**
     * Get all records from the table
     */
    public function all(): array
    {
        $sql = "SELECT * FROM {$this->table} ORDER BY {$this->primaryKey} DESC";
        $stmt = $this->pdo->query($sql);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    /**
     * Find record by primary key
     */
    public function find(int $id): ?array
    {
        $sql = "SELECT * FROM {$this->table} WHERE {$this->primaryKey} = :id LIMIT 1";
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute([':id' => $id]);
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        return $result ?: null;
    }

    /**
     * Find record by custom column
     */
    public function findBy(string $column, mixed $value): ?array
    {
        $sql = "SELECT * FROM {$this->table} WHERE {$column} = :value LIMIT 1";
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute([':value' => $value]);
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        return $result ?: null;
    }

    /**
     * Create new record
     */
    public function create(array $data): int|string
    {
        // Filter out empty values if needed (optional)
        $data = array_filter($data, fn($value) => $value !== null && $value !== '');

        $columns = implode(', ', array_keys($data));
        $placeholders = ':' . implode(', :', array_keys($data));

        $sql = "INSERT INTO {$this->table} ({$columns}) VALUES ({$placeholders})";

        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($data);

        return $this->pdo->lastInsertId();
    }

    /**
     * Update existing record
     */
    public function update(int $id, array $data): bool
    {
        // Filter null/empty if desired
        $data = array_filter($data, fn($value) => $value !== null);

        if (empty($data)) {
            return false;
        }

        $setParts = [];
        foreach (array_keys($data) as $column) {
            $setParts[] = "{$column} = :{$column}";
        }
        $set = implode(', ', $setParts);

        $sql = "UPDATE {$this->table} SET {$set} WHERE {$this->primaryKey} = :id";

        $data[':id'] = $id;

        $stmt = $this->pdo->prepare($sql);
        return $stmt->execute($data);
    }

    /**
     * Delete record
     */
    public function delete(int $id): bool
    {
        $sql = "DELETE FROM {$this->table} WHERE {$this->primaryKey} = :id";
        $stmt = $this->pdo->prepare($sql);
        return $stmt->execute([':id' => $id]);
    }

    /**
     * Generic where query with optional pagination
     */
    public function where(array $conditions, ?int $limit = null, ?int $offset = null): array
    {
        $whereParts = [];
        $params = [];

        foreach ($conditions as $column => $value) {
            if (is_array($value)) {
                // For IN queries: ['role' => ['admin', 'teacher']]
                $placeholders = [];
                foreach ($value as $i => $val) {
                    $key = ":{$column}_{$i}";
                    $placeholders[] = $key;
                    $params[$key] = $val;
                }
                $whereParts[] = "{$column} IN (" . implode(', ', $placeholders) . ")";
            } else {
                $key = ":{$column}";
                $whereParts[] = "{$column} = {$key}";
                $params[$key] = $value;
            }
        }

        $sql = "SELECT * FROM {$this->table}";
        if (!empty($whereParts)) {
            $sql .= " WHERE " . implode(' AND ', $whereParts);
        }

        $sql .= " ORDER BY {$this->primaryKey} DESC";

        if ($limit !== null) {
            $sql .= " LIMIT :limit";
            $params[':limit'] = $limit;
            if ($offset !== null) {
                $sql .= " OFFSET :offset";
                $params[':offset'] = $offset;
            }
        }

        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    /**
     * Count records matching conditions
     */
    public function count(array $conditions = []): int
    {
        $sql = "SELECT COUNT(*) FROM {$this->table}";
        $params = [];

        if (!empty($conditions)) {
            $whereParts = [];
            foreach ($conditions as $column => $value) {
                $key = ":{$column}";
                $whereParts[] = "{$column} = {$key}";
                $params[$key] = $value;
            }
            $sql .= " WHERE " . implode(' AND ', $whereParts);
        }

        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($params);
        return (int) $stmt->fetchColumn();
    }

    /**
     * Raw query (use carefully)
     */
    public function query(string $sql, array $params = []): array
    {
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    /**
     * Execute raw statement (INSERT/UPDATE/DELETE)
     */
    public function execute(string $sql, array $params = []): bool
    {
        $stmt = $this->pdo->prepare($sql);
        return $stmt->execute($params);
    }
}

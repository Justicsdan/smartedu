<?php

namespace App\Models;

use App\Core\Model;
use App\Core\Auth;
use PDO;

class User extends Model
{
    protected string $table = 'users';
    protected string $primaryKey = 'id';

    /**
     * Find user by email (used in login)
     */
    public function findByEmail(string $email): ?array
    {
        return $this->where(['email' => $email])[0] ?? null;
    }

    /**
     * Get users by school with optional role filter
     */
    public function getBySchool(int $school_id, ?string $role = null): array
    {
        $conditions = ['school_id' => $school_id];
        if ($role) {
            $conditions['role'] = $role;
        }

        return $this->where($conditions);
    }

    /**
     * Count users by role and school (for stats)
     */
    public function countByRoleAndSchool(string $role, int $school_id): int
    {
        return $this->count([
            'role'      => $role,
            'school_id' => $school_id
        ]);
    }

    /**
     * Count total users in school
     */
    public function countBySchool(int $school_id): int
    {
        return $this->count(['school_id' => $school_id]);
    }

    /**
     * Count total users by role (for superadmin stats)
     */
    public function countByRole(string $role): int
    {
        return $this->count(['role' => $role]);
    }

    /**
     * Count all users
     */
    public function countAll(): int
    {
        return $this->count();
    }

    /**
     * Search users in a school by name or email
     */
    public function searchInSchool(int $school_id, string $query, int $limit = 20): array
    {
        $query = "%{$query}%";

        $sql = "
            SELECT 
                id, name, email, role, profile_photo, status, created_at
            FROM {$this->table}
            WHERE school_id = :school_id
              AND (name LIKE :query OR email LIKE :query)
            ORDER BY name ASC
            LIMIT :limit
        ";

        $stmt = $this->pdo->prepare($sql);
        $stmt->execute([
            ':school_id' => $school_id,
            ':query'     => $query,
            ':limit'     => $limit
        ]);

        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    /**
     * Get current authenticated user from JWT payload
     */
    public function getAuthenticatedUser(): ?array
    {
        $payload = Auth::user();

        if (!$payload || !isset($payload['user_id'])) {
            return null;
        }

        $user = $this->find((int)$payload['user_id']);
        if ($user) {
            unset($user['password']);
        }

        return $user;
    }

    /**
     * Check if current user is superadmin
     */
    public function isCurrentUserSuperAdmin(): bool
    {
        return Auth::isSuperAdmin();
    }

    /**
     * Attempt login - returns success status, message, token, and user
     */
    public function attemptLogin(string $email, string $password): array
    {
        $user = $this->findByEmail($email);

        if (!$user) {
            return ['success' => false, 'message' => 'Invalid credentials'];
        }

        if ($user['status'] !== 'active') {
            return ['success' => false, 'message' => 'Your account is inactive. Contact administrator.'];
        }

        if (!password_verify($password, $user['password'])) {
            return ['success' => false, 'message' => 'Invalid credentials'];
        }

        unset($user['password']);
        $token = Auth::issue($user);

        return [
            'success' => true,
            'message' => 'Login successful',
            'token'   => $token,
            'user'    => $user
        ];
    }

    /**
     * Register new user with secure defaults
     */
    public function register(array $data): array
    {
        $required = ['name', 'email', 'password'];
        foreach ($required as $field) {
            if (empty($data[$field])) {
                return ['success' => false, 'message' => ucfirst($field) . ' is required'];
            }
        }

        if ($this->findByEmail($data['email'])) {
            return ['success' => false, 'message' => 'Email already registered'];
        }

        $data['password'] = password_hash($data['password'], PASSWORD_DEFAULT);
        $data['role'] = $data['role'] ?? 'student';
        $data['status'] = $data['status'] ?? 'active';

        // Only superadmin can create superadmin
        if ($data['role'] === 'super_admin' && !Auth::isSuperAdmin()) {
            return ['success' => false, 'message' => 'Unauthorized to create super admin'];
        }

        // Super admins have no school_id
        if ($data['role'] === 'super_admin') {
            $data['school_id'] = null;
        }

        $userId = $this->create($data);

        $user = $this->find($userId);
        unset($user['password']);

        $token = Auth::issue($user);

        return [
            'success' => true,
            'message' => 'Registration successful',
            'token'   => $token,
            'user'    => $user
        ];
    }

    /**
     * Override create - auto-hash password and enforce superadmin rules
     */
    public function create(array $data): int|string
    {
        if (!empty($data['password']) && !password_needs_rehash($data['password'])) {
            $data['password'] = password_hash($data['password'], PASSWORD_DEFAULT);
        }

        if (($data['role'] ?? '') === 'super_admin') {
            $data['school_id'] = null;
        }

        $data['created_at'] = date('Y-m-d H:i:s');

        return parent::create($data);
    }

    /**
     * Override update - safely handle password changes
     */
    public function update(int $id, array $data): bool
    {
        if (isset($data['password']) && !empty($data['password'])) {
            $data['password'] = password_hash($data['password'], PASSWORD_DEFAULT);
        } else {
            unset($data['password']);
        }

        // Prevent changing role to super_admin unless current user is super_admin
        if (isset($data['role']) && $data['role'] === 'super_admin' && !Auth::isSuperAdmin()) {
            throw new \Exception('Only super admin can promote to super admin');
        }

        if (isset($data['role']) && $data['role'] === 'super_admin') {
            $data['school_id'] = null;
        }

        return parent::update($id, $data);
    }
}

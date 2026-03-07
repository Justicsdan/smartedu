<?php

namespace App\Middlewares;

use App\Helpers\response;

class RoleMiddleware
{
    private array $allowedRoles;

    /**
     * Constructor accepts roles as a comma-separated string.
     * Example: "admin" or "admin,teacher,staff"
     *
     * @param string $roles
     */
    public function __construct(string $roles = '')
    {
        $this->allowedRoles = $roles
            ? array_map('trim', explode(',', $roles))
            : [];
    }

    public function handle()
    {
        // Ensure user is authenticated (populated by AuthMiddleware)
        $user = $_SERVER['user'] ?? null;

        if (!$user) {
            return response(
                json_encode(['error' => 'Unauthorized: No authentication context found']),
                401,
                ['Content-Type' => 'application/json']
            );
        }

        // Ensure the user payload actually has a 'role' key
        if (!isset($user['role'])) {
            return response(
                json_encode(['error' => 'Server Error: Malformed user payload']),
                500,
                ['Content-Type' => 'application/json']
            );
        }

        $userRole = trim($user['role']);

        // If no specific roles required (empty string passed), allow any authenticated user
        if (empty($this->allowedRoles)) {
            return true;
        }

        // Check if user's role is in allowed list
        // Using strict comparison (true) for security
        if (!in_array($userRole, $this->allowedRoles, true)) {
            return response(
                json_encode([
                    'error' => 'Forbidden: Insufficient permissions',
                    'required_roles' => $this->allowedRoles,
                    'your_role' => $userRole
                ]),
                403,
                ['Content-Type' => 'application/json']
            );
        }

        return true; // Role is allowed, proceed to controller
    }
}

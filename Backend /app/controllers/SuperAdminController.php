<?php

namespace App\Controllers;

use App\Core\Controller;
use App\Models\School;
use App\Models\User;
use App\Core\Auth; // For current user from JWT
use App\Helpers\validator;

class SuperAdminController extends Controller
{
    private $schoolModel;
    private $userModel;

    public function __construct()
    {
        $this->schoolModel = new School();
        $this->userModel   = new User();

        // Get current user from JWT (set by AuthMiddleware)
        $currentUser = Auth::user();

        if (!$currentUser) {
            return $this->error('Unauthorized. Please login.', 401);
        }

        if ($currentUser['role'] !== 'super_admin') {
            return $this->error('Forbidden. Super Admin access required.', 403);
        }
    }

    // ============================================================
    // 1. DASHBOARD
    // ============================================================

    public function dashboard()
    {
        $totalSchools = $this->schoolModel->countAll();
        $activeSchools = $this->schoolModel->countByStatus('active');
        $inactiveSchools = $totalSchools - $activeSchools;

        $totalUsers = $this->userModel->countAll();
        $totalAdmins = $this->userModel->countByRole('admin');
        $totalTeachers = $this->userModel->countByRole('teacher');
        $totalStudents = $this->userModel->countByRole('student');

        $recentSchools = $this->schoolModel->getRecent(5);

        return $this->json([
            'message' => 'Super Admin Dashboard',
            'stats' => [
                'total_schools'     => $totalSchools,
                'active_schools'    => $activeSchools,
                'inactive_schools'  => $inactiveSchools,
                'total_users'       => $totalUsers,
                'total_admins'      => $totalAdmins,
                'total_teachers'    => $totalTeachers,
                'total_students'    => $totalStudents
            ],
            'recent_schools' => $recentSchools
        ]);
    }

    // ============================================================
    // 2. SCHOOL MANAGEMENT
    // ============================================================

    public function getSchools()
    {
        $page = max(1, (int)($_GET['page'] ?? 1));
        $limit = min(50, (int)($_GET['limit'] ?? 20));
        $offset = ($page - 1) * $limit;
        $search = trim($_GET['search'] ?? '');

        $schools = $this->schoolModel->getPaginatedWithStats($limit, $offset);
        $total = $this->schoolModel->countAll($search);

        return $this->json([
            'data' => $schools,
            'pagination' => [
                'page'  => $page,
                'limit' => $limit,
                'total' => $total,
                'pages' => ceil($total / $limit)
            ]
        ]);
    }

    public function getSchool($id)
    {
        $school = $this->schoolModel->findWithStats($id);

        if (!$school) {
            return $this->error('School not found', 404);
        }

        $admins = $this->userModel->getByRoleAndSchool('admin', $id);
        $school['admins'] = $admins;

        return $this->json($school);
    }

    public function createSchool()
    {
        $input = json_decode(file_get_contents('php://input'), true);

        if (empty($input)) {
            return $this->error('No data provided', 400);
        }

        $rules = [
            'name'         => 'required|max:150',
            'code'         => 'required|max:20',
            'email'        => 'required|email',
            'phone'        => 'max:20',
            'address'      => 'max:255',
            'motto'        => 'max:255',
            'school_type'  => 'in:day,boarding',
            'admin_name'   => 'required_if:create_admin,1|max:100',
            'admin_email'  => 'required_if:create_admin,1|email',
            'admin_password' => 'min:8'
        ];

        if ($errors = validator($input, $rules)) {
            return $this->error(['errors' => $errors], 422);
        }

        // Normalize code
        $input['code'] = strtoupper(trim(str_replace(' ', '', $input['code'])));

        // Check unique code
        if ($this->schoolModel->findBy('code', $input['code'])) {
            return $this->error('School code already exists', 409);
        }

        // Create school
        $schoolData = [
            'name'         => $input['name'],
            'code'         => $input['code'],
            'email'        => $input['email'],
            'phone'        => $input['phone'] ?? null,
            'address'      => $input['address'] ?? null,
            'motto'        => $input['motto'] ?? null,
            'school_type'  => $input['school_type'] ?? 'day',
            'logo_path'    => $input['logo_path'] ?? null,
            'grading_scale'=> $input['grading_scale'] ?? null,
            'status'       => 'active'
        ];

        $schoolId = $this->schoolModel->create($schoolData);

        // Create first admin if requested
        if (!empty($input['admin_name'])) {
            $adminData = [
                'name'      => $input['admin_name'],
                'email'     => $input['admin_email'],
                'password'  => password_hash($input['admin_password'] ?? bin2hex(random_bytes(8)), PASSWORD_DEFAULT),
                'role'      => 'admin',
                'school_id' => $schoolId,
                'status'    => 'active'
            ];

            $this->userModel->create($adminData);
        }

        return $this->json([
            'message'   => 'School created successfully',
            'school_id' => $schoolId
        ], 201);
    }

    public function updateSchool($id)
    {
        $school = $this->schoolModel->find($id);
        if (!$school) {
            return $this->error('School not found', 404);
        }

        $input = json_decode(file_get_contents('php://input'), true);

        $allowed = ['name', 'email', 'phone', 'address', 'motto', 'school_type', 'logo_path', 'grading_scale', 'status'];
        $updateData = [];

        foreach ($allowed as $field) {
            if (isset($input[$field])) {
                $updateData[$field] = $input[$field];
            }
        }

        if (empty($updateData)) {
            return $this->error('No valid fields to update', 400);
        }

        if (isset($updateData['code'])) {
            $updateData['code'] = strtoupper(trim($updateData['code']));
            if ($this->schoolModel->findBy('code', $updateData['code']) && $updateData['code'] !== $school['code']) {
                return $this->error('School code already exists', 409);
            }
        }

        $this->schoolModel->update($id, $updateData);

        return $this->json(['message' => 'School updated successfully']);
    }

    public function deleteSchool($id)
    {
        $school = $this->schoolModel->find($id);
        if (!$school) {
            return $this->error('School not found', 404);
        }

        // Safety check - prevent deleting schools with users
        $userCount = $this->userModel->countBySchool($id);
        if ($userCount > 0) {
            return $this->error("Cannot delete school with {$userCount} users. Deactivate instead.", 409);
        }

        $this->schoolModel->delete($id);

        return $this->json(['message' => 'School deleted permanently']);
    }
}

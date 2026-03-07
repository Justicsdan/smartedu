<?php
// app/Controllers/AuthController.php

namespace App\Controllers;

class AuthController {
    private $db;

    public function __construct() {
        require_once __DIR__ . '/../../config/database.php';
        $database = new Database();
        $this->db = $database->getConnection();
    }

    // ============================================
    // LOGIN LOGIC (Multi-Roll)
    // ============================================
    
    public function login() {
        // 1. Get Raw Input
        $json = file_get_contents('php://input');
        $data = json_decode($json, true);

        // 2. Basic Validation
        if (!isset($data->email) || !isset($data->password) || !isset($data->role)) {
            http_response_code(400);
            echo json_encode(['message' => 'Email, Password, and Role are required']);
            exit;
        }

        $email = trim($data->email);
        $password = trim($data->password);
        $role = trim($data->role);
        $pin = isset($data->pin) ? trim($data->pin) : null;

        // 3. Database Query
        // Find user by email AND role
        $sql = "SELECT * FROM users WHERE email = ? AND role = ? LIMIT 1";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$email, $role]);
        
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        // 4. Verification
        if (!$user) {
            http_response_code(401);
            echo json_encode(['message' => 'Invalid credentials']);
            exit;
        }

        // 5. Check Password (or PIN for Students)
        // NOTE: In production, use password_verify()
        $passwordValid = false;

        if ($role === 'student') {
            // Student Login: Verify PIN against 'password' field
            // Note: Assuming 'password' in DB stores the PIN for students for simplicity in this schema
            // If you stored PIN separately, change this logic.
            if ($user['password'] === $password) {
                $passwordValid = true;
            }
        } else {
            // Other Roles: Verify Password
            // Note: The DB schema provided earlier did NOT hash passwords for the mock user. 
            // In a real app, use: password_verify($password, $user['password'])
            if ($user['password'] === $password) {
                $passwordValid = true;
            }
        }

        if (!$passwordValid) {
            http_response_code(401);
            echo json_encode(['message' => 'Invalid password or PIN']);
            exit;
        }

        // 6. Successful Login - Start Session
        session_start(); // Ensure session is started
        $_SESSION['user_id'] = $user['id'];
        $_SESSION['user_fullName'] = $user['fullName'];
        $_SESSION['user_role'] = $user['role'];
        $_SESSION['user_email'] = $user['email'];
        
        // If School Admin, also set school_id if they have one
        if ($user['role'] === 'admin' || $user['role'] === 'teacher') {
            $_SESSION['school_id'] = $user['school_id'];
        }

        // 7. Return Success Response
        http_response_code(200);
        echo json_encode([
            'message' => 'Login successful',
            'redirect' => $this->getDashboardUrl($user['role']),
            'user' => [
                'id' => $user['id'],
                'fullName' => $user['fullName'],
                'role' => $user['role']
            ]
        ]);
    }

    // ============================================
    // LOGOUT LOGIC
    // ============================================
    
    public function logout() {
        session_start();
        
        // Destroy session variables
        unset($_SESSION['user_id']);
        unset($_SESSION['user_fullName']);
        unset($_SESSION['user_role']);
        unset($_SESSION['school_id']);

        // Destroy session completely
        session_destroy();

        http_response_code(200);
        echo json_encode(['message' => 'Logged out successfully']);
    }

    // ============================================
    // HELPER: Get Redirect URL based on Role
    // ============================================
    private function getDashboardUrl($role) {
        // Assuming your HTML files are in 'pages/' folder
        switch ($role) {
            case 'superadmin':
                return 'pages/login.html'; // Or create a super admin dashboard
            case 'admin':
                return 'pages/admin_dashboard.html';
            case 'teacher':
                return 'pages/teacher_dashboard.html';
            case 'student':
                return 'pages/student_dashboard.html';
            default:
                return 'pages/login.html';
        }
    }
}
?>

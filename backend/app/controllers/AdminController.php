<?php
// app/Controllers/AdminController.php

namespace App\Controllers;

use App\Core\Router;
use App\Middlewares\AuthMiddleware;
use App\Middlewares\RoleMiddleware;

class AdminController {
    private $db;

    public function __construct() {
        require_once __DIR__ . '/../../config/database.php';
        $database = new Database();
        $this->db = $database->getConnection();
    }

    // ============================================
    // 1. CLASS MANAGEMENT
    // ============================================
    
    // GET /admin/classes
    public function getClasses() {
        // Get School ID from session
        $schoolId = $_SESSION['school_id'] ?? 1; // Default to 1 for Super Admin

        $sql = "SELECT * FROM classes WHERE school_id = ? ORDER BY created_at DESC";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$schoolId]);
        
        $classes = $stmt->fetchAll();
        
        echo json_encode([
            'status' => 'success',
            'data' => $classes
        ]);
    }

    // POST /admin/classes
    public function createClass($data) {
        // Validation
        if (empty($data['name']) || empty($data['school_id'])) {
            http_response_code(400);
            echo json_encode(['message' => 'Class name and School ID are required']);
            return;
        }

        $sql = "INSERT INTO classes (name, school_id, status, created_at) VALUES (?, ?, ?, NOW())";
        $stmt = $this->db->prepare($sql);
        
        if ($stmt->execute([$data['name'], $data['school_id'], 'active'])) {
            http_response_code(201);
            echo json_encode(['message' => 'Class created successfully']);
        } else {
            http_response_code(500);
            echo json_encode(['message' => 'Failed to create class']);
        }
    }

    // PUT /admin/classes/{id}
    public function updateClass($id, $data) {
        // Validation
        if (empty($data['name'])) {
            http_response_code(400);
            echo json_encode(['message' => 'Class name is required']);
            return;
        }

        $sql = "UPDATE classes SET name = ? WHERE id = ?";
        $stmt = $this->db->prepare($sql);
        
        if ($stmt->execute([$data['name'], $id])) {
            http_response_code(200);
            echo json_encode(['message' => 'Class updated successfully']);
        } else {
            http_response_code(500);
            echo json_encode(['message' => 'Failed to update class']);
        }
    }

    // DELETE /admin/classes/{id}
    public function deleteClass($id) {
        $sql = "DELETE FROM classes WHERE id = ?";
        $stmt = $this->db->prepare($sql);
        
        if ($stmt->execute([$id])) {
            http_response_code(200);
            echo json_encode(['message' => 'Class deleted successfully']);
        } else {
            http_response_code(500);
            echo json_encode(['message' => 'Failed to delete class']);
        }
    }

    // ============================================
    // 2. SUBJECT MANAGEMENT
    // ============================================

    // GET /admin/subjects
    public function getSubjects() {
        $schoolId = $_SESSION['school_id'] ?? 1;
        $sql = "SELECT * FROM subjects WHERE school_id = ? ORDER BY name ASC";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$schoolId]);
        
        $subjects = $stmt->fetchAll();
        echo json_encode(['status' => 'success', 'data' => $subjects]);
    }

    // POST /admin/subjects
    public function createSubject($data) {
        if (empty($data['name']) || empty($data['type'])) {
            http_response_code(400);
            echo json_encode(['message' => 'Subject name and type are required']);
            return;
        }

        $sql = "INSERT INTO subjects (name, type, school_id) VALUES (?, ?, ?)";
        $stmt = $this->db->prepare($sql);
        
        if ($stmt->execute([$data['name'], $data['type'], $_SESSION['school_id']])) {
            http_response_code(201);
            echo json_encode(['message' => 'Subject created']);
        } else {
            http_response_code(500);
            echo json_encode(['message' => 'Failed']);
        }
    }

    // PUT /admin/subjects/{id}
    public function updateSubject($id, $data) {
        if (empty($data['name'])) {
            http_response_code(400);
            echo json_encode(['message' => 'Subject name is required']);
            return;
        }

        $sql = "UPDATE subjects SET name = ?, type = ? WHERE id = ?";
        $stmt = $this->db->prepare($sql);
        
        if ($stmt->execute([$data['name'], $data['type'], $id])) {
            http_response_code(200);
            echo json_encode(['message' => 'Subject updated']);
        } else {
            http_response_code(500);
            echo json_encode(['message' => 'Failed']);
        }
    }

    // DELETE /admin/subjects/{id}
    public function deleteSubject($id) {
        $sql = "DELETE FROM subjects WHERE id = ?";
        $stmt = $this->db->prepare($sql);
        
        if ($stmt->execute([$id])) {
            http_response_code(200);
            echo json_encode(['message' => 'Subject deleted']);
        } else {
            http_response_code(500);
            echo json_encode(['message' => 'Failed']);
        }
    }

    // ============================================
    // 3. USER MANAGEMENT (Teachers & Students)
    // ============================================

    // GET /admin/users/teachers
    public function getTeachers() {
        $schoolId = $_SESSION['school_id'] ?? 1;
        $sql = "SELECT id, fullName, email, role FROM users WHERE role IN ('teacher', 'admin') AND school_id = ? ORDER BY fullName ASC";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$schoolId]);
        
        $teachers = $stmt->fetchAll();
        echo json_encode(['status' => 'success', 'data' => $teachers]);
    }

    // GET /admin/users/students
    public function getStudents() {
        $schoolId = $_SESSION['school_id'] ?? 1;
        $sql = "SELECT * FROM users WHERE role = 'student' AND school_id = ? ORDER BY fullName ASC";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$schoolId]);
        
        $students = $stmt->fetchAll();
        echo json_encode(['status' => 'success', 'data' => $students]);
    }

    // POST /admin/users (Create Teacher or Student)
    public function createUser($data) {
        // Validation
        if (empty($data['fullName']) || empty($data['email']) || empty($data['password']) || empty($data['role'])) {
            http_response_code(400);
            echo json_encode(['message' => 'All fields are required']);
            return;
        }

        // Hash Password (Use password_hash in production)
        $hashedPassword = password_hash($data['password'], PASSWORD_DEFAULT);

        // Generate unique ID
        $userId = uniqid('USR', true);

        $sql = "INSERT INTO users (id, fullName, email, password, role, school_id, created_at) VALUES (?, ?, ?, ?, ?, ?, NOW())";
        $stmt = $this->db->prepare($sql);
        
        if ($stmt->execute([$userId, $data['fullName'], $data['email'], $hashedPassword, $data['role'], $_SESSION['school_id']])) {
            http_response_code(201);
            echo json_encode(['message' => 'User created successfully']);
        } else {
            http_response_code(500);
            echo json_encode(['message' => 'Failed to create user']);
        }
    }

    // PUT /admin/users/{id}
    public function updateUser($id, $data) {
        $sql = "UPDATE users SET fullName = ?, email = ? WHERE id = ?";
        $stmt = $this->db->prepare($sql);
        
        // If password is provided, hash it
        if (!empty($data['password'])) {
             $sql = "UPDATE users SET fullName = ?, email = ?, password = ? WHERE id = ?";
             $stmt = $this->db->prepare($sql);
             $stmt->execute([$data['fullName'], $data['email'], password_hash($data['password'], PASSWORD_DEFAULT), $id]);
        } else {
            $stmt->execute([$data['fullName'], $data['email'], $id]);
        }

        echo json_encode(['message' => 'User updated']);
    }

    // DELETE /admin/users/{id}
    public function deleteUser($id) {
        $sql = "DELETE FROM users WHERE id = ?";
        $stmt = $this->db->prepare($sql);
        
        if ($stmt->execute([$id])) {
            http_response_code(200);
            echo json_encode(['message' => 'User deleted']);
        } else {
            http_response_code(500);
            echo json_encode(['message' => 'Failed']);
        }
    }

    // ============================================
    // 4. ACADEMIC SESSIONS
    // ============================================

    // GET /admin/sessions
    public function getSessions() {
        $schoolId = $_SESSION['school_id'] ?? 1;
        $sql = "SELECT * FROM sessions WHERE school_id = ? ORDER BY created_at DESC";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$schoolId]);
        
        $sessions = $stmt->fetchAll();
        echo json_encode(['status' => 'success', 'data' => $sessions]);
    }

    // POST /admin/sessions
    public function createSession($data) {
        // Validation
        if (empty($data['name']) || empty($data['startDate']) || empty($data['endDate'])) {
            http_response_code(400);
            echo json_encode(['message' => 'Session details are required']);
            return;
        }

        $sql = "INSERT INTO sessions (name, start_date, end_date, status, school_id, created_at) VALUES (?, ?, ?, ?, ?, NOW())";
        $stmt = $this->db->prepare($sql);
        
        if ($stmt->execute([$data['name'], $data['startDate'], $data['endDate'], 'pending', $_SESSION['school_id']])) {
            http_response_code(201);
            echo json_encode(['message' => 'Session created']);
        } else {
            http_response_code(500);
            echo json_encode(['message' => 'Failed']);
        }
    }

    // PUT /admin/sessions/{id} (Update Status)
    public function updateSessionStatus($id, $data) {
        if (!isset($data['status'])) {
            http_response_code(400);
            echo json_encode(['message' => 'Status is required']);
            return;
        }

        $sql = "UPDATE sessions SET status = ? WHERE id = ?";
        $stmt = $this->db->prepare($sql);
        
        if ($stmt->execute([$data['status'], $id])) {
            echo json_encode(['message' => 'Session updated']);
        } else {
            echo json_encode(['message' => 'Failed']);
        }
    }

    // ============================================
    // 5. RESULTS MANAGEMENT
    // ============================================

    // GET /admin/results/class/{classId}/subject/{subjectId}
    public function getClassResults($classId, $subjectId) {
        $sql = "SELECT r.*, u.fullName as student_name, s.name as subject_name 
                FROM results r
                JOIN users u ON r.student_id = u.id
                JOIN subjects s ON r.subject_id = s.id
                WHERE r.class_id = ? AND r.subject_id = ?";
        
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$classId, $subjectId]);
        
        $results = $stmt->fetchAll();
        echo json_encode(['status' => 'success', 'data' => $results]);
    }

    // POST /admin/results (Approve or Submit)
    public function submitResults($data) {
        // Expecting: { "results": [{ "studentId": 1, "score": 85, "subjectId": 2 }, ... ] }
        
        if (!isset($data['results']) || empty($data['results'])) {
            http_response_code(400);
            echo json_encode(['message' => 'Results data is required']);
            return;
        }

        // Start transaction
        try {
            $this->db->beginTransaction();

            $stmt = $this->db->prepare("INSERT INTO results (student_id, subject_id, score, class_id, created_at) VALUES (?, ?, ?, ?, NOW())");
            
            $count = 0;
            foreach ($data['results'] as $result) {
                $stmt->execute([$result['studentId'], $result['subjectId'], $result['score'], $result['classId'] ?? 1]);
                $count++;
            }

            $this->db->commit();
            http_response_code(201);
            echo json_encode(['message' => "$count results submitted successfully"]);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['message' => 'Failed to submit results']);
        }
    }

    // GET /admin/results/student/{id}
    public function getStudentTranscript($id) {
        // Detailed Transcript for printing
        $sql = "SELECT r.score, s.name as subject_name, s.code, r.created_at
                FROM results r
                JOIN subjects s ON r.subject_id = s.id
                WHERE r.student_id = ? 
                ORDER BY s.name ASC";
        
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$id]);
        
        $results = $stmt->fetchAll();
        echo json_encode(['status' => 'success', 'data' => $results]);
    }

}
?>

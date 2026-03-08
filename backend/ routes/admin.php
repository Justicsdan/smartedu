<?php
// routes/admin.php

require_once __DIR__ . '/../config/database.php';

// Simple Router Logic (assuming you are not using a complex framework like Laravel)
// If you are using Slim/Laravel, adapt the Controller methods accordingly.

// Route Helper
function dispatchRequest($uri) {
    $uri = $_SERVER['REQUEST_URI'];
    
    // Parse the path (e.g., /admin/classes/update)
    $path = parse_url($uri, PHP_URL_PATH);
    
    // Check permissions
    // Note: In your AuthMiddleware, verify $_SESSION['role'] === 'admin'

    $controller = new \App\Controllers\AdminController();
    $method = $_SERVER['REQUEST_METHOD'];
    $input = json_decode(file_get_contents('php://input'), true);

    switch (true) {
        // --- Classes ---
        case (strpos($uri, '/api/admin/classes') !== false):
            if ($method === 'GET') return $controller->getClasses();
            if ($method === 'POST') return $controller->createClass($input);
            // Handling PUT/DELETE is tricky with simple PHP router, usually requires .htaccess rewrite or parameters
            // For now, we assume POST handles updates or specific logic
            break;

        // --- Subjects ---
        case (strpos($uri, '/api/admin/subjects') !== false):
            if ($method === 'GET') return $controller->getSubjects();
            if ($method === 'POST') return $controller->createSubject($input);
            break;

        // --- Users ---
        case (strpos($uri, '/api/admin/users/teachers') !== false):
            if ($method === 'GET') return $controller->getTeachers();
        
        case (strpos($uri, '/api/admin/users/students') !== false):
            if ($method === 'GET') return $controller->getStudents();
            
        case (strpos($uri, '/api/admin/users') !== false):
            if ($method === 'POST') return $controller->createUser($input);
            
        // Handling Updates/Deletes is complex without query params
        // In a real framework (Laravel/Slim), use /admin/users/{id}
            if ($method === 'PUT') return $controller->updateUser(1, $input); // Placeholder ID
            if ($method === 'DELETE') return $controller->deleteUser(1);
            break;

        // --- Sessions ---
        case (strpos($uri, '/api/admin/sessions') !== false):
            if ($method === 'GET') return $controller->getSessions();
            if ($method === 'POST') return $controller->createSession($input);
            
            if ($method === 'PUT') {
                // Extract ID from URI manually (Simple router limitation)
                $parts = explode('/', $uri);
                $id = end($parts);
                return $controller->updateSessionStatus($id, $input);
            }
            break;

        // --- Results ---
        case (strpos($uri, '/api/admin/results') !== false):
            if ($method === 'POST') return $controller->submitResults($input);
            // Get specific results
            // Manual parsing for /api/admin/results/class/1/subject/2
            if (strpos($uri, '/api/admin/results/class/') !== false) {
                 $parts = explode('/', $uri);
                 $classId = $parts[5] ?? null;
                 $subjectId = $parts[6] ?? null;
                 if ($classId && $subjectId) return $controller->getClassResults($classId, $subjectId);
            }
            
            // Student Transcript
            if (strpos($uri, '/api/admin/results/student/') !== false) {
                $parts = explode('/', $uri);
                $id = $parts[6] ?? null;
                if ($id) return $controller->getStudentTranscript($id);
            }
            break;

        default:
            http_response_code(404);
            echo json_encode(['message' => 'Route not found']);
            break;
    }
}

// Execute Router
if (strpos($_SERVER['REQUEST_URI'], '/api/admin') !== false) {
    dispatchRequest($_SERVER['REQUEST_URI']);
}
?>

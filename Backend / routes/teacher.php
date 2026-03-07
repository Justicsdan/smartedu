<?php

use App\Core\Router;
use App\Middlewares\AuthMiddleware;
use App\Middlewares\RoleMiddleware;

// ============================================
// Teacher Middleware Group
// ============================================
 $teacherMw = [AuthMiddleware::class, RoleMiddleware::class . ':teacher'];


// ============================================
// 1. Dashboard & Profile Management
// ============================================

// Teacher Dashboard Overview (Classes to teach, pending submissions, etc.)
 $router->add('GET', '/teacher/dashboard', ['App\Controllers\TeacherController', 'dashboard'], $teacherMw);

// Update Teacher Profile
// Body: { "name": "Mr. Doe", "phone": "..." }
 $router->add('PUT', '/teacher/profile', ['App\Controllers\TeacherController', 'updateProfile'], $teacherMw);


// ============================================
// 2. Classes & Subjects
// ============================================

// List all classes assigned to the teacher
// Returns: [{ class: Grade 10-A, subjects: [Math, Physics] }, ...]
 $router->add('GET', '/teacher/my-classes', ['App\Controllers\TeacherController', 'myClasses'], $teacherMw);

// Get list of subjects the teacher teaches (across all classes)
 $router->add('GET', '/teacher/my-subjects', ['App\Controllers\TeacherController', 'mySubjects'], $teacherMw);

// Get Students for a specific class_subject
// This verifies the teacher is assigned to this class_subject_id
 $router->add('GET', '/teacher/students/{class_subject_id}', ['App\Controllers\TeacherController', 'getStudents'], $teacherMw);


// ============================================
// 3. Results Management
// ============================================

// Save (Create) New Result
// Body: { "class_subject_id": 5, "student_id": 12, "exam_name": "Mid Term", "marks_obtained": 80 }
 $router->add('POST', '/teacher/results', ['App\Controllers\TeacherController', 'saveResult'], $teacherMw);

// Update Existing Result
// Body: { "marks_obtained": 85 } (Correcting a mistake)
 $router->add('PUT', '/teacher/results/{id}', ['App\Controllers\TeacherController', 'updateResult'], $teacherMw);


// ============================================
// 4. Teaching Materials (Notes/Assignments)
// ============================================

// Upload a PDF/Image for a class_subject
// Body: multipart/form-data (file, title, class_subject_id)
 $router->add('POST', '/teacher/materials', ['App\Controllers\TeacherController', 'uploadMaterial'], $teacherMw);

// List uploaded materials for a class
 $router->add('GET', '/teacher/materials/{class_subject_id}', ['App\Controllers\TeacherController', 'getMaterials'], $teacherMw);

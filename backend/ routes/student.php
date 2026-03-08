<?php

use App\Core\Router;
use App\Middlewares\AuthMiddleware;
use App\Middlewares\RoleMiddleware;

// ============================================
// Student Middleware Group
// ============================================
// Ensures user is logged in AND has 'student' role.
 $studentMw = [AuthMiddleware::class, RoleMiddleware::class . ':student'];


// ============================================
// 1. Dashboard & Profile Management
// ============================================

// Student Dashboard Summary (Attendance, GPA, Upcoming Exams)
 $router->add('GET', '/student/dashboard', ['App\Controllers\StudentController', 'dashboard'], $studentMw);

// Get Profile Details
 $router->add('GET', '/student/profile', ['App\Controllers\StudentController', 'getProfile'], $studentMw);

// Update Profile (Name, Address, Phone)
// Body: { "name": "John Doe", "address": "..." }
 $router->add('PUT', '/student/profile', ['App\Controllers\StudentController', 'updateProfile'], $studentMw);

// Change Password (Security)
// Body: { "current_password": "...", "new_password": "..." }
 $router->add('PUT', '/student/change-password', ['App\Controllers\StudentController', 'changePassword'], $studentMw);


// ============================================
// 2. Class & Subject Information
// ============================================

// Get current class info (Class Name, Class Teacher)
 $router->add('GET', '/student/my-class', ['App\Controllers\StudentController', 'myClass'], $studentMw);

// Get syllabus or resources for a specific subject
 $router->add('GET', '/student/subjects/{id}/details', ['App\Controllers\StudentController', 'subjectDetails'], $studentMw);


// ============================================
// 3. Results & Reports
// ============================================

// Get all results for current student
// Optional Query: ?year=2024&term=Term%201
 $router->add('GET', '/student/my-results', ['App\Controllers\StudentController', 'myResults'], $studentMw);

// Get results filtered by specific Exam Name
// Example: GET /student/my-results/exam/Mid%20Term
 $router->add('GET', '/student/my-results/exam/{exam_name}', ['App\Controllers\StudentController', 'myResultsByExam'], $studentMw);

// Download/View Printable Report Card
// Returns HTML/PDF. ?year=2024 is optional (defaults to current active session)
 $router->add('GET', '/student/report-card', ['App\Controllers\StudentController', 'reportCard'], $studentMw);

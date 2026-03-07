<?php

use App\Core\Router;
use App\Middlewares\AuthMiddleware;
use App\Middlewares\RoleMiddleware;

// ============================================
// Middleware Groups
// ============================================

// Full access for Admins
 $adminMw = [AuthMiddleware::class, RoleMiddleware::class . ':admin'];

// Read-only access for Teachers (so they can see what they teach)
 $teacherMw = [AuthMiddleware::class, RoleMiddleware::class . ':teacher'];

// ============================================
// 1. Create Assignment
// ============================================

// Assign a subject to a class (and optionally a teacher)
// Body: { "class_id": 5, "subject_id": 3, "teacher_id": 12 }
 $router->add('POST', '/admin/class-subjects', ['App\Controllers\AdminController', 'assignSubjectToClass'], $adminMw);


// ============================================
// 2. View Assignments
// ============================================

// View all subjects assigned to a specific class (useful for Class Details page)
// GET /admin/classes/5/subjects
 $router->add('GET', '/admin/classes/{class_id}/subjects', ['App\Controllers\AdminController', 'getSubjectsByClass'], $adminMw);

// View ALL assignments in the school (Overview table)
// GET /admin/class-subjects
 $router->add('GET', '/admin/class-subjects', ['App\Controllers\AdminController', 'getAllClassSubjects'], $adminMw);

// Get list of available teachers for a specific class/subject (for Dropdowns)
// GET /admin/teachers/available?class_id=5
 $router->add('GET', '/admin/teachers/available', ['App\Controllers\AdminController', 'getAvailableTeachers'], $adminMw);


// ============================================
// 3. Update Assignment
// ============================================

// Change the teacher assigned to a specific class-subject
// PUT /admin/class-subjects/8
// Body: { "teacher_id": 15 }
 $router->add('PUT', '/admin/class-subjects/{id}', ['App\Controllers\AdminController', 'updateClassSubjectTeacher'], $adminMw);


// ============================================
// 4. Delete Assignment
// ============================================

// Remove a subject from a class (unassigns everything)
// DELETE /admin/class-subjects/8
 $router->add('DELETE', '/admin/class-subjects/{id}', ['App\Controllers\AdminController', 'removeClassSubject'], $adminMw);


// ============================================
// 5. Teacher View
// ============================================

// Teachers can view their own assigned classes and subjects
// Note: Mapping to 'myClasses' is fine, but ensure the method handles the subject context.
 $router->add('GET', '/teacher/my-assignments', ['App\Controllers\TeacherController', 'myClasses'], $teacherMw);

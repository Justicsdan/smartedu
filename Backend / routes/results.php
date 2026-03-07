<?php

use App\Core\Router;
use App\Middlewares\AuthMiddleware;
use App\Middlewares\RoleMiddleware;

// ============================================
// Middleware Group
// ============================================
// Allows Admins and Teachers.
// Note: The Controller must enforce logic that Teachers can
// ONLY modify results for classes they are assigned to.
 $resultsMw = [AuthMiddleware::class, RoleMiddleware::class . ':admin,teacher'];


// ============================================
// 1. Create / Save Results
// ============================================

// Create/Update a single result (or array of results)
// Body: { "enrollment_id": 5, "class_subject_id": 10, "exam_name": "Mid Term", "marks_obtained": 85 }
 $router->add('POST', '/results', ['App\Controllers\ResultController', 'saveResults'], $resultsMw);

// Optional: Bulk Upload (Excel/CSV import)
// Body: multipart/form-data
 $router->add('POST', '/results/bulk-upload', ['App\Controllers\ResultController', 'bulkUpload'], $resultsMw);


// ============================================
// 2. View Results
// ============================================

// Get results for a specific Class + Subject combo
// Example: GET /results/class-subject/5?exam_name=Mid%20Term
// If exam_name is omitted, it returns all results for that class-subject
 $router->add('GET', '/results/class-subject/{id}', ['App\Controllers\ResultController', 'getClassResults'], $resultsMw);

// Generate Report Card for a student
// Example: GET /results/student/5/report-card
// Optional Year: GET /results/student/5/report-card?year=2024
 $router->add('GET', '/results/student/{id}/report-card', ['App\Controllers\ResultController', 'reportCard'], $resultsMw);


// ============================================
// 3. Modify Results
// ============================================

// Update a specific result (e.g., grade correction)
// Body: { "marks_obtained": 90, "remarks": "Excellent" }
 $router->add('PUT', '/results/{id}', ['App\Controllers\ResultController', 'updateResult'], $resultsMw);

// Delete a specific result entry
 $router->add('DELETE', '/results/{id}', ['App\Controllers\ResultController', 'deleteResult'], $resultsMw);


// ============================================
// 4. Statistics / Utilities
// ============================================

// Get summary for a class-subject (Average, Highest, Lowest)
 $router->add('GET', '/results/class-subject/{id}/stats', ['App\Controllers\ResultController', 'getClassSubjectStats'], $resultsMw);

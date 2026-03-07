<?php

use App\Core\Router;
use App\Middlewares\AuthMiddleware;
use App\Middlewares\RoleMiddleware;

// ============================================
// Superadmin Middleware Group
// ============================================
 $superAdminMw = [AuthMiddleware::class, RoleMiddleware::class . ':superadmin'];


// ============================================
// 1. Schools Management
// ============================================

// Create a new School
// Body: { "name": "Elite Academy", "code": "ELI-001", "address": "..." }
 $router->add('POST', '/superadmin/schools', ['App\Controllers\SuperAdminController', 'createSchool'], $superAdminMw);

// List all Schools (with pagination)
 $router->add('GET', '/superadmin/schools', ['App\Controllers\SuperAdminController', 'getSchools'], $superAdminMw);

// Get Specific School Details
 $router->add('GET', '/superadmin/schools/{id}', ['App\Controllers\SuperAdminController', 'getSchool'], $superAdminMw);

// Update School Info (e.g., Change Name, Address, Status)
// Body: { "name": "Updated Name", "status": "inactive" }
 $router->add('PUT', '/superadmin/schools/{id}', ['App\Controllers\SuperAdminController', 'updateSchool'], $superAdminMw);

// Delete a School (WARNING: This will cascade delete users/enrollments based on DB Schema)
 $router->add('DELETE', '/superadmin/schools/{id}', ['App\Controllers\SuperAdminController', 'deleteSchool'], $superAdminMw);


// ============================================
// 2. School Admin Management
// ============================================

// Create an Admin for a specific school (The user who runs the school)
// Body: { "name": "Principal John", "email": "admin@elite.com", "password": "123" }
 $router->add('POST', '/superadmin/schools/{school_id}/admins', ['App\Controllers\SuperAdminController', 'createAdmin'], $superAdminMw);

// List all Admins for a specific school
 $router->add('GET', '/superadmin/schools/{school_id}/admins', ['App\Controllers\SuperAdminController', 'getSchoolAdmins'], $superAdminMw);


// ============================================
// 3. Dashboard & Analytics
// ============================================

// Get Platform-wide statistics (Total Schools, Total Users, etc.)
 $router->add('GET', '/superadmin/stats', ['App\Controllers\SuperAdminController', 'getStats'], $superAdminMw);

import 'package:flutter/material.dart';

import '../features/dashboard/super_admin/super_admin_dashboard.dart';
import '../features/dashboard/school_admin/school_admin_dashboard.dart';
import '../features/dashboard/teacher/teacher_dashboard.dart';
import '../features/dashboard/student/student_dashboard.dart';

/// Role-based redirect utility.
///
/// NOTE: In the current architecture, GoRouter handles routing via
/// Initializer widgets (SchoolAdminInitializer, TeacherInitializer, StudentInitializer)
/// which load data BEFORE rendering the dashboard.
///
/// This class exists as a fallback/helper for any place that needs to
/// render a dashboard widget by role string without full initialization.
///
/// MASTER PLAN: Role strings must match those set in AuthService login returns.
class RoleRedirect {

  /// Render a dashboard widget by role string.
  /// Does NOT initialize the provider — use Initializer widgets for that.
  static Widget redirect(String role, {Map<String, dynamic>? data}) {
    switch (role) {
      case 'super_admin':
        return SuperAdminDashboard(adminData: data);

      case 'school_admin':
        return SchoolAdminDashboard(schoolData: data);

      case 'teacher':
        return TeacherDashboard(teacherData: data);

      case 'student':
        return StudentDashboard(studentData: data);

      case 'locked_out':
        return _buildLockedOutScreen(data?['message']);

      default:
        return _buildInvalidRoleScreen(role);
    }
  }

  /// Get the route path for a given role.
  /// Used by GoRouter after successful login.
  static String routeForRole(String role) {
    switch (role) {
      case 'super_admin':
        return '/dashboard/superadmin';
      case 'school_admin':
        return '/dashboard/schooladmin';
      case 'teacher':
        return '/dashboard/teacher';
      case 'student':
        return '/dashboard/student';
      default:
        return '/';
    }
  }

  /// Get a human-readable role label.
  static String roleLabel(String role) {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'school_admin':
        return 'School Admin';
      case 'teacher':
        return 'Teacher';
      case 'student':
        return 'Student';
      case 'locked_out':
        return 'Locked Out';
      default:
        return role;
    }
  }

  /// Check if a role string is valid.
  static bool isValidRole(String role) {
    return ['super_admin', 'school_admin', 'teacher', 'student'].contains(role);
  }

  /// Get role color for UI theming.
  static Color roleColor(String role) {
    switch (role) {
      case 'super_admin':
        return const Color(0xFF1E3C72);
      case 'school_admin':
        return const Color(0xFF4F8CFF);
      case 'teacher':
        return const Color(0xFF0D47A1);
      case 'student':
        return const Color(0xFF2E7D32);
      default:
        return Colors.grey;
    }
  }

  /// Get role icon for UI theming.
  static IconData roleIcon(String role) {
    switch (role) {
      case 'super_admin':
        return Icons.admin_panel_settings;
      case 'school_admin':
        return Icons.school;
      case 'teacher':
        return Icons.person;
      case 'student':
        return Icons.person_outline;
      default:
        return Icons.help_outline;
    }
  }

  // ==========================================
  // ERROR SCREENS
  // ==========================================

  static Widget _buildInvalidRoleScreen(String? role) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.error_outline, size: 40, color: Colors.red),
            ),
            const SizedBox(height: 24),
            const Text(
              'Invalid Role',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B2A4A)),
            ),
            const SizedBox(height: 12),
            Text(
              role != null ? 'Unknown role: "$role"' : 'No role specified',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Please go back and select a valid role.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildLockedOutScreen(String? message) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.lock_outline, size: 40, color: Colors.orange),
            ),
            const SizedBox(height: 24),
            const Text(
              'Account Locked',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B2A4A)),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                message ?? 'Too many failed login attempts. Please wait before trying again.',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

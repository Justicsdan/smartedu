import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:smartedu/core/providers/school_admin_provider.dart';
import 'package:smartedu/core/providers/teacher/teacher_provider.dart';
import 'package:smartedu/core/providers/student/student_provider.dart';
import '../features/home/home_page.dart';
import '../features/auth/role_selection_page.dart';
import '../features/auth/login_page.dart';
import '../features/dashboard/super_admin/super_admin_dashboard.dart';
import '../features/dashboard/school_admin/school_admin_dashboard.dart';
import '../features/dashboard/teacher/teacher_dashboard.dart';
import '../features/dashboard/student/student_dashboard.dart';
import '../features/dashboard/teacher/teacher_profile_page.dart';
import '../features/dashboard/student/pages/student_profile_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: kDebugMode,
    redirect: _handleRedirect,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomePage()),
      GoRoute(path: '/role-selection', builder: (context, state) => const RoleSelectionPage()),
      GoRoute(
        path: '/login',
        builder: (context, state) {
          String role = 'Student';
          if (state.extra is String) role = state.extra as String;
          else if (state.extra is Map<String, dynamic>) role = (state.extra as Map<String, dynamic>)['role'] as String? ?? 'Student';
          return LoginPage(selectedRole: role);
        },
      ),
      GoRoute(
        path: '/dashboard/superadmin',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return _SuperAdminInitializer(adminData: extra);
        },
      ),
      GoRoute(
        path: '/dashboard/schooladmin',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return _SchoolAdminInitializer(schoolData: extra);
        },
      ),
      GoRoute(
        path: '/dashboard/teacher',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return _TeacherInitializer(teacherData: extra);
        },
      ),
      GoRoute(
        path: '/teacher-profile',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) return const _NotFoundPage();
          return TeacherProfilePage(teacherData: extra);
        },
      ),
      GoRoute(
        path: '/dashboard/student',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return _StudentInitializer(studentData: extra);
        },
      ),
      GoRoute(
        path: '/student-profile',
        builder: (context, state) => const StudentProfilePage(),
      ),
      GoRoute(path: '/404', builder: (context, state) => const _NotFoundPage()),
    ],
  );
}

String? _handleRedirect(BuildContext context, GoRouterState state) {
  const publicPaths = ['/', '/role-selection', '/login', '/404'];
  if (publicPaths.contains(state.matchedLocation)) return null;
  return null;
}

class _SchoolAdminInitializer extends StatefulWidget {
  final Map<String, dynamic>? schoolData;
  const _SchoolAdminInitializer({super.key, this.schoolData});
  @override
  State<_SchoolAdminInitializer> createState() => _SchoolAdminInitializerState();
}

class _SchoolAdminInitializerState extends State<_SchoolAdminInitializer> {
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final provider = context.read<SchoolAdminProvider>();
      final loginData = Map<String, dynamic>.from(widget.schoolData ?? {});
      final schoolId = loginData['schoolId']?.toString() ?? '';
      final adminId = loginData['id']?.toString() ?? '';
      if (schoolId.isEmpty) throw Exception('School ID not found. Please log in again.');
      await provider.initializeWithSchool(loginData: loginData, schoolId: schoolId, adminId: adminId);
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('SchoolAdmin init error: $e');
      if (mounted) setState(() => _errorMessage = _friendlyError(e.toString()));
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('School ID not found')) return 'School ID not found. Please log in again.';
    if (raw.contains('School not found')) return 'School not found on server. Contact support.';
    if (raw.contains('network') || raw.contains('socket')) return 'Network error. Check your internet connection.';
    if (raw.contains('JWT') || raw.contains('token')) return 'Session expired. Please log in again.';
    return 'Failed to load school data. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) return _buildError();
    if (!_isInitialized) return _buildLoading(const Color(0xFF4F8CFF), Icons.school, 'Loading School Data...');
    return SchoolAdminDashboard(schoolData: widget.schoolData);
  }

  Widget _buildLoading(Color color, IconData icon, String message) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 80, height: 80, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Icon(icon, size: 40, color: color)),
            const SizedBox(height: 24),
            SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 3, color: color)),
            const SizedBox(height: 16),
            Text(message, style: TextStyle(fontSize: 15, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.error_outline, size: 40, color: Colors.red)),
              const SizedBox(height: 24),
              const Text('Initialization Error', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5)),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(onPressed: () => context.go('/role-selection'), child: const Text('Go Back')),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                        _isInitialized = false;
                      });
                      _initialize();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B2A4A), foregroundColor: Colors.white),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeacherInitializer extends StatefulWidget {
  final Map<String, dynamic>? teacherData;
  const _TeacherInitializer({super.key, this.teacherData});
  @override
  State<_TeacherInitializer> createState() => _TeacherInitializerState();
}

class _TeacherInitializerState extends State<_TeacherInitializer> {
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final provider = context.read<TeacherProvider>();
      final loginData = Map<String, dynamic>.from(widget.teacherData ?? {});
      final schoolId = loginData['schoolId']?.toString() ?? '';
      final teacherId = loginData['id']?.toString() ?? '';
      if (schoolId.isEmpty || teacherId.isEmpty) throw Exception('Invalid login data. Please try again.');
      await provider.initialize(loginData: loginData, schoolId: schoolId, teacherId: teacherId);
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Teacher init error: $e');
      if (mounted) setState(() => _errorMessage = _friendlyError(e.toString()));
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('Invalid login')) return 'Invalid login data. Please try again.';
    if (raw.contains('network') || raw.contains('socket')) return 'Network error. Check your internet connection.';
    return 'Failed to load teacher data. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.error_outline, size: 40, color: Colors.red)),
                const SizedBox(height: 24),
                const Text('Initialization Error', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5)),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(onPressed: () => context.go('/role-selection'), child: const Text('Go Back')),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                          _isInitialized = false;
                        });
                        _initialize();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 80, height: 80, decoration: BoxDecoration(color: const Color(0xFF0D47A1).withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.person_pin, size: 40, color: Color(0xFF0D47A1))),
              const SizedBox(height: 24),
              SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 3, color: const Color(0xFF0D47A1))),
              const SizedBox(height: 16),
              Text('Loading Teacher Data...', style: TextStyle(fontSize: 15, color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }
    return TeacherDashboard(teacherData: widget.teacherData);
  }
}

class _StudentInitializer extends StatefulWidget {
  final Map<String, dynamic>? studentData;
  const _StudentInitializer({super.key, this.studentData});
  @override
  State<_StudentInitializer> createState() => _StudentInitializerState();
}

class _StudentInitializerState extends State<_StudentInitializer> {
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final provider = context.read<StudentProvider>();
      final loginData = Map<String, dynamic>.from(widget.studentData ?? {});
      final schoolId = loginData['schoolId']?.toString() ?? '';
      final studentId = loginData['id']?.toString() ?? '';
      if (schoolId.isEmpty || studentId.isEmpty) throw Exception('Invalid login data. Please try again.');
      await provider.initialize(schoolId, studentId, loginData);
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Student init error: $e');
      if (mounted) setState(() => _errorMessage = _friendlyError(e.toString()));
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('Invalid login')) return 'Invalid login data. Please try again.';
    if (raw.contains('network') || raw.contains('socket')) return 'Network error. Check your internet connection.';
    return 'Failed to load student data. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.error_outline, size: 40, color: Colors.red)),
                const SizedBox(height: 24),
                const Text('Initialization Error', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5)),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(onPressed: () => context.go('/role-selection'), child: const Text('Go Back')),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                          _isInitialized = false;
                        });
                        _initialize();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 80, height: 80, decoration: BoxDecoration(color: const Color(0xFF2E7D32).withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.person, size: 40, color: Color(0xFF2E7D32))),
              const SizedBox(height: 24),
              SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 3, color: const Color(0xFF2E7D32))),
              const SizedBox(height: 16),
              Text('Loading Student Data...', style: TextStyle(fontSize: 15, color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }
    return StudentDashboard(studentData: widget.studentData);
  }
}

class _SuperAdminInitializer extends StatefulWidget {
  final Map<String, dynamic>? adminData;
  const _SuperAdminInitializer({super.key, this.adminData});
  @override
  State<_SuperAdminInitializer> createState() => _SuperAdminInitializerState();
}

class _SuperAdminInitializerState extends State<_SuperAdminInitializer> {
  @override
  Widget build(BuildContext context) => SuperAdminDashboard(adminData: widget.adminData);
}

class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Page Not Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B2A4A))),
            const SizedBox(height: 8),
            const Text('The page you are looking for does not exist.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B2A4A), foregroundColor: Colors.white),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}

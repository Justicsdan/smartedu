import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import 'core/providers/school_admin_provider.dart';
import 'core/super_admin_provider.dart';
import 'core/providers/teacher/teacher_provider.dart';
import 'core/providers/student/student_provider.dart';

import 'features/home/home_page.dart';
import 'features/auth/login_page.dart';
import 'features/auth/role_selection_page.dart';
import 'features/auth/super_admin_login_page.dart';
import 'features/auth/school_code_login_page.dart';
import 'features/dashboard/super_admin/super_admin_dashboard.dart';
import 'features/dashboard/school_admin/pages/page_dashboard.dart';
import 'features/dashboard/school_admin/pages/page_classes.dart';
import 'features/dashboard/school_admin/pages/page_academic.dart';
import 'features/dashboard/school_admin/pages/page_results.dart';
import 'features/dashboard/school_admin/pages/page_publish_results.dart';
import 'features/dashboard/school_admin/pages/page_settings.dart';
import 'features/dashboard/school_admin/pages/page_credentials.dart';
import 'features/dashboard/school_admin/pages/page_students.dart';
import 'features/dashboard/school_admin/pages/page_teachers.dart';
import 'features/dashboard/school_admin/pages/page_fees.dart';
import 'features/dashboard/teacher/teacher_dashboard.dart';
import 'features/dashboard/school_admin/widgets/chat_bot_widget.dart';
import 'features/dashboard/school_admin/add_student_page.dart';
import 'features/dashboard/school_admin/add_teacher_page.dart';
import 'features/dashboard/student/student_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    if (kDebugMode) FlutterError.dumpErrorToConsole(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) debugPrint('ASYNC ERROR: $error');
    return true;
  };
  await Supabase.initialize(
    url: 'https://tcjsmkhmfjigutfhjtem.supabase.co',
    anonKey: 'sb_publishable_zWDvjhEldcV8eutnlRypGA_LGpOUhkg',
    debug: kDebugMode,
  );
  try {
    await Supabase.instance.client.auth.signOut();
  } catch (_) {}
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SchoolAdminProvider()),
        ChangeNotifierProvider(create: (_) => SuperAdminProvider()),
        ChangeNotifierProvider(create: (_) => TeacherProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
      ],
      child: const SmartEduApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const HomePage(),
    ),
    GoRoute(
      path: '/role-selection',
      builder: (_, __) => const RoleSelectionPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (_, state) {
        final role = state.extra as String? ?? 'Student';
        return LoginPage(selectedRole: role);
      },
    ),
    GoRoute(
      path: '/s/:code',
      builder: (_, state) {
        final data = state.extra as Map<String, dynamic>?;
        final code = state.pathParameters['code'] ?? '';
        if (data != null) return SchoolCodeLoginPage(school: data);
        return FutureBuilder(
          future: Supabase.instance.client.from('schools').select().eq('school_code', code).maybeSingle(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Scaffold(backgroundColor: Color(0xFFF7F8FA), body: Center(child: CircularProgressIndicator(color: Color(0xFF1A237E))));
            }
            if (snap.data == null) {
              return Scaffold(backgroundColor: const Color(0xFF080C22), body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.error_outline, size: 48, color: Colors.white24), const SizedBox(height: 16), Text('School code not found', style: TextStyle(color: Colors.white54, fontSize: 16)), const SizedBox(height: 20), ElevatedButton(onPressed: () => ctx.go('/'), child: const Text('Go Home'))])));
            }
            return SchoolCodeLoginPage(school: snap.data!);
          },
        );
      },
    ),
    GoRoute(
      path: '/super-admin-login',
      builder: (_, __) => const SuperAdminLoginPage(),
    ),
    GoRoute(
      path: '/dashboard/superadmin',
      builder: (_, state) {
        final data = state.extra as Map<String, dynamic>? ?? {};
        return SuperAdminDashboard(adminData: data);
      },
    ),
    GoRoute(
      path: '/dashboard/schooladmin',
      builder: (_, state) {
        final data = state.extra as Map<String, dynamic>? ?? {};
        return _SchoolAdminInitializer(schoolData: data);
      },
    ),
    GoRoute(
      path: '/dashboard/teacher',
      builder: (_, state) {
        final data = state.extra as Map<String, dynamic>? ?? {};
        return _TeacherInitializer(teacherData: data);
      },
    ),
    GoRoute(
      path: '/dashboard/student',
      builder: (_, state) {
        final data = state.extra as Map<String, dynamic>? ?? {};
        return _StudentInitializer(studentData: data);
      },
    ),
    GoRoute(
      path: '/teacher-profile',
      builder: (_, state) {
        final data = state.extra as Map<String, dynamic>? ?? {};
        return TeacherDashboard(teacherData: data);
      },
    ),
  ],
);

class SmartEduApp extends StatelessWidget {
  const SmartEduApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'SmartEdu',
      theme: _buildTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.light,
      routerConfig: _router,
      builder: (context, child) {
        ErrorWidget.builder = (details) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F6FA),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bug_report_outlined,
                      size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Something went wrong',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      kDebugMode
                          ? details.exception.toString()
                          : 'An unexpected error occurred',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Go Home'),
                  ),
                ],
              ),
            ),
          );
        };
        return child ?? const SizedBox.shrink();
      },
    );
  }
}

class _SchoolAdminInitializer extends StatefulWidget {
  final Map<String, dynamic> schoolData;
  const _SchoolAdminInitializer({required this.schoolData});

  @override
  State<_SchoolAdminInitializer> createState() =>
      _SchoolAdminInitializerState();
}

class _SchoolAdminInitializerState extends State<_SchoolAdminInitializer> {
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final p = context.read<SchoolAdminProvider>();
      await p.initializeFromLoginData(widget.schoolData);
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      debugPrint('ADMIN INIT ERR: $e');
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: Color(0xFFD32F2F)),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text('Failed to load school data',
                    style: TextStyle(
                        fontSize: 15, color: Colors.grey.shade600)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.go('/role-selection'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    elevation: 0),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
    if (!_ready) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F8FA),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1A237E)),
        ),
      );
    }
    return const _AdminShell();
  }
}

class _TeacherInitializer extends StatefulWidget {
  final Map<String, dynamic> teacherData;
  const _TeacherInitializer({required this.teacherData});

  @override
  State<_TeacherInitializer> createState() => _TeacherInitializerState();
}

class _TeacherInitializerState extends State<_TeacherInitializer> {
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final p = context.read<TeacherProvider>();
      final d = widget.teacherData;
      final schoolId = (d['schoolId'] ?? d['school_id'])?.toString() ?? '';
      final teacherId = (d['id'])?.toString() ?? '';
      if (schoolId.isEmpty || teacherId.isEmpty) {
        throw Exception('Missing school or teacher ID');
      }
      await p.initialize(
        loginData: {
          'first_name': d['firstName'] ?? d['first_name'] ?? '',
          'last_name': d['lastName'] ?? d['last_name'] ?? '',
          'email': d['email'] ?? '',
          'phone': d['phone'] ?? '',
          'staff_id': d['staffId'] ?? d['staff_id'] ?? '',
        },
        schoolId: schoolId,
        teacherId: teacherId,
      );
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      debugPrint('TEACHER INIT ERR: $e');
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: Color(0xFFD32F2F)),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text('Failed to load teacher data',
                    style: TextStyle(
                        fontSize: 15, color: Colors.grey.shade600)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.go('/role-selection'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    elevation: 0),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
    if (!_ready) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F8FA),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1A237E)),
        ),
      );
    }
    return const TeacherDashboard();
  }
}

class _StudentInitializer extends StatefulWidget {
  final Map<String, dynamic> studentData;
  const _StudentInitializer({required this.studentData});

  @override
  State<_StudentInitializer> createState() => _StudentInitializerState();
}

class _StudentInitializerState extends State<_StudentInitializer> {
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final p = context.read<StudentProvider>();
      final d = widget.studentData;
      final schoolId = (d['schoolId'] ?? d['school_id'])?.toString() ?? '';
      final studentId = (d['id'])?.toString() ?? '';
      if (schoolId.isEmpty || studentId.isEmpty) {
        throw Exception('Missing school or student ID');
      }
      await p.initialize(schoolId, studentId, widget.studentData);
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      debugPrint('STUDENT INIT ERR: $e');
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: Color(0xFFD32F2F)),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text('Failed to load student data',
                    style: TextStyle(
                        fontSize: 15, color: Colors.grey.shade600)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.go('/role-selection'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    elevation: 0),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
    if (!_ready) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F8FA),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1A237E)),
        ),
      );
    }
    return StudentDashboard(studentData: widget.studentData);
  }
}

class _AdminShell extends StatefulWidget {
  const _AdminShell();

  @override
  State<_AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<_AdminShell> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _navItems = [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.people_rounded, label: 'Students'),
    _NavItem(icon: Icons.person_pin_rounded, label: 'Teachers'),
    _NavItem(icon: Icons.layers_rounded, label: 'Classes'),
    _NavItem(icon: Icons.calendar_today_rounded, label: 'Academic'),
    _NavItem(icon: Icons.edit_note_rounded, label: 'Scores'),
    _NavItem(icon: Icons.publish_rounded, label: 'Publish'),
    _NavItem(icon: Icons.settings_rounded, label: 'Settings'),
    _NavItem(icon: Icons.vpn_key_rounded, label: 'Credentials'),
    _NavItem(icon: Icons.payment_rounded, label: 'Fees'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SchoolAdminProvider>();
    final schoolName = p.schoolName.isNotEmpty ? p.schoolName : 'School Portal';
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF7F8FA),
      drawer: _buildDrawer(schoolName),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE8EAED))),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu_rounded, size: 22, color: Color(0xFF111827)),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  const SizedBox(width: 8),
                  Text(_navItems[_selectedIndex].label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, size: 20, color: Color(0xFF9CA3AF)),
                    tooltip: 'Logout',
                    onPressed: () => context.go('/role-selection'),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildPage(p)),
          ],
        ),
      ),
      floatingActionButton: _buildAiFab(),
    );
  }

  Widget _buildDrawer(String schoolName) {
    return Drawer(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
            decoration: const BoxDecoration(color: Color(0xFF1A237E)),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.school_rounded, size: 22, color: Colors.white70),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(schoolName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _navItems.length,
              itemBuilder: (_, i) {
                final item = _navItems[i];
                final selected = i == _selectedIndex;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () { Navigator.pop(context); setState(() => _selectedIndex = i); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(color: selected ? const Color(0xFFF0F4FF) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          Icon(item.icon, size: 20, color: selected ? const Color(0xFF1A237E) : const Color(0xFF6B7280)),
                          const SizedBox(width: 14),
                          Text(item.label, style: TextStyle(fontSize: 14, fontWeight: selected ? FontWeight.w600 : FontWeight.w500, color: selected ? const Color(0xFF1A237E) : const Color(0xFF6B7280))),
                          if (selected) ...[const Spacer(), Container(width: 4, height: 20, decoration: BoxDecoration(color: const Color(0xFF1A237E), borderRadius: BorderRadius.circular(2)))],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          InkWell(
            onTap: () { Navigator.pop(context); context.go('/role-selection'); },
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 20, color: Color(0xFFD32F2F)),
                    SizedBox(width: 14),
                    Text('Logout', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFD32F2F))),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(SchoolAdminProvider p) {
    switch (_selectedIndex) {
      case 0:
        return PageDashboard(studentCount: p.students.length, teacherCount: p.teacherCount, classCount: p.classes.length, subjectCount: p.subjects.length, assignmentCount: p.assignments.length, activeCbtCount: p.cbtExams.where((e) => e['is_published'] == true).length, classes: p.classes, schoolName: p.schoolName, schoolUrl: p.schoolLogoUrl, onNavigate: (i) => setState(() => _selectedIndex = i));
      case 1:
        return PageStudents(students: p.students, onDelete: (id) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete: $id'))); }, onAdd: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddStudentPage(classes: p.classes))).then((_) async { await p.reloadData(); if (mounted) setState(() {}); }), onRefresh: () {});
      case 2:
        return PageTeachers(teachers: p.teachers, onDelete: (id) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete: $id'))); }, onAdd: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTeacherPage())).then((_) async { await p.reloadData(); if (mounted) setState(() {}); }));
      case 3:
        return PageClasses(classes: p.classes, subjects: p.subjects, assignments: p.assignments, teachers: p.teachers, students: p.students, classSubjects: p.classSubjects, onAddClassSubject: (classId, subjectId) => p.addClassSubjectToDb(classId: classId, subjectId: subjectId), onRemoveClassSubject: (csId) => p.removeClassSubjectFromDb(csId), onAddClass: (data) {}, onDeleteClass: (data) {}, onAddSubject: (data) {}, onDeleteSubject: (data) {}, onAddAssignment: (data) {}, onDeleteAssignment: (data) {});
      case 4:
        return PageAcademic(classes: p.classes, academicYears: p.sessions, onYearsUpdated: (years) {});
      case 5:
        return PageResults(classes: p.classes, subjects: p.subjects, classSubjects: p.classSubjects, students: p.students, assignments: p.assignments, scores: p.scores, resultsVisible: true, onSaveScores: (scores) => p.saveScores(scores), onToggleVisibility: (_) {});
      case 6:
        return const PagePublishResults();
      case 7:
        return PageSettings(schoolName: p.schoolName, schoolAddress: '', schoolPhone: '', schoolEmail: '', onUpdate: (name, address, phone, email) {});
      case 8:
        return const PageCredentials();
      case 9:
        return PageFees();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAiFab() {
    final p = context.read<SchoolAdminProvider>();
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: const Color(0xFF1A237E).withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => ChatBotWidget(
                role: 'School Admin',
                apiKey: const String.fromEnvironment('GEMINI_API_KEY'),
                schoolContext: {
                  'schoolName': p.schoolName,
                  'currentSession': p.currentSession,
                  'currentTerm': p.currentTerm,
                  'studentCount': p.students.length,
                  'teacherCount': p.teacherCount,
                  'classCount': p.classes.length,
                  'subjectCount': p.subjects.length,
                  'gradingStandard': p.schoolSettings?['grading_standard'] ?? 'Nigerian',
                  'classList': p.classes.map((c) => {'name': c['name'], 'student_count': c['student_count'], 'tier': c['tier']}).toList(),
                },
              ),
            );
          },
          child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.smart_toy, color: Colors.white, size: 20), SizedBox(width: 8), Text('Ask AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))]),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

ThemeData _buildTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: const Color(0xFF1B2A4A),
    scaffoldBackgroundColor: const Color(0xFFF5F6FA),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1B2A4A),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: Color(0xFF1B2A4A), width: 2),
      ),
      contentPadding:
          EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10))),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
    ),
    dividerTheme:
        DividerThemeData(color: Colors.grey.shade200, thickness: 1),
  );
}

ThemeData _buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: const Color(0xFF1B2A4A),
    scaffoldBackgroundColor: const Color(0xFF121212),
  );
}

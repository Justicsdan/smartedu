import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import 'core/providers/school_admin_provider.dart';
import 'core/super_admin_provider.dart';
import 'core/providers/teacher/teacher_provider.dart';
import 'core/providers/student/student_provider.dart';
import 'core/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) { if (kDebugMode) FlutterError.dumpErrorToConsole(details); };
  PlatformDispatcher.instance.onError = (error, stack) { if (kDebugMode) debugPrint('ASYNC ERROR: $error'); return true; };
  await Supabase.initialize(url: 'https://tcjsmkhmfjigutfhjtem.supabase.co', anonKey: 'sb_publishable_zWDvjhEldcV8eutnlRypGA_LGpOUhkg', debug: kDebugMode);
  try { await Supabase.instance.client.auth.signOut(); } catch (_) {}
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) => SchoolAdminProvider()),
    ChangeNotifierProvider(create: (_) => SuperAdminProvider()),
    ChangeNotifierProvider(create: (_) => TeacherProvider()),
    ChangeNotifierProvider(create: (_) => StudentProvider()),
  ], child: const SmartEduApp()));
}

class SmartEduApp extends StatelessWidget {
  const SmartEduApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'SmartEdu',
      theme: _buildTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
      builder: (context, child) {
        ErrorWidget.builder = (details) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F6FA),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bug_report_outlined, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Something went wrong', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      kDebugMode ? details.exception.toString() : 'An unexpected error occurred',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(onPressed: () => context.go('/'), child: const Text('Go Home')),
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

ThemeData _buildTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: const Color(0xFF1B2A4A),
    scaffoldBackgroundColor: const Color(0xFFF5F6FA),
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1B2A4A), foregroundColor: Colors.white, elevation: 0),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: Color(0xFFE0E0E0))),
      enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: Color(0xFFE0E0E0))),
      focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: Color(0xFF1B2A4A), width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
      ),
    ),
    cardTheme: CardThemeData(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200))),
    dividerTheme: DividerThemeData(color: Colors.grey.shade200, thickness: 1),
  );
}

ThemeData _buildDarkTheme() => ThemeData(useMaterial3: true, brightness: Brightness.dark, colorSchemeSeed: const Color(0xFF1B2A4A), scaffoldBackgroundColor: const Color(0xFF121212));

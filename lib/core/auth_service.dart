// ==========================================
// File: lib/core/auth_service.dart
// ==========================================
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {

  static Map<String, dynamic> _normalizeKeys(Map<String, dynamic> data) {
    final normalized = <String, dynamic>{};
    data.forEach((key, value) {
      final parts = key.split('_');
      if (parts.length > 1) {
        final camelKey = parts[0] + parts.sublist(1).map((part) => part[0].toUpperCase() + part.substring(1)).join();
        normalized[camelKey] = value;
      } else {
        normalized[key] = value;
      }
    });
    return normalized;
  }

  static Future<Map<String, dynamic>?> _loginWithRpc(
    String rpcName,
    Map<String, dynamic> params, {
    bool establishSession = false,
    String? sessionPassword,
  }) async {
    try {
      final res = await Supabase.instance.client
          .rpc(rpcName, params: params)
          .timeout(const Duration(seconds: 15)); // Increased for cold starts

      if (res == null) {
        debugPrint('$rpcName returned null');
        return {'error': 'null_response', 'message': 'Server returned no data.'};
      }

      // CRITICAL DEBUG: Catch if SQL returns bool/list instead of JSON object
      if (res is! Map<String, dynamic>) {
        final errorMsg = 'RPC returned ${res.runtimeType} instead of JSON. Your SQL function must RETURN JSON (e.g., json_build_object). Value: $res';
        debugPrint('$rpcName format error: $errorMsg');
        return {'error': 'invalid_format', 'message': errorMsg};
      }

      final data = _normalizeKeys(res);

      if (data['success'] == true) {
        if (establishSession) {
          final email = data['email'] as String?;
          if (email != null && email.isNotEmpty && sessionPassword != null) {
            try {
              await Supabase.instance.client.auth.signInWithPassword(email: email, password: sessionPassword);
            } catch (e) {
              debugPrint('Auth session link warning: $e'); // Swallowed to match your original flow
            }
          }
        }
        data.remove('success');
        return data;
      }

      // Handle known SQL error states
      if (data['error'] == 'locked_out') {
        return {'role': 'locked_out', 'error': 'locked_out', 'message': data['message'] ?? 'Too many failed attempts.'};
      }
      if (data['error'] == 'deactivated') {
        return {'role': 'school_admin', 'error': 'deactivated', 'message': data['message'] ?? 'Account deactivated.'};
      }

      // If success is not true, print what we actually got
      debugPrint('$rpcName failed. Raw payload: $data');
      return {'error': 'invalid_credentials', 'message': data['message'] ?? 'Invalid username or password.'};

    } on TimeoutException {
      return {'error': 'timeout', 'message': 'Request timed out. Check connection.'};
    } catch (e) {
      debugPrint('$rpcName exception: $e');
      return {'error': 'rpc_exception', 'message': 'Login failed: $e'};
    }
  }

  static Future<Map<String, dynamic>?> loginSuperAdmin(String username, String password) async {
    return _loginWithRpc(
      'rpc_login_super_admin',
      {'p_username': username.trim(), 'p_password': password},
    );
  }

  static Future<Map<String, dynamic>?> loginSchoolAdmin(String username, String password) async {
    return _loginWithRpc(
      'rpc_login_school_admin',
      {'p_username': username.trim(), 'p_password': password},
      establishSession: true,
      sessionPassword: password,
    );
  }

  static Future<Map<String, dynamic>?> loginTeacher(String username, String password) async {
    return _loginWithRpc(
      'rpc_login_teacher',
      {'p_username': username.trim(), 'p_password': password},
      establishSession: true,
      sessionPassword: password,
    );
  }

  static Future<Map<String, dynamic>?> loginStudent(String username, String pin) async {
    return _loginWithRpc(
      'rpc_login_student',
      {'p_username': username.trim(), 'p_pin': pin.trim()},
    );
  }

  static Future<void> logout() async {
    try { await Supabase.instance.client.auth.signOut(); } catch (e) { debugPrint('Auth signOut skipped: $e'); }
  }

  static Future<Map<String, dynamic>> changeSchoolAdminPassword(String adminId, String currentPassword, String newPassword) async {
    try {
      final res = await Supabase.instance.client.rpc('rpc_change_school_admin_password', params: {'p_admin_id': adminId, 'p_current_password': currentPassword, 'p_new_password': newPassword});
      return Map<String, dynamic>.from(res);
    } catch (e) { return {'success': false, 'message': 'Network error.'}; }
  }

  static Future<Map<String, dynamic>> changeTeacherPassword(String teacherId, String currentPassword, String newPassword) async {
    try {
      final res = await Supabase.instance.client.rpc('rpc_change_teacher_password', params: {'p_teacher_id': teacherId, 'p_current_password': currentPassword, 'p_new_password': newPassword});
      return Map<String, dynamic>.from(res);
    } catch (e) { return {'success': false, 'message': 'Network error.'}; }
  }

  static Future<Map<String, dynamic>> changeStudentPin(String studentId, String currentPin, String newPin) async {
    try {
      final res = await Supabase.instance.client.rpc('rpc_change_student_pin', params: {'p_student_id': studentId, 'p_current_pin': currentPin, 'p_new_pin': newPin});
      return Map<String, dynamic>.from(res);
    } catch (e) { return {'success': false, 'message': 'Network error.'}; }
  }

  static Map<String, dynamic> validatePasswordStrength(String password) {
    final errors = <String>[];
    int score = 0;
    if (password.length >= 6) score += 1;
    if (password.length >= 8) score += 1;
    if (password.length >= 12) score += 1;
    if (RegExp(r'[A-Z]').hasMatch(password)) score += 1;
    if (RegExp(r'[a-z]').hasMatch(password)) score += 1;
    if (RegExp(r'[0-9]').hasMatch(password)) score += 1;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score += 1;
    if (password.length < 6) errors.add('Minimum 6 characters');
    if (!RegExp(r'[A-Z]').hasMatch(password)) errors.add('Include uppercase letter');
    if (!RegExp(r'[a-z]').hasMatch(password)) errors.add('Include lowercase letter');
    if (!RegExp(r'[0-9]').hasMatch(password)) errors.add('Include number');
    String strength;
    if (score <= 2) strength = 'Weak'; else if (score <= 4) strength = 'Fair'; else if (score <= 6) strength = 'Strong'; else strength = 'Very Strong';
    return {'valid': errors.isEmpty, 'score': score, 'strength': strength, 'errors': errors};
  }
}

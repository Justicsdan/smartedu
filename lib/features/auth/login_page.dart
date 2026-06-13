import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartedu/core/services/db_proxy.dart';

class LoginPage extends StatefulWidget {
  final String selectedRole;
  const LoginPage({super.key, required this.selectedRole});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _fieldOneController = TextEditingController();
  final _fieldTwoController = TextEditingController();
  bool _isLoading = false;
  bool _obscureTwo = true;
  String? _errorMessage;

  Color get _roleColor {
    switch (widget.selectedRole) {
      case 'Student': return const Color(0xFF2E7D32);
      case 'School Admin': return const Color(0xFF1565C0);
      case 'Teacher': return const Color(0xFFEF6C00);
      case 'Super Admin': return const Color(0xFF6A1B9A);
      default: return const Color(0xFF1E3C72);
    }
  }

  String get _roleTitle => widget.selectedRole;

  String get _fieldOneLabel {
    switch (widget.selectedRole) {
      case 'Student': return 'Admission Number';
      default: return 'Username';
    }
  }

  String get _fieldTwoLabel {
    switch (widget.selectedRole) {
      case 'Student': return 'PIN';
      default: return 'Password';
    }
  }

  IconData get _fieldOneIcon {
    switch (widget.selectedRole) {
      case 'Student': return Icons.badge_outlined;
      default: return Icons.person_outline_rounded;
    }
  }

  bool get _isFieldTwoPassword => widget.selectedRole != 'Student';

  @override
  void dispose() {
    _fieldOneController.dispose();
    _fieldTwoController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      switch (widget.selectedRole) {
        case 'Student': await _loginStudent(); break;
        case 'School Admin': await _loginSchoolAdmin(); break;
        case 'Teacher': await _loginTeacher(); break;
        case 'Super Admin': await _loginSuperAdmin(); break;
      }
    } catch (e) {
      debugPrint('LOGIN ERROR: $e');
      if (mounted) {
        setState(() {
          _errorMessage = _friendlyError(e.toString());
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('Invalid credentials') || raw.contains('not found') || raw.contains('No rows') || raw.contains('empty')) {
      return 'Invalid credentials. Please check and try again.';
    }
    if (raw.contains('deactivated') || raw.contains('not active')) {
      return 'This account has been deactivated. Contact support.';
    }
    if (raw.contains('network') || raw.contains('socket') || raw.contains('Failed to fetch')) {
      return 'Network error. Check your internet connection.';
    }
    return 'Login failed. Please try again.';
  }

  /// RPC helper — calls a PostgreSQL function, returns first row or null.
  /// Handles both List (RETURN QUERY) and single Map (RETURN row) responses.
  Future<Map<String, dynamic>?> _rpcLogin(String functionName, Map<String, dynamic> params) async {
    final response = await Supabase.instance.client.rpc(functionName, params: params);
    if (response == null) return null;
    if (response is List) {
      if (response.isEmpty) return null;
      return response.first as Map<String, dynamic>;
    }
    if (response is Map<String, dynamic>) {
      if (response.isEmpty) return null;
      return response;
    }
    return null;
  }

  // ── Student: direct .eq() query (plain text PINs) ──

  Future<void> _loginStudent() async {
    final admissionNo = _fieldOneController.text.trim();
    final pin = _fieldTwoController.text.trim();

    final response = await Supabase.instance.client
        .from('students')
        .select('id, school_id, first_name, last_name, class_id, is_active')
        .eq('admission_no', admissionNo)
        .eq('pin', pin)
        .maybeSingle();

    if (response == null) throw Exception('Invalid credentials');
    if (response['is_active'] == false) throw Exception('Account deactivated');
    // Bridge: get JWT for migrated providers
    try { await DbProxy.instance.login('student', admissionNo, pin); } catch (_) {}

    if (mounted) {
      context.go('/dashboard/student', extra: {
        'id': response['id'],
        'schoolId': response['school_id'],
        'firstName': response['first_name'],
        'lastName': response['last_name'],
        'classId': response['class_id'],
        'admissionNo': admissionNo,
      });
    }
  }

  // ── School Admin: RPC (bcrypt or plain text) ──

  Future<void> _loginSchoolAdmin() async {
    final username = _fieldOneController.text.trim();
    final password = _fieldTwoController.text.trim();

    final r = await _rpcLogin('login_school_admin', {
      'p_username': username,
      'p_password': password,
    });
    if (r == null) throw Exception('Invalid credentials');

    final schoolId = r['id'].toString();
    if (mounted) {
      context.go('/dashboard/schooladmin', extra: {
        'id': schoolId,
        'schoolId': schoolId,
        'schoolName': r['name'],
        'logoUrl': r['logo_url'],
      });
    }
  }

  // ── Teacher: RPC (bcrypt or plain text) ──

  Future<void> _loginTeacher() async {
    final username = _fieldOneController.text.trim();
    final password = _fieldTwoController.text.trim();

    final r = await _rpcLogin('login_teacher', {
      'p_username': username,
      'p_password': password,
    });
    if (r == null) throw Exception('Invalid credentials');

    if (mounted) {
      context.go('/dashboard/teacher', extra: {
        'id': r['id'],
        'schoolId': r['school_id'],
        'firstName': r['first_name'],
        'lastName': r['last_name'],
        'passportUrl': r['passport_url'],
      });
    }
  }

  // ── Super Admin: RPC (bcrypt or plain text) ──

  Future<void> _loginSuperAdmin() async {
    final username = _fieldOneController.text.trim();
    final password = _fieldTwoController.text.trim();

    final r = await _rpcLogin('login_super_admin', {
      'p_username': username,
      'p_password': password,
    });
    if (r == null) throw Exception('Invalid credentials');

    if (mounted) {
      context.go('/dashboard/superadmin', extra: {
        'id': r['id'],
        'name': r['name'],
        'username': username,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E40AF)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => context.go('/role-selection'),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F6FA),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF64748B)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: _roleColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            widget.selectedRole == 'Student'
                                ? Icons.school_rounded
                                : widget.selectedRole == 'School Admin'
                                    ? Icons.admin_panel_settings_rounded
                                    : widget.selectedRole == 'Teacher'
                                        ? Icons.person_outline_rounded
                                        : Icons.shield_outlined,
                            size: 32,
                            color: _roleColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          _roleTitle,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Center(
                        child: Text(
                          'Enter your credentials to continue',
                          style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildInputField(
                        controller: _fieldOneController,
                        label: _fieldOneLabel,
                        icon: _fieldOneIcon,
                        obscure: false,
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        controller: _fieldTwoController,
                        label: _fieldTwoLabel,
                        icon: Icons.lock_outline,
                        obscure: _isFieldTwoPassword,
                        suffix: _isFieldTwoPassword
                            ? IconButton(
                                icon: Icon(
                                  _obscureTwo ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 20,
                                  color: const Color(0xFF9CA3AF),
                                ),
                                onPressed: () => setState(() => _obscureTwo = !_obscureTwo),
                              )
                            : null,
                      ),
                      const SizedBox(height: 8),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, size: 18, color: Color(0xFFDC2626)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(fontSize: 13, color: Color(0xFFDC2626), height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _roleColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : const Text('Sign In', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscure,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure && _obscureTwo,
      validator: (value) {
        if (value == null || value.trim().isEmpty) return '$label is required';
        return null;
      },
      style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: Icon(icon, size: 20, color: const Color(0xFF9CA3AF)),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 44),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _roleColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFFECACA)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      ),
    );
  }
}

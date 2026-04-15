// ==========================================
// File: lib/features/dashboard/super_admin/add_school_page.dart
// ==========================================
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddSchoolPage extends StatefulWidget {
  const AddSchoolPage({super.key});

  @override
  State<AddSchoolPage> createState() => _AddSchoolPageState();
}

class _AddSchoolPageState extends State<AddSchoolPage> {
  final _formKey = GlobalKey<FormState>();

  final _schoolNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _mottoController = TextEditingController();

  final _adminUsernameController = TextEditingController();
  final _adminPasswordController = TextEditingController();

  String? _selectedSchoolType;
  File? _logoFile;
  bool _isUploading = false;
  bool _obscurePassword = true;
  int _currentStep = 0;

  final List<String> _schoolTypes = [
    'Primary',
    'Secondary',
    'Both (Primary & Secondary)',
  ];

  @override
  void dispose() {
    _schoolNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _mottoController.dispose();
    _adminUsernameController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  String _mapSchoolType(String? displayType) {
    switch (displayType) {
      case 'Primary':
        return 'primary';
      case 'Secondary':
        return 'secondary';
      case 'Both (Primary & Secondary)':
        return 'mixed';
      default:
        return 'secondary';
    }
  }

  String _getTypeDescription(String type) {
    switch (type) {
      case 'Primary':
        return 'Primary school — suitable for Nursery to Primary 6';
      case 'Secondary':
        return 'Secondary school — suitable for JSS 1 to SSS 3';
      case 'Both (Primary & Secondary)':
        return 'Combined school — covers both primary and secondary levels';
      default:
        return '';
    }
  }

  String _getDefaultGrading(String? displayType) {
    switch (displayType) {
      case 'Primary':
        return 'PRIMARY';
      case 'Secondary':
        return 'WAEC';
      case 'Both (Primary & Secondary)':
        return 'WAEC';
      default:
        return 'WAEC';
    }
  }

  Future<bool> _adminUsernameExists(String username) async {
    final res = await Supabase.instance.client
        .from('schools')
        .select('id')
        .eq('admin_username', username.toLowerCase())
        .limit(1);
    return res.isNotEmpty;
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    if (value.trim().length < 3) return 'Min 3 characters';
    if (value.trim().contains(' ')) return 'No spaces allowed';
    if (RegExp(r'[^\w]').hasMatch(value.trim())) return 'Only letters, numbers, underscores';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    if (value.length < 6) return 'Min 6 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Include at least one uppercase letter';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Include at least one number';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!RegExp(r'^[\w\.\-\+]+@[\w\.\-]+\.[a-zA-Z]{2,}$').hasMatch(value.trim())) {
      return 'Invalid email format';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final cleaned = value.trim().replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
    if (cleaned.length < 7 || cleaned.length > 15) return 'Invalid phone (7-15 digits)';
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) return 'Phone must contain only digits';
    return null;
  }

  Future<void> _pickLogo() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, maxHeight: 512, maxWidth: 512, imageQuality: 80);
      if (picked != null) setState(() => _logoFile = File(picked.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking image: $e'), backgroundColor: const Color(0xFFD32F2F), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
      }
    }
  }

  Future<void> _pickLogoCamera() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.camera, maxHeight: 512, maxWidth: 512, imageQuality: 80);
      if (picked != null) setState(() => _logoFile = File(picked.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFD32F2F), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
      }
    }
  }

  Future<String?> _uploadLogo(String schoolId) async {
    if (_logoFile == null) return null;
    try {
      final safeName = _schoolNameController.text.trim().replaceAll(' ', '_').toLowerCase();
      final path = '$schoolId/school_logo_${safeName}.jpg';
      await Supabase.instance.client.storage.from('passports').upload(path, _logoFile!, fileOptions: const FileOptions(upsert: true));
      return Supabase.instance.client.storage.from('passports').getPublicUrl(path);
    } catch (e) {
      debugPrint('Logo upload error: $e');
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSchoolType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a school type'), backgroundColor: Color(0xFFE65100), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
      return;
    }

    final username = _adminUsernameController.text.trim().toLowerCase();
    setState(() => _isUploading = true);
    try {
      final exists = await _adminUsernameExists(username);
      if (exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Row(children: [const Icon(Icons.warning_amber_rounded, color: Colors.white), const SizedBox(width: 10), Expanded(child: Text('Admin username "$username" already exists. Use a different username.'))]),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ));
        }
        return;
      }
    } catch (e) {
      debugPrint('USERNAME CHECK ERR: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.domain_add_rounded, size: 22, color: Color(0xFF1A237E))),
            const SizedBox(width: 12),
            const Text("Create School?", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFF111827), letterSpacing: -0.3)),
          ],
        ),
        content: Text('Create "${_schoolNameController.text.trim()}" with admin username "$username"?', style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)), child: const Text("Create", style: TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _isUploading = true);

    try {
      final dbType = _mapSchoolType(_selectedSchoolType);
      final defaultGrading = _getDefaultGrading(_selectedSchoolType);

      final schoolResponse = await Supabase.instance.client.from('schools').insert({
        'name': _schoolNameController.text.trim(),
        'location': _addressController.text.trim(),
        'whatsapp': _whatsappController.text.trim(),
        'school_type': dbType,
        'is_active': true,
        'has_paid_current_term': false,
        'admin_username': username,
        'admin_password': _adminPasswordController.text.trim(),
      }).select().single();

      final schoolId = schoolResponse['id'] as String;

      final logoUrl = await _uploadLogo(schoolId);
      if (logoUrl != null) {
        await Supabase.instance.client.from('schools').update({'logo_url': logoUrl}).eq('id', schoolId);
      }

      await Supabase.instance.client.from('school_settings').insert({
        'school_id': schoolId,
        'exam_template': defaultGrading,
        'current_session': '',
        'current_term': '',
        'grading_system': _getDefaultGradingSystem(defaultGrading),
        'assessment_types': _getDefaultAssessmentTypes(defaultGrading),
        'subject_max_score': 100,
        'show_position': true,
        'show_grade_only': false,
        'date_format': 'dd/MM/yyyy',
        'timezone': 'UTC',
        'principal_name': '',
        'motto': _mottoController.text.trim(),
      });

      if (_mottoController.text.trim().isNotEmpty) {
        await Supabase.instance.client.from('schools').update({'motto': _mottoController.text.trim()}).eq('id', schoolId);
      }

      final locationUpdates = <String, dynamic>{};
      if (_emailController.text.trim().isNotEmpty) locationUpdates['email'] = _emailController.text.trim();
      if (_countryController.text.trim().isNotEmpty) locationUpdates['country'] = _countryController.text.trim();
      if (_stateController.text.trim().isNotEmpty) locationUpdates['state'] = _stateController.text.trim();
      if (_cityController.text.trim().isNotEmpty) locationUpdates['city'] = _cityController.text.trim();
      if (locationUpdates.isNotEmpty) {
        await Supabase.instance.client.from('schools').update(locationUpdates).eq('id', schoolId);
      }

      if (mounted) _showSuccessDialog(schoolId);
    } on PostgrestException catch (e) {
      if (mounted) {
        String msg = 'Error creating school';
        if (e.code == '23505') {
          msg = 'Admin username "$username" already exists. Use a different username.';
        } else if (e.message?.contains('admin_username') == true) {
          msg = 'Admin username already taken.';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: const Color(0xFFD32F2F), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFD32F2F), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  List<Map<String, dynamic>> _getDefaultGradingSystem(String template) {
    switch (template) {
      case 'PRIMARY':
        return [
          {"min": 90, "max": 100, "grade": "5", "remark": "Excellent"},
          {"min": 80, "max": 89, "grade": "4", "remark": "Very Good"},
          {"min": 70, "max": 79, "grade": "3", "remark": "Good"},
          {"min": 50, "max": 69, "grade": "2", "remark": "Fair"},
          {"min": 0, "max": 49, "grade": "1", "remark": "Poor"},
        ];
      case 'WAEC':
      default:
        return [
          {"min": 75, "max": 100, "grade": "A1", "remark": "Excellent"},
          {"min": 70, "max": 74, "grade": "B2", "remark": "Very Good"},
          {"min": 65, "max": 69, "grade": "B3", "remark": "Good"},
          {"min": 60, "max": 64, "grade": "C4", "remark": "Credit"},
          {"min": 55, "max": 59, "grade": "C5", "remark": "Credit"},
          {"min": 50, "max": 54, "grade": "C6", "remark": "Credit"},
          {"min": 45, "max": 49, "grade": "D7", "remark": "Pass"},
          {"min": 40, "max": 44, "grade": "E8", "remark": "Pass"},
          {"min": 0, "max": 39, "grade": "F9", "remark": "Fail"},
        ];
    }
  }

  List<Map<String, dynamic>> _getDefaultAssessmentTypes(String template) {
    switch (template) {
      case 'PRIMARY':
        return [
          {"id": "ca1", "name": "CA1", "max": 20},
          {"id": "ca2", "name": "CA2", "max": 20},
          {"id": "exam", "name": "Exam", "max": 60},
        ];
      case 'WAEC':
      default:
        return [
          {"id": "ca1", "name": "CA1", "max": 10},
          {"id": "ca2", "name": "CA2", "max": 10},
          {"id": "assignment", "name": "Assignment", "max": 10},
          {"id": "midterm", "name": "Mid-term", "max": 20},
          {"id": "exam", "name": "Exam", "max": 50},
        ];
    }
  }

  void _showSuccessDialog(String schoolId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.check_circle_rounded, size: 36, color: Color(0xFF2E7D32)),
            ),
            const SizedBox(height: 18),
            const Text('School Created Successfully!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827), letterSpacing: -0.3)),
            const SizedBox(height: 4),
            Text(_schoolNameController.text.trim(), style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8EAF6))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      const Text("Username", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(_adminUsernameController.text.trim().toLowerCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A237E))),
                  const SizedBox(height: 14),
                  const Divider(color: Color(0xFFE8EAF6)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      const Text("Password", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(_adminPasswordController.text.trim(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A237E))),
                  const SizedBox(height: 14),
                  const Divider(color: Color(0xFFE8EAF6)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(Icons.fingerprint_rounded, size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 6),
                      const Text("School ID (for support)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(schoolId, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.grey.shade600)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('Share these credentials with the school admin.\nThey can change their password after first login.', style: TextStyle(fontSize: 12, color: Colors.grey.shade400, height: 1.5), textAlign: TextAlign.center),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            child: const Text("Done", style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Column(
        children: [
          // ── Header ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)), onPressed: () => Navigator.pop(context)),
                    const SizedBox(width: 8),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.domain_add_rounded, size: 20, color: Color(0xFF1A237E)),
                    ),
                    const SizedBox(width: 12),
                    const Text('Add New School', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF111827), letterSpacing: -0.5)),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),

          // ── Stepper ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Row(
              children: [
                _stepIndicator(0, 'School Info', Icons.domain_rounded),
                _stepLine(0),
                _stepIndicator(1, 'Admin Credentials', Icons.lock_rounded),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),

          // ── Content ──
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 100),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _currentStep == 0 ? _buildStepOne() : _buildStepTwo(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stepper Widgets ──

  Widget _stepIndicator(int step, String label, IconData icon) {
    final active = _currentStep >= step;
    final done = _currentStep > step;
    final color = done ? const Color(0xFF2E7D32) : (active ? const Color(0xFF1A237E) : Colors.grey.shade400);
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (step < _currentStep) setState(() => _currentStep = step);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: done ? const Color(0xFFE8F5E9) : (active ? const Color(0xFFF0F4FF) : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(8),
                border: done ? null : Border.all(color: active ? const Color(0xFFE8EAF6) : Colors.grey.shade200),
              ),
              child: done ? const Icon(Icons.check_rounded, size: 18, color: Color(0xFF2E7D32)) : Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(label, style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.normal, color: active ? const Color(0xFF111827) : Colors.grey.shade400), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepLine(int afterStep) {
    final done = _currentStep > afterStep;
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: done ? const Color(0xFF2E7D32) : Colors.grey.shade200, borderRadius: BorderRadius.circular(1)),
    );
  }

  // ── Step 1: School Info ──

  Widget _buildStepOne() {
    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Logo Upload ──
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickLogo,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFBFC),
                    borderRadius: BorderRadius.circular(55),
                    border: Border.all(color: _logoFile != null ? const Color(0xFF1A237E) : const Color(0xFFE8EAED), width: 2),
                  ),
                  child: _logoFile != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(55), child: Image.file(_logoFile!, fit: BoxFit.cover))
                      : Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt_rounded, size: 30, color: Colors.grey.shade400), const SizedBox(height: 6), Text("Upload Logo", style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500))]),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _logoAction(Icons.photo_library_rounded, 'Gallery', const Color(0xFF1A237E), _pickLogo),
                  const SizedBox(width: 4),
                  _logoAction(Icons.camera_alt_rounded, 'Camera', const Color(0xFF1A237E), _pickLogoCamera),
                  if (_logoFile != null) ...[
                    const SizedBox(width: 4),
                    _logoAction(Icons.delete_outline_rounded, 'Remove', const Color(0xFFD32F2F), () => setState(() => _logoFile = null)),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── School Fields ──
        _sectionHeader('School Details', Icons.domain_rounded, const Color(0xFFF0F4FF), const Color(0xFF1A237E)),
        const SizedBox(height: 14),
        _textField('School Name *', _schoolNameController, validator: (v) => _validateRequired(v, 'School name')),
        _dropdownField('School Type *', _selectedSchoolType, _schoolTypes, (val) => setState(() => _selectedSchoolType = val)),

        if (_selectedSchoolType != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE8EAF6))),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: const Color(0xFF1A237E).withOpacity(0.7)),
                const SizedBox(width: 8),
                Expanded(child: Text('${_getTypeDescription(_selectedSchoolType!)} — Default grading: ${_getDefaultGrading(_selectedSchoolType)}', style: TextStyle(color: const Color(0xFF1A237E).withOpacity(0.8), fontSize: 13))),
              ],
            ),
          ),

        _textField('Address / Location *', _addressController, validator: (v) => _validateRequired(v, 'Address')),
        Row(children: [Expanded(child: _textField('City', _cityController)), const SizedBox(width: 12), Expanded(child: _textField('State', _stateController))]),
        _textField('Country', _countryController, hintText: 'e.g. Nigeria, Ghana'),
        _textField('WhatsApp / Phone *', _whatsappController, keyboardType: TextInputType.phone, validator: (v) => _validateRequired(v, 'Phone'), hintText: '+2348012345678'),
        _textField('School Email', _emailController, keyboardType: TextInputType.emailAddress, validator: _validateEmail, hintText: 'info@schoolname.com'),
        _textField('School Motto', _mottoController, hintText: 'Excellence in Character and Learning'),

        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate() && _selectedSchoolType != null) {
                setState(() => _currentStep = 1);
              } else if (_selectedSchoolType == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a school type'), backgroundColor: Color(0xFFE65100), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Continue to Admin Credentials', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)), SizedBox(width: 8), Icon(Icons.arrow_forward_rounded, size: 18)]),
          ),
        ),
      ],
    );
  }

  // ── Step 2: Admin Credentials ──

  Widget _buildStepTwo() {
    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('School Admin Credentials', Icons.lock_rounded, const Color(0xFFFFF3E0), const Color(0xFFE65100)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFFE0B2))),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: const Color(0xFFE65100).withOpacity(0.8)),
              const SizedBox(width: 10),
              Expanded(child: Text('The admin will use these credentials to log in and manage their school independently. Each admin username must be unique across all schools.', style: TextStyle(color: const Color(0xFFE65100).withOpacity(0.85), fontSize: 13, height: 1.5))),
            ],
          ),
        ),
        _textField('Admin Username *', _adminUsernameController, validator: _validateUsername, hintText: 'Lowercase, no spaces (e.g. graceville_admin)'),
        _textField(
          'Admin Password *',
          _adminPasswordController,
          validator: _validatePassword,
          isPassword: true,
          hintText: 'Min 6 chars, include uppercase & number',
          suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20, color: Colors.grey.shade500), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
        ),

        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep = 0),
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF1A237E), side: const BorderSide(color: Color(0xFF1A237E)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.arrow_back_rounded, size: 18), SizedBox(width: 8), Text('Back', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14))]),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white, elevation: 0, disabledBackgroundColor: Colors.grey.shade300, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: _isUploading
                      ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)), SizedBox(width: 10), Text('Creating...', style: TextStyle(fontSize: 14))])
                      : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check_rounded, size: 18), SizedBox(width: 8), Text('Create School & Admin', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14))]),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── UI Helpers ──

  Widget _sectionHeader(String title, IconData icon, Color bgColor, Color iconColor) {
    return Row(
      children: [
        Container(width: 32, height: 32, decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: iconColor)),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
      ],
    );
  }

  Widget _logoAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: color), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color))]),
        ),
      ),
    );
  }

  Widget _textField(String label, TextEditingController controller, {TextInputType? keyboardType, String? Function(String?)? validator, bool isPassword = false, String? hintText, Widget? suffixIcon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        obscureText: isPassword ? _obscurePassword : false,
        textCapitalization: keyboardType == TextInputType.text ? TextCapitalization.words : TextCapitalization.none,
        style: const TextStyle(fontSize: 15, color: Color(0xFF111827)),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          labelStyle: TextStyle(color: Colors.grey.shade600),
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          border: const OutlineInputBorder(),
          enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFE0E0E0))),
          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF1A237E), width: 1.5)),
          errorBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFD32F2F))),
          focusedErrorBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFD32F2F))),
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          counterText: '',
        ),
      ),
    );
  }

  Widget _dropdownField(String label, String? currentValue, List<String> items, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: currentValue,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600),
          border: const OutlineInputBorder(),
          enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFE0E0E0))),
          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF1A237E), width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        ),
        items: items.map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 14, color: Color(0xFF111827)))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

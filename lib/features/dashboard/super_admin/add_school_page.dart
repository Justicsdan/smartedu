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

  // School fields
  final _schoolNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _mottoController = TextEditingController();

  // Admin fields
  final _adminUsernameController = TextEditingController();
  final _adminPasswordController = TextEditingController();

  String? _selectedSchoolType;
  File? _logoFile;
  bool _isUploading = false;
  bool _obscurePassword = true;

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

  // =========================================================
  // TYPE MAPPING
  // =========================================================

  /// Map display label to DB value.
  String _mapSchoolType(String? displayType) {
    switch (displayType) {
      case 'Primary': return 'primary';
      case 'Secondary': return 'secondary';
      case 'Both (Primary & Secondary)': return 'mixed';
      default: return 'secondary';
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
      case 'Primary': return 'PRIMARY';
      case 'Secondary': return 'WAEC';
      case 'Both (Primary & Secondary)': return 'WAEC';
      default: return 'WAEC';
    }
  }

  // =========================================================
  // VALIDATION
  // =========================================================

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
    if (value == null || value.trim().isEmpty) return null; // Optional
    if (!RegExp(r'^[\w\.\-\+]+@[\w\.\-]+\.[a-zA-Z]{2,}$').hasMatch(value.trim())) {
      return 'Invalid email format';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Optional
    final cleaned = value.trim().replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
    if (cleaned.length < 7 || cleaned.length > 15) return 'Invalid phone (7-15 digits)';
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) return 'Phone must contain only digits';
    return null;
  }

  // =========================================================
  // IMAGE PICKER
  // =========================================================

  Future<void> _pickLogo() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxHeight: 512,
        maxWidth: 512,
        imageQuality: 80,
      );
      if (picked != null) {
        setState(() => _logoFile = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickLogoCamera() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        maxHeight: 512,
        maxWidth: 512,
        imageQuality: 80,
      );
      if (picked != null) {
        setState(() => _logoFile = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // =========================================================
  // LOGO UPLOAD
  // Uses 'passports' bucket (the one created in schema).
  // Schools stored in: {schoolId}/school_logo.jpg
  // =========================================================

  Future<String?> _uploadLogo(String schoolId) async {
    if (_logoFile == null) return null;

    try {
      final safeName = _schoolNameController.text.trim().replaceAll(' ', '_').toLowerCase();
      final path = '$schoolId/school_logo_${safeName}.jpg';

      await Supabase.instance.client.storage.from('passports').upload(
        path,
        _logoFile!,
        fileOptions: const FileOptions(upsert: true),
      );

      return Supabase.instance.client.storage.from('passports').getPublicUrl(path);
    } catch (e) {
      print('Logo upload error: $e');
      // Continue without logo rather than fail the whole creation
      return null;
    }
  }

  // =========================================================
  // SUBMIT
  // =========================================================

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSchoolType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a school type'), backgroundColor: Colors.orange),
      );
      return;
    }

    // Confirm
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create School?'),
        content: Text('Create "${_schoolNameController.text.trim()}" with admin username "${_adminUsernameController.text.trim()}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3C72)),
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isUploading = true);

    try {
      final dbType = _mapSchoolType(_selectedSchoolType);
      final defaultGrading = _getDefaultGrading(_selectedSchoolType);

      // 1. Insert school (admin_username and admin_password stored directly in schools table per schema)
      final schoolResponse = await Supabase.instance.client
          .from('schools')
          .insert({
            'name': _schoolNameController.text.trim(),
            'location': _addressController.text.trim(),
            'whatsapp': _whatsappController.text.trim(),
            'school_type': dbType,
            'is_active': true,
            'has_paid_current_term': false,
            'admin_username': _adminUsernameController.text.trim().toLowerCase(),
            'admin_password': _adminPasswordController.text.trim(),
          })
          .select()
          .single();

      final schoolId = schoolResponse['id'] as String;

      // 2. Upload logo AFTER getting schoolId for tenant-isolated path
      final logoUrl = await _uploadLogo(schoolId);
      if (logoUrl != null) {
        await Supabase.instance.client
            .from('schools')
            .update({'logo_url': logoUrl})
            .eq('id', schoolId);
      }

      // 3. Create school_settings row with defaults
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

      // 4. Update motto in schools table too (if provided)
      if (_mottoController.text.trim().isNotEmpty) {
        await Supabase.instance.client
            .from('schools')
            .update({'motto': _mottoController.text.trim()})
            .eq('id', schoolId);
      }

      // 5. Update email/country/state/city in schools table
      final locationUpdates = <String, dynamic>{};
      if (_emailController.text.trim().isNotEmpty) locationUpdates['email'] = _emailController.text.trim();
      if (_countryController.text.trim().isNotEmpty) locationUpdates['country'] = _countryController.text.trim();
      if (_stateController.text.trim().isNotEmpty) locationUpdates['state'] = _stateController.text.trim();
      if (_cityController.text.trim().isNotEmpty) locationUpdates['city'] = _cityController.text.trim();
      if (locationUpdates.isNotEmpty) {
        await Supabase.instance.client
            .from('schools')
            .update(locationUpdates)
            .eq('id', schoolId);
      }

      if (mounted) {
        _showSuccessDialog(schoolId);
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        String msg = 'Error creating school';
        if (e.code == '23505') {
          msg = 'Admin username "${_adminUsernameController.text.trim()}" already exists. Use a different username.';
        } else if (e.message?.contains('admin_username') == true) {
          msg = 'Admin username already taken.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  /// Get default grading system JSONB for template.
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

  /// Get default assessment types JSONB for template.
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

  // =========================================================
  // SUCCESS DIALOG
  // =========================================================

  void _showSuccessDialog(String schoolId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'School Created Successfully!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              _schoolNameController.text.trim(),
              style: const TextStyle(fontSize: 15, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3C72).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E3C72).withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'School Admin Login Credentials:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3C72), fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Username', _adminUsernameController.text.trim().toLowerCase()),
                  _buildInfoRow('Password', _adminPasswordController.text.trim()),
                  const Divider(height: 24),
                  const Text(
                    'School ID (for support):',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    schoolId,
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Share the credentials with the school admin.\nThey can change their password after first login.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF1E3C72)),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3C72)),
            child: const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E3C72)),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                value,
                style: const TextStyle(fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New School'),
        backgroundColor: const Color(0xFF1E3C72),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── SCHOOL DETAILS ──
              _buildSectionHeader('School Details'),
              const SizedBox(height: 8),

              // Logo Picker
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickLogo,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _logoFile != null ? const Color(0xFF1E3C72) : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: _logoFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.file(_logoFile!, fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey.shade500),
                                  const SizedBox(height: 4),
                                  Text('Upload Logo', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton.icon(
                          onPressed: _pickLogo,
                          icon: const Icon(Icons.photo_library, size: 14),
                          label: const Text('Gallery', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(foregroundColor: const Color(0xFF1E3C72), padding: const EdgeInsets.symmetric(horizontal: 8)),
                        ),
                        TextButton.icon(
                          onPressed: _pickLogoCamera,
                          icon: const Icon(Icons.camera_alt, size: 14),
                          label: const Text('Camera', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(foregroundColor: const Color(0xFF1E3C72), padding: const EdgeInsets.symmetric(horizontal: 8)),
                        ),
                        if (_logoFile != null)
                          TextButton.icon(
                            onPressed: () => setState(() => _logoFile = null),
                            icon: const Icon(Icons.delete_outline, size: 14),
                            label: const Text('Remove', style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(foregroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 8)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              _buildTextField('School Name *', _schoolNameController,
                  validator: (v) => _validateRequired(v, 'School name')),
              _buildDropdown(
                'School Type *',
                _selectedSchoolType,
                _schoolTypes,
                (val) => setState(() => _selectedSchoolType = val),
              ),

              // Type description
              if (_selectedSchoolType != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3C72).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1E3C72).withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.school, size: 20, color: Color(0xFF1E3C72)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_getTypeDescription(_selectedSchoolType!)} — Default grading: ${_getDefaultGrading(_selectedSchoolType)}',
                          style: const TextStyle(color: Color(0xFF1E3C72), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              _buildTextField('Address / Location *', _addressController,
                  validator: (v) => _validateRequired(v, 'Address')),

              // Global location fields
              Row(
                children: [
                  Expanded(child: _buildTextField('City', _cityController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('State', _stateController)),
                ],
              ),
              _buildTextField('Country', _cityController, hintText: 'e.g. Nigeria, Ghana, Kenya'),

              _buildTextField('WhatsApp / Phone *', _whatsappController,
                  keyboardType: TextInputType.phone,
                  validator: (v) => _validateRequired(v, 'Phone'),
                  hintText: 'e.g. +2348012345678'),
              _buildTextField('School Email', _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  hintText: 'e.g. info@schoolname.com'),
              _buildTextField('School Motto', _mottoController,
                  hintText: 'e.g. Excellence in Character and Learning'),

              const SizedBox(height: 28),

              // ── ADMIN CREDENTIALS ──
              _buildSectionHeader('School Admin Credentials'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The admin will use these credentials to log in and manage their school independently.',
                        style: TextStyle(color: Colors.orange.shade700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              _buildTextField('Admin Username *', _adminUsernameController,
                  validator: _validateUsername,
                  hintText: 'Lowercase, no spaces (e.g. graceville_admin)'),
              _buildTextField(
                'Admin Password *',
                _adminPasswordController,
                validator: _validatePassword,
                isPassword: true,
                hintText: 'Min 6 chars, include uppercase & number',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),

              const SizedBox(height: 32),

              // ── SUBMIT ──
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3C72),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: _isUploading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)),
                            SizedBox(width: 12),
                            Text('Creating School...', style: TextStyle(fontSize: 16)),
                          ],
                        )
                      : const Text('Create School & Admin Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // UI HELPERS
  // =========================================================

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E3C72)),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool isPassword = false,
    String? hintText,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        obscureText: isPassword ? _obscurePassword : false,
        textCapitalization: keyboardType == TextInputType.text ? TextCapitalization.words : TextCapitalization.none,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          border: const OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF1E3C72), width: 2),
          ),
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          counterText: '',
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String? currentValue,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: currentValue,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF1E3C72), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        items: items.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

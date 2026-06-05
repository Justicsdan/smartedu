// ==========================================
// File: lib/features/dashboard/school_admin/add_teacher_page.dart
// ==========================================
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smartedu/core/providers/school_admin_provider.dart';

class AddTeacherPage extends StatefulWidget {
  const AddTeacherPage({super.key});

  @override
  State<AddTeacherPage> createState() => _AddTeacherPageState();
}

class _AddTeacherPageState extends State<AddTeacherPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _data = {};
  bool _isUploading = false;

  Uint8List? _photoBytes;
  String _photoFileName = '';
  bool _isPhotoUploading = false;

  void _snack(String message, {bool success = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor:
            success ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.only(
            bottom: 24, left: 16, right: 16),
      ),
    );
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    if (value.trim().length < 2) return 'Min 2 characters';
    if (RegExp(r'[0-9]').hasMatch(value.trim())) return 'No numbers';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!RegExp(r'^[\w\.\-\+]+@[\w\.\-]+\.\w+$')
        .hasMatch(value.trim())) {
      return 'Invalid email';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final cleaned =
        value.trim().replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
    if (cleaned.length < 7 || cleaned.length > 15) return 'Invalid';
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) return 'Digits only';
    return null;
  }

  String? _validateDropdown(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  Future<bool> _staffIdExists(
      String staffId, String schoolId) async {
    final res = await Supabase.instance.client
        .from('teachers')
        .select('id')
        .eq('school_id', schoolId)
        .eq('staff_id', staffId)
        .limit(1);
    return res.isNotEmpty;
  }

  Future<void> _showPhotoOptions() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.photo_camera_rounded,
                      size: 20,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Upload Photo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Gallery
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFBFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8EAED)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.photo_library_rounded,
                        size: 20,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose from Gallery',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        Text(
                          'Pick an existing photo',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Camera
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFBFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8EAED)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        size: 20,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Take a Photo',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        Text(
                          'Use your camera',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Remove
            if (_photoBytes != null) ...[
              const SizedBox(height: 8),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _photoBytes = null;
                    _photoFileName = '';
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Remove Photo',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                          Text(
                            'Remove selected photo',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        _photoBytes = bytes;
        _photoFileName = picked.name;
      });
    } catch (e) {
      debugPrint('Image pick error: $e');
      _snack('Could not pick image', success: false);
    }
  }

  Future<String?> _uploadPhoto(String teacherId) async {
    if (_photoBytes == null || _photoBytes!.isEmpty) return null;
    setState(() => _isPhotoUploading = true);
    try {
      final provider = context.read<SchoolAdminProvider>();
      final schoolId = provider.schoolId;
      if (schoolId.isEmpty || teacherId.isEmpty) return null;
      final ext = _photoFileName.split('.').last.toLowerCase();
      final safeExt =
          (ext.length <= 5 && RegExp(r'^[a-z]+$').hasMatch(ext))
              ? ext
              : 'jpg';
      final path = 'teachers/$schoolId/$teacherId.$safeExt';
      final supabase = Supabase.instance.client;
      await supabase.storage.from('passports').upload(
            path,
            _photoBytes!,
            fileOptions: const FileOptions(upsert: true),
          );
      final publicUrl =
          supabase.storage.from('passports').getPublicUrl(path);
      final cleanUrl = publicUrl.split('?').first;
      return cleanUrl;
    } catch (e) {
      debugPrint('Photo upload error: $e');
      _snack('Photo upload failed', success: false);
      return null;
    } finally {
      if (mounted) setState(() => _isPhotoUploading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final firstName = (_data['first_name'] ?? '').toString().trim();
    final lastName = (_data['last_name'] ?? '').toString().trim();
    final staffId = (_data['staff_id'] ?? '').toString().trim();

    setState(() => _isUploading = true);
    try {
      final provider = context.read<SchoolAdminProvider>();
      final schoolId = provider.schoolId;
      if (schoolId.isEmpty) {
        _snack('School ID missing. Log out and back in.',
            success: false);
        return;
      }

      final exists = await _staffIdExists(staffId, schoolId);
      if (exists) {
        _snack('Staff ID "$staffId" already exists.',
            success: false);
        return;
      }
    } catch (e) {
      debugPrint('DUP CHECK ERR: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.person_add_rounded,
                    size: 24, color: Color(0xFF1A237E)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Confirm Addition',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add $firstName $lastName ($staffId)?',
                style: TextStyle(
                    fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Add Teacher',
                          style: TextStyle(
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true) return;

    setState(() => _isUploading = true);
    try {
      final provider = context.read<SchoolAdminProvider>();
      final schoolId = provider.schoolId;
      if (schoolId.isEmpty) {
        _snack('School ID missing.', success: false);
        return;
      }

      _data['school_id'] = schoolId;
      _data['passport_url'] = '';
      _data['is_active'] = true;

      final result = await Supabase.instance.client
          .from('teachers')
          .insert([_data])
          .select('id')
          .single();
      final teacherId = result['id'] as String;
      debugPrint('TEACHER INSERT SUCCESS! ID: $teacherId');

      if (_photoBytes != null) {
        final photoUrl = await _uploadPhoto(teacherId);
        if (photoUrl != null && photoUrl.isNotEmpty) {
          await Supabase.instance.client
              .from('teachers')
              .update({'passport_url': photoUrl})
              .eq('id', teacherId);
        }
      }

      if (mounted) {
        _snack('Teacher added successfully!');
        Navigator.pop(context, _data);
      }
    } catch (e) {
      debugPrint('TEACHER SAVE ERROR: $e');
      if (mounted) {
        final msg = e.toString();
        String display = msg;
        if (msg.contains('duplicate') ||
            msg.contains('unique') ||
            msg.contains('staff_id') ||
            msg.contains('username')) {
          display =
              'A teacher with this Staff ID or username already exists.';
        }
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SelectableText(display,
                style: const TextStyle(fontSize: 11)),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.only(
                bottom: 24, left: 16, right: 16),
            duration: const Duration(seconds: 15),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'Add New Teacher',
          style: TextStyle(
              fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: 16.0, vertical: 24.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8EAED)),
              ),
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Photo
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _isUploading
                                ? null
                                : _showPhotoOptions,
                            child: Stack(
                              children: [
                                Container(
                                  height: 110,
                                  width: 110,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A237E)
                                        .withOpacity(0.06),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _photoBytes != null
                                          ? const Color(0xFF1A237E)
                                          : const Color(0xFF1A237E)
                                              .withOpacity(0.2),
                                      width: 2,
                                    ),
                                    image: _photoBytes != null
                                        ? DecorationImage(
                                            image:
                                                MemoryImage(
                                                    _photoBytes!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: _photoBytes == null
                                      ? _photoPlaceholder()
                                      : null,
                                ),
                                if (_isPhotoUploading)
                                  Container(
                                    height: 110,
                                    width: 110,
                                    decoration: BoxDecoration(
                                      color: Colors.black
                                          .withOpacity(0.4),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 30,
                                        height: 30,
                                        child:
                                            CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (_photoBytes != null &&
                                    !_isPhotoUploading)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () => setState(() {
                                        _photoBytes = null;
                                        _photoFileName = '';
                                      }),
                                      child: Container(
                                        padding:
                                            const EdgeInsets.all(3),
                                        decoration:
                                            const BoxDecoration(
                                          color: Color(0xFFDC2626),
                                          shape:
                                              BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _photoBytes != null
                                ? 'Tap to change photo'
                                : 'Tap to add passport photo',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Basic Information
                    _sectionHeader(
                      'Basic Information',
                      Icons.person_rounded,
                      const Color(0xFFF0F4FF),
                      const Color(0xFF1A237E),
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      'Staff ID',
                      'staff_id',
                      validator: _validateRequired,
                      icon: Icons.badge_outlined,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            'First Name',
                            'first_name',
                            validator: _validateName,
                            icon: Icons.person_outline,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(
                            'Last Name',
                            'last_name',
                            validator: _validateName,
                          ),
                        ),
                      ],
                    ),
                    _buildDropdown(
                      'Gender',
                      'gender',
                      ['Male', 'Female'],
                      validator: _validateDropdown,
                      icon: Icons.wc_outlined,
                    ),
                    const SizedBox(height: 20),

                    // Contact Information
                    _sectionHeader(
                      'Contact Information',
                      Icons.contact_phone_rounded,
                      const Color(0xFFF3E5F5),
                      const Color(0xFF1565C0),
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      'Email Address',
                      'email',
                      type: TextInputType.emailAddress,
                      validator: _validateEmail,
                      icon: Icons.email_outlined,
                    ),
                    _buildField(
                      'Phone Number',
                      'phone',
                      type: TextInputType.phone,
                      validator: _validatePhone,
                      hintText: '+234...',
                      icon: Icons.phone_outlined,
                    ),
                    _buildField(
                      'Home Address',
                      'home_address',
                      icon: Icons.home_outlined,
                    ),
                    const SizedBox(height: 20),

                    // Work Information
                    _sectionHeader(
                      'Work Information',
                      Icons.work_rounded,
                      const Color(0xFFFFF3E0),
                      const Color(0xFFE65100),
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      'Department',
                      'department',
                      icon: Icons.business_outlined,
                    ),
                    _buildField(
                      'Qualification',
                      'qualification',
                      hintText: 'e.g. B.Ed, M.Sc, PGDE',
                      icon: Icons.school_outlined,
                    ),
                    const SizedBox(height: 28),

                    // Submit
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed:
                            _isUploading ? null : _submit,
                        icon: _isUploading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ))
                            : const Icon(
                                Icons.person_add, size: 20),
                        label: Text(
                          _isUploading
                              ? 'Saving...'
                              : 'Save Teacher',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF1A237E),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              const Color(0xFF1A237E)
                                  .withOpacity(0.5),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.person_add_alt_1_outlined,
            size: 20,
            color: Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Add Photo',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(
      String title, IconData icon, Color iconBg, Color iconColor) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 17, color: iconColor),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildField(String label, String key,
      {TextInputType type = TextInputType.text,
      String? Function(String?)? validator,
      String? hintText,
      IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        keyboardType: type,
        textCapitalization: type == TextInputType.text
            ? TextCapitalization.words
            : TextCapitalization.none,
        style: const TextStyle(
          fontSize: 15,
          height: 1.4,
          letterSpacing: 0.2,
          color: Color(0xFF111827),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade400,
            letterSpacing: 0.2,
          ),
          prefixIcon: icon != null
              ? Icon(
                  icon,
                  size: 20,
                  color: const Color(0xFF1A237E)
                      .withOpacity(0.7))
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: Color(0xFF1A237E),
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: Color(0xFFD32F2F),
            )),
          filled: true,
          fillColor: const Color(0xFFFAFBFC),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        validator: validator,
        onSaved: (v) {
          if (v != null && v.trim().isNotEmpty)
            _data[key] = v.trim();
        },
      ),
    );
  }

  Widget _buildDropdown(String label, String key, List<String> items,
      {String? Function(String?)? validator, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        style: const TextStyle(
          fontSize: 15,
          height: 1.4,
          letterSpacing: 0.2,
          color: Color(0xFF111827),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: icon != null
              ? Icon(
                  icon,
                  size: 20,
                  color: const Color(0xFF1A237E)
                      .withOpacity(0.7))
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: Color(0xFF1A237E),
              width: 2,
            ),
          ),
          filled: true,
          fillColor: const Color(0xFFFAFBFC),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
        ),
        items: items
            .map((e) => DropdownMenuItem(
                value: e,
                child: Text(
                  e,
                  style: const TextStyle(
                    fontSize: 15,
                    letterSpacing: 0.2,
                  ),
                )))
            .toList(),
        validator: validator,
        onChanged: (v) => setState(() => _data[key] = v),
        onSaved: (v) => _data[key] = v,
      ),
    );
  }
}

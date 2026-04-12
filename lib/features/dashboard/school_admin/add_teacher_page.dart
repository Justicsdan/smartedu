import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
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

  // Photo state
  Uint8List? _photoBytes;
  String _photoFileName = '';
  bool _isPhotoUploading = false;

  // =========================================================
  // VALIDATORS
  // =========================================================

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    if (value.trim().length < 2) return 'Min 2 characters';
    if (RegExp(r'[0-9]').hasMatch(value.trim())) return 'No numbers allowed';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!RegExp(r'^[\w\.\-\+]+@[\w\.\-]+\.\w+$').hasMatch(value.trim())) {
      return 'Invalid email';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final cleaned = value.trim().replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
    if (cleaned.length < 7 || cleaned.length > 15) return 'Invalid (7-15 digits)';
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) return 'Digits only';
    return null;
  }

  String? _validateDropdown(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  // =========================================================
  // PHOTO PICKER (Gallery + Camera bottom sheet)
  // =========================================================

  Future<void> _showPhotoOptions() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Photo',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0D47A1))),
              const SizedBox(height: 12),
              ListTile(
                leading:
                    const Icon(Icons.photo_library, color: Color(0xFF0D47A1)),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF0D47A1)),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_photoBytes != null) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Photo',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _photoBytes = null;
                      _photoFileName = '';
                    });
                  },
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Could not pick image: $e'),
            backgroundColor: Colors.red));
      }
    }
  }

  // =========================================================
  // PHOTO UPLOAD (HTTP REST — Iron Rule #7)
  // =========================================================

  Future<String?> _uploadPhoto(String teacherId) async {
    if (_photoBytes == null || _photoBytes!.isEmpty) return null;

    setState(() => _isPhotoUploading = true);
    try {
      final provider = context.read<SchoolAdminProvider>();
      final schoolId = provider.schoolId;
      if (schoolId.isEmpty || teacherId.isEmpty) return null;

      final ext = _photoFileName.split('.').last.toLowerCase();
      if (ext.isEmpty || ext.length > 5) {
        // Fallback extension
        final validExt = ['jpg', 'jpeg', 'png', 'webp', 'gif'];
        final detected = validExt.first;
        ext.replaceRange(0, ext.length, detected);
      }
      final safeExt = (ext.length <= 5 && RegExp(r'^[a-z]+$').hasMatch(ext))
          ? ext
          : 'jpg';
      final path = 'teachers/$schoolId/$teacherId.$safeExt';

      final supabase = Supabase.instance.client;
      await supabase.storage.from('passports').upload(
            path,
            _photoBytes!,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl = supabase.storage.from('passports').getPublicUrl(path);
      // Remove trailing query params if any
      final cleanUrl = publicUrl.split('?').first;
      debugPrint('Photo uploaded: $cleanUrl');
      return cleanUrl;
    } catch (e) {
      debugPrint('Photo upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Photo upload failed: $e'),
            backgroundColor: Colors.orange));
      }
      return null;
    } finally {
      if (mounted) setState(() => _isPhotoUploading = false);
    }
  }

  // =========================================================
  // SUBMIT
  // =========================================================

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final firstName = (_data['first_name'] ?? '').toString().trim();
    final lastName = (_data['last_name'] ?? '').toString().trim();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Confirm Addition'),
        content: Text('Add $firstName $lastName (${_data['staff_id']})?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _isUploading = true);

    try {
      final provider = context.read<SchoolAdminProvider>();
      final schoolId = provider.schoolId;

      if (schoolId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('FATAL: School ID missing. Log out and back in.'),
              backgroundColor: Colors.red));
        }
        return;
      }

      // Step 1: Insert teacher without photo
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

      // Step 2: Upload photo if selected
      if (_photoBytes != null) {
        final photoUrl = await _uploadPhoto(teacherId);
        if (photoUrl != null && photoUrl.isNotEmpty) {
          await Supabase.instance.client
              .from('teachers')
              .update({'passport_url': photoUrl})
              .eq('id', teacherId);
          _data['passport_url'] = photoUrl;
          debugPrint('TEACHER PHOTO UPDATED: $photoUrl');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Teacher added successfully!'),
            backgroundColor: Colors.green));
        Navigator.pop(context, _data);
      }
    } catch (e) {
      debugPrint('TEACHER SAVE ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: SelectableText(e.toString(),
                  style: const TextStyle(fontSize: 11)),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 15)),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Add New Teacher',
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 0),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Photo picker
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _isUploading ? null : _showPhotoOptions,
                            child: Stack(
                              children: [
                                Container(
                                  height: 100,
                                  width: 100,
                                  decoration: BoxDecoration(
                                    color: _photoBytes != null
                                        ? Colors.transparent
                                        : const Color(0xFF0D47A1)
                                            .withOpacity(0.08),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF0D47A1)
                                          .withOpacity(0.2),
                                      width: 2,
                                    ),
                                    image: _photoBytes != null
                                        ? DecorationImage(
                                            image: MemoryImage(_photoBytes!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: _photoBytes == null
                                      ? const Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                                Icons
                                                    .person_add_alt_1_outlined,
                                                size: 36,
                                                color: Color(0xFF0D47A1)),
                                            SizedBox(height: 4),
                                            Text('Add Photo',
                                                style: TextStyle(
                                                    color: Color(0xFF0D47A1),
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.w500)),
                                          ],
                                        )
                                      : null,
                                ),
                                // Upload spinner overlay
                                if (_isPhotoUploading)
                                  Container(
                                    height: 100,
                                    width: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.4),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 30,
                                        height: 30,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5),
                                      ),
                                    ),
                                  ),
                                // Edit badge when photo exists
                                if (_photoBytes != null && !_isPhotoUploading)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      height: 28,
                                      width: 28,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0D47A1),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(Icons.edit,
                                          size: 13, color: Colors.white),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (_photoBytes != null)
                            Text('Tap to change photo',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade500))
                          else
                            Text('Tap to add passport photo',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Basic Information
                    _buildSectionTitle('Basic Information'),
                    const SizedBox(height: 12),
                    _buildField('Staff ID', 'staff_id',
                        validator: _validateRequired,
                        icon: Icons.badge_outlined),
                    Row(
                      children: [
                        Expanded(
                            child: _buildField('First Name', 'first_name',
                                validator: _validateName,
                                icon: Icons.person_outline)),
                        const SizedBox(width: 12),
                        Expanded(
                            child:
                                _buildField('Last Name', 'last_name',
                                    validator: _validateName)),
                      ],
                    ),
                    _buildDropdown('Gender', 'gender', ['Male', 'Female'],
                        validator: _validateDropdown,
                        icon: Icons.wc_outlined),
                    const SizedBox(height: 20),

                    // Contact Information
                    _buildSectionTitle('Contact Information'),
                    const SizedBox(height: 12),
                    _buildField('Email Address', 'email',
                        type: TextInputType.emailAddress,
                        validator: _validateEmail,
                        icon: Icons.email_outlined),
                    _buildField('Phone Number', 'phone',
                        type: TextInputType.phone,
                        validator: _validatePhone,
                        hintText: '+234...',
                        icon: Icons.phone_outlined),
                    _buildField('Home Address', 'home_address',
                        icon: Icons.home_outlined),
                    const SizedBox(height: 20),

                    // Work Information
                    _buildSectionTitle('Work Information'),
                    const SizedBox(height: 12),
                    _buildField('Department', 'department',
                        icon: Icons.business_outlined),
                    _buildField('Qualification', 'qualification',
                        hintText: 'e.g. B.Ed, M.Sc, PGDE',
                        icon: Icons.school_outlined),
                    const SizedBox(height: 28),

                    // Submit Button
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isUploading ? null : _submit,
                        icon: _isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5))
                            : const Icon(Icons.person_add, size: 22),
                        label: Text(
                            _isUploading ? 'Saving...' : 'Save Teacher',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D47A1),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.blue.shade200,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
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

  // =========================================================
  // FORM WIDGETS
  // =========================================================

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.black54,
            letterSpacing: 0.5));
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
            fontSize: 15, height: 1.4, letterSpacing: 0.2, color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.2),
          hintText: hintText,
          hintStyle: TextStyle(
              fontSize: 13, color: Colors.grey.shade500, letterSpacing: 0.2),
          prefixIcon: icon != null
              ? Icon(icon, size: 20, color: Colors.grey.shade600)
              : null,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFF0D47A1), width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: validator,
        onSaved: (v) {
          if (v != null && v.trim().isNotEmpty) _data[key] = v.trim();
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
            fontSize: 15, height: 1.4, letterSpacing: 0.2, color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.2),
          prefixIcon: icon != null
              ? Icon(icon, size: 20, color: Colors.grey.shade600)
              : null,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFF0D47A1), width: 1.5)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
        items: items
            .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e,
                    style: const TextStyle(fontSize: 15, letterSpacing: 0.2))))
            .toList(),
        validator: validator,
        onChanged: (v) => setState(() => _data[key] = v),
        onSaved: (v) => _data[key] = v,
      ),
    );
  }
}

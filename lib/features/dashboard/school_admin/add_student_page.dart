import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartedu/core/providers/school_admin_provider.dart';

class AddStudentPage extends StatefulWidget {
  final List<Map<String, dynamic>> classes;

  const AddStudentPage({super.key, required this.classes});

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _data = {};

  XFile? _pickedXFile;
  String? _passportUrlPreview;
  bool _isUploading = false;
  bool _isPickingImage = false;

  final _dobController = TextEditingController();
  DateTime? _selectedDob;

  @override
  void dispose() {
    _dobController.dispose();
    super.dispose();
  }

  String _getSchoolId(SchoolAdminProvider provider) => provider.schoolId;

  // ─── IMAGE ───────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
          source: source, maxHeight: 512, imageQuality: 75);
      if (pickedFile != null) {
        setState(() {
          _pickedXFile = pickedFile;
          _passportUrlPreview = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Could not access ${source == ImageSource.camera ? 'camera' : 'gallery'}.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10))));
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  void _removeImage() =>
      setState(() {
        _pickedXFile = null;
        _passportUrlPreview = null;
      });

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Upload Photo',
                    style: Theme.of(ctx)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700))),
            ListTile(
              leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.photo_library_rounded,
                      color: Colors.blue.shade700)),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Pick an existing photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.camera_alt_rounded,
                      color: Colors.green.shade700)),
              title: const Text('Take a Photo'),
              subtitle: const Text('Use your camera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_pickedXFile != null)
              ListTile(
                leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.delete_outline_rounded,
                        color: Colors.red.shade700)),
                title: const Text('Remove Photo'),
                subtitle: const Text('Remove selected photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _removeImage();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─── DATE ────────────────────────────────────────────────────

  Future<void> _selectDateOfBirth() async {
    final initial = _selectedDob ?? DateTime(2010, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      helpText: 'Select Date of Birth',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
                primary: Color(0xFF0D47A1),
                onPrimary: Colors.white,
                surface: Colors.white)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        final f =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        _dobController.text = f;
        _data['date_of_birth'] = f;
      });
    }
  }

  // ─── VALIDATORS ──────────────────────────────────────────────

  String? _vAdm(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    if (v.trim().length < 2) return 'Min 2 chars';
    return null;
  }

  String? _vName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    if (v.trim().length < 2) return 'Min 2 chars';
    if (RegExp(r'[0-9]').hasMatch(v.trim())) return 'No numbers';
    return null;
  }

  String? _vOptName(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    if (v.trim().length < 2) return 'Min 2 chars';
    if (RegExp(r'[0-9]').hasMatch(v.trim())) return 'No numbers';
    return null;
  }

  String? _vPhone(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final c = v.trim().replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
    if (c.length < 7 || c.length > 15) return 'Invalid';
    if (!RegExp(r'^\d+$').hasMatch(c)) return 'Digits only';
    return null;
  }

  String? _vEmail(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    if (!RegExp(r'^[\w\.\-\+]+@[\w\.\-]+\.\w+$').hasMatch(v.trim()))
      return 'Invalid email';
    return null;
  }

  String? _vYear(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final y = int.tryParse(v.trim());
    if (y == null) return 'Invalid';
    if (y < 1990 || y > DateTime.now().year + 1) return 'Out of range';
    return null;
  }

  String? _vDrop(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    return null;
  }

  // ─── SUBMIT ──────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_data['class_id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Please select a class'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10))));
      return;
    }

    final fn = (_data['first_name'] ?? '').toString().trim();
    final ln = (_data['last_name'] ?? '').toString().trim();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Confirm Addition'),
        content: Text('Add $fn $ln (${_data['admission_no']})?'),
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
            child:
                const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _isUploading = true);
    try {
      final provider = context.read<SchoolAdminProvider>();
      final schoolId = _getSchoolId(provider);
      if (schoolId.isEmpty) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('FATAL: School ID missing.'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))));
        return;
      }

      _data['passport_url'] = '';
      if (_pickedXFile != null) {
        try {
          final ts = DateTime.now().millisecondsSinceEpoch;
          final adm = (_data['admission_no'] ?? 'unknown')
              .toString()
              .replaceAll(' ', '_');
          final path = '$schoolId/students/${adm}_$ts.jpg';
          final bytes = await _pickedXFile!.readAsBytes();
          await Supabase.instance.client.storage
              .from('passports')
              .upload(path, bytes,
                  fileOptions: const FileOptions(upsert: true));
          _data['passport_url'] = Supabase.instance.client.storage
              .from('passports')
              .getPublicUrl(path);
        } catch (e) {
          debugPrint('IMG FAIL: $e');
        }
      }

      _data['school_id'] = schoolId;
      _data['is_active'] = true;
      // PIN is auto-generated — don't send from form
      _data.remove('pin');

      final result = await Supabase.instance.client
          .from('students')
          .insert([_data])
          .select('id')
          .single();
      debugPrint('SUCCESS: ${result['id']}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 10),
            Text('Student added successfully!')
          ]),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
        Navigator.pop(context, _data);
      }
    } catch (e) {
      debugPrint('SAVE ERR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: SelectableText(e.toString(),
              style: const TextStyle(fontSize: 11)),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 15),
        ));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ─── BUILD ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Add New Student',
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
                      color: Colors.black.withOpacity(0.05), blurRadius: 10)
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Photo ──────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _showImagePickerSheet,
                            child: Stack(
                              children: [
                                Container(
                                  height: 100,
                                  width: 100,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D47A1)
                                        .withOpacity(0.08),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: _pickedXFile != null
                                            ? const Color(0xFF0D47A1)
                                            : const Color(0xFF0D47A1)
                                                .withOpacity(0.2),
                                        width: 2),
                                  ),
                                  child: ClipOval(child: _buildPhoto()),
                                ),
                                if (_pickedXFile != null)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: _removeImage,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle),
                                        child: const Icon(Icons.close,
                                            color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text('Tap to add photo',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Basic Information ──────────────────
                    _sectionTitle('Basic Information'),
                    const SizedBox(height: 12),
                    _field('Admission No', 'admission_no',
                        icon: Icons.fingerprint_rounded, validator: _vAdm),
                    Row(
                      children: [
                        Expanded(
                            child: _field('First Name', 'first_name',
                                icon: Icons.person_outline, validator: _vName)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _field('Last Name', 'last_name',
                                validator: _vName)),
                      ],
                    ),
                    _field('Middle Name', 'middle_name', validator: _vOptName),
                    _dropdown('Gender', 'gender', ['Male', 'Female'],
                        validator: _vDrop, icon: Icons.wc_outlined),
                    const SizedBox(height: 20),

                    // ── Personal Details ──────────────────
                    _sectionTitle('Personal Details'),
                    const SizedBox(height: 12),
                    _dateField('Date of Birth'),
                    _dropdown('School Level', 'school_level',
                        ['Primary', 'Secondary', 'Tertiary'],
                        def: 'Secondary', icon: Icons.school_outlined),
                    _field('Home Address', 'home_address',
                        icon: Icons.home_outlined),
                    const SizedBox(height: 20),

                    // ── Class & Admission ─────────────────
                    _sectionTitle('Class & Admission'),
                    const SizedBox(height: 12),
                    _classDropdown(),
                    _field('Session', 'admission_session',
                        hint: 'e.g. 2024/2025',
                        icon: Icons.calendar_view_month_outlined),
                    _dropdown('Admission Mode', 'admission_mode',
                        ['Fresh', 'Transfer', 'Repeat']),
                    _field('Admission Year', 'class_admission_year',
                        type: TextInputType.number,
                        validator: _vYear,
                        hint: 'e.g. 2024',
                        icon: Icons.event_outlined),
                    const SizedBox(height: 20),

                    // ── Extracurricular ───────────────────
                    _sectionTitle('Extracurricular'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child: _field('Sport Team', 'sport_team',
                                hint: 'e.g. Football',
                                icon: Icons.sports_soccer)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _field('Club/Society', 'club_society',
                                hint: 'e.g. Jet Club',
                                icon: Icons.groups_outlined)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Parent / Guardian ─────────────────
                    _sectionTitle('Parent / Guardian'),
                    const SizedBox(height: 12),
                    _field('Parent Name', 'parent_name',
                        validator: _vName, icon: Icons.person_outline),
                    _field('Parent Phone', 'parent_phone',
                        type: TextInputType.phone,
                        validator: _vPhone,
                        hint: '+234...',
                        icon: Icons.phone_outlined),
                    _field('Parent Email', 'parent_email',
                        type: TextInputType.emailAddress,
                        validator: _vEmail,
                        hint: 'parent@email.com',
                        icon: Icons.email_outlined),
                    _field('Parent Occupation', 'parent_occupation',
                        hint: 'e.g. Teacher, Engineer',
                        icon: Icons.work_outline),
                    const SizedBox(height: 28),

                    // ── Submit ────────────────────────────
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
                            _isUploading ? 'Saving...' : 'Save Student',
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

  // ─── PHOTO DISPLAY ───────────────────────────────────────────

  Widget _buildPhoto() {
    if (_isPickingImage)
      return const Center(
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Color(0xFF0D47A1)));
    if (_pickedXFile != null) {
      return FutureBuilder<Uint8List>(
        future: _pickedXFile!.readAsBytes(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.done && snap.hasData)
            return Image.memory(snap.data!, fit: BoxFit.cover);
          return const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFF0D47A1)));
        },
      );
    }
    if (_passportUrlPreview != null)
      return Image.network(_passportUrlPreview!, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _photoPlaceholder());
    return _photoPlaceholder();
  }

  Widget _photoPlaceholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo_outlined, size: 32, color: Color(0xFF0D47A1)),
        SizedBox(height: 4),
        Text('Photo',
            style: TextStyle(
                color: Color(0xFF0D47A1),
                fontSize: 11,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ─── REUSABLE BUILDERS ───────────────────────────────────────

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
              letterSpacing: 0.5)),
    );
  }

  Widget _field(String label, String key,
      {TextInputType type = TextInputType.text,
      String? Function(String?)? validator,
      String? hint,
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
          hintText: hint,
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

  Widget _dateField(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _dobController,
        readOnly: true,
        style: const TextStyle(
            fontSize: 15, height: 1.4, letterSpacing: 0.2, color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.2),
          hintText: 'Select date',
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          suffixIcon: const Icon(Icons.calendar_today,
              color: Color(0xFF0D47A1), size: 20),
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
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        onTap: _selectDateOfBirth,
      ),
    );
  }

  Widget _dropdown(String label, String key, List<String> items,
      {String? def, IconData? icon, String? Function(String?)? validator}) {
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
        value: _data[key] ?? def,
        items: items
            .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e,
                    style: const TextStyle(
                        fontSize: 15, letterSpacing: 0.2))))
            .toList(),
        validator: validator,
        onChanged: (v) => setState(() => _data[key] = v),
        onSaved: (v) => _data[key] = v,
      ),
    );
  }

  Widget _classDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        style: const TextStyle(
            fontSize: 15, height: 1.4, letterSpacing: 0.2, color: Colors.black87),
        decoration: InputDecoration(
          labelText: 'Class',
          labelStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.2),
          prefixIcon: const Icon(Icons.class_rounded,
              size: 20, color: Color(0xFF0D47A1)),
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
        value: _data['class_id'],
        hint: widget.classes.isEmpty
            ? const Text('No classes created yet',
                style: TextStyle(fontSize: 13, color: Colors.redAccent))
            : const Text('Select Class', style: TextStyle(fontSize: 13)),
        isExpanded: true,
        items: widget.classes.isEmpty
            ? []
            : widget.classes.map((c) {
                final n = (c['name'] ?? '').toString();
                final s = (c['section'] ?? '').toString();
                return DropdownMenuItem(
                    value: c['id']?.toString() ?? '',
                    child: Text(
                        s.isNotEmpty ? '$n - $s' : n,
                        style: const TextStyle(
                            fontSize: 15, letterSpacing: 0.2),
                        overflow: TextOverflow.ellipsis));
              }).toList(),
        onChanged: widget.classes.isEmpty
            ? null
            : (v) {
                if (v != null) setState(() => _data['class_id'] = v);
              },
        onSaved: (v) {
          if (v != null) _data['class_id'] = v;
        },
      ),
    );
  }
}

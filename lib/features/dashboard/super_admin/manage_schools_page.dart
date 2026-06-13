// ==========================================
// File: lib/features/dashboard/super_admin/manage_schools_page.dart
// ==========================================
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartedu/core/super_admin_provider.dart';
import 'package:smartedu/core/school_model.dart';

class ManageSchoolsPage extends StatefulWidget {
  const ManageSchoolsPage({super.key});

  @override
  State<ManageSchoolsPage> createState() => _ManageSchoolsPageState();
}

class _ManageSchoolsPageState extends State<ManageSchoolsPage> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _whatsappController = TextEditingController();
  String _schoolType = 'primary';
  String _logoBase64 = '';
  html.File? _logoFile;
  bool _isSubmitting = false;

  Future<void> _pickLogo() async {
    final input = html.FileUploadInputElement();
    input.accept = 'image/*';
    input.click();
    input.onChange.listen((event) {
      final files = input.files;
      if (files == null || files.isEmpty) return;
      final file = files.first;
      final reader = html.FileReader();
      reader.onLoadEnd.listen((event) {
        setState(() {
          _logoBase64 = reader.result as String;
          _logoFile = file;
        });
      });
      reader.readAsDataUrl(file);
    });
  }

  Future<void> _showAddDialog() async {
    _nameController.clear();
    _locationController.clear();
    _whatsappController.clear();
    _schoolType = 'primary';
    _logoBase64 = '';
    _logoFile = null;

    String? dialogError;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSt) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            title: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.domain_add_rounded, size: 22, color: Color(0xFF1A237E)),
                ),
                const SizedBox(width: 12),
                const Text("Register New School", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFF111827), letterSpacing: -0.3)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (dialogError != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFECACA))),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, size: 18, color: Color(0xFFDC2626)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(dialogError!, style: const TextStyle(fontSize: 13, color: Color(0xFFDC2626), height: 1.3))),
                        ],
                      ),
                    ),
                  GestureDetector(
                    onTap: _pickLogo,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFBFC),
                        borderRadius: BorderRadius.circular(55),
                        border: Border.all(color: const Color(0xFFE8EAED), width: 2),
                      ),
                      child: _logoBase64.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(55),
                              child: Image.network(_logoBase64, fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt_rounded, size: 32, color: Colors.grey.shade400),
                                const SizedBox(height: 6),
                                Text("Upload Logo", style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(fontSize: 15, color: Color(0xFF111827)),
                    decoration: InputDecoration(
                      labelText: "School Name",
                      labelStyle: TextStyle(color: Colors.grey.shade600),
                      border: const OutlineInputBorder(),
                      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFE0E0E0))),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF1A237E))),
                      prefixIcon: const Icon(Icons.school_rounded, color: Color(0xFF1A237E)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _locationController,
                    style: const TextStyle(fontSize: 15, color: Color(0xFF111827)),
                    decoration: InputDecoration(
                      labelText: "Location / Address",
                      labelStyle: TextStyle(color: Colors.grey.shade600),
                      border: const OutlineInputBorder(),
                      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFE0E0E0))),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF1A237E))),
                      prefixIcon: const Icon(Icons.location_on_rounded, color: Color(0xFF1A237E)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _whatsappController,
                    style: const TextStyle(fontSize: 15, color: Color(0xFF111827)),
                    decoration: InputDecoration(
                      labelText: "WhatsApp Number",
                      labelStyle: TextStyle(color: Colors.grey.shade600),
                      border: const OutlineInputBorder(),
                      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFE0E0E0))),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF2E7D32))),
                      prefixIcon: const Icon(Icons.chat_rounded, color: Color(0xFF2E7D32)),
                      hintText: "+234 xxx xxx xxxx",
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _schoolType,
                    decoration: InputDecoration(
                      labelText: "School Type",
                      labelStyle: TextStyle(color: Colors.grey.shade600),
                      border: const OutlineInputBorder(),
                      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFE0E0E0))),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF1A237E))),
                      prefixIcon: const Icon(Icons.category_rounded, color: Color(0xFF1A237E)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'primary', child: Text('Primary')),
                      DropdownMenuItem(value: 'secondary', child: Text('Secondary')),
                      DropdownMenuItem(value: 'tertiary', child: Text('Tertiary')),
                      DropdownMenuItem(value: 'vocational', child: Text('Vocational')),
                      DropdownMenuItem(value: 'montessori', child: Text('Montessori')),
                      DropdownMenuItem(value: 'creche', child: Text('Creche')),
                      DropdownMenuItem(value: 'special_needs', child: Text('Special Needs')),
                      DropdownMenuItem(value: 'both', child: Text('Primary & Secondary')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (v) => setSt(() => _schoolType = v!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: _isSubmitting ? null : () async {
                  if (_nameController.text.isEmpty || _locationController.text.isEmpty) {
                    setSt(() => dialogError = 'School name and location are required.');
                    return;
                  }
                  setSt(() => _isSubmitting = true);
                  String logoUrl = '';
                  if (_logoFile != null) {
                    final rd = html.FileReader();
                    rd.readAsArrayBuffer(_logoFile!);
                    await rd.onLoadEnd.first;
                    final bytes = Uint8List.fromList((rd.result as ByteBuffer).asUint8List());
                    final ext = _logoFile!.name.split('.').last;
                    final sp = 'schools/${DateTime.now().millisecondsSinceEpoch}.$ext';
                    await Supabase.instance.client.storage.from('school-logos').upload(sp, bytes, fileOptions: const FileOptions(upsert: true));
                    logoUrl = Supabase.instance.client.storage.from('school-logos').getPublicUrl(sp);
                  }
                  final provider = context.read<SuperAdminProvider>();
                  final result = await provider.addSchool(
                    name: _nameController.text.trim(),
                    location: _locationController.text.trim(),
                    schoolType: _schoolType,
                    logoUrl: logoUrl,
                    whatsapp: _whatsappController.text.trim(),
                  );
                  Navigator.pop(ctx);
                  if (result != null) {
                    _showCredentialsDialog(result['username']!, result['password']!, schoolName: result['school_name'] ?? '', schoolCode: result['school_code'] ?? '');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: const Text("Failed to register school"), backgroundColor: const Color(0xFFD32F2F), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Register", style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    html.window.navigator.clipboard?.writeText(text);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$label copied to clipboard"),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showCredentialsDialog(String username, String password, {String schoolName = '', String schoolCode = ''}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.check_circle_rounded, size: 22, color: Color(0xFF2E7D32)),
            ),
            const SizedBox(width: 12),
            const Text("School Registered!", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFF111827), letterSpacing: -0.3)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (schoolName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.domain_rounded, size: 16, color: Color(0xFF111827)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(schoolName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)))),
                  ],
                ),
              ),
            if (schoolCode.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.pin_rounded, size: 16, color: Color(0xFF1A237E)),
                      const SizedBox(width: 6),
                      const Text('School Code:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                      const SizedBox(width: 8),
                      Text(schoolCode, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A237E), letterSpacing: 2)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _copyToClipboard(schoolCode, "School Code"),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: const Color(0xFF1A237E).withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                          child: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF1A237E)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const Text("Save these credentials for the school admin:", style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8EAF6))),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      const Text("Username", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _copyToClipboard(username, "Username"),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: const Color(0xFF1A237E).withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                          child: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF1A237E)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Align(alignment: Alignment.centerLeft, child: Text(username, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A237E)))),
                  const SizedBox(height: 14),
                  const Divider(color: Color(0xFFE8EAF6)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      const Text("Password", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _copyToClipboard(password, "Password"),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: const Color(0xFF1A237E).withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                          child: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF1A237E)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Align(alignment: Alignment.centerLeft, child: Text(password, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A237E)))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _copyToClipboard('Username: $username\nPassword: $password', "Credentials"),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE8EAF6))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.content_copy_rounded, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text("Copy Both", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
            child: const Text("Done", style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _showLoginDialog(School school) async {
    final logoUrl = school.logoUrl;
    final logoValid = logoUrl != null && logoUrl.isNotEmpty;
    final provider = context.read<SuperAdminProvider>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSt) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            title: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.key_rounded, size: 22, color: Color(0xFFF57F17)),
                ),
                const SizedBox(width: 12),
                const Text("Admin Login Credentials", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFF111827), letterSpacing: -0.3)),
              ],
            ),
            content: FutureBuilder<Map<String, String>?>(
              future: provider.fetchSchoolCredentials(school.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF1A237E))),
                  );
                }
                final creds = snapshot.data;
                final username = creds?['username'] ?? school.adminUsername ?? 'N/A';
                final password = creds?['password'] ?? 'N/A';

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (logoValid)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: const Color(0xFFF0F4FF),
                          backgroundImage: NetworkImage(logoUrl),
                          onBackgroundImageError: logoValid ? (_, __) {} : null,
                        ),
                      ),
                    Text(school.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          const Icon(Icons.pin_rounded, size: 16, color: Color(0xFF1A237E)),
                          const SizedBox(width: 6),
                          const Text('School Code:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                          const SizedBox(width: 8),
                          Text(school.safeSchoolCode, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A237E), letterSpacing: 2)),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _copyToClipboard(school.safeSchoolCode, "School Code"),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: const Color(0xFFF57F17).withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                              child: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFFF57F17)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFFFAFBFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8EAED))),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person_outline_rounded, size: 16, color: Colors.grey.shade500),
                              const SizedBox(width: 6),
                              const Text("Username", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => _copyToClipboard(username, "Username"),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(color: const Color(0xFFF57F17).withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                                  child: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFFF57F17)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Align(alignment: Alignment.centerLeft, child: Text(username, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A237E)))),
                          const SizedBox(height: 14),
                          const Divider(color: Color(0xFFE8EAED)),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Icon(Icons.lock_outline_rounded, size: 16, color: Colors.grey.shade500),
                              const SizedBox(width: 6),
                              const Text("Password", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => _copyToClipboard(password, "Password"),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(color: const Color(0xFFF57F17).withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                                  child: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFFF57F17)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Align(alignment: Alignment.centerLeft, child: Text(password, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A237E)))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _copyToClipboard('Username: $username\nPassword: $password', "Credentials"),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFFE082))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.content_copy_rounded, size: 16, color: Colors.grey.shade700),
                            const SizedBox(width: 6),
                            Text("Copy Both", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                          ],
                        ),
                      ),
                    ),
                    if (snapshot.hasError) ...[
                      const SizedBox(height: 12),
                      Text("Error loading credentials", style: TextStyle(fontSize: 12, color: Colors.red.shade400)),
                    ],
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final result = await provider.regenerateSchoolPassword(school.id);
                  if (result != null && mounted) {
                    _showCredentialsDialog(result['username']!, result['password']!, schoolName: school.name, schoolCode: school.safeSchoolCode);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: const Text("Password regenerated successfully"), backgroundColor: const Color(0xFF2E7D32), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: const Text("Failed to regenerate password"), backgroundColor: const Color(0xFFD32F2F), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    );
                  }
                },
                style: TextButton.styleFrom(foregroundColor: const Color(0xFFF57F17)),
                child: const Text("Reset Password"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                child: const Text("Close", style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(School school) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.delete_outline_rounded, size: 22, color: Color(0xFFD32F2F)),
            ),
            const SizedBox(width: 12),
            const Text("Delete School", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFF111827), letterSpacing: -0.3)),
          ],
        ),
        content: Text('Are you sure you want to delete "${school.name}"? This action cannot be undone.', style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<SuperAdminProvider>().deleteSchool(school.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("${school.name} deleted"), backgroundColor: const Color(0xFFD32F2F), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              );
            },
            child: const Text("Delete", style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.domain_rounded, size: 20, color: Color(0xFF1A237E)),
                    ),
                    const SizedBox(width: 12),
                    const Text('Manage Schools', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF111827), letterSpacing: -0.5)),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          Expanded(
            child: Consumer<SuperAdminProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.schools.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)));
                }
                if (provider.schools.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(18)),
                          child: const Icon(Icons.school_rounded, size: 32, color: Color(0xFF9CA3AF)),
                        ),
                        const SizedBox(height: 16),
                        const Text('No schools registered yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                        const SizedBox(height: 6),
                        Text('Tap "Register School" to add your first school.', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: provider.schools.length,
                  itemBuilder: (context, index) {
                    return _SchoolCard(
                      school: provider.schools[index],
                      index: index,
                      onToggleStatus: () => provider.toggleSchoolStatus(provider.schools[index].id),
                      onTogglePayment: () => provider.togglePaymentStatus(provider.schools[index].id),
                      onViewLogin: () => _showLoginDialog(provider.schools[index]),
                      onDelete: () => _confirmDelete(provider.schools[index]),
                    );
                  },
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: const Color(0xFF1A237E).withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 5))],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _showAddDialog,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 16),
                        Icon(Icons.add, color: Colors.white, size: 22),
                        SizedBox(width: 8),
                        Text('Register School', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                        SizedBox(width: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SchoolCard extends StatefulWidget {
  final School school;
  final int index;
  final VoidCallback onToggleStatus;
  final VoidCallback onTogglePayment;
  final VoidCallback onViewLogin;
  final VoidCallback onDelete;

  const _SchoolCard({
    required this.school,
    required this.index,
    required this.onToggleStatus,
    required this.onTogglePayment,
    required this.onViewLogin,
    required this.onDelete,
  });

  @override
  State<_SchoolCard> createState() => _SchoolCardState();
}

class _SchoolCardState extends State<_SchoolCard> {
  bool _hovered = false;

  String get _typeString => widget.school.schoolType.toString().split('.').last.toLowerCase();

  Color get _typeColor {
    switch (_typeString) {
      case 'primary':
        return const Color(0xFF0984E3);
      case 'secondary':
        return const Color(0xFF6C5CE7);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String get _typeLabel {
    final name = _typeString;
    return name.isEmpty ? '' : '${name[0].toUpperCase()}${name.substring(1)}';
  }

  bool get _isPaid {
    final statusStr = widget.school.subscriptionStatus.toString().split('.').last.toLowerCase();
    return statusStr == 'active';
  }

  @override
  Widget build(BuildContext context) {
    final logoUrl = widget.school.logoUrl;
    final logoValid = logoUrl != null && logoUrl.isNotEmpty;
    final whatsapp = widget.school.whatsapp;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _hovered ? _typeColor.withOpacity(0.02) : (widget.index.isEven ? Colors.white : const Color(0xFFFAFBFC)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _hovered ? _typeColor.withOpacity(0.25) : const Color(0xFFE8EAED)),
          boxShadow: _hovered ? [BoxShadow(color: _typeColor.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4))] : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 52,
                  decoration: BoxDecoration(color: _typeColor, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 14),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _typeColor.withOpacity(0.2)),
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: _typeColor.withOpacity(0.05),
                    backgroundImage: logoValid ? NetworkImage(logoUrl) : null,
                    onBackgroundImageError: logoValid ? (_, __) {} : null,
                    child: logoValid ? null : Icon(Icons.school_rounded, size: 22, color: _typeColor.withOpacity(0.5)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.school.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on_outlined, size: 12, color: Colors.grey.shade400),
                              const SizedBox(width: 3),
                              Flexible(child: Text(widget.school.location ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                          if (whatsapp != null && whatsapp.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.chat_rounded, size: 12, color: const Color(0xFF25D366)),
                                const SizedBox(width: 3),
                                Text(whatsapp, style: const TextStyle(fontSize: 12, color: Color(0xFF25D366), fontWeight: FontWeight.w500)),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_typeLabel.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: _typeColor.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                    child: Text(_typeLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _typeColor)),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                GestureDetector(
                  onTap: widget.onToggleStatus,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: (widget.school.isActive ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F)).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: widget.school.isActive ? const Color(0xFF4ADE80) : const Color(0xFFEF5350),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: (widget.school.isActive ? const Color(0xFF4ADE80) : const Color(0xFFEF5350)).withOpacity(0.4), blurRadius: 4)],
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(widget.school.isActive ? "Active" : "Inactive", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: widget.school.isActive ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: widget.onTogglePayment,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: (_isPaid ? const Color(0xFF2E7D32) : const Color(0xFFE65100)).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, size: 13, color: _isPaid ? const Color(0xFF2E7D32) : const Color(0xFFE65100)),
                        const SizedBox(width: 4),
                        Text(_isPaid ? "Paid" : "Unpaid", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _isPaid ? const Color(0xFF2E7D32) : const Color(0xFFE65100))),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                _actionBtn(Icons.key_rounded, 'View Login', const Color(0xFFF57F17), widget.onViewLogin),
                const SizedBox(width: 6),
                _actionBtn(Icons.delete_outline_rounded, 'Delete', const Color(0xFFD32F2F), widget.onDelete),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, String tooltip, Color color, VoidCallback onTap) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: _hovered ? 1.0 : 0.55,
      child: SizedBox(
        width: 36,
        height: 36,
        child: IconButton(
          icon: Icon(icon, size: 18, color: _hovered ? color : Colors.grey.shade400),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          tooltip: tooltip,
          onPressed: onTap,
        ),
      ),
    );
  }
}

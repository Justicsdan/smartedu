import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartedu/core/services/db_proxy.dart';

class TeacherEditProfileSheet extends StatefulWidget {
  final Map<String, dynamic> teacher;
  const TeacherEditProfileSheet({super.key, required this.teacher});
  @override
  State<TeacherEditProfileSheet> createState() => _TeacherEditProfileSheetState();
}

class _TeacherEditProfileSheetState extends State<TeacherEditProfileSheet> {
  late final TextEditingController _fnCtrl, _lnCtrl, _emailCtrl, _phoneCtrl, _deptCtrl, _qualCtrl, _addrCtrl;
  String? _gender;
  String _photo = '';
  bool _saving = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final t = widget.teacher;
    _fnCtrl = TextEditingController(text: (t['first_name'] ?? '').toString());
    _lnCtrl = TextEditingController(text: (t['last_name'] ?? '').toString());
    _emailCtrl = TextEditingController(text: (t['email'] ?? '').toString());
    _phoneCtrl = TextEditingController(text: (t['phone'] ?? '').toString());
    _deptCtrl = TextEditingController(text: (t['department'] ?? '').toString());
    _qualCtrl = TextEditingController(text: (t['qualification'] ?? '').toString());
    _addrCtrl = TextEditingController(text: (t['home_address'] ?? '').toString());
    final g = (t['gender'] ?? '').toString().trim();
    _gender = g.isEmpty ? null : g.toLowerCase();
    _photo = (t['passport_url'] ?? '').toString().trim();
  }

  @override
  void dispose() {
    _fnCtrl.dispose();
    _lnCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _deptCtrl.dispose();
    _qualCtrl.dispose();
    _addrCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePhoto() async {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    html.document.body!.append(input);
    final completer = Completer<void>();
    input.addEventListener('change', (_) => completer.complete());
    input.click();
    await completer.future;
    if (input.files == null || input.files!.isEmpty) {
      input.remove();
      return;
    }
    final file = input.files!.first;
    input.remove();
    if (file.size > 2 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Image must be less than 2MB'),
          backgroundColor: Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }
    setState(() => _uploading = true);
    try {
      final reader = html.FileReader();
      final readC = Completer<Uint8List?>();
      reader.onLoadEnd.listen((_) {
        final r = reader.result;
        readC.complete(r != null
            ? (r is Uint8List ? r : (r as ByteBuffer).asUint8List())
            : null);
      });
      reader.onError.listen((_) => readC.complete(null));
      reader.readAsArrayBuffer(file);
      final bytes = await readC.future;
      if (bytes == null) return;
      final ext = file.name.split('.').last.toLowerCase();
      final safeExt =
          (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) ? ext : 'jpg';
      final pth =
          'teachers/${widget.teacher['id']}/${DateTime.now().millisecondsSinceEpoch}.$safeExt';
      final url = Supabase.instance.client.storage.from('school-logos').getPublicUrl(pth);
      final uploadUrl = url.replaceAll('/object/public/', '/object/public/');
      final uri = Uri.parse(uploadUrl);
      final anonKey = 'sb_publishable_zWDvjhEldcV8eutnlRypGA_LGpOUhkg';
      final res = await http.post(uri, headers: {
        'Authorization': 'Bearer $anonKey',
        'Content-Type': 'image/$safeExt',
        'x-upsert': 'true',
      }, body: bytes);
      if (res.statusCode == 200) {
        await DbProxy.instance
            .from('teachers')
            .eq('id', widget.teacher['id'])
            .update({'passport_url': url});
        if (mounted) {
          setState(() => _photo = url);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Photo updated'),
            backgroundColor: Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        print('TEACHER EDIT ERROR: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 10),
        ));
      }
    }
    if (mounted) setState(() => _uploading = false);
  }

  Future<void> _save() async {
    final fn = _fnCtrl.text.trim();
    final ln = _lnCtrl.text.trim();
    if (fn.isEmpty || ln.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('First name and last name are required'),
        backgroundColor: Color(0xFFD32F2F),
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      final data = <String, dynamic>{
        'first_name': fn,
        'last_name': ln,
        'gender': _gender,
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'department': _deptCtrl.text.trim(),
        'qualification': _qualCtrl.text.trim(),
        'home_address': _addrCtrl.text.trim(),
      };
      await DbProxy.instance
          .from('teachers')
          .eq('id', widget.teacher['id'])
          .update(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Teacher updated successfully'),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        print('TEACHER SAVE ERROR: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 10),
        ));
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final first = (widget.teacher['first_name'] ?? '').toString();
    final last = (widget.teacher['last_name'] ?? '').toString();
    final ini = '${first.isNotEmpty ? first[0] : ''}${last.isNotEmpty ? last[0] : ''}'.toUpperCase();
    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 20,
              offset: Offset(0, -4))
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4)),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _uploading ? null : _changePhoto,
                  child: Stack(
                    children: [
                      ClipOval(
                        child: _photo.isNotEmpty
                            ? Image.network(_photo,
                                width: 88,
                                height: 88,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                    width: 88,
                                    height: 88,
                                    color: Colors.grey.shade100,
                                    child: const Icon(Icons.person,
                                        size: 36, color: Colors.grey)))
                            : Container(
                                width: 88,
                                height: 88,
                                color: const Color(0xFFF0F4FF),
                                child: Center(
                                    child: Text(ini,
                                        style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1A237E))))),
                      ),
                      if (_uploading)
                        Positioned.fill(
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                shape: BoxShape.circle),
                            child: const Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 3, color: Colors.white))),
                        ),
                      if (!_uploading && _photo.isEmpty)
                        Positioned.fill(
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                                color: const Color(0xFF1A237E),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2)),
                            child: const Icon(Icons.camera_alt_rounded,
                                size: 15, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text('Tap to change photo',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHdr('PERSONAL INFORMATION'),
                  Row(
                    children: [
                      Expanded(
                          child: _field(
                              label: 'First Name *',
                              c: _fnCtrl,
                              hint: 'First name',
                              icon: Icons.person_outline)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _field(
                              label: 'Last Name *', c: _lnCtrl, hint: 'Last name')),
                    ],
                  ),
                  DropdownButtonFormField<String>(
                    value: _gender,
                    decoration:
                        _dec(label: 'Gender', icon: Icons.wc_rounded),
                    items: const [
                      DropdownMenuItem(
                          value: 'male', child: Text('Male')),
                      DropdownMenuItem(
                          value: 'female', child: Text('Female')),
                    ],
                    onChanged: (v) => setState(() => _gender = v),
                  ),
                  const SizedBox(height: 14),
                  _field(
                      label: 'Email',
                      c: _emailCtrl,
                      hint: 'Email address',
                      icon: Icons.email_outlined,
                      kb: TextInputType.emailAddress),
                  _field(
                      label: 'Phone',
                      c: _phoneCtrl,
                      hint: 'Phone number',
                      icon: Icons.phone_outlined,
                      kb: TextInputType.phone),
                  _sectionHdr('WORK INFORMATION'),
                  _field(
                      label: 'Department',
                      c: _deptCtrl,
                      hint: 'Department',
                      icon: Icons.business_outlined),
                  _field(
                      label: 'Qualification',
                      c: _qualCtrl,
                      hint: 'Qualification'),
                  _field(
                      label: 'Home Address',
                      c: _addrCtrl,
                      hint: 'Residential address',
                      icon: Icons.location_on_outlined,
                      mx: 2),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFF0F0F0)))),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                      child: Text('Cancel',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        disabledBackgroundColor:
                            const Color(0xFF1A237E).withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Save Changes',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHdr(String t) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 8),
        child: Text(t,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9CA3AF),
                letterSpacing: 0.5)),
      );

  Widget _field(
          {required String label,
          required TextEditingController c,
          String hint = '',
          IconData? icon,
          TextInputType? kb,
          int mx = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
        decoration: _dec(label: label, hint: hint, icon: icon),
        keyboardType: kb,
        maxLines: mx,
      ),
    );
  }

  InputDecoration _dec(
      {required String label,
      String hint = '',
      IconData? icon,
      Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
      hintText: hint,
      border: const OutlineInputBorder(),
      enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE8EAED))),
      focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF1A237E), width: 2)),
      prefixIcon:
          icon != null ? Icon(icon, size: 18, color: Colors.grey.shade400) : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
    );
  }
}

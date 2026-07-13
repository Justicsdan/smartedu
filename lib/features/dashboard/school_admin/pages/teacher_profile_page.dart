import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/db_proxy.dart';

class TeacherProfilePage extends StatefulWidget {
  final Map<String, dynamic> teacherData;

  const TeacherProfilePage({super.key, required this.teacherData});

  @override
  State<TeacherProfilePage> createState() => _TeacherProfilePageState();
}

class _TeacherProfilePageState extends State<TeacherProfilePage> {
  String _photo = '';
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _photo = (widget.teacherData['passport_url'] ?? '').toString().trim();
    if (_photo.isNotEmpty) _photo = '$_photo?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _pickPhoto() async {
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
          backgroundColor: Color(0xFFD32F2F)));
      }
      return;
    }
    final readC = Completer<Uint8List?>();
    final reader = html.FileReader();
    reader.onLoadEnd.listen((_) {
      try {
        final r = reader.result;
        readC.complete(r != null ? (r is Uint8List ? r : (r as ByteBuffer).asUint8List()) : null);
      } catch (_) {
        readC.complete(null);
      }
    });
    reader.onError.listen((_) => readC.complete(null));
    reader.readAsArrayBuffer(file);
    final bytes = await readC.future;
    if (bytes == null) return;
    setState(() => _uploading = true);
    try {
      final ext = file.name.split('.').last;
      final tid = widget.teacherData['id'].toString();
      final ts = DateTime.now().millisecondsSinceEpoch; final path = 'teachers/$tid/${tid}_$ts.$ext';
      final url = Supabase.instance.client.storage.from('passports').getPublicUrl(path);
      final uploadUrl = url.replaceAll('/object/public/', '/object/');
      final uri = Uri.parse(uploadUrl);
      final anonKey = 'sb_publishable_zWDvjhEldcV8eutnlRypGA_LGpOUhkg';
      final res = await http.post(uri, headers: {
        'Authorization': 'Bearer $anonKey',
        'Content-Type': 'image/$ext',
        'x-upsert': 'true',
      }, body: bytes);
      if (res.statusCode == 200) {
        await DbProxy.instance.from('teachers').eq('id', tid).update({'passport_url': url});
        if (mounted) {
          setState(() => _photo = '$url?t=${DateTime.now().millisecondsSinceEpoch}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Passport updated successfully'), backgroundColor: Color(0xFF2E7D32)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload error: $e'), backgroundColor: Color(0xFFD32F2F)));
      }
    }
    if (mounted) setState(() => _uploading = false);
  }

  @override
  Widget build(BuildContext context) {
    final firstName = (widget.teacherData['first_name'] ?? '').toString();
    final lastName = (widget.teacherData['last_name'] ?? '').toString();
    final name = '$firstName $lastName'.trim();
    final subject = (widget.teacherData['subject'] ?? 'Not Assigned').toString();
    final email = (widget.teacherData['email'] ?? '').toString();
    final phone = (widget.teacherData['phone'] ?? '').toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Teacher Profile'),
        backgroundColor: const Color(0xFF00C9A7),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: const BoxDecoration(
                color: Color(0xFF00C9A7),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _uploading ? null : _pickPhoto,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 56,
                          backgroundColor: Colors.white,
                          backgroundImage: _photo.isNotEmpty ? NetworkImage(_photo) : null,
                          child: _photo.isEmpty
                              ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: Color(0xFF00C9A7), fontWeight: FontWeight.bold, fontSize: 36))
                              : null,
                        ),
                        if (_uploading)
                          const Positioned.fill(
                            child: CircleAvatar(
                              radius: 56,
                              backgroundColor: Colors.black54,
                              child: Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                            ),
                          ),
                        if (!_uploading)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(color: Color(0xFF1A237E), shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!_uploading)
                    Text('Tap photo to change', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7))),
                  const SizedBox(height: 8),
                  Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(Icons.work_rounded, 'Subject', subject),
                  if (email.isNotEmpty) _InfoRow(Icons.email, 'Email', email),
                  if (phone.isNotEmpty) _InfoRow(Icons.phone, 'Phone', phone),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C9A7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _InfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF00C9A7).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF00C9A7)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF00C9A7))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

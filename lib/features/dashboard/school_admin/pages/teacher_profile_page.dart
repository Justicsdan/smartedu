import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TeacherProfilePage extends StatelessWidget {
  final Map<String, dynamic> teacherData;

  const TeacherProfilePage({super.key, required this.teacherData});

  @override
  Widget build(BuildContext context) {
    final firstName = (teacherData['first_name'] ?? '').toString();
    final lastName = (teacherData['last_name'] ?? '').toString();
    final name = '$firstName $lastName'.trim();
    final passportUrl = (teacherData['passport_url'] ?? '').toString();
    final subject = (teacherData['subject'] ?? 'Not Assigned').toString();
    final email = (teacherData['email'] ?? '').toString();
    final phone = (teacherData['phone'] ?? '').toString();

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
            // [FIX] Corrected borderRadius syntax: Radius.circular required
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: const BoxDecoration(
                color: Color(0xFF00C9A7),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: Colors.white,
                    backgroundImage: passportUrl.isNotEmpty ? NetworkImage(passportUrl) : null,
                    child: passportUrl.isEmpty
                        ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: Color(0xFF00C9A7), fontWeight: FontWeight.bold, fontSize: 36))
                        : null,
                  ),
                  const SizedBox(height: 16),
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

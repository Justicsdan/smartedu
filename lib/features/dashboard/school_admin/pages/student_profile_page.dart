import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StudentProfilePage extends StatelessWidget {
  final Map<String, dynamic> studentData;

  const StudentProfilePage({super.key, required this.studentData});

  @override
  Widget build(BuildContext context) {
    final firstName = (studentData['first_name'] ?? '').toString();
    final lastName = (studentData['last_name'] ?? '').toString();
    final name = '$firstName $lastName'.trim();
    final admissionNo = (studentData['admission_no'] ?? '').toString();
    final passportUrl = (studentData['passport_url'] ?? '').toString();
    final className = (studentData['className'] ?? studentData['class_name'] ?? 'Not Assigned').toString();
    final parentEmail = (studentData['parent_email'] ?? '').toString();
    final parentPhone = (studentData['parent_phone'] ?? '').toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Student Profile'),
        backgroundColor: const Color(0xFF1A237E),
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
                color: Color(0xFF1A237E),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: Colors.white,
                    backgroundImage: passportUrl.isNotEmpty ? NetworkImage(passportUrl) : null,
                    child: passportUrl.isEmpty
                        ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold, fontSize: 36))
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  if (admissionNo.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('ADM: $admissionNo', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ),
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
                  _InfoRow(Icons.class_, 'Class', className),
                  if (parentEmail.isNotEmpty) _InfoRow(Icons.email, 'Parent Email', parentEmail),
                  if (parentPhone.isNotEmpty) _InfoRow(Icons.phone, 'Parent Phone', parentPhone),
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
                  backgroundColor: const Color(0xFF1A237E),
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
              color: const Color(0xFF1A237E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF1A237E), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A237E))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

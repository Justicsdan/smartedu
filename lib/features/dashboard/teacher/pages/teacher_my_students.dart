import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartedu/core/teacher_provider.dart';

class TeacherMyStudentsPage extends StatelessWidget {
  const TeacherMyStudentsPage({super.key});

  String _studentName(Map<String, dynamic> s) {
    final first = (s['first_name'] ?? '').toString().trim();
    final last = (s['last_name'] ?? '').toString().trim();
    return '$first $last'.trim();
  }

  String _studentClass(Map<String, dynamic> s) {
    final cls = s['classes'] as Map<String, dynamic>? ?? {};
    final name = cls['name']?.toString() ?? '';
    final section = cls['section']?.toString() ?? '';
    return section.isNotEmpty ? '$name $section' : name;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TeacherProvider>();
    final isFormTeacher = provider.formTeacherClassId != null;
    final formClassStudents = isFormTeacher ? provider.getStudentsInClass(provider.formTeacherClassId!) : <Map<String, dynamic>>[];
    final allStudentIds = <String>{};
    for (final classId in provider.assignedClassIds) {
      for (final s in provider.getStudentsInClass(classId)) {
        allStudentIds.add(s['id'].toString());
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("My Students", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
          const SizedBox(height: 8),
          Text(isFormTeacher ? "You are the form teacher of ${provider.getClassName(provider.formTeacherClassId)}" : "Students from your assigned classes", style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 24),
          if (isFormTeacher) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade200)),
              child: Row(
                children: [
                  const Icon(Icons.supervisor_account_rounded, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Form Teacher Class", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        Text("${provider.getClassName(provider.formTeacherClassId)} - ${formClassStudents.length} Students", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (formClassStudents.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No students in your class yet", style: TextStyle(color: Colors.grey))))
            else
              ...formClassStudents.map((s) => _StudentCard(student: s, studentName: _studentName(s), studentClass: _studentClass(s))),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
          ],
          if (allStudentIds.isNotEmpty) ...[
            const Text("All Students (From Assigned Classes)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
            const SizedBox(height: 16),
            ...provider.students.where((s) => allStudentIds.contains(s['id'].toString())).map((s) => _StudentCard(student: s, studentName: _studentName(s), studentClass: _studentClass(s))),
          ],
          if (allStudentIds.isEmpty && !isFormTeacher)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(60),
                child: Column(
                  children: [
                    Icon(Icons.people_outline, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text("No students found", style: TextStyle(fontSize: 16, color: Colors.grey)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final Map<String, dynamic> student;
  final String studentName;
  final String studentClass;

  const _StudentCard({required this.student, required this.studentName, required this.studentClass});

  @override
  Widget build(BuildContext context) {
    final initial = studentName.isNotEmpty ? studentName[0].toUpperCase() : '?';
    final admissionNo = student['admission_no']?.toString() ?? student['id']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF0D47A1).withOpacity(0.1),
            child: Text(
              initial,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF111827))),
                Text("Adm: $admissionNo", style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          if (studentClass.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(20)),
              child: Text(studentClass, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange)),
            ),
        ],
      ),
    );
  }
}

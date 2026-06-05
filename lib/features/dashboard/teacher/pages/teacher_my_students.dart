// ==========================================
// File: lib/features/dashboard/teacher/pages/teacher_my_students.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartedu/core/providers/teacher/teacher_provider.dart';

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
    final formClassStudents = isFormTeacher
        ? provider.getStudentsInClass(provider.formTeacherClassId!)
        : <Map<String, dynamic>>[];
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
          const Text(
            'My Students',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isFormTeacher
                ? 'You are the form teacher of ${provider.getClassName(provider.formTeacherClassId)}'
                : 'Students from your assigned classes',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          if (isFormTeacher) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF00695C).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2F1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.supervisor_account_rounded,
                        color: Color(0xFF00695C)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Form Teacher Class',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF00695C),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${provider.getClassName(provider.formTeacherClassId)} \u00B7 ${formClassStudents.length} student${formClassStudents.length != 1 ? 's' : ''}',
                          style: const TextStyle(
                              fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2F1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle,
                            size: 14, color: Color(0xFF00695C)),
                        SizedBox(width: 4),
                        Text(
                          'Active',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF00695C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (formClassStudents.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.people_outline,
                            size: 28, color: Colors.grey.shade400),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No students in your class yet',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              for (int i = 0; i < formClassStudents.length; i++)
                _StudentCard(
                  student: formClassStudents[i],
                  studentName: _studentName(formClassStudents[i]),
                  studentClass: _studentClass(formClassStudents[i]),
                  index: i,
                ),
            const SizedBox(height: 28),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              height: 1,
              color: const Color(0xFFE8EAED),
            ),
            const SizedBox(height: 20),
          ],
          if (allStudentIds.isNotEmpty) ...[
            Row(
              children: [
                const Text(
                  'All Students (Assigned Classes)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${allStudentIds.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final s in provider.students
                .where((s) => allStudentIds.contains(s['id'].toString()))
                .toList())
              _StudentCard(
                student: s,
                studentName: _studentName(s),
                studentClass: _studentClass(s),
                index: provider.students.indexOf(s),
              ),
          ],
          if (allStudentIds.isEmpty && !isFormTeacher)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(60),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FA),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(Icons.people_outline,
                          size: 32, color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No students found',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Students will appear once assigned to your classes.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
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
  final int index;

  const _StudentCard({
    required this.student,
    required this.studentName,
    required this.studentClass,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final initial =
        studentName.isNotEmpty ? studentName[0].toUpperCase() : '?';
    final admissionNo = student['admission_no']?.toString() ??
        student['id']?.toString() ??
        '';
    final passportUrl = (student['passport_url'] ?? '').toString().trim();
    final gender =
        (student['gender'] ?? '').toString().trim().toLowerCase();

    Color avatarBg;
    Color avatarText;
    if (gender == 'female') {
      avatarBg = const Color(0xFFFCE4EC);
      avatarText = const Color(0xFFC62828);
    } else {
      avatarBg = const Color(0xFFF0F4FF);
      avatarText = const Color(0xFF1A237E);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: index.isEven ? Colors.white : const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: avatarBg,
            backgroundImage:
                passportUrl.isNotEmpty ? NetworkImage(passportUrl) : null,
            onBackgroundImageError:
                passportUrl.isNotEmpty ? (_, __) {} : null,
            child: passportUrl.isEmpty
                ? Text(
                    initial,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: avatarText,
                      fontSize: 16,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Adm: $admissionNo',
                  style:
                      const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (studentClass.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                studentClass,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE65100),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ==========================================
// File: lib/features/dashboard/teacher/pages/teacher_my_classes.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartedu/core/providers/teacher/teacher_provider.dart';

class TeacherMyClassesPage extends StatelessWidget {
  const TeacherMyClassesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TeacherProvider>();
    final assigned = provider.mySubjectAssignments;

    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final a in assigned) {
      final classId = a['class_id']?.toString() ?? '';
      if (classId.isEmpty) continue;
      grouped.putIfAbsent(classId, () => []).add(a);
    }

    final ftClass = provider.getFormTeacherClass();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Classes & Subjects',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Classes and subjects assigned to you by the school admin',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          if (ftClass != null)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF00695C).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2F1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.supervisor_account,
                              color: Color(0xFF00695C)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'FORM TEACHER',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF00695C),
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${ftClass['name'] ?? ''} ${ftClass['section'] ?? ''}'
                                    .trim(),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111827),
                                ),
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.people,
                                  size: 14, color: Color(0xFF00695C)),
                              const SizedBox(width: 4),
                              Text(
                                '${provider.getStudentsInClass(ftClass['id']?.toString() ?? '').length} Students',
                                style: const TextStyle(
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
                ],
              ),
            ),

          if (assigned.isEmpty && ftClass == null)
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
                      child: Icon(Icons.class_outlined,
                          size: 32, color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No classes assigned yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Contact your school admin to get assigned',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            for (final entry in grouped.entries)
              _ClassCard(
                classId: entry.key,
                subjects: entry.value,
                provider: provider,
              ),
        ],
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final String classId;
  final List<Map<String, dynamic>> subjects;
  final TeacherProvider provider;

  const _ClassCard({
    required this.classId,
    required this.subjects,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final className = provider.getClassName(classId);
    final students = provider.getStudentsInClass(classId);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.class_rounded,
                      color: Color(0xFF1A237E)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        className,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${students.length} student${students.length != 1 ? 's' : ''}',
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
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${subjects.length} subject${subjects.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE65100),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: const Color(0xFFE8EAED),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in subjects)
                  _SubjectPill(
                    subject: s['subjects'] as Map<String, dynamic>? ?? {},
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectPill extends StatelessWidget {
  final Map<String, dynamic> subject;

  const _SubjectPill({required this.subject});

  @override
  Widget build(BuildContext context) {
    final name = subject['name']?.toString() ?? 'Unknown';
    final code = subject['code']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FFF4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.menu_book, size: 15, color: Color(0xFF2E7D32)),
          const SizedBox(width: 6),
          Text(
            name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E7D32),
            ),
          ),
          if (code.isNotEmpty) ...[
            const SizedBox(width: 5),
            Text(
              '($code)',
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF81C784)),
            ),
          ],
        ],
      ),
    );
  }
}

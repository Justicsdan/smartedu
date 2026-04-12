import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartedu/core/teacher_provider.dart';

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
          const Text("My Classes & Subjects", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
          const SizedBox(height: 8),
          const Text("Classes and subjects assigned to you by the school admin", style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 24),

          // Form Master class card
          if (ftClass != null)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.teal.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
                    child: Row(
                      children: [
                        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.teal, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.supervisor_account, color: Colors.white)),
                        const SizedBox(width: 16),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text("Form Teacher", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.teal, letterSpacing: 0.5)),
                          const SizedBox(height: 2),
                          Text("${ftClass['name'] ?? ''} ${ftClass['section'] ?? ''}".trim(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                        ])),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: Colors.teal.shade100, borderRadius: BorderRadius.circular(20)),
                          child: Text("${provider.getStudentsInClass(ftClass['id']?.toString() ?? '').length} Students", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.teal)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Subject teacher assignments grouped by class
          if (assigned.isEmpty && ftClass == null)
            const Center(child: Padding(padding: EdgeInsets.all(60), child: Column(children: [
              Icon(Icons.class_outlined, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text("No classes assigned yet", style: TextStyle(fontSize: 16, color: Colors.grey)),
              SizedBox(height: 8),
              Text("Contact your school admin to get assigned", style: TextStyle(fontSize: 13, color: Colors.grey)),
            ])))
          else
            ...grouped.entries.map((entry) {
              final className = provider.getClassName(entry.key);
              final subjects = entry.value;
              final students = provider.getStudentsInClass(entry.key);

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFF0D47A1).withOpacity(0.05), borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
                      child: Row(
                        children: [
                          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF0D47A1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.class_rounded, color: Colors.white)),
                          const SizedBox(width: 16),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(className, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                            Text("${students.length} Students", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                          ])),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(20)), child: Text("${subjects.length} Subject(s)", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange))),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: subjects.map((s) {
                          final subj = s['subjects'] as Map<String, dynamic>? ?? {};
                          final subjName = subj['name']?.toString() ?? 'Unknown';
                          final subjCode = subj['code']?.toString() ?? '';
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.orange.shade200)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.menu_book, size: 16, color: Colors.orange),
                              const SizedBox(width: 8),
                              Text(subjName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.orange)),
                              if (subjCode.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Text("($subjCode)", style: TextStyle(fontSize: 11, color: Colors.orange.shade400)),
                              ],
                            ]),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

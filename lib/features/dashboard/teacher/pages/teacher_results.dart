import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartedu/core/providers/teacher/teacher_provider.dart';

class TeacherResultsPage extends StatelessWidget {
  const TeacherResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TeacherProvider>();
    
    // FIX: Added null-aware operator '?' to prevent crash on null map
    final myScores = provider.scores
        .where((s) => s['recordedBy'] == provider.currentTeacher?['id'])
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Score Records",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Scores you have entered for students",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          if (myScores.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(60),
                child: Column(
                  children: [
                    Icon(Icons.bar_chart_outlined, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      "No scores recorded yet",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Go to 'Enter Scores' to add scores",
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(
                  const Color(0xFF0D47A1).withOpacity(0.05),
                ),
                columns: const [
                  DataColumn(label: Text('Student')),
                  DataColumn(label: Text('Class')),
                  DataColumn(label: Text('Subject')),
                  DataColumn(label: Text('CA1'), numeric: true),
                  DataColumn(label: Text('CA2'), numeric: true),
                  DataColumn(label: Text('Exam'), numeric: true),
                  DataColumn(label: Text('Total'), numeric: true),
                ],
                rows: myScores
                    .map((s) => DataRow(
                          cells: [
                            DataCell(Text(s['studentName'] ?? 'Unknown')),
                            DataCell(Text(provider.getClassName(s['classId']))),
                            DataCell(Text(provider.getSubjectName(s['subjectId']))),
                            DataCell(Text('${s['ca1'] ?? 0}')),
                            DataCell(Text('${s['ca2'] ?? 0}')),
                            DataCell(Text('${s['exam'] ?? 0}')),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (s['total'] ?? 0) >= 50
                                      ? Colors.green.shade50
                                      : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${s['total'] ?? 0}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: (s['total'] ?? 0) >= 50
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

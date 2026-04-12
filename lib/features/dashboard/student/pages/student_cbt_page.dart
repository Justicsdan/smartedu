import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartedu/core/providers/student/student_provider.dart';

class StudentCbtPage extends StatelessWidget {
  const StudentCbtPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.quiz_rounded, color: Color(0xFF2E7D32), size: 28),
                SizedBox(width: 16),
                Text("CBT Exams", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (provider.cbtExams.isEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.all(60),
                child: Column(
                  children: [
                    Icon(Icons.quiz_outlined, size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text("No CBT exams available", style: TextStyle(fontSize: 18, color: Colors.grey.shade500)),
                    const SizedBox(height: 8),
                    Text("Your exams will appear here when teachers create them", style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
                  ],
                ),
              ),
            )
          else
            ...provider.cbtExams.map((exam) {
              final isActive = exam['isActive'] == true;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isActive ? Colors.green.shade200 : Colors.grey.shade100,
                    width: isActive ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isActive ? Icons.play_circle_rounded : Icons.lock_clock_rounded,
                        color: isActive ? Colors.green : Colors.grey,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exam['title'] ?? 'CBT Exam',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B2A4A)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${exam['className'] ?? ''} • ${exam['subjectName'] ?? ''}",
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          if (exam['duration'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              "Duration: ${exam['duration']} minutes",
                              style: const TextStyle(fontSize: 12, color: Colors.orange),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isActive)
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.play_arrow),
                        label: const Text("Start"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "Not Available",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
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

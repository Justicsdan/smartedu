import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartedu/core/providers/student/student_provider.dart';

class StudentHomePage extends StatelessWidget {
  const StudentHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<StudentProvider>();
    final passport = p.passportUrl;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _welcomeBanner(p, passport),
          const SizedBox(height: 20),
          _sectionTitle('Quick Stats'),
          const SizedBox(height: 14),
          Row(
            children: [
              _statCard('Subjects', '${p.scores.length}', Icons.menu_book_rounded, const Color(0xFF1A237E)),
              const SizedBox(width: 12),
              _statCard('Average', '${p.getOverallAverage().toStringAsFixed(1)}%', Icons.trending_up_rounded, const Color(0xFF2E7D32)),
            ],
          ),
          const SizedBox(height: 24),
          _sectionTitle('Recent Results'),
          const SizedBox(height: 14),
          if (p.scores.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE8EAED))),
              child: const Column(
                children: [
                  Icon(Icons.grading_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No results available yet', style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            )
          else
            ...p.scores.take(3).map((score) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8EAED))),
              child: Row(
                children: [
                  Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.assignment_rounded, size: 18, color: Color(0xFF1A237E))),
                  const SizedBox(width: 12),
                  Expanded(child: Text(score['subjectName'] ?? 'Subject', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF111827)))),
                  Text('${score['total'] ?? 0}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _welcomeBanner(StudentProvider p, String passport) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1A237E), Color(0xFF3949AB)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF1A237E).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withOpacity(0.15),
            backgroundImage: passport.isNotEmpty ? NetworkImage(passport) : null,
            onBackgroundImageError: passport.isNotEmpty ? (_, __) {} : null,
            child: passport.isEmpty ? const Icon(Icons.person, size: 32, color: Colors.white70) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome Back,', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6))),
                const SizedBox(height: 4),
                Text(p.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 2),
                Text(p.classDisplay, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)));
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8EAED))),
        child: Row(
          children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 20, color: color)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
              Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ]),
          ],
        ),
      ),
    );
  }
}

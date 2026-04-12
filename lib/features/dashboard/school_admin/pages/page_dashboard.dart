// ==========================================
// File: lib/features/dashboard/school_admin/pages/page_dashboard.dart
// ==========================================
import 'package:flutter/material.dart';

class PageDashboard extends StatelessWidget {
  final int studentCount,
      teacherCount,
      classCount,
      subjectCount,
      assignmentCount,
      activeCbtCount;
  final List<Map<String, dynamic>> classes;

  const PageDashboard({
    super.key,
    required this.studentCount,
    required this.teacherCount,
    required this.classCount,
    required this.subjectCount,
    required this.assignmentCount,
    required this.activeCbtCount,
    required this.classes,
  });

  @override
  Widget build(BuildContext context) {
    int sssCount = 0;
    int jssCount = 0;
    int primaryCount = 0;
    int unassigned = 0;
    for (final c in classes) {
      final tier = (c['tier'] ?? '').toString().toUpperCase();
      if (tier == 'JSS') {
        jssCount++;
      } else if (tier == 'PRIMARY') {
        primaryCount++;
      } else {
        sssCount++;
      }
      if (c['tier'] == null || c['tier'].toString().isEmpty) unassigned++;
    }

    return Container(
      color: const Color(0xFFF7F8FA),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$studentCount students  ·  $teacherCount teachers  ·  $classCount classes  ·  $subjectCount subjects',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 28),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.45,
              ),
              children: [
                _StatCard(
                  title: 'Students',
                  value: '$studentCount',
                  icon: Icons.people_rounded,
                  iconBg: const Color(0xFFF0F4FF),
                  iconColor: const Color(0xFF1A237E),
                  accentColor: const Color(0xFF1A237E),
                ),
                _StatCard(
                  title: 'Teachers',
                  value: '$teacherCount',
                  icon: Icons.person_pin_rounded,
                  iconBg: const Color(0xFFFFF3E0),
                  iconColor: const Color(0xFFE65100),
                  accentColor: const Color(0xFFE65100),
                ),
                _StatCard(
                  title: 'Classes',
                  value: '$classCount',
                  icon: Icons.layers_rounded,
                  iconBg: const Color(0xFFF3E5F5),
                  iconColor: const Color(0xFF7B1FA2),
                  accentColor: const Color(0xFF7B1FA2),
                ),
                _StatCard(
                  title: 'Subjects',
                  value: '$subjectCount',
                  icon: Icons.menu_book_rounded,
                  iconBg: const Color(0xFFF0FFF4),
                  iconColor: const Color(0xFF2E7D32),
                  accentColor: const Color(0xFF2E7D32),
                ),
                _StatCard(
                  title: 'Assignments',
                  value: '$assignmentCount',
                  icon: Icons.assignment_rounded,
                  iconBg: const Color(0xFFFFF8E1),
                  iconColor: const Color(0xFFF57F17),
                  accentColor: const Color(0xFFF57F17),
                ),
                _StatCard(
                  title: 'Active CBTs',
                  value: '$activeCbtCount',
                  icon: Icons.quiz_rounded,
                  iconBg: const Color(0xFFFFEBEE),
                  iconColor: const Color(0xFFB71C1C),
                  accentColor: const Color(0xFFB71C1C),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8EAED)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.bar_chart_rounded, size: 18, color: Color(0xFF1A237E)),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Class Distribution',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _tierPill('SSS', sssCount, bg: const Color(0xFFE3F2FD), fg: const Color(0xFF1565C0)),
                      const SizedBox(width: 10),
                      _tierPill('JSS', jssCount, bg: const Color(0xFFFFF3E0), fg: const Color(0xFFE65100)),
                      const SizedBox(width: 10),
                      _tierPill('PRIMARY', primaryCount, bg: const Color(0xFFF3E5F5), fg: const Color(0xFF7B1FA2)),
                      const SizedBox(width: 10),
                      if (unassigned > 0)
                        _tierPill('Unassigned', unassigned, bg: Colors.grey.shade200, fg: Colors.grey.shade600),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$unassigned class${unassigned != 1 ? 'es' : ''} have no tier set',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.class_rounded, size: 17, color: Color(0xFF7B1FA2)),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Classes Overview',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...classes.map((c) {
              final className = "${c['name']} - ${c['section'] ?? ''}";
              final studentCount = c['studentCount'] ?? 0;
              final tier = (c['tier'] ?? '').toString().toUpperCase();
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8EAED)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(className, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 22,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(6)),
                                  child: Text('$studentCount', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1A237E))),
                                ),
                                const SizedBox(width: 6),
                                Text('Students', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (tier.isNotEmpty) ...[
                        _tierBadge(tier),
                        const SizedBox(width: 8),
                      ],
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: IconButton(
                          icon: Icon(Icons.people_outline, size: 18, color: Colors.grey.shade400),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          onPressed: () {},
                          tooltip: 'View students',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _StatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(height: 14),
          Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _tierPill(String label, int count, {required Color bg, required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
      child: Text('$label ($count)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg, letterSpacing: 0.5)),
    );
  }

  Widget _tierBadge(String tier) {
    final colorMap = {'SSS': const Color(0xFFE3F2FD), 'JSS': const Color(0xFFFFF3E0), 'PRIMARY': const Color(0xFFF3E5F5), 'UNASSIGNED': Colors.grey.shade200};
    final textMap = {'SSS': const Color(0xFF1565C0), 'JSS': const Color(0xFFE65100), 'PRIMARY': const Color(0xFF7B1FA2), 'UNASSIGNED': Colors.grey.shade600};
    final bg = colorMap[tier] ?? Colors.grey.shade200;
    final fg = textMap[tier] ?? Colors.grey.shade600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
      child: Text(tier, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg, letterSpacing: 0.5)),
    );
  }
}

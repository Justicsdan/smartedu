// ==========================================
// File: lib/features/dashboard/school_admin/pages/page_dashboard.dart
// ==========================================
import 'package:flutter/material.dart';

class PageDashboard extends StatefulWidget {
  final int studentCount;
  final int teacherCount;
  final int classCount;
  final int subjectCount;
  final int assignmentCount;
  final int activeCbtCount;
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
  State<PageDashboard> createState() => _PageDashboardState();
}

class _PageDashboardState extends State<PageDashboard> {
  int _hoveredCard = -1;
  int _hoveredClass = -1;

  @override
  Widget build(BuildContext context) {
    int sssCount = 0;
    int jssCount = 0;
    int primaryCount = 0;
    int unassigned = 0;
    for (final c in widget.classes) {
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

    final total = widget.classes.isNotEmpty ? widget.classes.length : 1;

    return Container(
      color: const Color(0xFFF7F8FA),
      child: Column(
        children: [
          Container(
            height: 3,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1A237E),
                  Color(0xFF3949AB),
                  Color(0xFF7B1FA2),
                  Color(0xFFE65100),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _summaryChip('${widget.studentCount} Students', Icons.people_rounded, const Color(0xFF1A237E)),
                      _summaryChip('${widget.teacherCount} Teachers', Icons.person_pin_rounded, const Color(0xFFE65100)),
                      _summaryChip('${widget.classCount} Classes', Icons.layers_rounded, const Color(0xFF7B1FA2)),
                      _summaryChip('${widget.subjectCount} Subjects', Icons.menu_book_rounded, const Color(0xFF2E7D32)),
                    ],
                  ),
                  const SizedBox(height: 28),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossCount = constraints.maxWidth > 950
                          ? 3
                          : constraints.maxWidth > 620
                              ? 2
                              : 1;
                      return GridView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.5,
                        ),
                        children: [
                          _statCard(0, 'Students', '${widget.studentCount}', Icons.people_rounded, const Color(0xFFF0F4FF), const Color(0xFF1A237E), const Color(0xFFE8EAF6)),
                          _statCard(1, 'Teachers', '${widget.teacherCount}', Icons.person_pin_rounded, const Color(0xFFFFF3E0), const Color(0xFFE65100), const Color(0xFFFBE9E7)),
                          _statCard(2, 'Classes', '${widget.classCount}', Icons.layers_rounded, const Color(0xFFF3E5F5), const Color(0xFF7B1FA2), const Color(0xFFF3E5F5)),
                          _statCard(3, 'Subjects', '${widget.subjectCount}', Icons.menu_book_rounded, const Color(0xFFF0FFF4), const Color(0xFF2E7D32), const Color(0xFFE8F5E9)),
                          _statCard(4, 'Assignments', '${widget.assignmentCount}', Icons.assignment_rounded, const Color(0xFFFFF8E1), const Color(0xFFF57F17), const Color(0xFFFCEFC7)),
                          _statCard(5, 'Active CBTs', '${widget.activeCbtCount}', Icons.quiz_rounded, const Color(0xFFFFEBEE), const Color(0xFFB71C1C), const Color(0xFFFFCDD2)),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final twoCol = constraints.maxWidth > 720;
                      if (twoCol) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _distributionCard(sssCount, jssCount, primaryCount, unassigned, total)),
                            const SizedBox(width: 16),
                            Expanded(child: _quickInfoCard()),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          _distributionCard(sssCount, jssCount, primaryCount, unassigned, total),
                          const SizedBox(height: 16),
                          _quickInfoCard(),
                        ],
                      );
                    },
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
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E5F5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${widget.classes.length}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF7B1FA2)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (widget.classes.isEmpty)
                    _emptyState()
                  else
                    ...widget.classes.asMap().entries.map((e) => _classCard(e.value, e.key)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _statCard(int index, String title, String value, IconData icon, Color iconBg, Color accent, Color lightBg) {
    final hovered = _hoveredCard == index;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredCard = index),
      onExit: (_) => setState(() => _hoveredCard = -1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: hovered ? lightBg.withOpacity(0.35) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: hovered ? accent.withOpacity(0.3) : const Color(0xFFE8EAED)),
          boxShadow: hovered
              ? [BoxShadow(color: accent.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 6))]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 3,
              width: 32,
              decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, size: 22, color: accent),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withOpacity(hovered ? 0.1 : 0.04),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: hovered ? accent : const Color(0xFF111827),
                letterSpacing: -1.2,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _distributionCard(int sss, int jss, int primary, int unassigned, int total) {
    final sssPct = (sss / total * 100).round();
    final jssPct = (jss / total * 100).round();
    final primaryPct = (primary / total * 100).round();
    final unassignedPct = (unassigned / total * 100).round();

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
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.bar_chart_rounded, size: 18, color: Color(0xFF1A237E)),
              ),
              const SizedBox(width: 12),
              const Text('Class Distribution', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            ],
          ),
          const SizedBox(height: 20),
          if (widget.classes.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 30,
                child: Row(
                  children: [
                    if (sss > 0)
                      Expanded(flex: sss, child: _barSegment(sssPct, const Color(0xFF1565C0), 'SSS')),
                    if (jss > 0)
                      Expanded(flex: jss, child: _barSegment(jssPct, const Color(0xFFE65100), 'JSS')),
                    if (primary > 0)
                      Expanded(flex: primary, child: _barSegment(primaryPct, const Color(0xFF7B1FA2), 'PRI')),
                    if (unassigned > 0)
                      Expanded(flex: unassigned, child: _barSegment(unassignedPct, Colors.grey[400]!, '?')),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 18,
            runSpacing: 10,
            children: [
              _legendDot('SSS', sss, const Color(0xFF1565C0)),
              _legendDot('JSS', jss, const Color(0xFFE65100)),
              _legendDot('PRIMARY', primary, const Color(0xFF7B1FA2)),
              if (unassigned > 0) _legendDot('Unassigned', unassigned, Colors.grey[500]!),
            ],
          ),
          if (unassigned > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange[200]!)),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange[700]),
                  const SizedBox(width: 6),
                  Text('$unassigned class${unassigned != 1 ? 'es' : ''} have no tier set', style: TextStyle(fontSize: 12, color: Colors.orange[800], fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _barSegment(int pct, Color color, String label) {
    return Container(
      alignment: Alignment.center,
      color: color,
      child: pct >= 15 ? Text('$label $pct%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.3)) : null,
    );
  }

  Widget _legendDot(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text('$label ($count)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
      ],
    );
  }

  Widget _quickInfoCard() {
    final ratio = widget.teacherCount > 0 ? (widget.studentCount / widget.teacherCount).toStringAsFixed(1) : 'N/A';
    final avgPerClass = widget.classCount > 0 ? (widget.studentCount / widget.classCount).round() : 'N/A';
    final subjPerClass = widget.classCount > 0 ? (widget.subjectCount / widget.classCount).toStringAsFixed(1) : 'N/A';

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
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: const Color(0xFFF0FFF4), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.insights_rounded, size: 18, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(width: 12),
              const Text('Quick Overview', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            ],
          ),
          const SizedBox(height: 18),
          _metricRow('Student : Teacher', ratio, const Color(0xFF1A237E)),
          const SizedBox(height: 12),
          _metricRow('Avg Students / Class', '$avgPerClass', const Color(0xFF7B1FA2)),
          const SizedBox(height: 12),
          _metricRow('Avg Subjects / Class', subjPerClass, const Color(0xFF2E7D32)),
          const SizedBox(height: 12),
          _metricRow('Active CBT Exams', '${widget.activeCbtCount}', const Color(0xFFB71C1C)),
          const SizedBox(height: 12),
          _metricRow('Total Assignments', '${widget.assignmentCount}', const Color(0xFFF57F17)),
        ],
      ),
    );
  }

  Widget _metricRow(String label, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF0F1F3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: accent.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
            child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: accent)),
          ),
        ],
      ),
    );
  }

  Widget _classCard(Map<String, dynamic> c, int index) {
    final hovered = _hoveredClass == index;
    final name = c['name']?.toString() ?? '';
    final section = c['section']?.toString() ?? '';
    final className = section.isNotEmpty ? '$name - $section' : name;
    final studentCount = c['studentCount'] ?? 0;
    final tier = (c['tier'] ?? '').toString().toUpperCase();

    final tierColor = tier == 'JSS'
        ? const Color(0xFFE65100)
        : tier == 'PRIMARY'
            ? const Color(0xFF7B1FA2)
            : const Color(0xFF1565C0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredClass = index),
      onExit: (_) => setState(() => _hoveredClass = -1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: hovered ? tierColor.withOpacity(0.03) : (index.isEven ? Colors.white : const Color(0xFFFAFBFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hovered ? tierColor.withOpacity(0.3) : const Color(0xFFE8EAED)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 38,
                decoration: BoxDecoration(color: tierColor, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(className, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.people_outline_rounded, size: 13, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text('$studentCount student${studentCount != 1 ? 's' : ''}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
                  ],
                ),
              ),
              if (tier.isNotEmpty) ...[
                _tierBadge(tier),
                const SizedBox(width: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _tierBadge(String tier) {
    final bgs = {'SSS': const Color(0xFFE3F2FD), 'JSS': const Color(0xFFFFF3E0), 'PRIMARY': const Color(0xFFF3E5F5)};
    final fgs = {'SSS': const Color(0xFF1565C0), 'JSS': const Color(0xFFE65100), 'PRIMARY': const Color(0xFF7B1FA2)};
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bgs[tier] ?? Colors.grey[200], borderRadius: BorderRadius.circular(6)),
      child: Text(tier, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fgs[tier] ?? Colors.grey[600], letterSpacing: 0.5)),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: const Color(0xFFF3E5F5), borderRadius: BorderRadius.circular(16)),
              child: Icon(Icons.class_rounded, size: 28, color: const Color(0xFF7B1FA2).withOpacity(0.6)),
            ),
            const SizedBox(height: 16),
            Text('No classes yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey[700])),
            const SizedBox(height: 4),
            Text('Create your first class to get started', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }
}

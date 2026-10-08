// ==========================================
// File: lib/features/dashboard/school_admin/pages/page_dashboard.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/db_proxy.dart';
import '../../../../core/providers/school_admin_provider.dart';
import '../widgets/admin_subject_averages_chart.dart';
import '../widgets/admin_attendance_trend_chart.dart';
import '../widgets/admin_ace_subject_chart.dart';

class PageDashboard extends StatefulWidget {
  final int studentCount;
  final int teacherCount;
  final int classCount;
  final int subjectCount;
  final int assignmentCount;
  final int activeCbtCount;
  final List<Map<String, dynamic>> classes;
  final String schoolName;
  final String schoolUrl;
  final ValueChanged<int>? onNavigate;

  const PageDashboard({
    super.key,
    required this.studentCount,
    required this.teacherCount,
    required this.classCount,
    required this.subjectCount,
    required this.assignmentCount,
    required this.activeCbtCount,
    required this.classes,
    this.schoolName = '',
    this.schoolUrl = '',
    this.onNavigate,
  });

  @override
  State<PageDashboard> createState() => _PageDashboardState();
}

class _PageDashboardState extends State<PageDashboard> {
  bool _hideEmptyClasses = false;
  bool _aceLoading = true;
  Set<String> _studentsWithPace = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAceProgress());
  }

  Future<void> _loadAceProgress() async {
    final provider = context.read<SchoolAdminProvider>();
    final isAce = provider.schoolSettings?['curriculum_mode'] == 'ace';
    if (!isAce) {
      if (mounted) setState(() => _aceLoading = false);
      return;
    }
    final sid = provider.currentSession?['id']?.toString() ?? '';
    final tid = provider.currentTerm?['id']?.toString() ?? '';
    if (sid.isEmpty || tid.isEmpty) {
      if (mounted) setState(() => _aceLoading = false);
      return;
    }
    try {
      final res = await DbProxy.instance.from('ace_pace_scores')
          .select('student_id')
          .eq('school_id', provider.schoolId)
          .eq('session_id', sid)
          .eq('term_id', tid)
          .get();
      if (mounted) {
        setState(() {
          _studentsWithPace = res.map((e) => e['student_id'] as String).toSet();
          _aceLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _aceLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.read<SchoolAdminProvider>();
    final isAce = provider.schoolSettings?['curriculum_mode'] == 'ace';

    // Strictly check if any student is assigned to the class in the provider
    final displayedClasses = _hideEmptyClasses
        ? widget.classes.where((c) => provider.students.any((s) => s['class_id'] == c['id'])).toList()
        : widget.classes;

    return Container(
      color: const Color(0xFFF8FAFC),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER WITH LOGO ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome back!', style: theme.textTheme.headlineSmall?.copyWith(color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        Text(widget.schoolName, style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
                      ],
                    ),
                  ),
                  if (widget.schoolUrl.isNotEmpty)
                    Container(
                      width: 110, // Bumped up size for desktop visibility
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF1A237E).withOpacity(0.3), width: 3), // Subtle blue border
                        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.network(
                          widget.schoolUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.school, size: 60, color: Color(0xFF1A237E)),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // --- SECTION A: STAT CARDS ---
              _buildStatCards(theme, isAce),
              const SizedBox(height: 32),

              // --- SECTION B: QUICK ACCESS ---
              _buildSectionHeader(theme, 'Quick Access', Icons.apps_rounded),
              const SizedBox(height: 16),
              _buildQuickAccess(theme, isAce),
              const SizedBox(height: 32),

              // --- SECTION C: RECORDING PROGRESS ---
              _buildSectionHeader(theme, isAce ? 'PACE Entry Progress' : 'Recording Progress', Icons.assignment_turned_in_rounded),
              const SizedBox(height: 16),
              _buildRecordingProgress(theme, provider, displayedClasses, isAce),
              const SizedBox(height: 32),

              // --- SECTION D: VISUAL ANALYTICS ---
              _buildSectionHeader(theme, isAce ? 'Subject PT Averages' : 'Subject Performance', Icons.bar_chart_rounded),
              const SizedBox(height: 16),
              _buildAnalyticsSection(theme, isAce),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildStatCards(ThemeData theme, bool isAce) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _statCard(theme, 'Students', widget.studentCount, Icons.people_rounded, const Color(0xFF1A237E), const Color(0xFFE8EAF6), 1),
        _statCard(theme, 'Teachers', widget.teacherCount, Icons.person_pin_rounded, const Color(0xFFE65100), const Color(0xFFFBE9E7), 2),
        _statCard(theme, 'Classes', widget.classCount, Icons.layers_rounded, const Color(0xFF7B1FA2), const Color(0xFFF3E5F5), 3),
        _statCard(theme, 'Subjects', widget.subjectCount, Icons.menu_book_rounded, const Color(0xFF00838F), const Color(0xFFE0F7FA), 3),
        if (!isAce) _statCard(theme, 'Assignments', widget.assignmentCount, Icons.task_rounded, const Color(0xFF2E7D32), const Color(0xFFE8F5E9), 3),
        _statCard(theme, 'Active CBTs', widget.activeCbtCount, Icons.computer_rounded, const Color(0xFFC62828), const Color(0xFFFFEBEE), 6),
      ],
    );
  }

  Widget _statCard(ThemeData theme, String label, int count, IconData icon, Color color, Color bg, int? navIndex) {
    return SizedBox(
      width: 220,
      child: InkWell(
        onTap: navIndex != null ? () => widget.onNavigate?.call(navIndex) : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 16),
              Text(count.toString(), style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
              const SizedBox(height: 4),
              Text(label, style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccess(ThemeData theme, bool isAce) {
    final items = [
      {'icon': Icons.people_rounded, 'title': 'Students', 'desc': 'View & manage all students', 'color': const Color(0xFF1A237E), 'bg': const Color(0xFFE8EAF6), 'index': 1},
      {'icon': Icons.person_pin_rounded, 'title': 'Teachers', 'desc': 'Staff list, roles & assignments', 'color': const Color(0xFFE65100), 'bg': const Color(0xFFFBE9E7), 'index': 2},
      {'icon': Icons.layers_rounded, 'title': 'Classes', 'desc': 'Manage classes & subjects', 'color': const Color(0xFF7B1FA2), 'bg': const Color(0xFFF3E5F5), 'index': 3},
      {'icon': Icons.calendar_month_rounded, 'title': 'Academic', 'desc': 'Sessions, terms & population', 'color': const Color(0xFF00838F), 'bg': const Color(0xFFE0F7FA), 'index': 4},
      if (!isAce) {'icon': Icons.edit_note_rounded, 'title': 'Score Entry', 'desc': 'Enter scores by class & subject', 'color': const Color(0xFF2E7D32), 'bg': const Color(0xFFE8F5E9), 'index': 5},
      if (isAce) {'icon': Icons.speed_rounded, 'title': 'PACE Scores', 'desc': 'Enter PACE scores by student', 'color': const Color(0xFF2E7D32), 'bg': const Color(0xFFE8F5E9), 'index': 12},
      {'icon': Icons.computer_rounded, 'title': 'CBT Exams', 'desc': 'Create & manage computer tests', 'color': const Color(0xFFC62828), 'bg': const Color(0xFFFFEBEE), 'index': 6},
      if (!isAce) {'icon': Icons.publish_rounded, 'title': 'Publish Results', 'desc': 'Compute summaries & publish', 'color': const Color(0xFF4527A0), 'bg': const Color(0xFFEDE7F6), 'index': 7},
      if (isAce) {'icon': Icons.description_rounded, 'title': 'ACE Reports', 'desc': 'Generate ACE progress reports', 'color': const Color(0xFF4527A0), 'bg': const Color(0xFFEDE7F6), 'index': 13},
      {'icon': Icons.settings_rounded, 'title': 'Settings', 'desc': 'Profile, branding & grading', 'color': const Color(0xFF5D4037), 'bg': const Color(0xFFEFEBE9), 'index': 8},
      {'icon': Icons.badge_rounded, 'title': 'Credentials', 'desc': 'Generate & print login cards', 'color': const Color(0xFFF57F17), 'bg': const Color(0xFFFFF8E1), 'index': 9},
      {'icon': Icons.account_balance_wallet_rounded, 'title': 'Fees', 'desc': 'Manage fees & payments', 'color': const Color(0xFF0277BD), 'bg': const Color(0xFFE1F5FE), 'index': 10},
      {'icon': Icons.assessment_rounded, 'title': 'Reports', 'desc': 'View analytics & reports', 'color': const Color(0xFF558B2F), 'bg': const Color(0xFFF1F8E9), 'index': 14},
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: items.map((item) {
        return SizedBox(
          width: 300,
          child: InkWell(
            onTap: () => widget.onNavigate?.call(item['index'] as int),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: item['bg'] as Color, borderRadius: BorderRadius.circular(12)),
                    child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['title'] as String, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
                        const SizedBox(height: 4),
                        Text(item['desc'] as String, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Row _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF1A237E), size: 24),
            const SizedBox(width: 12),
            Text(title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
          ],
        ),
        if (title.contains('Progress'))
          Row(
            children: [
              Text('Hide empty classes', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
              Switch(
                value: _hideEmptyClasses,
                onChanged: (val) => setState(() => _hideEmptyClasses = val),
                activeColor: const Color(0xFF1A237E),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildRecordingProgress(ThemeData theme, SchoolAdminProvider provider, List<Map<String, dynamic>> displayedClasses, bool isAce) {
    // In ACE mode, we don't have a simple "scores entered" metric from provider.scores
    // So we hide this section for ACE to avoid confusion, or show a placeholder.
    if (isAce) {
      if (_aceLoading) {
        return Container(
          height: 200,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
          child: const Center(child: CircularProgressIndicator()),
        );
      }
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayedClasses.length,
          separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[100]),
          itemBuilder: (context, index) {
            final classMap = displayedClasses[index];
            final classId = classMap['id'] as String?;
            if (classId == null) return const SizedBox.shrink();

            final classStudents = provider.students.where((s) => s['class_id'] == classId).toList();
            final totalStudents = classStudents.length;
            final studentsScored = classStudents.where((s) => _studentsWithPace.contains(s['id'] as String)).length;
            double progress = totalStudents > 0 ? (studentsScored / totalStudents) * 100 : 0;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 120, // Fixed width so it stays close to the chart
                    child: Text(
                      '${classMap['name'] ?? 'Unknown'} ${classMap['section'] ?? ''}',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      backgroundColor: Colors.grey[200],
                      color: progress >= 100 ? Colors.green : const Color(0xFF1A237E),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 80,
                    child: Text(
                      '$studentsScored / $totalStudents',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    if (provider.scores.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
        child: Center(child: Text('No score entry data available yet.', style: theme.textTheme.bodyLarge)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: displayedClasses.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[100]),
        itemBuilder: (context, index) {
          final classMap = displayedClasses[index];
          final classId = classMap['id'] as String?;
          if (classId == null) return const SizedBox.shrink();

          final classScores = provider.scores.where((s) => s['class_id'] == classId).toList();
          final totalStudents = (classMap['student_count'] as int?) ?? 0;
          final studentsScored = classScores.map((s) => s['student_id'] as String).toSet().length;
          double progress = totalStudents > 0 ? (studentsScored / totalStudents) * 100 : 0;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            title: Text(
              '${classMap['name'] ?? 'Unknown'} ${classMap['section'] ?? ''}',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: Colors.grey[200],
                color: progress >= 100 ? Colors.green : const Color(0xFF1A237E),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            trailing: SizedBox(
              width: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$studentsScored / $totalStudents', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text('Students', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500])),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnalyticsSection(ThemeData theme, bool isAce) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Dynamically select the correct subject chart based on curriculum mode
        final subjectChart = isAce ? const AdminAceSubjectChart() : const AdminSubjectAveragesChart();
        
        if (constraints.maxWidth > 900) {
          // Side-by-side on desktop
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _chartWrapper(subjectChart)),
              const SizedBox(width: 16),
              Expanded(child: _chartWrapper(const AdminAttendanceTrendChart())),
            ],
          );
        }
        
        // Stacked on mobile/tablet
        return Column(
          children: [
            _chartWrapper(subjectChart),
            const SizedBox(height: 16),
            _chartWrapper(const AdminAttendanceTrendChart()),
          ],
        );
      },
    );
  }

  Widget _chartWrapper(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: child,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:smartedu/core/providers/school_admin_provider.dart';
import 'add_student_page.dart';
import 'add_teacher_page.dart';
import 'pages/page_students.dart';
import 'pages/page_teachers.dart';
import 'pages/page_classes.dart';
import 'pages/page_results.dart';
import 'pages/page_publish_results.dart';
import 'pages/page_cbt.dart';
import 'pages/page_academic.dart';
import 'pages/page_credentials.dart';
import 'pages/page_settings.dart';
import 'pages/page_announcements.dart';
import 'pages/page_complaints.dart';
import 'widgets/chat_bot_widget.dart';

class SchoolAdminDashboard extends StatefulWidget {
  final Map<String, dynamic>? schoolData;

  const SchoolAdminDashboard({super.key, this.schoolData});

  @override
  State<SchoolAdminDashboard> createState() => _SchoolAdminDashboardState();
}

class _SchoolAdminDashboardState extends State<SchoolAdminDashboard> {
  int _selectedIndex = 0;

  String _getSchoolName(SchoolAdminProvider provider) {
    if (provider.schoolName.isNotEmpty) return provider.schoolName;
    return widget.schoolData?['schoolName'] ?? widget.schoolData?['name'] ?? 'School';
  }

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.dashboard_outlined, label: 'Dashboard', color: Color(0xFF1A237E)),
    _NavItem(icon: Icons.people_outline, label: 'Students', color: Color(0xFF1A237E)),
    _NavItem(icon: Icons.person_outline, label: 'Teachers', color: Color(0xFF2E7D32)),
    _NavItem(icon: Icons.layers_outlined, label: 'Classes', color: Color(0xFF7B1FA2)),
    _NavItem(icon: Icons.grading_outlined, label: 'Results', color: Color(0xFF00897B)),
    _NavItem(icon: Icons.publish, label: 'Publish', color: Color(0xFF2E7D32)),
    _NavItem(icon: Icons.quiz_outlined, label: 'CBT Exams', color: Color(0xFF5C6BC0)),
    _NavItem(icon: Icons.campaign_outlined, label: 'Announcements', color: Color(0xFF1565C0)),
    _NavItem(icon: Icons.menu_book_outlined, label: 'Academic', color: Color(0xFFE65100)),
    _NavItem(icon: Icons.vpn_key_outlined, label: 'Credentials', color: Color(0xFF455A64)),
    _NavItem(icon: Icons.settings_outlined, label: 'Settings', color: Color(0xFF546E7A)),
    _NavItem(icon: Icons.report_problem_outlined, label: 'Complaints', color: Color(0xFFD32F2F)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Row(
        children: [
          if (MediaQuery.of(context).size.width >= 768) _buildSidebar(context),
          Expanded(child: _buildMainContent(context)),
        ],
      ),
      drawer: MediaQuery.of(context).size.width < 768 ? _buildDrawer(context) : null,
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 260,
      color: const Color(0xFF1B2A4A),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Consumer<SchoolAdminProvider>(
              builder: (context, provider, child) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A237E).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.school, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getSchoolName(provider),
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Consumer<SchoolAdminProvider>(
              builder: (context, provider, child) {
                final session = provider.currentSession;
                final term = provider.currentTerm;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    session != null ? '${session['name']} · ${term?['name'] ?? ''}' : '',
                    style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: List.generate(_navItems.length, (index) {
                  final item = _navItems[index];
                  final selected = _selectedIndex == index;
                  return _buildNavItem(item, selected, index);
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: GestureDetector(
                onTap: () => context.go('/role-selection'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.logout, color: Colors.redAccent, size: 20),
                      SizedBox(width: 12),
                      Text('Logout', style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(_NavItem item, bool selected, int index) {
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? item.color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: selected ? item.color.withOpacity(0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, color: selected ? item.color : Colors.white54, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              item.label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildCurrentPage()),
          ],
        ),
        Positioned(
          bottom: 90,
          right: 24,
          child: FloatingActionButton.extended(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => ChatBotWidget(
                  role: 'School Admin',
                  apiKey: const String.fromEnvironment('GEMINI_API_KEY'),
                ),
              );
            },
            backgroundColor: const Color(0xFF1A237E),
            icon: const Icon(Icons.smart_toy, color: Colors.white),
            label: const Text('Ask AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            heroTag: 'school_admin_chatbot_fab',
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 64,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (MediaQuery.of(context).size.width < 768)
            IconButton(icon: const Icon(Icons.menu, color: Color(0xFF111827)), onPressed: () => Scaffold.of(context).openDrawer()),
          if (MediaQuery.of(context).size.width < 768)
            Text(_getSchoolName(context.read<SchoolAdminProvider>()), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
          if (MediaQuery.of(context).size.width >= 768)
            Text(_navItems[_selectedIndex].label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF111827), letterSpacing: -0.5)),
          const Spacer(),
          Consumer<SchoolAdminProvider>(
            builder: (context, provider, child) {
              if (provider.terms.isEmpty) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE8EAED)),
                ),
                child: DropdownButton<String>(
                  value: provider.currentTerm?['id'] as String?,
                  underline: const SizedBox(),
                  isDense: true,
                  items: provider.terms.map((t) => DropdownMenuItem<String>(
                    value: t['id'] as String?,
                    child: Text('${t['name']}', style: const TextStyle(fontSize: 12, color: Color(0xFF111827), fontWeight: FontWeight.w500)),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) provider.setCurrentTerm(value);
                  },
                ),
              );
            },
          ),
          const Stack(
            children: [
              Icon(Icons.notifications_outlined, color: Color(0xFF9CA3AF), size: 24),
              Positioned(right: 8, top: 8, child: Icon(Icons.circle, size: 8, color: Colors.red)),
            ],
          ),
          const SizedBox(width: 12),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: const Color(0xFF1A237E), borderRadius: BorderRadius.circular(10)),
            child: const Center(child: Text('SA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
          ),
          const SizedBox(width: 12),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Admin', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
              Text('School Admin', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPage() {
    return Consumer<SchoolAdminProvider>(
      builder: (context, p, child) {
        switch (_selectedIndex) {
          case 0:
            return _buildDashboardHome(context, p);
          case 1:
            return PageStudents(
              students: p.students,
              onDelete: (id) => p.deleteStudentFromDb(id),
              onAdd: () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddStudentPage(classes: p.classes)));
                if (result != null) {
                  if (mounted) p.addStudent(result);
                }
              },
            );
          case 2:
            return PageTeachers(
              teachers: p.teachers,
              onDelete: (id) => p.deleteTeacherFromDb(id),
              onAdd: () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTeacherPage()));
                if (result != null) {
                  if (mounted) p.addTeacher(result);
                }
              },
            );
          case 3:
            return PageClasses(
              classes: p.classes,
              subjects: p.subjects,
              classSubjects: p.classSubjects,
              assignments: p.assignments,
              teachers: p.teachers,
              students: p.students,
              onAddClassSubject: (classId, subjectId) => p.addClassSubjectToDb(classId: classId, subjectId: subjectId),
              onRemoveClassSubject: (csId) => p.removeClassSubjectFromDb(csId),
              onAddClass: (cls) => p.addClass(cls),
              onDeleteClass: (cls) => p.deleteClass(cls),
              onAddSubject: (subj) => p.addSubject(subj),
              onDeleteSubject: (subj) => p.deleteSubject(subj),
              onAddAssignment: (assign) => p.addAssignment(assign),
              onDeleteAssignment: (assign) => p.deleteAssignment(assign),
            );
          case 4:
            return PageResults(
              classes: p.classes,
              subjects: p.subjects,
              classSubjects: p.classSubjects,
              students: p.students,
              assignments: p.assignments,
              scores: p.scores,
              resultsVisible: p.resultsVisible,
              onSaveScores: (scores) => p.saveScoresToDb(scores),
              onToggleVisibility: (val) => p.toggleResults(val),
            );
          case 5:
            return const PagePublishResults();
          case 6:
            return PageCbt(
              exams: p.cbtExams,
              classes: p.classes,
              subjects: p.subjects,
              onAdd: (exam) => p.addCbtExam(exam),
              onToggle: (id) => p.toggleCbt(id),
              onDelete: (id) => p.deleteCbtExam(id),
            );
          case 7:
            return PageAnnouncements();
          case 8:
            return PageAcademic(classes: p.classes, academicYears: [], onYearsUpdated: (_) {});
          case 9:
            return const PageCredentials();
          case 10:
            return PageSettings(
              schoolName: p.schoolName,
              schoolAddress: p.schoolAddress,
              schoolPhone: p.schoolPhone,
              schoolEmail: p.schoolEmail,
              onUpdate: (n, a, ph, e) => p.updateSchoolSettings(n, a, ph, e),
            );
          case 11:
            return const PageComplaints();
          default:
            return const Center(child: Text("Page not found"));
        }
      },
    );
  }

  Widget _buildDashboardHome(BuildContext context, SchoolAdminProvider p) {
    final hasData = p.students.isNotEmpty || p.classes.isNotEmpty || p.teachers.isNotEmpty;

    final sssClasses = p.classes.where((c) => c['tier'] == 'SSS').toList();
    final jssClasses = p.classes.where((c) => c['tier'] == 'JSS').toList();
    final primaryClasses = p.classes.where((c) => c['tier'] == 'PRIMARY').toList();
    final noTierClasses = p.classes.where((c) => c['tier'] == null || (c['tier'] as String?)?.isEmpty == true).toList();

    final sessionName = p.currentSession?['name'] as String? ?? '';
    final termName = p.currentTerm?['name'] as String? ?? '';
    final termStart = p.currentTerm?['term_start_date'] as String?;
    final termEnd = p.currentTerm?['term_end_date'] as String?;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildWelcomeBanner(p, sessionName, termName),
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, constraints) {
            final count = constraints.maxWidth > 1000 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
            return GridView.count(
              crossAxisCount: count,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: count == 3 ? 2.4 : (count == 2 ? 2.6 : 3.2),
              children: [
                _buildStatCard(icon: Icons.person_outline, label: 'Total Students', value: '${p.students.length}', bgColor: const Color(0xFFF0F4FF), iconColor: const Color(0xFF1A237E), subtitle: '${p.classes.length} classes'),
                _buildStatCard(icon: Icons.people_outline, label: 'Total Teachers', value: '${p.teachers.length}', bgColor: const Color(0xFFF0FFF4), iconColor: const Color(0xFF2E7D32), subtitle: 'Active staff'),
                _buildStatCard(icon: Icons.apps, label: 'Active Classes', value: '${p.classes.length}', bgColor: const Color(0xFFFFF3E0), iconColor: const Color(0xFFE65100), subtitle: '${p.subjects.length} subjects'),
                _buildStatCard(icon: Icons.quiz_outlined, label: 'CBT Exams', value: '${p.cbtExams.length}', bgColor: const Color(0xFFFFF8E1), iconColor: const Color(0xFFF57F17), subtitle: 'Created'),
                _buildStatCard(icon: Icons.grading_outlined, label: 'Scores Logged', value: '${p.scores.length}', bgColor: const Color(0xFFFCE4EC), iconColor: const Color(0xFFC62828), subtitle: 'This term'),
                _buildStatCard(icon: Icons.menu_book, label: 'Subjects', value: '${p.subjects.length}', bgColor: const Color(0xFFF3E5F5), iconColor: const Color(0xFF7B1FA2), subtitle: 'In curriculum'),
              ],
            );
          },
        ),
        const SizedBox(height: 32),
        if (sessionName.isNotEmpty || termName.isNotEmpty) _buildSessionCard(sessionName, termName, termStart, termEnd),
        if (sessionName.isNotEmpty || termName.isNotEmpty) const SizedBox(height: 28),
        if (p.classes.isNotEmpty) ...[
          Row(
            children: [
              Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFFF3E5F5), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.layers, color: Color(0xFF7B1FA2), size: 16)),
              const SizedBox(width: 10),
              const Text('Class Distribution', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFF3E5F5), borderRadius: BorderRadius.circular(12)),
                child: Text('${p.classes.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF7B1FA2))),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (sssClasses.isNotEmpty) _tierCard('SSS', 'Senior Secondary', sssClasses, const Color(0xFF1A237E), const Color(0xFFF0F4FF)),
          if (sssClasses.isNotEmpty) const SizedBox(height: 10),
          if (jssClasses.isNotEmpty) _tierCard('JSS', 'Junior Secondary', jssClasses, const Color(0xFFE65100), const Color(0xFFFFF3E0)),
          if (jssClasses.isNotEmpty) const SizedBox(height: 10),
          if (primaryClasses.isNotEmpty) _tierCard('PRIMARY', 'Primary School', primaryClasses, const Color(0xFF7B1FA2), const Color(0xFFF3E5F5)),
          if (primaryClasses.isNotEmpty) const SizedBox(height: 10),
          if (noTierClasses.isNotEmpty) _tierCard('UNSET', 'No tier assigned', noTierClasses, const Color(0xFF546E7A), const Color(0xFFF5F5F5)),
          if (noTierClasses.isNotEmpty) const SizedBox(height: 28),
        ],
        _buildQuickActionsSection(),
        const SizedBox(height: 32),
        if (!hasData) _buildEmptyGuide(),
      ],
    );
  }

  Widget _buildWelcomeBanner(SchoolAdminProvider p, String session, String term) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE8EAED)), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(width: 52, height: 52, decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.waving_hand, color: Color(0xFF1A237E), size: 26)),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_getSchoolName(p), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF111827), letterSpacing: -0.3)),
                const SizedBox(height: 4),
                Text('Welcome back! Here\'s your school overview.', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
              ],
            ),
          ),
          if (session.isNotEmpty || term.isNotEmpty) ...[
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today, color: Color(0xFF1A237E), size: 14),
                  const SizedBox(width: 8),
                  Text([session, term].where((s) => s.isNotEmpty).join(' · '), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A237E))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSessionCard(String session, String term, String? termStart, String? termEnd) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE8EAED)), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.calendar_today, color: Color(0xFF00897B), size: 22)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Active Session', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(child: Text(session, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)), overflow: TextOverflow.ellipsis)),
                    if (term.isNotEmpty) ...[const SizedBox(width: 6), const Text('·', style: TextStyle(color: Color(0xFFD1D5DB))), const SizedBox(width: 6), Flexible(child: Text(term, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)), overflow: TextOverflow.ellipsis))],
                  ],
                ),
                if (termStart != null || termEnd != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 12, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 4),
                      if (termStart != null) Text('Starts ${_formatDate(termStart)}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                      if (termStart != null && termEnd != null) Text('  ·  ', style: TextStyle(fontSize: 12, color: Color(0xFFD1D5DB))),
                      if (termEnd != null) Text('Ends ${_formatDate(termEnd)}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(6)), child: const Text('Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF00897B), letterSpacing: 0.3))),
        ],
      ),
    );
  }

  Widget _tierCard(String tier, String description, List<Map<String, dynamic>> classes, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE8EAED)), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)), child: Icon(Icons.class_outlined, color: color, size: 22)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(description, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(5)), child: Text(tier, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5))),
                  ],
                ),
                const SizedBox(height: 4),
                Text(classes.map((c) => c['name']?.toString() ?? '').join('  ·  '), style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)), child: Text('${classes.length} class${classes.length != 1 ? 'es' : ''}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color))),
        ],
      ),
    );
  }

  Widget _buildStatCard({required IconData icon, required String label, required String value, required Color bgColor, required Color iconColor, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE8EAED)), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: iconColor, size: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF111827), height: 1.1)),
                const SizedBox(height: 3),
                Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF111827))),
                const SizedBox(height: 1),
                Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    final actions = [
      _QuickAction(icon: Icons.person_add, label: 'Add Student', color: const Color(0xFF1A237E), bgColor: const Color(0xFFF0F4FF), index: 1),
      _QuickAction(icon: Icons.person_add_alt, label: 'Add Teacher', color: const Color(0xFF2E7D32), bgColor: const Color(0xFFF0FFF4), index: 2),
      _QuickAction(icon: Icons.quiz_outlined, label: 'Create CBT', color: const Color(0xFFF57F17), bgColor: const Color(0xFFFFF8E1), index: 6),
      _QuickAction(icon: Icons.publish, label: 'Publish Results', color: const Color(0xFFE65100), bgColor: const Color(0xFFFFF3E0), index: 5),
      _QuickAction(icon: Icons.grading_outlined, label: 'Enter Scores', color: const Color(0xFF00897B), bgColor: const Color(0xFFE0F2F1), index: 4),
      _QuickAction(icon: Icons.vpn_key_outlined, label: 'Credentials', color: const Color(0xFF455A64), bgColor: const Color(0xFFECEFF1), index: 9),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.bolt, color: Color(0xFFE65100), size: 16)),
            const SizedBox(width: 10),
            const Text('Quick Actions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: actions.map((a) {
            return InkWell(
              onTap: () => setState(() => _selectedIndex = a.index),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE8EAED))),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 30, height: 30, decoration: BoxDecoration(color: a.bgColor, borderRadius: BorderRadius.circular(7)), child: Icon(a.icon, color: a.color, size: 15)),
                    const SizedBox(width: 8),
                    Text(a.label, style: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w500, fontSize: 13)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEmptyGuide() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE8EAED)), borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Container(width: 72, height: 72, decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.rocket_launch, color: Color(0xFF1A237E), size: 32)),
          const SizedBox(height: 18),
          const Text('Get Started', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 8),
          Text('Set up your school by creating classes,\nadding subjects, and enrolling students\nfrom the sidebar menu.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.5)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _guideStep('1', 'Create\nClasses', const Color(0xFFE65100), const Color(0xFFFFF3E0)),
              Container(width: 40, height: 1, color: const Color(0xFFE8EAED)),
              _guideStep('2', 'Add\nSubjects', const Color(0xFF7B1FA2), const Color(0xFFF3E5F5)),
              Container(width: 40, height: 1, color: const Color(0xFFE8EAED)),
              _guideStep('3', 'Enroll\nStudents', const Color(0xFF1A237E), const Color(0xFFF0F4FF)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _guideStep(String number, String label, Color color, Color bgColor) {
    return Column(
      children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)), child: Center(child: Text(number, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)))),
        const SizedBox(height: 8),
        Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.3)),
      ],
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFF1B2A4A),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Consumer<SchoolAdminProvider>(
                  builder: (context, provider, child) {
                    return Row(
                      children: [
                        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF1A237E).withOpacity(0.5), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.school, color: Colors.white, size: 20)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_getSchoolName(provider), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: List.generate(_navItems.length, (index) {
                    final item = _navItems[index];
                    final selected = _selectedIndex == index;
                    return GestureDetector(
                      onTap: () { setState(() => _selectedIndex = index); Navigator.pop(context); },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(color: selected ? item.color.withOpacity(0.12) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            Container(width: 32, height: 32, decoration: BoxDecoration(color: selected ? item.color.withOpacity(0.2) : Colors.transparent, borderRadius: BorderRadius.circular(8)), child: Icon(item.icon, color: selected ? item.color : Colors.white54, size: 18)),
                            const SizedBox(width: 12),
                            Text(item.label, style: TextStyle(color: selected ? Colors.white : Colors.white70, fontSize: 14, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: GestureDetector(
                  onTap: () => context.go('/role-selection'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Row(children: [Icon(Icons.logout, color: Colors.redAccent, size: 20), SizedBox(width: 12), Text('Logout', style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w500))]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final Color color;
  const _NavItem({required this.icon, required this.label, required this.color});
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final int index;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.bgColor, required this.index});
}

// ==========================================
// File: lib/features/dashboard/teacher/teacher_dashboard.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:smartedu/core/teacher_provider.dart';
import '../school_admin/widgets/chat_bot_widget.dart';
import 'pages/teacher_my_classes.dart';
import 'pages/teacher_enter_scores.dart';
import 'pages/teacher_my_students.dart';
import 'pages/teacher_assignments.dart';
import 'pages/teacher_results.dart';
import 'pages/teacher_attendance.dart';

class TeacherDashboard extends StatefulWidget {
  final Map<String, dynamic>? teacherData;

  const TeacherDashboard({super.key, this.teacherData});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  String _selectedNavId = 'home';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<TeacherProvider>();
      if (!provider.isInitialized) return;
      _setRoleDefault(provider);
    });
  }

  void _setRoleDefault(TeacherProvider provider) {
    if (!provider.isSubjectTeacher && provider.isFormMaster) {
      setState(() => _selectedNavId = 'form_class');
    }
  }

  List<_NavItem> _buildNavItems(bool isFormMaster, bool isSubjectTeacher) {
    final items = <_NavItem>[];
    items.add(const _NavItem(id: 'home', icon: Icons.home_rounded, label: 'Home'));

    if (isFormMaster && isSubjectTeacher) {
      items.add(const _NavItem(id: 'fm_hdr', label: 'AS FORM MASTER', isHeader: true));
    }

    if (isFormMaster) {
      items.add(const _NavItem(id: 'form_class', icon: Icons.class_rounded, label: 'My Class'));
      items.add(const _NavItem(id: 'form_students', icon: Icons.people_rounded, label: 'My Students'));
      items.add(const _NavItem(id: 'attendance', icon: Icons.fact_check_rounded, label: 'Attendance'));
    }

    if (isFormMaster && isSubjectTeacher) {
      items.add(const _NavItem(id: 'st_hdr', label: 'AS SUBJECT TEACHER', isHeader: true));
    }

    if (isSubjectTeacher) {
      items.add(const _NavItem(id: 'my_classes', icon: Icons.class_rounded, label: 'My Classes'));
      items.add(const _NavItem(id: 'enter_scores', icon: Icons.edit_note_rounded, label: 'Enter Scores'));
      items.add(const _NavItem(id: 'assignments', icon: Icons.assignment_rounded, label: 'Assignments'));
    }

    if (isFormMaster || isSubjectTeacher) {
      items.add(const _NavItem(id: 'results', icon: Icons.bar_chart_rounded, label: 'Results'));
    }

    return items;
  }

  String _currentPageLabel(List<_NavItem> items) {
    for (final item in items) {
      if (item.id == _selectedNavId) return item.label;
    }
    return 'Home';
  }

  String _getInitials(TeacherProvider provider) {
    final name = provider.teacherName;
    if (name.isEmpty) return 'T';
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 768;
    final provider = context.watch<TeacherProvider>();
    final navItems = _buildNavItems(provider.isFormMaster, provider.isSubjectTeacher);

    if (provider.isInitialized &&
        !navItems.any((i) => i.id == _selectedNavId && !i.isHeader)) {
      _selectedNavId = 'home';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Stack(
        children: [
          Row(
            children: [
              if (!isSmall)
                _buildDesktopSidebar(provider, navItems),
              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(provider, navItems, isSmall),
                    Expanded(child: _buildCurrentPage()),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton.extended(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => ChatBotWidget(
                    role: 'Teacher',
                    apiKey: const String.fromEnvironment('GEMINI_API_KEY'),
                  ),
                );
              },
              backgroundColor: const Color(0xFF0D47A1),
              icon: const Icon(Icons.smart_toy, color: Colors.white),
              label: const Text('Ask AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      drawer: isSmall ? _buildMobileDrawer(provider, navItems) : null,
    );
  }

  Widget _buildDesktopSidebar(TeacherProvider provider, List<_NavItem> items) {
    return Container(
      width: 260,
      color: const Color(0xFF0D47A1),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Teacher Portal', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.teacherName,
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (provider.schoolName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      provider.schoolName,
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  _buildRoleBadges(provider),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: items.map((item) {
                  if (item.isHeader) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 6),
                      child: Text(
                        item.label,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    );
                  }
                  final selected = _selectedNavId == item.id;
                  return _AnimatedSidebarItem(
                    item: item,
                    isSelected: selected,
                    onTap: () => setState(() => _selectedNavId = item.id),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Consumer<TeacherProvider>(
                builder: (context, p, _) {
                  if (p.currentSession == null || p.currentTerm == null) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${p.currentSession!['name'] ?? 'Session'}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                        Text('${p.currentTerm!['name'] ?? 'Term'}', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10)),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.all(12),
              child: GestureDetector(
                onTap: () => context.go('/role-selection'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadges(TeacherProvider provider) {
    if (!provider.isFormMaster && !provider.isSubjectTeacher) return const SizedBox.shrink();
    final badges = <Widget>[];
    if (provider.isFormMaster) {
      badges.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: Colors.teal.shade400.withOpacity(0.3), borderRadius: BorderRadius.circular(4)),
        child: const Text('Form Master', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
      ));
    }
    if (provider.isSubjectTeacher) {
      badges.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: Colors.orange.shade400.withOpacity(0.3), borderRadius: BorderRadius.circular(4)),
        child: const Text('Subject Teacher', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
      ));
    }
    return Row(children: badges);
  }

  Widget _buildTopBar(TeacherProvider provider, List<_NavItem> items, bool isSmall) {
    return Container(
      height: 64,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (isSmall)
            IconButton(icon: const Icon(Icons.menu, color: Color(0xFF0D47A1)), onPressed: () => Scaffold.of(context).openDrawer()),
          if (isSmall)
            const Text('Teacher Portal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
          if (!isSmall)
            Text(_currentPageLabel(items), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF0D47A1))),
          const Spacer(),
          if (!isSmall)
            Consumer<TeacherProvider>(
              builder: (context, p, _) {
                if (p.terms.isEmpty) return const SizedBox.shrink();
                final currentName = p.currentTerm?['name'] ?? 'Term';
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => _TermPickerDialog(
                          terms: p.terms,
                          currentId: p.currentTerm?['id'] as String?,
                          onPick: (v) {
                            Navigator.pop(ctx);
                            if (v != null) {
                              p.setCurrentTerm(v);
                              _setRoleDefault(p);
                            }
                          },
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D47A1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: Color(0xFF0D47A1)),
                          const SizedBox(width: 6),
                          Text(currentName, style: const TextStyle(fontSize: 12, color: Color(0xFF0D47A1), fontWeight: FontWeight.w500)),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF0D47A1)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          GestureDetector(
            onTap: () => context.go('/teacher-profile', extra: provider.currentTeacher),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: Colors.orange.shade400, borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text(_getInitials(provider), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(provider.teacherName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0D47A1))),
                    Text(provider.staffId.isNotEmpty ? provider.staffId : 'Teacher', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_selectedNavId) {
      case 'home':
        return const _TeacherHomePage();
      case 'form_class':
        return const TeacherMyClassesPage();
      case 'form_students':
        return const TeacherMyStudentsPage();
      case 'attendance':
        return const TeacherAttendancePage();
      case 'my_classes':
        return const TeacherMyClassesPage();
      case 'enter_scores':
        return TeacherEnterScoresPage();
      case 'assignments':
        return const TeacherAssignmentsPage();
      case 'results':
        return const TeacherResultsPage();
      default:
        return const _TeacherHomePage();
    }
  }

  Drawer _buildMobileDrawer(TeacherProvider provider, List<_NavItem> items) {
    return Drawer(
      child: Container(
        color: const Color(0xFF0D47A1),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  Icon(Icons.person, color: Colors.orange, size: 24),
                  SizedBox(width: 12),
                  Text('Teacher Portal', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(provider.teacherName, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                    if (provider.schoolName.isNotEmpty)
                      Text(provider.schoolName, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                    if (provider.currentSession != null)
                      Text('${provider.currentSession!['name']} - ${provider.currentTerm?['name'] ?? ''}', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10)),
                    const SizedBox(height: 4),
                    _buildRoleBadges(provider),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...items.map((item) {
                if (item.isHeader) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 20, top: 12, bottom: 4),
                    child: Text(item.label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                  );
                }
                final selected = _selectedNavId == item.id;
                return ListTile(
                  dense: true,
                  selected: selected,
                  selectedTileColor: Colors.orange.shade400,
                  leading: Icon(item.icon, color: selected ? Colors.white : Colors.white54, size: 20),
                  title: Text(item.label, style: TextStyle(color: selected ? Colors.white : Colors.white70, fontSize: 14)),
                  onTap: () {
                    setState(() => _selectedNavId = item.id);
                    Navigator.pop(context);
                  },
                );
              }),
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontSize: 14)),
                onTap: () => context.go('/role-selection'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String id;
  final IconData? icon;
  final String label;
  final bool isHeader;
  const _NavItem({required this.id, this.icon, required this.label, this.isHeader = false});
}

class _AnimatedSidebarItem extends StatefulWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  const _AnimatedSidebarItem({required this.item, required this.isSelected, required this.onTap});

  @override
  State<_AnimatedSidebarItem> createState() => _AnimatedSidebarItemState();
}

class _AnimatedSidebarItemState extends State<_AnimatedSidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isSelected || _isHovered;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(color: isActive ? Colors.orange.shade400 : Colors.transparent, borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              Icon(widget.item.icon, color: isActive ? Colors.white : Colors.white54, size: 20),
              const SizedBox(width: 14),
              Text(widget.item.label, style: TextStyle(color: isActive ? Colors.white : Colors.white70, fontSize: 14, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
              const Spacer(),
              if (widget.isSelected) Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeacherHomePage extends StatelessWidget {
  const _TeacherHomePage();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TeacherProvider>();

    if (!provider.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final assignedCount = provider.mySubjectAssignments.length;
    final classCount = provider.assignedClassIds.length;
    final studentCount = provider.students.length;
    final isFormMaster = provider.isFormMaster;
    final isSubjectTeacher = provider.isSubjectTeacher;
    final ftClass = provider.getFormTeacherClass();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1565C0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Welcome Back!", style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 8),
                Text(provider.teacherName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    Text("Staff ID: ${provider.staffId.isNotEmpty ? provider.staffId : 'N/A'}", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                    if (provider.schoolName.isNotEmpty)
                      Text(provider.schoolName, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                  ],
                ),
                if (provider.currentSession != null && provider.currentTerm != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                    child: Text("${provider.currentSession!['name']}  -  ${provider.currentTerm!['name']}", style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (!isFormMaster && !isSubjectTeacher)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                children: [
                  Icon(Icons.assignment_ind_outlined, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text("No Assignments Yet", style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text("Contact your school admin to get class or subject assignments.", style: TextStyle(fontSize: 13, color: Colors.grey.shade400), textAlign: TextAlign.center),
                ],
              ),
            ),

          if (isSubjectTeacher || isFormMaster)
            LayoutBuilder(
              builder: (context, constraints) {
                final crossCount = constraints.maxWidth > 600 ? 4 : 2;
                return GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: crossCount == 4 ? 1.05 : 1.4,
                  ),
                  children: [
                    if (isSubjectTeacher)
                      _StatCard(title: "Subjects", value: "$assignedCount", icon: Icons.menu_book_rounded, gradient: const LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1976D2)])),
                    _StatCard(title: "Classes", value: "$classCount", icon: Icons.class_rounded, gradient: const LinearGradient(colors: [Color(0xFFE65100), Color(0xFFFF8A65)])),
                    _StatCard(title: "Students", value: "$studentCount", icon: Icons.people_rounded, gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)])),
                    _StatCard(
                      title: "Form Master",
                      value: isFormMaster ? "Yes" : "No",
                      icon: Icons.supervisor_account_rounded,
                      gradient: LinearGradient(colors: isFormMaster ? [Color(0xFF00695C), Color(0xFF4DB6AC)] : [Color(0xFF757575), Color(0xFFBDBDBD)]),
                    ),
                  ],
                );
              },
            ),

          if (isFormMaster && ftClass != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00695C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00695C).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFF00695C).withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.supervisor_account, color: Color(0xFF00695C)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Form Teacher", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00695C))),
                        const SizedBox(height: 4),
                        Text(
                          "${ftClass['name'] ?? ''} ${ftClass['section'] ?? ''}".trim(),
                          style: const TextStyle(fontSize: 13, color: Color(0xFF00695C)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xFF00695C).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: const Text("Active", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF00695C))),
                  ),
                ],
              ),
            ),
          ],

          if (isSubjectTeacher) ...[
            const SizedBox(height: 24),
            const Text("My Assigned Subjects", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
            const SizedBox(height: 16),
            if (assignedCount == 0)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.assignment_ind_outlined, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text("No subjects assigned yet", style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              )
            else
              ...provider.mySubjectAssignments.map((assignment) {
                final subject = assignment['subjects'] as Map<String, dynamic>? ?? {};
                final cls = assignment['classes'] as Map<String, dynamic>? ?? {};
                final subjectName = subject['name'] ?? 'Unknown';
                final subjectCode = subject['code'] ?? '';
                final className = '${cls['name'] ?? ''} ${cls['section'] ?? ''}'.trim();

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade100),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFF0D47A1).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.menu_book, color: Color(0xFF0D47A1)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(subjectName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)), overflow: TextOverflow.ellipsis),
                                ),
                                if (subjectCode.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                                    child: Text(subjectCode, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.class_outlined, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text("Class: $className", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Text(className, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange)),
                      ),
                    ],
                  ),
                );
              }),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final LinearGradient gradient;
  const _StatCard({required this.title, required this.value, required this.icon, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: gradient, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: Colors.white, size: 20)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8))),
        ],
      ),
    );
  }
}

class _TermPickerDialog extends StatelessWidget {
  final List<Map<String, dynamic>> terms;
  final String? currentId;
  final ValueChanged<String?> onPick;

  const _TermPickerDialog({required this.terms, required this.currentId, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Term', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            const SizedBox(height: 16),
            ...terms.map((t) {
              final id = t['id']?.toString() ?? '';
              final name = t['name'] ?? '';
              final selected = id == currentId;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onPick(id),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFF0F4FF) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: selected ? const Color(0xFF1A237E) : const Color(0xFFE8EAED), width: selected ? 2 : 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 20, color: selected ? const Color(0xFF1A237E) : Colors.transparent),
                        const SizedBox(width: 10),
                        Text(name, style: TextStyle(fontSize: 14, fontWeight: selected ? FontWeight.w600 : FontWeight.w500, color: selected ? const Color(0xFF1A237E) : const Color(0xFF111827))),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

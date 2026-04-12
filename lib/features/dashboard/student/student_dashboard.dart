import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:smartedu/core/providers/student/student_provider.dart';
import 'package:smartedu/core/auth_service.dart';
import 'pages/student_home_page.dart';
import 'pages/student_results_page.dart';
import 'pages/student_assignments_page.dart';
import 'pages/student_cbt_page.dart';
import 'pages/student_announcements_page.dart';
import 'pages/student_attendance_page.dart';
import 'pages/student_complaints_page.dart';
import 'pages/student_fees_page.dart';
import 'pages/student_profile_page.dart';

class StudentDashboard extends StatefulWidget {
  final Map<String, dynamic>? studentData;
  const StudentDashboard({super.key, this.studentData});
  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;
  final List<_SidebarItem> _sidebarItems = const [
    _SidebarItem(icon: Icons.home_rounded, label: 'Home'),
    _SidebarItem(icon: Icons.bar_chart_rounded, label: 'Results'),
    _SidebarItem(icon: Icons.assignment_rounded, label: 'Assignments'),
    _SidebarItem(icon: Icons.quiz_rounded, label: 'CBT Exams'),
    _SidebarItem(icon: Icons.campaign_rounded, label: 'Announcements'),
    _SidebarItem(icon: Icons.event_available_rounded, label: 'Attendance'),
    _SidebarItem(icon: Icons.receipt_long_rounded, label: 'Fees'),
    _SidebarItem(icon: Icons.report_problem_rounded, label: 'Complaints'),
    _SidebarItem(icon: Icons.person_rounded, label: 'My Profile'),
  ];

  String _getStudentName(StudentProvider provider) {
    if (provider.studentName.isNotEmpty) return provider.studentName;
    final data = widget.studentData;
    if (data != null) {
      String first = data['firstName'] ?? '';
      String middle = data['middleName'] ?? '';
      String last = data['lastName'] ?? '';
      if (first.isNotEmpty || last.isNotEmpty) return '$first ${middle.isNotEmpty ? '$middle ' : ''}$last'.trim();
      return data['username'] ?? 'Student';
    }
    return 'Student';
  }

  String _getInitials(StudentProvider provider) {
    String name = _getStudentName(provider);
    if (name.isEmpty || name == 'Student') return 'S';
    if (name.contains('.')) { final p = name.split('.'); if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase(); }
    List<String> p = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }

  String _getClassDisplay(StudentProvider provider) {
    if (provider.className.isNotEmpty) return provider.className;
    final data = widget.studentData;
    if (data != null) {
      String c = data['className'] ?? '';
      if (c.isNotEmpty) return c;
      String id = data['classId'] ?? data['class_id'] ?? '';
      if (id.isNotEmpty) return 'Class ID: $id';
    }
    return 'Class';
  }

  String _getAdmissionNo(StudentProvider provider) {
    if (provider.admissionNo.isNotEmpty) return provider.admissionNo;
    return widget.studentData?['admissionNo'] ?? '';
  }

  String _getSchoolName(StudentProvider provider) {
    if (provider.schoolName.isNotEmpty) return provider.schoolName;
    return widget.studentData?['schoolName'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 768;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Row(
        children: [
          if (!isSmall) _buildSidebar(),
          Expanded(child: Column(children: [_buildTopBar(isSmall), Expanded(child: _buildCurrentPage())])),
        ],
      ),
      drawer: isSmall ? _buildDrawer() : null,
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      color: const Color(0xFF2E7D32),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Consumer<StudentProvider>(
                builder: (context, provider, _) {
                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.school, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getSchoolName(provider).isNotEmpty ? _getSchoolName(provider) : 'Student Portal',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Consumer<StudentProvider>(
                builder: (context, provider, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_getStudentName(provider), style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis, maxLines: 1),
                      if (_getAdmissionNo(provider).isNotEmpty) Text('ADM: ${_getAdmissionNo(provider)}', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10)),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: List.generate(_sidebarItems.length, (index) {
                  return _AnimatedSidebarItem(
                    item: _sidebarItems[index],
                    isSelected: _selectedIndex == index,
                    onTap: () => setState(() => _selectedIndex = index),
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Consumer<StudentProvider>(
                builder: (context, provider, _) {
                  if (provider.currentSession == null || provider.currentTerm == null) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('📊 ${provider.currentSession!['name'] ?? 'Session'}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                        Text('📅 ${provider.currentTerm!['name'] ?? 'Term'}', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10)),
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
                onTap: () async {
                  await AuthService.logout();
                  if (mounted) context.go('/role-selection');
                },
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

  Widget _buildTopBar(bool isSmall) {
    return Container(
      height: 64,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Consumer<StudentProvider>(
        builder: (context, provider, _) {
          return Row(
            children: [
              if (isSmall)
                IconButton(
                  icon: const Icon(Icons.menu, color: Color(0xFF2E7D32)),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              if (isSmall)
                const Text('Student Portal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
              if (!isSmall)
                Text(_sidebarItems[_selectedIndex].label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32))),
              const Spacer(),
              if (!isSmall)
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFF2E7D32).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: DropdownButton<String>(
                    value: provider.currentTerm?['id'] as String?,
                    underline: const SizedBox(),
                    isDense: true,
                    items: provider.terms.map((t) => DropdownMenuItem(value: t['id'] as String?, child: Text('${t['name']}', style: const TextStyle(fontSize: 12, color: Color(0xFF2E7D32))))).toList(),
                    onChanged: (value) { if (value != null) provider.setCurrentTerm(value); },
                  ),
                ),
              const Icon(Icons.notifications_outlined, color: Colors.grey, size: 24),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => setState(() => _selectedIndex = 8),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF2E7D32).withOpacity(0.1),
                  child: Text(_getInitials(provider), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32), fontSize: 14)),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => setState(() => _selectedIndex = 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_getStudentName(provider), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1B2A4A))),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0: return const StudentHomePage();
      case 1: return const StudentResultsPage();
      case 2: return const StudentAssignmentsPage();
      case 3: return const StudentCbtPage();
      case 4: return const StudentAnnouncementsPage();
      case 5: return const StudentAttendancePage();
      case 6: return const StudentFeesPage();
      case 7: return StudentComplaintsPage();
      case 8: return StudentProfilePage();
      default: return const Center(child: Text("Page not found"));
    }
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: Container(
        color: const Color(0xFF2E7D32),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Consumer<StudentProvider>(
                  builder: (context, provider, _) {
                    return Row(
                      children: [
                        const Icon(Icons.school, color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _getSchoolName(provider).isNotEmpty ? _getSchoolName(provider) : 'Student Portal',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Consumer<StudentProvider>(
                  builder: (context, provider, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_getStudentName(provider), style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w500)),
                        if (_getAdmissionNo(provider).isNotEmpty) Text('ADM: ${_getAdmissionNo(provider)}', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                        Text(_getClassDisplay(provider), style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: List.generate(_sidebarItems.length, (index) {
                    final item = _sidebarItems[index];
                    return ListTile(
                      dense: true,
                      selected: _selectedIndex == index,
                      selectedTileColor: Colors.white24,
                      leading: Icon(item.icon, color: _selectedIndex == index ? Colors.white : Colors.white54, size: 20),
                      title: Text(item.label, style: TextStyle(color: _selectedIndex == index ? Colors.white : Colors.white70, fontSize: 14)),
                      onTap: () {
                        setState(() => _selectedIndex = index);
                        Navigator.pop(context);
                      },
                    );
                  }),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontSize: 14)),
                onTap: () async {
                  await AuthService.logout();
                  if (mounted) context.go('/role-selection');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarItem {
  final IconData icon;
  final String label;
  const _SidebarItem({required this.icon, required this.label});
}

class _AnimatedSidebarItem extends StatefulWidget {
  final _SidebarItem item;
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
          decoration: BoxDecoration(color: isActive ? Colors.white24 : Colors.transparent, borderRadius: BorderRadius.circular(10)),
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

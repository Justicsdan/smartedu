// ==========================================
// File: lib/features/dashboard/super_admin/super_admin_dashboard.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:smartedu/core/super_admin_provider.dart';
import 'package:smartedu/core/school_model.dart';
import 'manage_schools_page.dart';

class SuperAdminDashboard extends StatefulWidget {
  final Map<String, dynamic>? adminData;

  const SuperAdminDashboard({super.key, this.adminData});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  int _hoveredStat = -1;
  int _hoveredSchool = -1;
  int _hoveredAction = -1;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<SuperAdminProvider>().fetchSchools();
      if (widget.adminData != null) {
        context.read<SuperAdminProvider>().login(widget.adminData!);
      }
    });
  }

  String _getAdminName(SuperAdminProvider provider) {
    if (provider.adminName.isNotEmpty) return provider.adminName;
    return widget.adminData?['name'] ?? 'Platform Owner';
  }

  String _getInitials(SuperAdminProvider provider) {
    String name = _getAdminName(provider);
    if (name.isEmpty) return 'SA';
    List<String> parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length > 2 ? 2 : name.length).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SuperAdminProvider>();
    final isSmall = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Row(
        children: [
          if (!isSmall) _buildSidebar(provider),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(provider, isSmall),
                Expanded(child: _buildDashboardBody(provider)),
              ],
            ),
          ),
        ],
      ),
      drawer: isSmall ? _buildDrawer(provider) : null,
    );
  }

  Widget _buildSidebar(SuperAdminProvider provider) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F172A), Color(0xFF1B2A4A)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white70, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Admin Portal', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF4ADE80),
                      boxShadow: [BoxShadow(color: const Color(0xFF4ADE80).withOpacity(0.5), blurRadius: 6)],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getAdminName(provider),
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.dashboard_outlined, size: 15, color: Colors.white.withOpacity(0.35)),
                  const SizedBox(width: 8),
                  Text('Navigation', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.35), letterSpacing: 0.8)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _sidebarItem(Icons.dashboard_rounded, 'Dashboard', const Color(0xFF60A5FA), true),
                  _sidebarItem(Icons.domain_rounded, 'Schools', const Color(0xFF34D399), false, onTap: () => _navigateToSchools()),
                ],
              ),
            ),
            const Divider(color: Color(0x15FFFFFF), indent: 20, endIndent: 20),
            Padding(
              padding: const EdgeInsets.all(12),
              child: GestureDetector(
                onTap: () => context.go('/role-selection'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(0.1)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.logout_rounded, color: Color(0xFFEF5350), size: 20),
                      SizedBox(width: 12),
                      Text('Logout', style: TextStyle(color: Color(0xFFEF5350), fontSize: 14, fontWeight: FontWeight.w500)),
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

  Widget _sidebarItem(IconData icon, String label, Color color, bool selected, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: selected ? Border.all(color: color.withOpacity(0.15)) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: selected ? color.withOpacity(0.15) : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: selected ? color : Colors.white.withOpacity(0.45), size: 18),
            ),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white.withOpacity(0.55), fontSize: 14, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(SuperAdminProvider provider, bool isSmall) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          if (isSmall)
            IconButton(icon: const Icon(Icons.menu_rounded, color: Color(0xFF111827)), onPressed: () => Scaffold.of(context).openDrawer()),
          if (isSmall)
            const Text('Admin Portal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          if (!isSmall)
            const Text('Dashboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF111827), letterSpacing: -0.5)),
          const Spacer(),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: const Color(0xFFFAFBFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE8EAED))),
            child: const Stack(
              children: [
                Center(child: Icon(Icons.notifications_outlined, color: Color(0xFF9CA3AF), size: 20)),
                Positioned(right: 7, top: 7, child: Icon(Icons.circle, size: 7, color: Color(0xFFEF4444))),
              ],
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => _showAdminProfile(context, provider),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFBFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE8EAED)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: const Color(0xFF1A237E), borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text(_getInitials(provider), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_getAdminName(provider), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                      Text('Super Admin', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardBody(SuperAdminProvider provider) {
    final schools = provider.schools;
    final activeSchools = schools.where((s) => s.isActive).length;
    final paidSchools = schools.where((s) => s.hasPaidCurrentTerm).length;
    final totalStudents = schools.fold<int>(0, (sum, s) => sum + (s.studentCount ?? 0));
    final totalTeachers = schools.fold<int>(0, (sum, s) => sum + (s.teacherCount ?? 0));
    final inactiveSchools = schools.length - activeSchools;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 3,
            margin: const EdgeInsets.only(bottom: 28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF3949AB), Color(0xFF7B1FA2), Color(0xFFE65100)]),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE8EAED)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF0F4FF), Color(0xFFE8EAF6)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.public_rounded, color: Color(0xFF1A237E), size: 26),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${_getAdminName(provider).split(' ').first}!',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF111827), letterSpacing: -0.3),
                      ),
                      const SizedBox(height: 4),
                      Text('Manage all schools across the globe.', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE8EAF6))),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined, color: Color(0xFF1A237E), size: 14),
                      SizedBox(width: 8),
                      Text('Global View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A237E))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (context, constraints) {
              final count = constraints.maxWidth > 1000 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
              return GridView.count(
                crossAxisCount: count,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: count == 4 ? 1.55 : (count == 2 ? 2.2 : 3.0),
                children: [
                  _statCard(0, Icons.domain_rounded, 'Total Schools', '${schools.length}', const Color(0xFFF0F4FF), const Color(0xFF1A237E), const Color(0xFFE8EAF6), 'Registered'),
                  _statCard(1, Icons.check_circle_outline_rounded, 'Active Schools', '$activeSchools', const Color(0xFFF0FFF4), const Color(0xFF2E7D32), const Color(0xFFE8F5E9), 'Running'),
                  _statCard(2, Icons.account_balance_wallet_outlined, 'Paid This Term', '$paidSchools', const Color(0xFFFFF3E0), const Color(0xFFE65100), const Color(0xFFFBE9E7), 'Subscriptions'),
                  _statCard(3, Icons.money_off_outlined, 'Unpaid Schools', '${schools.length - paidSchools}', const Color(0xFFFCE4EC), const Color(0xFFC62828), const Color(0xFFFFCDD2), 'Pending'),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoCol = constraints.maxWidth > 500;
              if (twoCol) {
                return Row(
                  children: [
                    Expanded(child: _miniStat(Icons.people_outline_rounded, 'Total Students', '$totalStudents', const Color(0xFFF3E5F5), const Color(0xFF7B1FA2))),
                    const SizedBox(width: 12),
                    Expanded(child: _miniStat(Icons.person_pin_rounded, 'Total Teachers', '$totalTeachers', const Color(0xFFE0F2F1), const Color(0xFF00897B))),
                    const SizedBox(width: 12),
                    Expanded(child: _miniStat(Icons.pause_circle_outline_rounded, 'Inactive', '$inactiveSchools', const Color(0xFFF5F5F5), const Color(0xFF6B7280))),
                  ],
                );
              }
              return Column(
                children: [
                  _miniStat(Icons.people_outline_rounded, 'Total Students', '$totalStudents', const Color(0xFFF3E5F5), const Color(0xFF7B1FA2)),
                  const SizedBox(height: 12),
                  _miniStat(Icons.person_pin_rounded, 'Total Teachers', '$totalTeachers', const Color(0xFFE0F2F1), const Color(0xFF00897B)),
                  const SizedBox(height: 12),
                  _miniStat(Icons.pause_circle_outline_rounded, 'Inactive', '$inactiveSchools', const Color(0xFFF5F5F5), const Color(0xFF6B7280)),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          _buildQuickActions(),
          const SizedBox(height: 32),
          _buildSchoolsSection(schools),
        ],
      ),
    );
  }

  Widget _statCard(int index, IconData icon, String label, String value, Color iconBg, Color accent, Color lightBg, String subtitle) {
    final hovered = _hoveredStat == index;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredStat = index),
      onExit: (_) => setState(() => _hoveredStat = -1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: hovered ? lightBg.withOpacity(0.4) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: hovered ? accent.withOpacity(0.3) : const Color(0xFFE8EAED)),
          boxShadow: hovered ? [BoxShadow(color: accent.withOpacity(0.08), blurRadius: 18, offset: const Offset(0, 5))] : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 3, width: 28, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [iconBg, lightBg]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accent, size: 24),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withOpacity(hovered ? 0.08 : 0.03)),
                ),
              ],
            ),
            const Spacer(),
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: hovered ? accent : const Color(0xFF111827), letterSpacing: -1.2, height: 1)),
            const SizedBox(height: 3),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
            const SizedBox(height: 1),
            Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(IconData icon, String label, String value, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8EAED)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF111827), height: 1.1)),
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.bolt_rounded, color: Color(0xFFE65100), size: 16),
            ),
            const SizedBox(width: 10),
            const Text('Quick Actions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _actionCard(0, Icons.add_circle_outline_rounded, 'Register School', 'Add new institution', const Color(0xFF1A237E), const Color(0xFFF0F4FF), () => _navigateToSchools()),
            _actionCard(1, Icons.manage_accounts_outlined, 'Manage Schools', 'Edit & configure', const Color(0xFF5C6BC0), const Color(0xFFF3E5F5), () => _navigateToSchools()),
          ],
        ),
      ],
    );
  }

  Widget _actionCard(int index, IconData icon, String title, String subtitle, Color color, Color bgColor, VoidCallback onTap) {
    final hovered = _hoveredAction == index;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredAction = index),
      onExit: (_) => setState(() => _hoveredAction = -1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 190,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: hovered ? bgColor.withOpacity(0.4) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hovered ? color.withOpacity(0.3) : const Color(0xFFE8EAED)),
          boxShadow: hovered ? [BoxShadow(color: color.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))] : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 12),
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: hovered ? color : const Color(0xFF111827))),
                const SizedBox(height: 3),
                Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSchoolsSection(List<School> schools) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.domain_rounded, color: Color(0xFF1A237E), size: 16),
            ),
            const SizedBox(width: 10),
            const Text('Registered Schools', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(10)),
              child: Text('${schools.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1A237E))),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (schools.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 48),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE8EAED)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(18)),
                    child: const Icon(Icons.school_rounded, size: 32, color: Color(0xFF9CA3AF)),
                  ),
                  const SizedBox(height: 16),
                  const Text('No Schools Yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                  const SizedBox(height: 6),
                  Text('Register your first school to get started.', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                ],
              ),
            ),
          )
        else
          ...schools.asMap().entries.map((e) => _schoolTile(e.value, e.key)),
      ],
    );
  }

  Widget _schoolTile(School s, int index) {
    final typeColor = _getTypeColor(s);
    final typeLabel = _getTypeLabel(s);
    final logo = s.logoUrl;
    final logoValid = logo != null && logo.isNotEmpty;
    final hovered = _hoveredSchool == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredSchool = index),
      onExit: (_) => setState(() => _hoveredSchool = -1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hovered ? typeColor.withOpacity(0.02) : (index.isEven ? Colors.white : const Color(0xFFFAFBFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hovered ? typeColor.withOpacity(0.25) : const Color(0xFFE8EAED)),
          boxShadow: hovered ? [BoxShadow(color: typeColor.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 3))] : [],
        ),
        child: Row(
          children: [
            Container(width: 4, height: 44, decoration: BoxDecoration(color: typeColor, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 14),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: typeColor.withOpacity(0.2)),
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: typeColor.withOpacity(0.05),
                backgroundImage: logoValid ? NetworkImage(logo) : null,
                onBackgroundImageError: logoValid ? (_, __) {} : null,
                child: logoValid ? null : Icon(Icons.school_rounded, size: 22, color: typeColor.withOpacity(0.5)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on_outlined, size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 3),
                          Flexible(child: Text(s.location ?? 'No location', style: TextStyle(fontSize: 12, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      if (s.studentCount != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_outline_rounded, size: 12, color: Colors.grey.shade400),
                            const SizedBox(width: 3),
                            Text('${s.studentCount} students', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                          ],
                        ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time_rounded, size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 3),
                          Text(_timeAgo(s.createdAt), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (typeLabel.isNotEmpty) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: typeColor.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                child: Text(typeLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: typeColor)),
              ),
            ],
            const SizedBox(width: 10),
            _statusDot(s.isActive),
          ],
        ),
      ),
    );
  }

  Widget _statusDot(bool isActive) {
    final color = isActive ? const Color(0xFF4ADE80) : const Color(0xFFEF5350);
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6)],
      ),
    );
  }

  Color _getTypeColor(School s) {
    final type = s.schoolType.toString().split('.').last.toLowerCase();
    switch (type) {
      case 'primary':
        return const Color(0xFF0984E3);
      case 'secondary':
        return const Color(0xFF6C5CE7);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _getTypeLabel(School s) {
    final type = s.schoolType.toString().split('.').last.toLowerCase();
    if (type.isEmpty) return '';
    return '${type[0].toUpperCase()}${type.substring(1)}';
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }

  void _navigateToSchools() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageSchoolsPage()));
  }

  void _showAdminProfile(BuildContext context, SuperAdminProvider provider) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF0F4FF), Color(0xFFE8EAF6)]),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(child: Text(_getInitials(provider), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1A237E)))),
              ),
              const SizedBox(height: 18),
              Text(_getAdminName(provider), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827), letterSpacing: -0.3)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(6)),
                child: const Text('Super Admin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A237E))),
              ),
              const SizedBox(height: 4),
              Text('Platform Owner', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Drawer _buildDrawer(SuperAdminProvider provider) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0F172A), Color(0xFF1B2A4A)]),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withOpacity(0.06))),
                      child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white70, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Admin Portal', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(_getAdminName(provider), style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12), overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _drawerItem(Icons.dashboard_rounded, 'Dashboard', const Color(0xFF60A5FA), true),
                    _drawerItem(Icons.domain_rounded, 'Schools', const Color(0xFF34D399), false, onTap: () { Navigator.pop(context); _navigateToSchools(); }),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: GestureDetector(
                  onTap: () => context.go('/role-selection'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.withOpacity(0.1))),
                    child: const Row(
                      children: [
                        Icon(Icons.logout_rounded, color: Color(0xFFEF5350), size: 20),
                        SizedBox(width: 12),
                        Text('Logout', style: TextStyle(color: Color(0xFFEF5350), fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, Color color, bool selected, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: selected ? Border.all(color: color.withOpacity(0.15)) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: selected ? color.withOpacity(0.15) : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: selected ? color : Colors.white.withOpacity(0.45), size: 18),
            ),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white.withOpacity(0.55), fontSize: 14, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

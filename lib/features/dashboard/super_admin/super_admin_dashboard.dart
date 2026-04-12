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

  // ═══════════════════════════════════════════
  // SIDEBAR
  // ═══════════════════════════════════════════

  Widget _buildSidebar(SuperAdminProvider provider) {
    return Container(
      width: 260,
      color: const Color(0xFF1B2A4A),
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
                      color: const Color(0xFF1A237E).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Admin Portal', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _getAdminName(provider),
                style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 28),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _sidebarItem(Icons.dashboard_outlined, 'Dashboard', const Color(0xFF1A237E), true),
                  _sidebarItem(Icons.domain_outlined, 'Schools', const Color(0xFF2E7D32), false, onTap: () => _navigateToSchools()),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: GestureDetector(
                onTap: () => context.go('/role-selection'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
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

  Widget _sidebarItem(IconData icon, String label, Color color, bool selected, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: selected ? color.withOpacity(0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: selected ? color : Colors.white54, size: 18),
            ),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white70, fontSize: 14, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // TOP BAR
  // ═══════════════════════════════════════════

  Widget _buildTopBar(SuperAdminProvider provider, bool isSmall) {
    return Container(
      height: 64,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (isSmall)
            IconButton(icon: const Icon(Icons.menu, color: Color(0xFF111827)), onPressed: () => Scaffold.of(context).openDrawer()),
          if (isSmall)
            const Text('Admin Portal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
          if (!isSmall)
            const Text('Dashboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF111827), letterSpacing: -0.5)),
          const Spacer(),
          const Stack(
            children: [
              Icon(Icons.notifications_outlined, color: Color(0xFF9CA3AF), size: 24),
              Positioned(right: 8, top: 8, child: Icon(Icons.circle, size: 8, color: Colors.red)),
            ],
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _showAdminProfile(context, provider),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: const Color(0xFF1A237E), borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text(_getInitials(provider), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_getAdminName(provider), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                    const Text('Super Admin', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                  ],
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, size: 18, color: Color(0xFF9CA3AF)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // DASHBOARD BODY
  // ═══════════════════════════════════════════

  Widget _buildDashboardBody(SuperAdminProvider provider) {
    final schools = provider.schools;
    final activeSchools = schools.where((s) => s.isActive).length;
    final paidSchools = schools.where((s) => s.hasPaidCurrentTerm).length;
    final totalStudents = schools.fold<int>(0, (sum, s) => sum + (s.studentCount ?? 0));
    final totalTeachers = schools.fold<int>(0, (sum, s) => sum + (s.teacherCount ?? 0));
    final inactiveSchools = schools.length - activeSchools;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Welcome Banner ──
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
                    color: const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.public, color: Color(0xFF1A237E), size: 26),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${_getAdminName(provider).split(' ').first}!',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF111827), letterSpacing: -0.3),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage all schools across the globe.',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
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

          // ── Stats Grid ──
          LayoutBuilder(
            builder: (context, constraints) {
              final count = constraints.maxWidth > 1000 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
              return GridView.count(
                crossAxisCount: count,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: count == 4 ? 1.6 : (count == 2 ? 2.2 : 3.0),
                children: [
                  _statCard(Icons.domain, 'Total Schools', '${schools.length}', const Color(0xFFF0F4FF), const Color(0xFF1A237E), 'Registered'),
                  _statCard(Icons.check_circle_outline, 'Active Schools', '$activeSchools', const Color(0xFFF0FFF4), const Color(0xFF2E7D32), 'Running'),
                  _statCard(Icons.account_balance_wallet_outlined, 'Paid This Term', '$paidSchools', const Color(0xFFFFF3E0), const Color(0xFFE65100), 'Subscriptions'),
                  _statCard(Icons.money_off_outlined, 'Unpaid Schools', '${schools.length - paidSchools}', const Color(0xFFFCE4EC), const Color(0xFFC62828), 'Pending'),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          // ── Mini Stats Row ──
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 500) {
                return Row(
                  children: [
                    Expanded(child: _miniStat(Icons.people_outline, 'Total Students', '$totalStudents', const Color(0xFFF3E5F5), const Color(0xFF7B1FA2))),
                    const SizedBox(width: 12),
                    Expanded(child: _miniStat(Icons.person_pin_outlined, 'Total Teachers', '$totalTeachers', const Color(0xFFE0F2F1), const Color(0xFF00897B))),
                    const SizedBox(width: 12),
                    Expanded(child: _miniStat(Icons.pause_circle_outline, 'Inactive', '$inactiveSchools', const Color(0xFFF5F5F5), const Color(0xFF6B7280))),
                  ],
                );
              }
              return Column(
                children: [
                  _miniStat(Icons.people_outline, 'Total Students', '$totalStudents', const Color(0xFFF3E5F5), const Color(0xFF7B1FA2)),
                  const SizedBox(height: 12),
                  _miniStat(Icons.person_pin_outlined, 'Total Teachers', '$totalTeachers', const Color(0xFFE0F2F1), const Color(0xFF00897B)),
                  const SizedBox(height: 12),
                  _miniStat(Icons.pause_circle_outline, 'Inactive', '$inactiveSchools', const Color(0xFFF5F5F5), const Color(0xFF6B7280)),
                ],
              );
            },
          ),
          const SizedBox(height: 32),

          // ── Quick Actions ──
          _buildQuickActions(),
          const SizedBox(height: 32),

          // ── Schools List ──
          _buildSchoolsSection(schools),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // STAT CARDS
  // ═══════════════════════════════════════════

  Widget _statCard(IconData icon, String label, String value, Color bgColor, Color iconColor, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8EAED)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 24),
          ),
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827), height: 1.1)),
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // QUICK ACTIONS
  // ═══════════════════════════════════════════

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
              child: const Icon(Icons.bolt, color: Color(0xFFE65100), size: 16),
            ),
            const SizedBox(width: 10),
            const Text('Quick Actions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _actionPill(Icons.add_circle_outline, 'Register School', 'Add new institution', const Color(0xFF1A237E), const Color(0xFFF0F4FF), () => _navigateToSchools()),
            _actionPill(Icons.manage_accounts_outlined, 'Manage Schools', 'Edit & configure', const Color(0xFF5C6BC0), const Color(0xFFF3E5F5), () => _navigateToSchools()),
          ],
        ),
      ],
    );
  }

  Widget _actionPill(IconData icon, String title, String subtitle, Color color, Color bgColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE8EAED)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // SCHOOLS LIST
  // ═══════════════════════════════════════════

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
              child: const Icon(Icons.domain, color: Color(0xFF1A237E), size: 16),
            ),
            const SizedBox(width: 10),
            const Text('Registered Schools', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(12)),
              child: Text('${schools.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1A237E))),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (schools.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE8EAED)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.school, size: 28, color: Color(0xFF9CA3AF)),
                ),
                const SizedBox(height: 16),
                const Text('No Schools Yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                const SizedBox(height: 8),
                Text('Register your first school to get started.', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
              ],
            ),
          )
        else
          ...schools.map((s) => _schoolTile(s)),
      ],
    );
  }

  Widget _schoolTile(School s) {
    final typeColor = _getTypeColor(s);
    final typeLabel = _getTypeLabel(s);
    final logo = s.logoUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8EAED)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: typeColor.withOpacity(0.3), width: 1.5),
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: typeColor.withOpacity(0.05),
              backgroundImage: (logo != null && logo.isNotEmpty) ? NetworkImage(logo) : null,
              child: (logo == null || logo.isEmpty) ? Icon(Icons.school, size: 24, color: typeColor.withOpacity(0.6)) : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 4),
                    Flexible(child: Text(s.location ?? 'No location', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time, size: 13, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 4),
                    Text(_timeAgo(s.createdAt), style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                    if (s.studentCount != null) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.people_outline, size: 13, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 4),
                      Text('${s.studentCount} students', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (typeLabel.isNotEmpty) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(typeLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: typeColor)),
            ),
          ],
          const SizedBox(width: 10),
          _statusDot(s.isActive),
        ],
      ),
    );
  }

  Widget _statusDot(bool isActive) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF4CAF50) : const Color(0xFFEF5350),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: (isActive ? const Color(0xFF4CAF50) : const Color(0xFFEF5350)).withOpacity(0.4), blurRadius: 6),
        ],
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
        return Colors.grey;
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

  // ═══════════════════════════════════════════
  // NAVIGATION
  // ═══════════════════════════════════════════

  void _navigateToSchools() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageSchoolsPage()));
  }

  void _showAdminProfile(BuildContext context, SuperAdminProvider provider) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(18)),
                child: Text(_getInitials(provider), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1A237E))),
              ),
              const SizedBox(height: 18),
              Text(_getAdminName(provider), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
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

  // ═══════════════════════════════════════════
  // MOBILE DRAWER
  // ═══════════════════════════════════════════

  Drawer _buildDrawer(SuperAdminProvider provider) {
    return Drawer(
      child: Container(
        color: const Color(0xFF1B2A4A),
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
                      decoration: BoxDecoration(color: const Color(0xFF1A237E).withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Admin Portal', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _getAdminName(provider),
                  style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _drawerItem(Icons.dashboard_outlined, 'Dashboard', const Color(0xFF1A237E), true),
                    _drawerItem(Icons.domain_outlined, 'Schools', const Color(0xFF2E7D32), false, onTap: () { Navigator.pop(context); _navigateToSchools(); }),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: GestureDetector(
                  onTap: () => context.go('/role-selection'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
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
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, Color color, bool selected, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: selected ? color.withOpacity(0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: selected ? color : Colors.white54, size: 18),
            ),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white70, fontSize: 14, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

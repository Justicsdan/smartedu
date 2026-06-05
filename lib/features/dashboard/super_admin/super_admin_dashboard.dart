// ==========================================
// File: lib/features/dashboard/super_admin/super_admin_dashboard.dart
// ==========================================
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartedu/core/super_admin_provider.dart';
import 'manage_schools_page.dart';

class SuperAdminDashboard extends StatefulWidget {
  final Map<String, dynamic>? adminData;

  const SuperAdminDashboard({super.key, this.adminData});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> with TickerProviderStateMixin {
  bool _loading = true;
  int _hoveredStat = -1;
  int _hoveredAction = -1;
  int _hoveredSchool = -1;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    Future.microtask(() async {
      if (widget.adminData != null) {
        context.read<SuperAdminProvider>().login(widget.adminData!);
      }
      await context.read<SuperAdminProvider>().fetchSchools();
      if (mounted) {
        setState(() => _loading = false);
        _fadeController.forward();
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  String _getAdminName(SuperAdminProvider provider) {
    if (provider.adminName.isNotEmpty) return provider.adminName;
    return widget.adminData?['name'] ?? 'Platform Owner';
  }

  String _getInitials(SuperAdminProvider provider) {
    String name = _getAdminName(provider);
    if (name.isEmpty) return 'PO';
    List<String> parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length > 2 ? 2 : name.length).toUpperCase();
  }

  Future<void> _goToSchools() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageSchoolsPage()));
    if (mounted) await context.read<SuperAdminProvider>().fetchSchools();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SuperAdminProvider>();

    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F2F5),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.2),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                builder: (context, value, child) => Transform.scale(scale: value, child: child),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1A237E), Color(0xFF3949AB)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: const Color(0xFF1A237E).withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: const Icon(Icons.shield_rounded, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(height: 20),
              Text('Loading portal...', style: TextStyle(fontSize: 13, color: Colors.grey.shade500, letterSpacing: 0.3)),
            ],
          ),
        ),
      );
    }

    final schools = provider.schools;
    final activeSchools = schools.where((s) => s.isActive).length;
    final totalStudents = schools.fold<int>(0, (sum, s) => sum + (s.studentCount ?? 0));
    final totalTeachers = schools.fold<int>(0, (sum, s) => sum + (s.teacherCount ?? 0));
    final inactiveSchools = schools.length - activeSchools;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Column(
        children: [
          _buildHeader(provider),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        children: [
                          _buildProfileCard(provider),
                          const SizedBox(height: 14),
                          _buildStatsGrid(schools.length, activeSchools, totalStudents, totalTeachers, inactiveSchools),
                          const SizedBox(height: 14),
                          _buildActions(provider),
                          const SizedBox(height: 14),
                          _buildSchoolsList(schools),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(SuperAdminProvider provider) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [const Color(0xFF0F172A), const Color(0xFF1E293B)]),
        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF60A5FA), Color(0xFF818CF8)]),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: const Color(0xFF60A5FA).withOpacity(0.3), blurRadius: 8)],
            ),
            child: const Icon(Icons.shield_outlined, color: Colors.white, size: 15),
          ),
          const SizedBox(width: 10),
          const Text('Admin Portal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.2)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(5)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: const Color(0xFF4ADE80), shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFF4ADE80).withOpacity(0.5), blurRadius: 4)]),
                ),
                const SizedBox(width: 6),
                Text(_getAdminName(provider), style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => context.go('/role-selection'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.logout_rounded, size: 12, color: Color(0xFFFCA5A5)),
                  SizedBox(width: 4),
                  Text('Logout', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFFCA5A5))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(SuperAdminProvider provider) {
    return MouseRegion(
      
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: const [Color(0xFFFFFFFF), Color(0xFFFAFBFF)]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: const Color(0xFF1A237E).withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Hero(
              tag: 'admin_avatar',
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(begin: Alignment(-0.4, -0.8), end: Alignment(0.8, 0.6), colors: [Color(0xFF3949AB), Color(0xFF1A237E), Color(0xFF0D47A1)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: const Color(0xFF1A237E).withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 6))],
                ),
                child: Center(
                  child: Text(_getInitials(provider), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_getAdminName(provider), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.3)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _roleBadge('Super Admin', const Color(0xFF1A237E), const Color(0xFFEFF6FF), Icons.admin_panel_settings_rounded),
                      const SizedBox(width: 6),
                      _roleBadge('Platform Owner', const Color(0xFF7C3AED), const Color(0xFFF5F3FF), Icons.stars_rounded),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _showChangePassword(provider),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(Icons.key_rounded, size: 18, color: Color(0xFF94A3B8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleBadge(String label, Color color, Color bg, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.08))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.2)),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(int total, int active, int students, int teachers, int inactive) {
    final stats = [
      _StatItem(Icons.domain_rounded, 'Schools', '$total', const Color(0xFF1A237E), const Color(0xFFEEF2FF), const Color(0xFFC7D2FE)),
      _StatItem(Icons.check_circle_rounded, 'Active', '$active', const Color(0xFF059669), const Color(0xFFECFDF5), const Color(0xFFA7F3D0)),
      _StatItem(Icons.group_rounded, 'Students', '$students', const Color(0xFF7C3AED), const Color(0xFFF5F3FF), const Color(0xFFDDD6FE)),
      _StatItem(Icons.person_rounded, 'Teachers', '$teachers', const Color(0xFFEA580C), const Color(0xFFFFF7ED), const Color(0xFFFED7AA)),
    ];

    return Column(
      children: [
        Row(
          children: stats.asMap().entries.map((e) {
            final hovered = _hoveredStat == e.key;
            return Expanded(
              child: MouseRegion(
                onEnter: (_) => setState(() => _hoveredStat = e.key),
                onExit: (_) => setState(() => _hoveredStat = -1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  margin: EdgeInsets.only(left: e.key == 0 ? 0 : 5, right: e.key == 3 ? 0 : 5),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  decoration: BoxDecoration(
                    color: e.value.bgColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: hovered ? e.value.color.withOpacity(0.3) : e.value.color.withOpacity(0.08)),
                    boxShadow: hovered ? [BoxShadow(color: e.value.color.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))] : [],
                  ),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: hovered ? 36 : 32,
                        height: hovered ? 36 : 32,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: e.value.color.withOpacity(0.1), blurRadius: 6)]),
                        child: Icon(e.value.icon, color: e.value.color, size: hovered ? 18 : 16),
                      ),
                      const SizedBox(height: 8),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(fontSize: hovered ? 22 : 20, fontWeight: FontWeight.w800, color: e.value.color, height: 1),
                        child: Text(e.value.value),
                      ),
                      const SizedBox(height: 2),
                      Text(e.value.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: e.value.color.withOpacity(0.6), letterSpacing: 0.3)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (inactive > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline_rounded, size: 12, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text('$inactive inactive school${inactive > 1 ? 's' : ''}', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildActions(SuperAdminProvider provider) {
    final actions = [
      _ActionItem(Icons.manage_search_rounded, 'Manage Schools', 'View, edit & configure all schools', const Color(0xFF1A237E), const Color(0xFFEEF2FF), _goToSchools),
      _ActionItem(Icons.add_business_rounded, 'Register School', 'Add a new institution to the platform', const Color(0xFF059669), const Color(0xFFECFDF5), _goToSchools),
      _ActionItem(Icons.key_rounded, 'Change Password', 'Update your admin account credentials', const Color(0xFFEA580C), const Color(0xFFFFF7ED), () => _showChangePassword(provider)),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: actions.asMap().entries.map((e) {
          final isLast = e.key == actions.length - 1;
          final hovered = _hoveredAction == e.key;
          return Column(
            children: [
              MouseRegion(
                onEnter: (_) => setState(() => _hoveredAction = e.key),
                onExit: (_) => setState(() => _hoveredAction = -1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                    color: hovered ? e.value.bgColor.withOpacity(0.5) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: e.value.onTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: e.value.bgColor,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: hovered ? [BoxShadow(color: e.value.color.withOpacity(0.15), blurRadius: 8)] : [],
                          ),
                          child: Icon(e.value.icon, color: e.value.color, size: 18),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.value.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                              const SizedBox(height: 1),
                              Text(e.value.subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade400, height: 1.3)),
                            ],
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: hovered ? e.value.color.withOpacity(0.1) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: hovered ? e.value.color : Colors.grey.shade300),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!isLast) const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSchoolsList(List<dynamic> schools) {
    if (schools.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
                child: Icon(Icons.school_rounded, size: 24, color: Colors.grey.shade300),
              ),
              const SizedBox(height: 12),
              Text('No schools registered yet', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade400)),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.domain_rounded, size: 14, color: Color(0xFF1A237E)),
                ),
                const SizedBox(width: 8),
                const Text('Registered Schools', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [const Color(0xFF1A237E), const Color(0xFF3949AB)]), borderRadius: BorderRadius.circular(6)),
                  child: Text('${schools.length}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _goToSchools,
                  child: Text('View All', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF1A237E).withOpacity(0.7))),
                ),
              ],
            ),
          ),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
          ...schools.asMap().entries.map((e) => _schoolRow(e.value, e.key, schools.length)),
        ],
      ),
    );
  }

  Widget _schoolRow(dynamic s, int index, int total) {
    final name = s.name ?? 'Unknown';
    final location = s.location ?? '';
    final isActive = s.isActive;
    final studentCount = s.studentCount ?? 0;
    final logo = s.logoUrl;
    final logoValid = logo != null && logo.isNotEmpty;
    final typeColor = _getTypeColor(s);
    final isLast = index == total - 1;
    final hovered = _hoveredSchool == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredSchool = index),
      onExit: (_) => setState(() => _hoveredSchool = -1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(left: 8, right: 8, top: 2, bottom: isLast ? 8 : 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: hovered ? const Color(0xFFF8FAFC) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: hovered ? 4 : 3,
              height: 34,
              decoration: BoxDecoration(color: typeColor, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: typeColor.withOpacity(0.15))),
              child: CircleAvatar(
                radius: 17,
                backgroundColor: typeColor.withOpacity(0.05),
                backgroundImage: logoValid ? NetworkImage(logo) : null,
                onBackgroundImageError: logoValid ? (_, __) {} : null,
                child: logoValid ? null : Icon(Icons.school_rounded, size: 15, color: typeColor.withOpacity(0.4)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)), overflow: TextOverflow.ellipsis, maxLines: 1),
                  if (location.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 10, color: Colors.grey.shade400),
                        const SizedBox(width: 2),
                        Flexible(child: Text(location, style: TextStyle(fontSize: 11, color: Colors.grey.shade400), overflow: TextOverflow.ellipsis, maxLines: 1)),
                      ],
                    ),
                ],
              ),
            ),
            if (studentCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(5)),
                child: Text('$studentCount', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500)),
              ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: hovered ? 10 : 8,
              height: hovered ? 10 : 8,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF4ADE80) : const Color(0xFFEF5350),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: (isActive ? const Color(0xFF4ADE80) : const Color(0xFFEF5350)).withOpacity(hovered ? 0.6 : 0.35), blurRadius: hovered ? 8 : 4)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(dynamic s) {
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

  void _snack(String msg, {bool success = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: success ? const Color(0xFF059669) : const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  void _showChangePassword(SuperAdminProvider p) {
    final curr = TextEditingController();
    final newp = TextEditingController();
    final conf = TextEditingController();
    bool loading = false;
    bool obscureCurr = true;
    bool obscureNew = true;
    bool obscureConf = true;
    String? err;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setSt) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          title: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFF7ED), Color(0xFFFED7AA)]), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.lock_rounded, size: 24, color: Color(0xFFEA580C)),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Change Password', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A), letterSpacing: -0.3)),
                  SizedBox(height: 2),
                  Text('Keep your account secure', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                ],
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (err != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFECACA))),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(err!, style: const TextStyle(fontSize: 13, color: Color(0xFFDC2626), height: 1.3))),
                    ],
                  ),
                ),
              TextField(
                controller: curr,
                obscureText: obscureCurr,
                style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  labelStyle: TextStyle(color: Colors.grey.shade500),
                  border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFE2E8F0)), borderRadius: BorderRadius.all(Radius.circular(10))),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF1A237E), width: 2), borderRadius: BorderRadius.all(Radius.circular(10))),
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF1A237E)),
                  suffixIcon: GestureDetector(onTap: () => setSt(() => obscureCurr = !obscureCurr), child: Icon(obscureCurr ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey.shade400)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: newp,
                obscureText: obscureNew,
                style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'New Password',
                  labelStyle: TextStyle(color: Colors.grey.shade500),
                  border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFE2E8F0)), borderRadius: BorderRadius.all(Radius.circular(10))),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF1A237E), width: 2), borderRadius: BorderRadius.all(Radius.circular(10))),
                  prefixIcon: const Icon(Icons.lock_open_rounded, color: Color(0xFF1A237E)),
                  suffixIcon: GestureDetector(onTap: () => setSt(() => obscureNew = !obscureNew), child: Icon(obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey.shade400)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: conf,
                obscureText: obscureConf,
                style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  labelStyle: TextStyle(color: Colors.grey.shade500),
                  border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFE2E8F0)), borderRadius: BorderRadius.all(Radius.circular(10))),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF1A237E), width: 2), borderRadius: BorderRadius.all(Radius.circular(10))),
                  prefixIcon: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF1A237E)),
                  suffixIcon: GestureDetector(onTap: () => setSt(() => obscureConf = !obscureConf), child: Icon(obscureConf ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey.shade400)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.pop(ctx),
              style: TextButton.styleFrom(foregroundColor: Colors.grey.shade500, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      setSt(() { err = null; loading = true; });
                      if (curr.text.isEmpty || newp.text.isEmpty || conf.text.isEmpty) {
                        setSt(() { err = 'All fields are required'; loading = false; });
                        return;
                      }
                      if (newp.text.length < 6) {
                        setSt(() { err = 'New password must be at least 6 characters'; loading = false; });
                        return;
                      }
                      if (newp.text != conf.text) {
                        setSt(() { err = 'New passwords do not match'; loading = false; });
                        return;
                      }
                      try {
                        final r = await Supabase.instance.client.rpc('change_super_admin_password', params: {
                          'current_password': curr.text,
                          'new_password': newp.text,
                          'admin_username': p.adminUsername,
                        }).timeout(const Duration(seconds: 8));
                        if (r['success'] == true) {
                          Navigator.pop(ctx);
                          _snack('Password changed successfully');
                        } else {
                          setSt(() { err = r['error'] ?? 'Failed'; loading = false; });
                        }
                      } catch (e) {
                        setSt(() { err = 'Something went wrong'; loading = false; });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Update Password', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ],
        ),
      ),
    ).then((_) {
      curr.dispose();
      newp.dispose();
      conf.dispose();
    });
  }
}

class _StatItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bgColor;
  final Color lightColor;
  _StatItem(this.icon, this.label, this.value, this.color, this.bgColor, this.lightColor);
}

class _ActionItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;
  _ActionItem(this.icon, this.title, this.subtitle, this.color, this.bgColor, this.onTap);
}

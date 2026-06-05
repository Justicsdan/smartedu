// ==========================================
// File: lib/features/dashboard/school_admin/pages/page_dashboard.dart
// ==========================================
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

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

class _PageDashboardState extends State<PageDashboard> with TickerProviderStateMixin {
  late AnimationController _orbController;
  late AnimationController _gradientController;
  late AnimationController _staggerController;
  late Animation<double> _staggerAnimation;

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _gradientController = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _staggerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    _staggerAnimation = CurvedAnimation(parent: _staggerController, curve: Curves.easeOutCubic);
    _staggerController.forward();
  }

  @override
  void dispose() {
    _orbController.dispose();
    _gradientController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  double _staggerDelay(int index, int total) => (index / total).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    int sssCount = 0, jssCount = 0, primaryCount = 0, unassigned = 0;
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
    final isNewSchool = widget.studentCount == 0 && widget.teacherCount == 0 && widget.classCount == 0;

    return Container(
      color: const Color(0xFFEEF0F6),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 56),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBanner(),
            _buildWaveDivider(),
            if (isNewSchool) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
                child: _buildGettingStarted(),
              ),
              const SizedBox(height: 12),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 0),
              child: _buildQuickActions(),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 0),
              child: _buildQuickAccess(),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 0),
              child: _buildStatGrid(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
              child: _buildMidSection(sssCount, jssCount, primaryCount, unassigned, total),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
              child: _buildClassesSection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return ListenableBuilder(
      listenable: _gradientController,
      builder: (_, __) {
        final t = _gradientController.value;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(32, 44, 32, 40),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.2 - sin(t * pi) * 0.3, -1.0),
              end: Alignment(1.0 + cos(t * pi) * 0.3, 1.2),
              colors: [
                HSLColor.fromAHSL(1.0, 230 + sin(t * pi * 2) * 10, 0.7, 0.18 + sin(t * pi * 2) * 0.03).toColor(),
                HSLColor.fromAHSL(1.0, 235 + sin(t * pi * 2 + 1) * 10, 0.75, 0.22 + sin(t * pi * 2 + 1) * 0.02).toColor(),
                HSLColor.fromAHSL(1.0, 225 + cos(t * pi * 2) * 10, 0.65, 0.28 + cos(t * pi * 2) * 0.03).toColor(),
                HSLColor.fromAHSL(1.0, 220 + sin(t * pi * 2 + 2) * 10, 0.6, 0.34 + sin(t * pi * 2 + 2) * 0.02).toColor(),
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: ClipRect(
            child: Stack(
              children: [
                _floatingOrb(right: -30, top: -40, size: 180, opacity: 0.08, phaseX: 2.0, phaseY: 1.5),
                _floatingOrb(right: 60, bottom: -40, size: 140, opacity: 0.1, phaseX: 1.5, phaseY: 2.2, color: Colors.purpleAccent),
                _floatingOrb(left: -20, bottom: -20, size: 100, opacity: 0.05, phaseX: 1.0, phaseY: 1.8, color: Colors.cyanAccent),
                _floatingOrb(left: 100, top: -10, size: 60, opacity: 0.06, phaseX: 2.5, phaseY: 1.2, color: Colors.amberAccent),
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.025,
                    child: CustomPaint(painter: _GridPainter()),
                  ),
                ),
                for (int i = 0; i < 8; i++) _particle(i),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.white.withOpacity(0.15)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF69F0AE),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF69F0AE).withOpacity(0.6),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'ADMIN DASHBOARD',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF90CAF9),
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            const _ShimmerText(
                              'Welcome back!',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (widget.schoolName.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                widget.schoolName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                            Text(
                              "Here's what's happening at your school today",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.5),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.15)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: widget.schoolUrl.isNotEmpty
                              ? Image.network(
                                  widget.schoolUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.dashboard_rounded,
                                    size: 32,
                                    color: Color(0xFF90CAF9),
                                  ),
                                )
                              : const Icon(
                                  Icons.dashboard_rounded,
                                  size: 32,
                                  color: Color(0xFF90CAF9),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _bannerChip('${widget.studentCount} Students', const Color(0xFF64B5F6)),
                        _bannerChip('${widget.teacherCount} Teachers', const Color(0xFFFFB74D)),
                        _bannerChip('${widget.classCount} Classes', const Color(0xFFCE93D8)),
                        _bannerChip('${widget.subjectCount} Subjects', const Color(0xFF81C784)),
                        _bannerChip('${widget.assignmentCount} Assignments', const Color(0xFFFFF176)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _floatingOrb({
    double? right,
    double? left,
    double? top,
    double? bottom,
    required double size,
    double opacity = 0.08,
    double phaseX = 2.0,
    double phaseY = 1.5,
    Color? color,
  }) {
    final c = color ?? Colors.white;
    return Positioned(
      right: right,
      left: left,
      top: top,
      bottom: bottom,
      child: ListenableBuilder(
        listenable: _orbController,
        builder: (_, child) {
          final t = _orbController.value;
          return Transform.translate(
            offset: Offset(sin(t * phaseX * pi) * 18, cos(t * phaseY * pi) * 22),
            child: child,
          );
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [c.withOpacity(opacity), c.withOpacity(0)],
              stops: const [0.0, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _particle(int index) {
    final rng = Random(index * 137);
    final startX = rng.nextDouble();
    final startY = rng.nextDouble();
    final pSize = 2.0 + rng.nextDouble() * 3;
    final speed = 0.5 + rng.nextDouble() * 1.5;
    final drift = 20 + rng.nextDouble() * 40;
    return Positioned(
      left: startX * 400,
      top: startY * 200,
      child: ListenableBuilder(
        listenable: _orbController,
        builder: (_, __) {
          final t = _orbController.value;
          final progress = (t * speed) % 1.0;
          return Opacity(
            opacity: sin(progress * pi) * 0.4,
            child: Transform.translate(
              offset: Offset(
                sin(progress * pi * 2 + index) * drift,
                -progress * 60,
              ),
              child: Container(
                width: pSize,
                height: pSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _bannerChip(String text, Color dotColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: dotColor.withOpacity(0.6), blurRadius: 8),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveDivider() =>
      CustomPaint(size: const Size(double.infinity, 30), painter: _WavePainter());

  Widget _buildGettingStarted() {
    final steps = [
      (icon: Icons.school_rounded, label: 'Set up your school profile', sub: 'Add name, logo & contact details', navIndex: 7),
      (icon: Icons.add_circle_outline_rounded, label: 'Create your first class', sub: 'Add classes like JSS 1, SSS 2, etc.', navIndex: 3),
      (icon: Icons.menu_book_rounded, label: 'Add subjects', sub: 'Link subjects to each class', navIndex: 3),
      (icon: Icons.person_add_rounded, label: 'Register students', sub: 'Add students with admission numbers', navIndex: 1),
      (icon: Icons.group_add_rounded, label: 'Add teachers', sub: 'Create staff accounts & assign roles', navIndex: 2),
    ];
    return _StaggeredSlide(
      animation: _staggerAnimation,
      delay: 0.0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFE082)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFE082).withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFF57F17), Color(0xFFFFB300)]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF57F17).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.rocket_launch_rounded, size: 22, color: Colors.white),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Getting Started', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFFE65100))),
                    SizedBox(height: 2),
                    Text('Follow these steps to set up your school', style: TextStyle(fontSize: 12, color: Color(0xFFBF360C))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            for (int i = 0; i < steps.length; i++)
              _gettingStartedStep(i, steps[i]),
          ],
        ),
      ),
    );
  }

  Widget _gettingStartedStep(int index, ({IconData icon, String label, String sub, int navIndex}) step) {
    return GestureDetector(
      onTap: () => widget.onNavigate?.call(step.navIndex),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFE082).withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF57F17).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(step.icon, size: 18, color: const Color(0xFFF57F17)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                  const SizedBox(height: 2),
                  Text(step.sub, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ],
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFF57F17).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFFF57F17)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return _StaggeredSlide(
      animation: _staggerAnimation,
      delay: 0.05,
      child: Row(
        children: [
          _quickAction(Icons.person_add_rounded, 'Add Student', const Color(0xFF1A237E), 1),
          const SizedBox(width: 10),
          _quickAction(Icons.group_add_rounded, 'Add Teacher', const Color(0xFF2E7D32), 2),
          const SizedBox(width: 10),
          _quickAction(Icons.add_circle_outline_rounded, 'New Class', const Color(0xFF7B1FA2), 3),
          const SizedBox(width: 10),
          _quickAction(Icons.quiz_rounded, 'Create CBT', const Color(0xFFC62828), 5),
        ],
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, Color accent, int navIndex) {
    return GestureDetector(
      onTap: () => widget.onNavigate?.call(navIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [accent, accent.withOpacity(0.7)]),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccess() {
    final navItems = [
      (icon: Icons.people_rounded, title: 'Students', desc: 'View & manage all students', color: const Color(0xFF1A237E), bg: const Color(0xFFE8EAF6), index: 1, count: widget.studentCount),
      (icon: Icons.person_pin_rounded, title: 'Teachers', desc: 'Staff list, roles & assignments', color: const Color(0xFFE65100), bg: const Color(0xFFFBE9E7), index: 2, count: widget.teacherCount),
      (icon: Icons.layers_rounded, title: 'Classes', desc: 'Manage classes & subjects', color: const Color(0xFF7B1FA2), bg: const Color(0xFFF3E5F5), index: 3, count: widget.classCount),
      (icon: Icons.calendar_month_rounded, title: 'Academic', desc: 'Sessions, terms & population', color: const Color(0xFF00838F), bg: const Color(0xFFE0F7FA), index: 4, count: null),
      (icon: Icons.edit_note_rounded, title: 'Score Entry', desc: 'Enter scores by class & subject', color: const Color(0xFF2E7D32), bg: const Color(0xFFE8F5E9), index: 5, count: null),
      (icon: Icons.publish_rounded, title: 'Publish Results', desc: 'Compute summaries & publish', color: const Color(0xFFC62828), bg: const Color(0xFFFFEBEE), index: 6, count: null),
      (icon: Icons.settings_rounded, title: 'Settings', desc: 'Profile, branding & grading', color: const Color(0xFF4527A0), bg: const Color(0xFFEDE7F6), index: 7, count: null),
      (icon: Icons.badge_rounded, title: 'Credentials', desc: 'Generate & print login cards', color: const Color(0xFFF57F17), bg: const Color(0xFFFFF8E1), index: 8, count: null),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF3949AB)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.apps_rounded, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text('Quick Access', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827), letterSpacing: -0.3)),
            const SizedBox(width: 8),
            Text('Navigate to any section', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth > 800 ? 4 : constraints.maxWidth > 560 ? 2 : 1;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (int i = 0; i < navItems.length; i++)
                  SizedBox(
                    width: cols == 1 ? double.infinity : (constraints.maxWidth - (cols - 1) * 12) / cols,
                    child: _StaggeredSlide(
                      animation: _staggerAnimation,
                      delay: 0.1 + _staggerDelay(i, navItems.length) * 0.3,
                      child: _navCard(navItems[i]),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _navCard(({IconData icon, String title, String desc, Color color, Color bg, int index, int? count}) item) {
    return GestureDetector(
      onTap: () => widget.onNavigate?.call(item.index),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8EBF0)),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -12,
              top: -12,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(shape: BoxShape.circle, color: item.color.withOpacity(0.02)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [item.color, item.color.withOpacity(0.65)]),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(item.icon, size: 22, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: item.color)),
                        const SizedBox(height: 2),
                        Text(item.desc, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.count != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: item.bg, borderRadius: BorderRadius.circular(6)),
                          child: Text('${item.count}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: item.color)),
                        ),
                        const SizedBox(height: 6),
                      ],
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: item.color.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.arrow_forward_rounded, size: 14, color: item.color.withOpacity(0.3)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatGrid() {
    final cards = [
      _StatCardData(title: 'Students', count: widget.studentCount, icon: Icons.people_rounded, accent: const Color(0xFF1A237E), accentLight: const Color(0xFF3949AB), tintBg: const Color(0xFFE8EAF6)),
      _StatCardData(title: 'Teachers', count: widget.teacherCount, icon: Icons.person_pin_rounded, accent: const Color(0xFFE65100), accentLight: const Color(0xFFFF8F00), tintBg: const Color(0xFFFBE9E7)),
      _StatCardData(title: 'Classes', count: widget.classCount, icon: Icons.layers_rounded, accent: const Color(0xFF7B1FA2), accentLight: const Color(0xFFAB47BC), tintBg: const Color(0xFFF3E5F5)),
      _StatCardData(title: 'Subjects', count: widget.subjectCount, icon: Icons.menu_book_rounded, accent: const Color(0xFF2E7D32), accentLight: const Color(0xFF43A047), tintBg: const Color(0xFFE8F5E9)),
      _StatCardData(title: 'Assignments', count: widget.assignmentCount, icon: Icons.assignment_rounded, accent: const Color(0xFFF57F17), accentLight: const Color(0xFFFFB300), tintBg: const Color(0xFFFCEFC7)),
      _StatCardData(title: 'Active CBTs', count: widget.activeCbtCount, icon: Icons.quiz_rounded, accent: const Color(0xFFC62828), accentLight: const Color(0xFFEF5350), tintBg: const Color(0xFFFFCDD2)),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 950 ? 3 : constraints.maxWidth > 620 ? 2 : 1;
        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            childAspectRatio: 1.6,
          ),
          children: [
            for (int i = 0; i < cards.length; i++)
              _StaggeredSlide(
                animation: _staggerAnimation,
                delay: 0.35 + _staggerDelay(i, cards.length) * 0.2,
                child: _statCard(cards[i]),
              ),
          ],
        );
      },
    );
  }

  Widget _statCard(_StatCardData d) {
    final maxVal = widget.studentCount > 0 ? widget.studentCount.toDouble() : 1.0;
    final progress = (d.count / maxVal).clamp(0.0, 1.0);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8EBF0)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(shape: BoxShape.circle, color: d.accent.withOpacity(0.02)),
            ),
          ),
          Positioned(
            left: 20,
            bottom: 16,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: d.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 20, 18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [d.accent, d.accentLight]),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(d.icon, size: 22, color: Colors.white),
                      ),
                      const Spacer(),
                      _AnimatedCount(
                        count: d.count,
                        duration: const Duration(milliseconds: 1400),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: d.accent,
                          letterSpacing: -1.5,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(d.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[500])),
                    ],
                  ),
                ),
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CustomPaint(
                    painter: _RingPainter(
                      progress: progress,
                      color: d.accent,
                      bgColor: d.accent.withOpacity(0.04),
                      strokeWidth: 5.5,
                    ),
                    child: Center(
                      child: Text(
                        '${(progress * 100).round()}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: d.accent.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMidSection(int sss, int jss, int primary, int unassigned, int total) {
    return _StaggeredSlide(
      animation: _staggerAnimation,
      delay: 0.6,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final twoCol = constraints.maxWidth > 720;
          if (twoCol) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _distributionCard(sss, jss, primary, unassigned, total)),
                const SizedBox(width: 18),
                Expanded(child: _quickInfoCard()),
              ],
            );
          }
          return Column(
            children: [
              _distributionCard(sss, jss, primary, unassigned, total),
              const SizedBox(height: 18),
              _quickInfoCard(),
            ],
          );
        },
      ),
    );
  }

  Widget _distributionCard(int sss, int jss, int primary, int unassigned, int total) {
    final sssPct = (sss / total * 100).round();
    final jssPct = (jss / total * 100).round();
    final primaryPct = (primary / total * 100).round();
    final unassignedPct = (unassigned / total * 100).round();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFE8EAF6), Color(0xFFF0F4FF)]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF3949AB)]),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.bar_chart_rounded, size: 22, color: Colors.white),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Class Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                    SizedBox(height: 2),
                    Text('Breakdown by school tier', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                if (widget.classes.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 36,
                      child: _AnimatedBars(
                        animation: _staggerAnimation,
                        delay: 0.65,
                        children: [
                          if (sss > 0) Expanded(flex: sss, child: _barSegment(sssPct, const Color(0xFF1565C0), 'SSS')),
                          if (jss > 0) Expanded(flex: jss, child: _barSegment(jssPct, const Color(0xFFE65100), 'JSS')),
                          if (primary > 0) Expanded(flex: primary, child: _barSegment(primaryPct, const Color(0xFF7B1FA2), 'PRI')),
                          if (unassigned > 0) Expanded(flex: unassigned, child: _barSegment(unassignedPct, Colors.grey[400]!, '?')),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _legendBlock('SSS', sss, const Color(0xFF1565C0), const Color(0xFFE3F2FD))),
                    const SizedBox(width: 8),
                    Expanded(child: _legendBlock('JSS', jss, const Color(0xFFE65100), const Color(0xFFFFF3E0))),
                    const SizedBox(width: 8),
                    Expanded(child: _legendBlock('PRIMARY', primary, const Color(0xFF7B1FA2), const Color(0xFFF3E5F5))),
                    if (unassigned > 0) ...[
                      const SizedBox(width: 8),
                      Expanded(child: _legendBlock('None', unassigned, Colors.grey[500]!, Colors.grey[100]!)),
                    ],
                  ],
                ),
                if (unassigned > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFE082)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFE65100)),
                        SizedBox(width: 8),
                        Text('Some classes have no tier set', style: TextStyle(fontSize: 12, color: Color(0xFFE65100), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _barSegment(int pct, Color color, String label) => Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color),
        child: pct >= 15
            ? Text('$label $pct%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.3))
            : null,
      );

  Widget _legendBlock(String label, int count, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          _AnimatedCount(
            count: count,
            duration: const Duration(milliseconds: 1200),
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color, height: 1),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color.withOpacity(0.65), letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _quickInfoCard() {
    final ratio = widget.teacherCount > 0 ? (widget.studentCount / widget.teacherCount).toStringAsFixed(1) : 'N/A';
    final avgPerClass = widget.classCount > 0 ? (widget.studentCount / widget.classCount).round() : 'N/A';
    final subjPerClass = widget.classCount > 0 ? (widget.subjectCount / widget.classCount).toStringAsFixed(1) : 'N/A';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFE8F5E9), Color(0xFFF0FFF4)]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF43A047)]),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.insights_rounded, size: 22, color: Colors.white),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quick Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                    SizedBox(height: 2),
                    Text('Key metrics at a glance', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
            child: Column(
              children: [
                _metricRow('Student : Teacher', ratio, const Color(0xFF1A237E), Icons.swap_horiz_rounded, const Color(0xFFE8EAF6)),
                const SizedBox(height: 8),
                _metricRow('Avg Students / Class', '$avgPerClass', const Color(0xFF7B1FA2), Icons.group_work_rounded, const Color(0xFFF3E5F5)),
                const SizedBox(height: 8),
                _metricRow('Avg Subjects / Class', subjPerClass, const Color(0xFF2E7D32), Icons.grid_view_rounded, const Color(0xFFE8F5E9)),
                const SizedBox(height: 8),
                _metricRow('Active CBT Exams', '${widget.activeCbtCount}', const Color(0xFFC62828), Icons.quiz_rounded, const Color(0xFFFFEBEE)),
                const SizedBox(height: 8),
                _metricRow('Total Assignments', '${widget.assignmentCount}', const Color(0xFFF57F17), Icons.assignment_rounded, const Color(0xFFFFF8E1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricRow(String label, String value, Color accent, IconData icon, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[600]))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: accent)),
          ),
        ],
      ),
    );
  }

  Widget _buildClassesSection() {
    return _StaggeredSlide(
      animation: _staggerAnimation,
      delay: 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF7B1FA2), Color(0xFFAB47BC)]),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.class_rounded, size: 22, color: Colors.white),
              ),
              const SizedBox(width: 14),
              const Text('Classes Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827), letterSpacing: -0.3)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF7B1FA2), Color(0xFFAB47BC)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${widget.classes.length}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.classes.isEmpty)
            _emptyState()
          else
            for (final c in widget.classes)
              _classCard(c),
        ],
      ),
    );
  }

  Widget _classCard(Map<String, dynamic> c) {
    final name = c['name']?.toString() ?? '';
    final section = c['section']?.toString() ?? '';
    final className = section.isNotEmpty ? '$name - $section' : name;
    final studentCount = c['studentCount'] ?? 0;
    final tier = (c['tier'] ?? '').toString().toUpperCase();
    final tierColor = tier == 'JSS' ? const Color(0xFFE65100) : tier == 'PRIMARY' ? const Color(0xFF7B1FA2) : const Color(0xFF1565C0);
    final tierEnd = tier == 'JSS' ? const Color(0xFFFF8F00) : tier == 'PRIMARY' ? const Color(0xFFAB47BC) : const Color(0xFF42A5F5);
    final tierBg = tier == 'JSS' ? const Color(0xFFFFF3E0) : tier == 'PRIMARY' ? const Color(0xFFF3E5F5) : const Color(0xFFE3F2FD);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [tierColor, tierEnd],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -10,
              top: -10,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(shape: BoxShape.circle, color: tierBg.withOpacity(0.2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: tierBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: tierColor.withOpacity(0.1)),
                    ),
                    child: Icon(Icons.class_rounded, size: 24, color: tierColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(className, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(Icons.people_outline_rounded, size: 13, color: Colors.grey[400]),
                            const SizedBox(width: 4),
                            Text(
                              '$studentCount student${studentCount != 1 ? 's' : ''}',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[500]),
                            ),
                            if (studentCount > 0) ...[
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: tierBg, borderRadius: BorderRadius.circular(6)),
                                child: Text('Populated', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: tierColor)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (tier.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [tierColor, tierEnd]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        tier,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.8),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF7B1FA2), Color(0xFFAB47BC)]),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.class_rounded, size: 34, color: Colors.white),
            ),
            const SizedBox(height: 22),
            Text('No classes yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.grey[700])),
            const SizedBox(height: 6),
            Text('Create your first class to get started', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }
}

class _StatCardData {
  final String title;
  final int count;
  final IconData icon;
  final Color accent;
  final Color accentLight;
  final Color tintBg;
  _StatCardData({required this.title, required this.count, required this.icon, required this.accent, required this.accentLight, required this.tintBg});
}

class _StaggeredSlide extends StatelessWidget {
  final Animation<double> animation;
  final double delay;
  final Widget child;
  const _StaggeredSlide({required this.animation, required this.delay, required this.child});

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(delay, (delay + 0.4).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }
}

class _AnimatedBars extends StatelessWidget {
  final Animation<double> animation;
  final double delay;
  final List<Widget> children;
  const _AnimatedBars({required this.animation, required this.delay, required this.children});

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(delay, (delay + 0.5).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
    );
    return ClipRect(
      child: Align(
        alignment: Alignment.centerLeft,
        widthFactor: curved.value,
        child: Row(children: children),
      ),
    );
  }
}

class _AnimatedCount extends StatefulWidget {
  final int count;
  final Duration duration;
  final TextStyle style;
  const _AnimatedCount({required this.count, required this.duration, required this.style});

  @override
  State<_AnimatedCount> createState() => _AnimatedCountState();
}

class _AnimatedCountState extends State<_AnimatedCount> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _animation,
        builder: (_, __) => Text(
          (_animation.value * widget.count).round().toString(),
          style: widget.style,
        ),
      );
}

class _ShimmerText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const _ShimmerText(this.text, {required this.style});

  @override
  State<_ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<_ShimmerText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _controller,
        builder: (_, __) => ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [Colors.white, Colors.white.withOpacity(0.4), Colors.white],
            stops: [
              (_controller.value - 0.3).clamp(0.0, 1.0),
              _controller.value.clamp(0.0, 1.0),
              (_controller.value + 0.3).clamp(0.0, 1.0),
            ],
            tileMode: TileMode.mirror,
          ).createShader(bounds),
          blendMode: BlendMode.srcATop,
          child: Text(widget.text, style: widget.style),
        ),
      );
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;
  final double strokeWidth;
  _RingPainter({required this.progress, required this.color, required this.bgColor, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth * 2) / 2;
    canvas.drawCircle(center, radius, Paint()..color = bgColor..style = PaintingStyle.stroke..strokeWidth = strokeWidth);
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress || old.color != color;
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFEEF0F6)..style = PaintingStyle.fill;
    final path = Path()..moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 2) {
      path.lineTo(x, size.height * 0.5 + sin(x / 60 * pi) * 8 + sin(x / 30 * pi) * 4);
    }
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

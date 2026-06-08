import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final ScrollController _scrollCtrl = ScrollController();
  late final AnimationController _logoAnim;
  late final AnimationController _fadeAnim;
  late final AnimationController _gradientAnim;
  late final AnimationController _pulseAnim;
  late final AnimationController _borderAnim;

  Offset _mouseOffset = Offset.zero;
  int _hoveredFeature = -1;
  int _hoveredStep = -1;
  bool _showScrollTop = false;

  final _particles = List.generate(15, (i) {
    final r = math.Random(i * 7 + 3);
    return _PData(
      x: r.nextDouble(), y: r.nextDouble(), sz: r.nextDouble() * 2.5 + 0.8,
      op: r.nextDouble() * 0.2 + 0.05, ph: r.nextDouble(),
      dx: (r.nextDouble() - 0.5) * 30, dy: (r.nextDouble() - 0.5) * 30,
    );
  });

  @override
  void initState() {
    super.initState();
    _logoAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat(reverse: true);
    _fadeAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..forward();
    _gradientAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 5000))..repeat();
    _pulseAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 6000))..repeat();
    _borderAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final show = _scrollCtrl.offset > 400;
    if (show != _showScrollTop) setState(() => _showScrollTop = show);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _logoAnim.dispose();
    _fadeAnim.dispose();
    _gradientAnim.dispose();
    _pulseAnim.dispose();
    _borderAnim.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _openWhatsApp() {
    launchUrl(Uri.parse('https://wa.me/2347080304822'), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final sz = MediaQuery.of(context).size;
    final w = sz.width >= 640;
    return Scaffold(
      body: MouseRegion(
        onHover: (e) {
          setState(() {
            _mouseOffset = Offset(
              (e.localPosition.dx / sz.width - 0.5) * 2,
              (e.localPosition.dy / sz.height - 0.5) * 2,
            );
          });
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-0.8, -1.2),
                    end: Alignment(0.8, 1.2),
                    colors: [Color(0xFF080C22), Color(0xFF0E1630), Color(0xFF0B1025)],
                  ),
                ),
              ),
            ),
            for (final p in _particles)
              Positioned(
                top: p.y * sz.height,
                left: p.x * sz.width,
                child: AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) {
                    final v = (_pulseAnim.value + p.ph) % 1.0;
                    return Transform.translate(
                      offset: Offset(p.dx * math.sin(v * 2 * math.pi), p.dy * math.cos(v * 2 * math.pi)),
                      child: Container(
                        width: p.sz, height: p.sz,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF6366F1).withOpacity(p.op)),
                      ),
                    );
                  },
                ),
              ),
            Positioned(
              top: -120 + _mouseOffset.dy * 18,
              right: -80 + _mouseOffset.dx * 18,
              child: _orb(320, Colors.indigo, 0.07),
            ),
            Positioned(
              bottom: -140 - _mouseOffset.dy * 18,
              left: -100 + _mouseOffset.dx * 18,
              child: _orb(380, Colors.purple, 0.05),
            ),
            Positioned(
              top: sz.height * 0.45 + _mouseOffset.dy * 8,
              left: sz.width * 0.3 - _mouseOffset.dx * 8,
              child: _orb(200, const Color(0xFF6366F1), 0.04),
            ),
            Positioned.fill(
              child: SingleChildScrollView(
                controller: _scrollCtrl,
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: w ? 720 : 440),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      children: [
                        const SizedBox(height: 72),
                        _hero(w),
                        const SizedBox(height: 60),
                        _Reveal(scrollCtrl: _scrollCtrl, child: _features(w)),
                        const SizedBox(height: 60),
                        _Reveal(scrollCtrl: _scrollCtrl, child: _gradingShowcase(w)),
                        const SizedBox(height: 60),
                        _Reveal(scrollCtrl: _scrollCtrl, child: _steps(w)),
                        const SizedBox(height: 60),
                        _Reveal(scrollCtrl: _scrollCtrl, child: _trustBar(w)),
                        const SizedBox(height: 60),
                        _Reveal(scrollCtrl: _scrollCtrl, child: _faq(w)),
                        const SizedBox(height: 60),
                        _footer(w),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_showScrollTop)
              Positioned(
                bottom: 28, right: 28,
                child: _fab(Icons.keyboard_arrow_up, Colors.white, const Color(0xFF1A237E), () => _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic)),
              ),
            Positioned(
              bottom: 28, left: 28,
              child: _fab(Icons.chat_bubble_rounded, Colors.white, const Color(0xFF25D366), _openWhatsApp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orb(double size, Color color, double opacity) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, __) {
        final s = size + math.sin(_pulseAnim.value * 2 * math.pi) * 20;
        return Container(
          width: s, height: s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color.withOpacity(opacity + 0.02), color.withOpacity(opacity * 0.3), Colors.transparent],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }

  Widget _fab(IconData icon, Color iconColor, Color bg, VoidCallback onTap) {
    return Material(
      color: bg,
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: bg.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))],
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
      ),
    );
  }

  Widget _hero(bool w) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _logoAnim,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, math.sin(_logoAnim.value * 2 * math.pi) * 6),
            child: child,
          ),
          child: Container(
            width: w ? 90 : 72, height: w ? 90 : 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
              boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.35), blurRadius: 40, offset: const Offset(0, 14))],
            ),
            child: const Icon(Icons.school_rounded, size: 36, color: Colors.white),
          ),
        ),
        const SizedBox(height: 28),
        _animatedGradientText('Complete School\nManagement System', w ? 38 : 28, FontWeight.w900, -0.8, 1.15),
        const SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: w ? 40 : 20),
          child: Text(
            'Streamline admissions, scores, results, and more — built for Nigerian schools with full American GPA support.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: w ? 14 : 13, color: Colors.white.withOpacity(0.4), height: 1.6),
          ),
        ),
        const SizedBox(height: 32),
        _ctaButton('Get Started', w, () => context.go('/role-selection')),
        const SizedBox(height: 12),
        _ghostButton('Learn More', w, () => _scrollCtrl.animateTo(500, duration: const Duration(milliseconds: 800), curve: Curves.easeInOutCubic)),
        if (w) ...[const SizedBox(height: 28), _pills()],
      ],
    );
  }

  Widget _animatedGradientText(String text, double size, FontWeight weight, double spacing, double height) {
    return AnimatedBuilder(
      animation: _gradientAnim,
      builder: (_, child) {
        final t = _gradientAnim.value;
        return ShaderMask(
          shaderCallback: (b) {
            final c1 = const Color(0xFF6366F1);
            final c2 = const Color(0xFFA78BFA);
            final c3 = const Color(0xFFF472B6);
            return LinearGradient(
              colors: [
                c1,
                Color.lerp(c1, c2, (t * 2).clamp(0.0, 1.0))!,
                Color.lerp(c2, c3, ((t * 2 - 1).clamp(0.0, 1.0)))!,
                c1,
              ],
              stops: [
                (t * 2 - 0.4).clamp(0.0, 0.33),
                t.clamp(0.33, 0.66),
                (t * 2 + 0.4).clamp(0.66, 1.0),
                1.0,
              ],
              tileMode: TileMode.mirror,
            ).createShader(b);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: size, fontWeight: weight, color: Colors.white, letterSpacing: spacing, height: height)),
    );
  }

  Widget _ctaButton(String label, bool w, VoidCallback onTap) {
    return _HoverBtn(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: _borderAnim,
        builder: (_, child) {
          final a = _borderAnim.value * 2 * math.pi;
          return Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment(math.cos(a), math.sin(a)),
                end: Alignment(-math.cos(a), -math.sin(a)),
                colors: const [Color(0xFF6366F1), Color(0xFFEC4899), Color(0xFF8B5CF6), Color(0xFF6366F1)],
              ),
            ),
            child: child,
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: w ? 36 : 28, vertical: w ? 14 : 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0E0E2A), Color(0xFF191940)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Text('Get Started', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.2)),
            SizedBox(width: 6),
            Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
          ]),
        ),
      ),
    );
  }

  Widget _ghostButton(String label, bool w, VoidCallback onTap) {
    return _HoverBtn(
      isGhost: true,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: w ? 30 : 24, vertical: w ? 12 : 10),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.12))),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.6), letterSpacing: 0.2)),
      ),
    );
  }

  Widget _pills() {
    final items = [(Icons.bolt_rounded, 'Fast'), (Icons.verified_user_rounded, 'Secure'), (Icons.checkroom_rounded, 'Reliable'), (Icons.laptop_mac_rounded, 'Cross-Platform')];
    return Wrap(
      spacing: 8, runSpacing: 6, alignment: WrapAlignment.center,
      children: items.map((p) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.07))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(p.$1, size: 12, color: Colors.white38),
          const SizedBox(width: 5),
          Text(p.$2, style: const TextStyle(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.w500)),
        ]),
      )).toList(),
    );
  }

  Widget _features(bool w) {
    final feats = <Map<String, dynamic>>[
      {'icon': Icons.calculate_rounded, 'title': 'Smart Grading', 'desc': 'WAEC, BECE, 5-point & American GPA with auto positions.', 'color': const Color(0xFF6366F1)},
      {'icon': Icons.assessment_rounded, 'title': 'Result Publishing', 'desc': 'One-click publish with behavioral ratings & comments.', 'color': const Color(0xFF10B981)},
      {'icon': Icons.people_alt_rounded, 'title': 'Role-Based Access', 'desc': 'Separate dashboards for Admin, Teacher & Student.', 'color': const Color(0xFFF59E0B)},
      {'icon': Icons.quiz_rounded, 'title': 'CBT Exams', 'desc': 'Computer-based tests with auto grading & score sync.', 'color': const Color(0xFFEC4899)},
      {'icon': Icons.fingerprint_rounded, 'title': 'Secure Login', 'desc': 'PIN for students, bcrypt passwords for staff.', 'color': const Color(0xFF06B6D4)},
      {'icon': Icons.print_rounded, 'title': 'PDF Reports', 'desc': 'Professional results with photos, stamps & signatures.', 'color': const Color(0xFF8B5CF6)},
    ];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w ? 0 : 16),
      child: Column(
        children: [
          _sectionHeader('Powerful Features', 'Everything your school needs', w),
          const SizedBox(height: 24),
          Wrap(
            spacing: 14, runSpacing: 14,
            children: feats.asMap().entries.map((e) {
              final f = e.value;
              final hov = _hoveredFeature == e.key;
              final color = f['color'] as Color;
              return SizedBox(
                width: w ? (720 - 14) / 2 : double.infinity,
                child: MouseRegion(
                  onEnter: (_) => setState(() => _hoveredFeature = e.key),
                  onExit: (_) => setState(() => _hoveredFeature = -1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: hov ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: hov ? color.withOpacity(0.3) : Colors.white.withOpacity(0.06)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]), borderRadius: BorderRadius.circular(12)),
                          child: Icon(f['icon'] as IconData, size: 20, color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(f['title'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(hov ? 1.0 : 0.85))),
                              const SizedBox(height: 4),
                              Text(f['desc'] as String, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4), height: 1.45)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _gradingShowcase(bool w) {
    final systems = [
      _GSystem(
        title: 'SSS', subtitle: 'WAEC · NECO · IGCSE', icon: Icons.school_rounded, color: const Color(0xFF6366F1),
        grades: [
          ('A1', const Color(0xFF22C55E)), ('B2', const Color(0xFF4ADE80)), ('B3', const Color(0xFF86EFAC)),
          ('C4', const Color(0xFFFBBF24)), ('C5', const Color(0xFFFCD34D)), ('C6', const Color(0xFFFDE68A)),
          ('D7', const Color(0xFFFB923C)), ('E8', const Color(0xFFFDBA74)), ('F9', const Color(0xFFEF4444)),
        ],
        desc: 'Five assessment columns with auto position computation',
      ),
      _GSystem(
        title: 'JSS', subtitle: 'BECE Standard', icon: Icons.menu_book_rounded, color: const Color(0xFF10B981),
        grades: [
          ('A', const Color(0xFF22C55E)), ('B', const Color(0xFF14B8A6)),
          ('C', const Color(0xFFFBBF24)), ('P', const Color(0xFFFB923C)), ('F', const Color(0xFFEF4444)),
        ],
        desc: 'Continuous Assessment and Exam — two columns',
      ),
      _GSystem(
        title: 'Primary', subtitle: '5-Point Scale', icon: Icons.child_care_rounded, color: const Color(0xFFF59E0B),
        grades: [
          ('5', const Color(0xFF22C55E)), ('4', const Color(0xFF14B8A6)),
          ('3', const Color(0xFFFBBF24)), ('2', const Color(0xFFFB923C)), ('1', const Color(0xFFEF4444)),
        ],
        desc: 'Three assessment columns with simple grading',
      ),
      _GSystem(
        title: 'American', subtitle: 'US GPA System', icon: Icons.star_rounded, color: const Color(0xFFEC4899),
        grades: [
          ('A', const Color(0xFF22C55E)), ('A-', const Color(0xFF4ADE80)),
          ('B+', const Color(0xFF14B8A6)), ('B', const Color(0xFF2DD4BF)), ('B-', const Color(0xFF5EEAD4)),
          ('C+', const Color(0xFFFBBF24)), ('C', const Color(0xFFFCD34D)), ('C-', const Color(0xFFFDE68A)),
          ('D+', const Color(0xFFFB923C)), ('D', const Color(0xFFFDBA74)), ('D-', const Color(0xFFFED7AA)),
          ('F', const Color(0xFFEF4444)),
        ],
        desc: 'Five assessment columns with 4.0 GPA points',
      ),
    ];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w ? 0 : 16),
      child: Column(
        children: [
          _sectionHeader('Grading Standards', 'Nigerian and American systems, fully supported', w),
          const SizedBox(height: 24),
          Wrap(
            spacing: 14, runSpacing: 14,
            children: systems.map((g) => SizedBox(
              width: w ? (720 - 14) / 2 : double.infinity,
              child: _gradeCard(g),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _gradeCard(_GSystem g) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.025),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(gradient: LinearGradient(colors: [g.color, g.color.withOpacity(0.7)]), borderRadius: BorderRadius.circular(10)),
                child: Icon(g.icon, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(g.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text(g.subtitle, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 5, runSpacing: 5,
            children: g.grades.map((gr) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: gr.$2.withOpacity(0.12),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: gr.$2.withOpacity(0.25), width: 0.5),
              ),
              child: Text(gr.$1, style: TextStyle(fontSize: g.grades.length > 6 ? 10 : 11, fontWeight: FontWeight.w700, color: gr.$2, letterSpacing: 0.3)),
            )).toList(),
          ),
          const SizedBox(height: 14),
          Text(g.desc, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.32), height: 1.4)),
        ],
      ),
    );
  }

  Widget _steps(bool w) {
    final steps = [
      ('Set Up School', 'Configure your profile, grading system, and classes.', Icons.domain_add_rounded, const Color(0xFF6366F1)),
      ('Register People', 'Add students and teachers with photos and details.', Icons.group_add_rounded, const Color(0xFF10B981)),
      ('Enter & Publish', 'Record scores, compute positions, publish results.', Icons.publish_rounded, const Color(0xFFF59E0B)),
    ];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w ? 0 : 16),
      child: Column(
        children: [
          _sectionHeader('How It Works', 'Three steps to go live', w),
          const SizedBox(height: 20),
          ...steps.asMap().entries.map((e) {
            final s = e.value;
            final hov = _hoveredStep == e.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MouseRegion(
                onEnter: (_) => setState(() => _hoveredStep = e.key),
                onExit: (_) => setState(() => _hoveredStep = -1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(hov ? 0.05 : 0.02),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(hov ? 0.1 : 0.04)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(gradient: LinearGradient(colors: [s.$4, s.$4.withOpacity(0.65)]), borderRadius: BorderRadius.circular(14)),
                        child: Icon(s.$3, size: 22, color: Colors.white),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.$1, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(hov ? 1.0 : 0.82))),
                            const SizedBox(height: 4),
                            Text(s.$2, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(hov ? 0.45 : 0.3), height: 1.4)),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white.withOpacity(hov ? 0.3 : 0.1)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _trustBar(bool w) {
    final badges = [
      (Icons.verified_user_rounded, 'Secure'),
      (Icons.cloud_done_rounded, 'Cloud Hosted'),
      (Icons.speed_rounded, 'Fast'),
      (Icons.phone_iphone_rounded, 'Any Device'),
      (Icons.workspace_premium_rounded, 'Int\'l Standards'),
    ];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w ? 0 : 16),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: w ? 28 : 20, vertical: 22),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white.withOpacity(0.03), Colors.white.withOpacity(0.01)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Text('Built for Real Schools', style: TextStyle(fontSize: w ? 20 : 17, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3)),
            const SizedBox(height: 4),
            Text('Designed for Nigerian schools, ready for the world', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.35))),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10, runSpacing: 10, alignment: WrapAlignment.center,
              children: badges.map((b) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.035), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.06))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(b.$1, size: 15, color: const Color(0xFF818CF8)),
                  const SizedBox(width: 8),
                  Text(b.$2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70)),
                ]),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _faq(bool w) {
    final faqs = [
      ('How do I get started?', 'Sign up, set up your school profile, add classes, register students and teachers. You can publish your first results in under an hour.'),
      ('Which grading systems are supported?', 'WAEC, NECO, IGCSE for secondary school, BECE for junior school, 5-point scale for primary — plus a full American GPA system. Each tier supports custom overrides.'),
      ('Can I switch between Nigerian and American standards?', 'Yes. Toggle between standards in Settings and all tiers instantly adapt — grading scales, assessment columns, and grade computations update automatically.'),
      ('Does it work on mobile?', 'Fully responsive web application. Works seamlessly on phones, tablets, and desktops through any modern browser.'),
    ];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w ? 0 : 16),
      child: Column(
        children: [
          _sectionHeader('Common Questions', 'Quick answers', w),
          const SizedBox(height: 18),
          ...faqs.map((f) => _FaqItem(question: f.$1, answer: f.$2)),
        ],
      ),
    );
  }

  Widget _footer(bool w) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w ? 0 : 16),
      child: Column(
        children: [
          Container(height: 1, color: Colors.white.withOpacity(0.04)),
          const SizedBox(height: 24),
          InkWell(
            onTap: _openWhatsApp,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF25D366).withOpacity(0.18)),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366), size: 18),
                SizedBox(width: 8),
                Text('WhatsApp: 07080304822', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13)),
              ]),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(onPressed: () {}, child: Text('Privacy', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.25)))),
              Text('·', style: TextStyle(color: Colors.white.withOpacity(0.08))),
              TextButton(onPressed: () {}, child: Text('Terms', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.25)))),
              Text('·', style: TextStyle(color: Colors.white.withOpacity(0.08))),
              TextButton(onPressed: _openWhatsApp, child: Text('Support', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.25)))),
            ],
          ),
          const SizedBox(height: 14),
          Text('\u00a9 2025. All rights reserved.', style: TextStyle(color: Colors.white.withOpacity(0.12), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String sub, bool w) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: w ? 24 : 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3)),
        const SizedBox(height: 6),
        Text(sub, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.35))),
      ],
    );
  }
}

class _PData {
  final double x, y, sz, op, ph, dx, dy;
  const _PData({required this.x, required this.y, required this.sz, required this.op, required this.ph, required this.dx, required this.dy});
}

class _GSystem {
  final String title, subtitle, desc;
  final IconData icon;
  final Color color;
  final List<(String, Color)> grades;
  const _GSystem({required this.title, required this.subtitle, required this.icon, required this.color, required this.grades, required this.desc});
}

class _Reveal extends StatefulWidget {
  final Widget child;
  final ScrollController scrollCtrl;
  const _Reveal({required this.child, required this.scrollCtrl});

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slideY;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _opacity = CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5, curve: Curves.easeOut));
    _slideY = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.7, curve: Curves.easeOutCubic)),
    );
    widget.scrollCtrl.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (_done) return;
    final ctx = context;
    if (!ctx.mounted) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final pos = box.localToGlobal(Offset.zero);
    final vh = MediaQuery.of(ctx).size.height;
    if (pos.dy < vh * 0.92) {
      _done = true;
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    widget.scrollCtrl.removeListener(_check);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slideY, child: widget.child),
    );
  }
}

class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _open ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _open ? const Color(0xFF6366F1).withOpacity(0.2) : Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _open = !_open),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  width: 4, height: 18,
                  decoration: BoxDecoration(
                    color: _open ? const Color(0xFF6366F1) : Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(widget.question, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white))),
                Icon(_open ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 18, color: Colors.white.withOpacity(0.4)),
              ],
            ),
          ),
          if (_open) ...[
            const SizedBox(height: 12),
            Text(widget.answer, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.45), height: 1.55)),
          ],
        ],
      ),
    );
  }
}

class _HoverBtn extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool isGhost;
  const _HoverBtn({required this.child, required this.onTap, this.isGhost = false});

  @override
  State<_HoverBtn> createState() => _HoverBtnState();
}

class _HoverBtnState extends State<_HoverBtn> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: AnimatedScale(
        scale: _h ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: AnimatedOpacity(
          opacity: _h ? 1.0 : (widget.isGhost ? 0.75 : 0.9),
          duration: const Duration(milliseconds: 200),
          child: GestureDetector(onTap: widget.onTap, child: widget.child),
        ),
      ),
    );
  }
}

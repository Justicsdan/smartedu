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
  int _hoveredFeature = -1;
  int _hoveredStep = -1;
  bool _showScrollTop = false;

  @override
  void initState() {
    super.initState();
    _logoAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat(reverse: true);
    _fadeAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..forward();
    _gradientAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 5000))..repeat();
    _pulseAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
    _scrollCtrl.addListener(() {
      if (!_scrollCtrl.hasClients) return;
      final show = _scrollCtrl.offset > 400;
      if (show != _showScrollTop) setState(() => _showScrollTop = show);
    });
  }

  @override
  void dispose() {
    _logoAnim.dispose();
    _fadeAnim.dispose();
    _gradientAnim.dispose();
    _pulseAnim.dispose();
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
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-0.8, -1.2),
                  end: Alignment(0.8, 1.2),
                  colors: [Color(0xFF0A0E27), Color(0xFF111836), Color(0xFF0D1229)],
                ),
              ),
            ),
          ),
          Positioned(top: -120, right: -80, child: _orb(320, Colors.indigo, 0.08)),
          Positioned(bottom: -140, left: -100, child: _orb(380, Colors.purple, 0.06)),
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
                      const SizedBox(height: 48),
                      _features(w),
                      const SizedBox(height: 48),
                      _steps(w),
                      const SizedBox(height: 48),
                      _trusted(w),
                      const SizedBox(height: 48),
                      _faq(w),
                      const SizedBox(height: 48),
                      _footer(w),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_showScrollTop)
            Positioned(bottom: 28, right: 28, child: _fab(Icons.keyboard_arrow_up, Colors.white, const Color(0xFF1A237E), () => _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic))),
          Positioned(bottom: 28, left: 28, child: _fab(Icons.chat_bubble_rounded, Colors.white, const Color(0xFF25D366), _openWhatsApp)),
        ],
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
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color.withOpacity(opacity + 0.02), color.withOpacity(opacity * 0.3), Colors.transparent], stops: [0.0, 0.5, 1.0])),
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
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: bg.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))]),
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
          builder: (_, child) => Transform.translate(offset: Offset(0, math.sin(_logoAnim.value * 2 * math.pi) * 6), child: child),
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
          child: Text('Streamline admissions, scores, results, and more — all in one powerful platform.', textAlign: TextAlign.center, style: TextStyle(fontSize: w ? 14 : 13, color: Colors.white.withOpacity(0.45), height: 1.6)),
        ),
        const SizedBox(height: 32),
        _ctaButton('Get Started', w, () => context.go('/role-selection')),
        const SizedBox(height: 12),
        _ghostButton('Learn More', w, () => _scrollCtrl.animateTo(400, duration: const Duration(milliseconds: 800), curve: Curves.easeInOutCubic)),
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
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: w ? 36 : 28, vertical: w ? 14 : 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.2)),
          const SizedBox(width: 6),
          const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
        ]),
      ),
      onTap: onTap,
    );
  }

  Widget _ghostButton(String label, bool w, VoidCallback onTap) {
    return _HoverBtn(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: w ? 30 : 24, vertical: w ? 12 : 10),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.12))),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.6), letterSpacing: 0.2)),
      ),
      onTap: onTap,
      isGhost: true,
    );
  }

  Widget _pills() {
    final items = [(Icons.bolt_rounded, 'Fast'), (Icons.verified_user_rounded, 'Secure'), (Icons.checkroom_rounded, 'Reliable'), (Icons.laptop_mac_rounded, 'Cross-Platform')];
    return Wrap(spacing: 8, runSpacing: 6, alignment: WrapAlignment.center, children: items.map((p) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.07))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(p.$1, size: 12, color: Colors.white38), const SizedBox(width: 5), Text(p.$2, style: const TextStyle(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.w500))]),
      );
    }).toList());
  }

  Widget _features(bool w) {
    final feats = <Map<String, dynamic>>[
      {'icon': Icons.calculate_rounded, 'title': 'Smart Grading', 'desc': 'WAEC, BECE, 5-point & American GPA. Auto positions.', 'color': const Color(0xFF6366F1)},
      {'icon': Icons.assessment_rounded, 'title': 'Result Publishing', 'desc': 'One-click publish with behavioral ratings & comments.', 'color': const Color(0xFF10B981)},
      {'icon': Icons.people_alt_rounded, 'title': 'Role-Based Access', 'desc': 'Separate dashboards for Admin, Teacher, Student.', 'color': const Color(0xFFF59E0B)},
      {'icon': Icons.quiz_rounded, 'title': 'CBT Exams', 'desc': 'Computer-based tests with auto grading & score sync.', 'color': const Color(0xFFEC4899)},
      {'icon': Icons.fingerprint_rounded, 'title': 'Secure Login', 'desc': 'PIN for students, bcrypt for admins & teachers.', 'color': const Color(0xFF06B6D4)},
      {'icon': Icons.print_rounded, 'title': 'PDF Reports', 'desc': 'Professional results with photos, stamps & signatures.', 'color': const Color(0xFF8B5CF6)},
    ];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w ? 0 : 16),
      child: Column(
        children: [
          _sectionHeader('Powerful Features', 'Everything your school needs', w),
          const SizedBox(height: 24),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: feats.asMap().entries.map((e) {
              final f = e.value;
              final hov = _hoveredFeature == e.key;
              final color = f['color'] as Color;
              return SizedBox(
                width: w ? (720 - 28) / 2 : double.infinity,
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

  Widget _steps(bool w) {
    final steps = [
      ('01', 'Set Up School', 'Configure profile, grading & classes.', Icons.domain_add_rounded, const Color(0xFF6366F1)),
      ('02', 'Register People', 'Add students & teachers with photos.', Icons.group_add_rounded, const Color(0xFF10B981)),
      ('03', 'Enter & Publish', 'Score entry, positions, publish results.', Icons.publish_rounded, const Color(0xFFF59E0B)),
    ];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w ? 0 : 16),
      child: Column(children: [
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
                decoration: BoxDecoration(color: Colors.white.withOpacity(hov ? 0.05 : 0.02), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(hov ? 0.1 : 0.04))),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(gradient: LinearGradient(colors: [s.$5, s.$5.withOpacity(0.65)]), borderRadius: BorderRadius.circular(14)),
                      child: Icon(s.$4, size: 22, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [Text(s.$1, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: s.$5.withOpacity(0.4), letterSpacing: 2)), const SizedBox(width: 10), Text(s.$2, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(hov ? 1.0 : 0.82)))]),
                      const SizedBox(height: 4),
                      Text(s.$3, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(hov ? 0.45 : 0.3), height: 1.4)),
                    ])),
                  ],
                ),
              ),
            ),
          );
        }),
      ]),
    );
  }

  Widget _trusted(bool w) {
    final badges = [(Icons.verified_user_rounded, 'Secure'), (Icons.cloud_done_rounded, 'Cloud'), (Icons.speed_rounded, 'Fast'), (Icons.phone_iphone_rounded, 'Any Device'), (Icons.workspace_premium_rounded, 'International Standards')];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w ? 0 : 16),
      child: Container(
        padding: EdgeInsets.all(w ? 28 : 20),
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white.withOpacity(0.035), Colors.white.withOpacity(0.012)]), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.06))),
        child: Column(children: [
          Text('Built for Real Schools', style: TextStyle(fontSize: w ? 22 : 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3)),
          const SizedBox(height: 6),
          Text('Designed for Nigerian schools, ready for the world', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.38))),
          const SizedBox(height: 20),
          Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: badges.map((b) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.035), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.06))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(b.$1, size: 15, color: const Color(0xFF818CF8)), const SizedBox(width: 8), Text(b.$2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70))]),
          )).toList()),
        ]),
      ),
    );
  }

  Widget _faq(bool w) {
    final faqs = [
      ('How do I get started?', 'Sign up, set up your school, add classes, register students and teachers. Publish results in under an hour.'),
      ('Is my data secure?', 'Encrypted storage and transfers. Industry-standard security for your school information.'),
      ('Can I customize grading?', 'WAEC, NECO, IGCSE, BECE, 5-point, or American GPA — with per-tier custom overrides.'),
      ('Does it work on mobile?', 'Fully responsive. Works on phones, tablets, and desktops via any web browser.'),
    ];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w ? 0 : 16),
      child: Column(children: [
        _sectionHeader('Common Questions', 'Quick answers', w),
        const SizedBox(height: 18),
        ...faqs.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.05))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Container(width: 4, height: 18, decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(2)), margin: const EdgeInsets.only(right: 12)), Expanded(child: Text(f.$1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)))]),
              const SizedBox(height: 8),
              Text(f.$2, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4), height: 1.5)),
            ]),
          ),
        )),
      ]),
    );
  }

  Widget _footer(bool w) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w ? 0 : 16),
      child: Column(children: [
        Container(height: 1, color: Colors.white.withOpacity(0.05)),
        const SizedBox(height: 24),
        InkWell(
          onTap: _openWhatsApp,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
            decoration: BoxDecoration(color: const Color(0xFF25D366).withOpacity(0.1), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF25D366).withOpacity(0.18))),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366), size: 18), SizedBox(width: 8), Text('WhatsApp: 07080304822', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13))]),
          ),
        ),
        const SizedBox(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          TextButton(onPressed: () {}, child: Text('Privacy', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.3)))),
          Text('·', style: TextStyle(color: Colors.white.withOpacity(0.1))),
          TextButton(onPressed: () {}, child: Text('Terms', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.3)))),
          Text('·', style: TextStyle(color: Colors.white.withOpacity(0.1))),
          TextButton(onPressed: _openWhatsApp, child: Text('Support', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.3)))),
        ]),
        const SizedBox(height: 14),
        Text('© 2025. All rights reserved.', style: TextStyle(color: Colors.white.withOpacity(0.14), fontSize: 11)),
      ]),
    );
  }

  Widget _sectionHeader(String title, String sub, bool w) {
    return Column(children: [
      Text(title, style: TextStyle(fontSize: w ? 24 : 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3)),
      const SizedBox(height: 6),
      Text(sub, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.38))),
    ]);
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
      child: AnimatedScale(scale: _h ? 1.03 : 1.0, duration: const Duration(milliseconds: 200), child: AnimatedOpacity(opacity: _h ? 1.0 : (widget.isGhost ? 0.75 : 0.9), duration: const Duration(milliseconds: 200), child: GestureDetector(onTap: widget.onTap, child: widget.child))),
    );
  }
}

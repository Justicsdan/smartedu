import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _subtitleFade;
  late List<Animation<double>> _cardFades;
  late List<Animation<Offset>> _cardSlides;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _titleFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, -20),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    ));
    _subtitleFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.15, 0.5, curve: Curves.easeOut),
    );

    _cardFades = [];
    _cardSlides = [];
    for (int i = 0; i < 3; i++) {
      final start = 0.2 + (i * 0.15);
      final end = start + 0.35;
      _cardFades.add(CurvedAnimation(
        parent: _entranceController,
        curve: Interval(start, end, curve: Curves.easeOut),
      ));
      _cardSlides.add(Tween<Offset>(
        begin: const Offset(0, 30),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _entranceController,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      )));
    }

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-0.3, -0.8),
                  end: Alignment(0.8, 1.0),
                  colors: [
                    Color(0xFF060B1E),
                    Color(0xFF0B1633),
                    Color(0xFF0F1F4B),
                    Color(0xFF162560),
                  ],
                ),
              ),
            ),
          ),

          ...List.generate(18, (i) {
            final rng = Random(i * 7 + 3);
            final top = rng.nextDouble() * size.height;
            final left = rng.nextDouble() * size.width;
            final dotSize = rng.nextDouble() * 2.5 + 0.8;
            final opacity = rng.nextDouble() * 0.25 + 0.05;
            final duration = rng.nextDouble() * 4000 + 3000;
            final driftX = (rng.nextDouble() - 0.5) * 30;
            final driftY = (rng.nextDouble() - 0.5) * 30;
            return Positioned(
              top: top,
              left: left,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: duration.toInt()),
                curve: Curves.easeInOut,
                builder: (_, val, __) {
                  return Transform.translate(
                    offset: Offset(
                        driftX * sin(val * 2 * pi),
                        driftY * cos(val * 2 * pi)),
                    child: Container(
                      width: dotSize,
                      height: dotSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            const Color(0xFF5C6BC0).withOpacity(opacity),
                      ),
                    ),
                  );
                },
              ),
            );
          }),

          Positioned(
            top: -100,
            right: -80,
            child: _GlowOrb(
              size: 300,
              color: const Color(0xFF3F51B5),
              opacity: 0.2,
            ),
          ),
          Positioned(
            bottom: -120,
            left: -100,
            child: _GlowOrb(
              size: 350,
              color: const Color(0xFF1A237E),
              opacity: 0.25,
            ),
          ),
          Positioned(
            top: size.height * 0.3,
            left: size.width * 0.6,
            child: _GlowOrb(
              size: 180,
              color: const Color(0xFF7C4DFF),
              opacity: 0.08,
            ),
          ),

          Positioned(
            top: 60,
            left: 28,
            child:
                _CornerBracket(color: Colors.white.withOpacity(0.08)),
          ),
          Positioned(
            bottom: 40,
            right: 28,
            child: Transform.rotate(
              angle: pi,
              child:
                  _CornerBracket(color: Colors.white.withOpacity(0.08)),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 48),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FadeTransition(
                          opacity: _titleFade,
                          child: IconButton(
                            onPressed: () => context.go('/'),
                            icon: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: Colors.white.withOpacity(0.6),
                            ),
                            tooltip: 'Back',
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FadeTransition(
                        opacity: _titleFade,
                        child: SlideTransition(
                          position: _titleSlide,
                          child: const _PulsingIcon(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FadeTransition(
                        opacity: _titleFade,
                        child: SlideTransition(
                          position: _titleSlide,
                          child: ShaderMask(
                            shaderCallback: (bounds) {
                              return const LinearGradient(
                                colors: [
                                  Color(0xFFFFFFFF),
                                  Color(0xFFB3C6FF),
                                  Color(0xFF82B1FF),
                                ],
                              ).createShader(bounds);
                            },
                            blendMode: BlendMode.srcIn,
                            child: const Text(
                              'Sign In As',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeTransition(
                        opacity: _subtitleFade,
                        child: Text(
                          'Choose your role to get started',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withOpacity(0.4),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final roles = [
                            _RoleData(
                              icon: Icons.school_rounded,
                              gradient: const LinearGradient(
                                begin: Alignment(-0.5, -1),
                                end: Alignment(1, 0.5),
                                colors: [
                                  Color(0xFF42A5F5),
                                  Color(0xFF0D47A1)
                                ],
                              ),
                              glowColor: const Color(0xFF42A5F5),
                              title: 'Student',
                              subtitle: 'View results & attendance',
                              route: 'Student',
                            ),
                            _RoleData(
                              icon: Icons.person_rounded,
                              gradient: const LinearGradient(
                                begin: Alignment(-0.5, -1),
                                end: Alignment(1, 0.5),
                                colors: [
                                  Color(0xFF66BB6A),
                                  Color(0xFF1B5E20)
                                ],
                              ),
                              glowColor: const Color(0xFF66BB6A),
                              title: 'Teacher',
                              subtitle: 'Scores, attendance & more',
                              route: 'Teacher',
                            ),
                            _RoleData(
                              icon:
                                  Icons.admin_panel_settings_rounded,
                              gradient: const LinearGradient(
                                begin: Alignment(-0.5, -1),
                                end: Alignment(1, 0.5),
                                colors: [
                                  Color(0xFFFFB74D),
                                  Color(0xFFE65100)
                                ],
                              ),
                              glowColor: const Color(0xFFFFB74D),
                              title: 'School Admin',
                              subtitle: 'Full school management',
                              route: 'School Admin',
                            ),
                          ];

                          if (constraints.maxWidth < 420) {
                            return Column(
                              children: [
                                for (int i = 0; i < 3; i++) ...[
                                  if (i > 0) const SizedBox(height: 14),
                                  _buildCard(roles[i], i),
                                ],
                              ],
                            );
                          }

                          final cardW =
                              (constraints.maxWidth - 16) / 2;
                          return Column(
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    width: cardW,
                                    child: _buildCard(
                                        roles[0], 0),
                                  ),
                                  const SizedBox(width: 16),
                                  SizedBox(
                                    width: cardW,
                                    child: _buildCard(
                                        roles[1], 1),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: SizedBox(
                                  width: cardW,
                                  child: _buildCard(
                                      roles[2], 2),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 56),
                      FadeTransition(
                        opacity: _subtitleFade,
                        child: Text(
                          '\u00a9 2025 SmartEdu. All rights reserved.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.2),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(_RoleData role, int index) {
    return FadeTransition(
      opacity: _cardFades[index],
      child: SlideTransition(
        position: _cardSlides[index],
        child: _RoleCard(role: role),
      ),
    );
  }
}

class _RoleData {
  final IconData icon;
  final LinearGradient gradient;
  final Color glowColor;
  final String title;
  final String subtitle;
  final String route;
  const _RoleData({
    required this.icon,
    required this.gradient,
    required this.glowColor,
    required this.title,
    required this.subtitle,
    required this.route,
  });
}

class _PulsingIcon extends StatefulWidget {
  const _PulsingIcon();

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) {
        final scale = 1.0 + _pulse.value * 0.06;
        final glowOpacity = 0.15 + _pulse.value * 0.15;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1A237E)
                      .withOpacity(glowOpacity + 0.1),
                  const Color(0xFF3F51B5)
                      .withOpacity(glowOpacity),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5C6BC0)
                      .withOpacity(glowOpacity),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.lock_open_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        );
      },
    );
  }
}

class _GlowOrb extends StatefulWidget {
  final double size;
  final Color color;
  final double opacity;
  const _GlowOrb(
      {required this.size, required this.color, required this.opacity});

  @override
  State<_GlowOrb> createState() => _GlowOrbState();
}

class _GlowOrbState extends State<_GlowOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final breath = 1.0 + _ctrl.value * 0.15;
        return Container(
          width: widget.size * breath,
          height: widget.size * breath,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                widget.color.withOpacity(widget.opacity),
                widget.color.withOpacity(widget.opacity * 0.3),
                Colors.transparent,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CornerBracket extends StatelessWidget {
  final Color color;
  const _CornerBracket({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: CustomPaint(
        painter: _BracketPainter(color: color),
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  final Color color;
  _BracketPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(0, 12), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(12, 0), paint);
  }

  @override
  bool shouldRepaint(covariant _BracketPainter old) =>
      old.color != color;
}

class _RoleCard extends StatefulWidget {
  final _RoleData role;
  const _RoleCard({required this.role});

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.role;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/login', extra: r.route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          transform: _hovered
              ? (Matrix4.identity()
                ..translate(0.0, -4.0)
                ..scale(1.02))
              : Matrix4.identity(),
          transformAlignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _hovered
                    ? r.glowColor.withOpacity(0.45)
                    : Colors.white.withOpacity(0.07),
                width: _hovered ? 1.5 : 0.8,
              ),
              color: _hovered
                  ? r.glowColor.withOpacity(0.06)
                  : Colors.white.withOpacity(0.03),
              gradient: _hovered
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        r.glowColor.withOpacity(0.1),
                        Colors.white.withOpacity(0.02),
                      ],
                    )
                  : null,
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: r.glowColor.withOpacity(0.25),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: r.glowColor.withOpacity(0.1),
                        blurRadius: 60,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: r.gradient,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: r.glowColor
                            .withOpacity(_hovered ? 0.5 : 0.25),
                        blurRadius: _hovered ? 20 : 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child:
                      Icon(r.icon, color: Colors.white, size: 27),
                ),
                const SizedBox(height: 20),
                Text(
                  r.title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  r.subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.4),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _hovered
                            ? r.glowColor.withOpacity(0.15)
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: _hovered
                              ? r.glowColor.withOpacity(0.35)
                              : Colors.white.withOpacity(0.06),
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          _hovered
                              ? Icons.arrow_forward_rounded
                              : Icons.arrow_outward_rounded,
                          key: ValueKey(_hovered),
                          size: 16,
                          color: _hovered
                              ? r.glowColor
                              : Colors.white.withOpacity(0.25),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

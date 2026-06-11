import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SchoolCodeLoginPage extends StatefulWidget {
  final Map<String, dynamic> school;
  const SchoolCodeLoginPage({super.key, required this.school});

  @override
  State<SchoolCodeLoginPage> createState() => _SchoolCodeLoginPageState();
}

class _SchoolCodeLoginPageState extends State<SchoolCodeLoginPage>
    with SingleTickerProviderStateMixin {
  int _hoveredIndex = -1;
  late final AnimationController _anim;

  Color get _primary => _c(widget.school['primary_color']) ?? const Color(0xFF0D47A1);
  Color get _secondary => _c(widget.school['secondary_color']) ?? const Color(0xFF1A237E);
  Color get _accent => _c(widget.school['accent_color']) ?? const Color(0xFFFF6F00);

  Color? _c(dynamic v) {
    if (v == null) return null;
    final s = v.toString().replaceFirst('#', '');
    if (s.length == 6) return Color(int.parse('FF$s', radix: 16));
    return null;
  }

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoUrl = (widget.school['logo_url'] ?? '') as String;
    final schoolName = (widget.school['name'] ?? 'School') as String;
    final motto = (widget.school['motto'] ?? '') as String;
    final sz = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_primary, _secondary],
                ),
              ),
            ),
          ),
          Positioned(top: -100, right: -60, child: _orb(280, _accent, 0.1)),
          Positioned(bottom: -80, left: -80, child: _orb(240, _secondary, 0.08)),
          Positioned(top: sz.height * 0.3, left: sz.width * 0.1, child: _orb(160, _primary, 0.06)),
          if (logoUrl.isNotEmpty)
            Positioned.fill(
              child: Opacity(opacity: 0.03, child: Center(child: Image.network(logoUrl, width: 350, height: 350, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox.shrink()))),
            ),
          Positioned.fill(
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                  child: FadeTransition(
                    opacity: CurvedAnimation(parent: _anim, curve: const Interval(0, 0.5, curve: Curves.easeOut)),
                    child: SlideTransition(
                      position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(CurvedAnimation(parent: _anim, curve: const Interval(0, 0.5, curve: Curves.easeOutCubic))),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _logo(logoUrl),
                          const SizedBox(height: 24),
                          Text(schoolName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5, height: 1.2)),
                          if (motto.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
                                child: Text(motto, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5), fontStyle: FontStyle.italic)),
                              ),
                            ),
                          const SizedBox(height: 40),
                          FadeTransition(
                            opacity: CurvedAnimation(parent: _anim, curve: const Interval(0.3, 0.7, curve: Curves.easeOut)),
                            child: Text('Select your role', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.4), fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                          ),
                          const SizedBox(height: 24),
                          FadeTransition(
                            opacity: CurvedAnimation(parent: _anim, curve: const Interval(0.4, 0.85, curve: Curves.easeOut)),
                            child: _roleCard(Icons.person_rounded, 'Student', 'Results, attendance & assignments', 0, const Color(0xFF66BB6A)),
                          ),
                          const SizedBox(height: 14),
                          FadeTransition(
                            opacity: CurvedAnimation(parent: _anim, curve: const Interval(0.5, 0.9, curve: Curves.easeOut)),
                            child: _roleCard(Icons.cast_for_education_rounded, 'Teacher', 'Classes, scores & attendance', 1, const Color(0xFF42A5F5)),
                          ),
                          const SizedBox(height: 14),
                          FadeTransition(
                            opacity: CurvedAnimation(parent: _anim, curve: const Interval(0.6, 0.95, curve: Curves.easeOut)),
                            child: _roleCard(Icons.shield_moon_rounded, 'School Admin', 'Full school management', 2, const Color(0xFFFFA726)),
                          ),
                          const SizedBox(height: 48),
                          FadeTransition(
                            opacity: CurvedAnimation(parent: _anim, curve: const Interval(0.7, 1.0, curve: Curves.easeOut)),
                            child: GestureDetector(
                              onTap: () => context.go('/'),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.arrow_back_rounded, size: 14, color: Colors.white.withOpacity(0.2)),
                                  const SizedBox(width: 6),
                                  Text('Back to home', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.2), decoration: TextDecoration.underline)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
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

  Widget _orb(double size, Color color, double op) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color.withOpacity(op), color.withOpacity(op * 0.3), Colors.transparent], stops: const [0.0, 0.5, 1.0]),
      ),
    );
  }

  Widget _logo(String url) {
    return Container(
      width: 88, height: 88,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isNotEmpty
          ? Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.school, size: 40, color: Colors.white70))
          : const Icon(Icons.school, size: 40, color: Colors.white70),
    );
  }

  Widget _roleCard(IconData icon, String title, String subtitle, int index, Color accent) {
    final h = _hoveredIndex == index;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = -1),
      child: AnimatedScale(
        scale: h ? 1.06 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 210,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: h ? Colors.white.withOpacity(0.14) : Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: h ? accent.withOpacity(0.4) : Colors.white.withOpacity(0.08)),
            boxShadow: h ? [BoxShadow(color: accent.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 6))] : null,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.go('/login', extra: title),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment(-0.3, -0.3), end: Alignment(1.0, 1.0), colors: [accent, accent.withOpacity(0.6)]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: accent.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Icon(icon, size: 20, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 4),
              Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4), height: 1.3)),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

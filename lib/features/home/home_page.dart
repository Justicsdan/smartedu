import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  bool _isButtonHovering = false;

  late final AnimationController _floatController;
  late final AnimationController _fadeController;
  late final Animation<double> _floatAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
      body: Stack(
        children: [
          // Full-screen gradient — fills every pixel on all platforms
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0A1628),
                    Color(0xFF112A55),
                    Color(0xFF1E3C72),
                    Color(0xFF2A5298),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // Decorative glowing orbs
          Positioned(
            top: size.height * 0.08,
            right: size.width * 0.1,
            child: Container(
              width: isWide ? 200 : 120,
              height: isWide ? 200 : 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF5A9FFF).withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: size.height * 0.15,
            left: size.width * 0.05,
            child: Container(
              width: isWide ? 160 : 100,
              height: isWide ? 160 : 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7B61FF).withOpacity(0.06),
              ),
            ),
          ),

          // Content
          Positioned.fill(
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 40 : 24,
                      vertical: isWide ? 60 : 40,
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: isWide ? 40 : 20),

                            // Floating logo with glow
                            AnimatedBuilder(
                              animation: _floatAnimation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, _floatAnimation.value),
                                  child: child,
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.all(isWide ? 36 : 28),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.08),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.18),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF5A9FFF)
                                          .withOpacity(0.35),
                                      blurRadius: 60,
                                      spreadRadius: 8,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.4),
                                      blurRadius: 40,
                                      offset: const Offset(0, 16),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.school_rounded,
                                  size: isWide ? 130 : 100,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                            SizedBox(height: isWide ? 48 : 36),

                            // Title
                            Text(
                              "SmartEdu",
                              style: TextStyle(
                                fontSize: isWide ? 52 : 38,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: isWide ? 6 : 4,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 14),

                            // Subtitle
                            Text(
                              "Global School Management System",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: isWide ? 18 : 15,
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            SizedBox(height: isWide ? 70 : 50),

                            // Feature pills row
                            if (isWide)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 40),
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 10,
                                  runSpacing: 8,
                                  children: [
                                    _featurePill(Icons.speed_rounded, 'Fast'),
                                    _featurePill(Icons.shield_rounded, 'Secure'),
                                    _featurePill(Icons.cloud_done_rounded, 'Reliable'),
                                    _featurePill(Icons.devices_rounded, 'Cross-Platform'),
                                  ],
                                ),
                              ),

                            // Get Started button
                            MouseRegion(
                              onEnter: (_) => setState(() => _isButtonHovering = true),
                              onExit: (_) => setState(() => _isButtonHovering = false),
                              child: AnimatedScale(
                                scale: _isButtonHovering ? 1.06 : 1.0,
                                duration: const Duration(milliseconds: 200),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(40),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white
                                            .withOpacity(_isButtonHovering ? 0.25 : 0.1),
                                        blurRadius: _isButtonHovering ? 30 : 16,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () => context.go('/role-selection'),
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isWide ? 72 : 56,
                                        vertical: isWide ? 22 : 18,
                                      ),
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF0F1C3A),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(40),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      "Get Started",
                                      style: TextStyle(
                                        fontSize: isWide ? 19 : 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: isWide ? 100 : 60),

                            // Footer
                            const Text(
                              "Secure \u2022 Fast \u2022 Reliable",
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
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

  Widget _featurePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white60),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

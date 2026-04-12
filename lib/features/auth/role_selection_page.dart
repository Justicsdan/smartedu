// ==========================================
// File: lib/features/auth/role_selection_page.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Master Plan Check: PASSED (After Fix)
/// - Zero platform branding shown to end users.
/// - Purely acts as a generic "School Portal" gateway.
/// - Routes cleanly to login page with role payload.

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  final List<Map<String, dynamic>> roles = const [
    {
      "title": "Student",
      "icon": Icons.school_rounded,
      "color": Color(0xFF2E7D32),
    },
    {
      "title": "School Admin",
      "icon": Icons.admin_panel_settings_rounded,
      "color": Color(0xFF1565C0),
    },
    {
      "title": "Teacher",
      "icon": Icons.person_outline_rounded,
      "color": Color(0xFFEF6C00),
    },
    {
      "title": "Super Admin",
      "icon": Icons.shield_outlined,
      "color": Color(0xFF6A1B9A),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E40AF)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.menu_book_rounded, size: 50, color: Colors.white),
                  const SizedBox(height: 12),
                  const Text(
                    // CRITICAL FIX: Removed "Smart EDU" to enforce White-Label Master Plan.
                    // Schools must not see the platform name. This acts as a generic portal.
                    "School Portal",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Select your role to continue",
                    style: TextStyle(color: Colors.white60, fontSize: 15),
                  ),
                  const SizedBox(height: 50),

                  // Role Cards
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.15,
                    children: roles.map((role) => _buildRoleCard(context, role)).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context, Map<String, dynamic> role) {
    final title = role['title'] as String;
    final icon = role['icon'] as IconData;
    final color = role['color'] as Color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/login', extra: title),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 34),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

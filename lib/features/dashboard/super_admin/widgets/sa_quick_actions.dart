import 'package:flutter/material.dart';
import 'package:smartedu/features/dashboard/super_admin/manage_schools_page.dart';

class SaQuickActions extends StatelessWidget {
  const SaQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quick Actions",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3C72),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _ActionCard(
              icon: Icons.add_circle_outline,
              title: "Register School",
              subtitle: "Add new institution",
              color: const Color(0xFF1E3C72),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManageSchoolsPage())),
            ),
            const SizedBox(width: 14),
            _ActionCard(
              icon: Icons.manage_accounts_outlined,
              title: "Manage Schools",
              subtitle: "Edit & configure",
              color: const Color(0xFF6C63FF),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManageSchoolsPage())),
            ),
            const SizedBox(width: 14),
            _ActionCard(
              icon: Icons.bar_chart_outlined,
              title: "Reports",
              subtitle: "Analytics & stats",
              color: const Color(0xFF00B894),
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          width: 160,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered ? widget.color : Colors.grey.shade200,
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(_isHovered ? 0.15 : 0.05),
                blurRadius: _isHovered ? 16 : 6,
                offset: Offset(0, _isHovered ? 6 : 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isHovered ? widget.color : widget.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.icon,
                  size: 24,
                  color: _isHovered ? Colors.white : widget.color,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _isHovered ? widget.color : const Color(0xFF1E3C72),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class SchoolQuickActions extends StatelessWidget {
  const SchoolQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    // We will pass navigation functions when we integrate this
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Management",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
        ),
        const SizedBox(height: 16),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          children: [
            _ActionCard(icon: Icons.people_alt_outlined, title: "Students", color: const Color(0xFF1A237E), onTap: () {}),
            _ActionCard(icon: Icons.person_pin_outlined, title: "Teachers", color: const Color(0xFFE65100), onTap: () {}),
            _ActionCard(icon: Icons.class_outlined, title: "Classes", color: const Color(0xFF00695C), onTap: () {}),
            _ActionCard(icon: Icons.menu_book_outlined, title: "Subjects", color: const Color(0xFF4A148C), onTap: () {}),
            _ActionCard(icon: Icons.assignment_outlined, title: "Assignments", color: const Color(0xFFBF360C), onTap: () {}),
            _ActionCard(icon: Icons.bar_chart_outlined, title: "Results", color: const Color(0xFF1565C0), onTap: () {}),
            _ActionCard(icon: Icons.attach_money_outlined, title: "Fees", color: const Color(0xFF2E7D32), onTap: () {}),
            _ActionCard(icon: Icons.settings_outlined, title: "Settings", color: const Color(0xFF546E7A), onTap: () {}),
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
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
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _isHovered ? widget.color : Colors.grey.shade200, width: _isHovered ? 1.5 : 1),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(_isHovered ? 0.15 : 0.04),
                blurRadius: _isHovered ? 12 : 4,
                offset: Offset(0, _isHovered ? 4 : 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isHovered ? widget.color : widget.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, size: 24, color: _isHovered ? Colors.white : widget.color),
              ),
              const SizedBox(height: 10),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _isHovered ? widget.color : const Color(0xFF1A237E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

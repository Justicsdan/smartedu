import 'package:flutter/material.dart';
import 'package:smartedu/core/school_model.dart';

class SaSchoolsList extends StatelessWidget {
  final List<School> schools;

  const SaSchoolsList({super.key, required this.schools});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Registered Schools",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3C72),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3C72).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${schools.length} total",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E3C72),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (schools.isEmpty)
          const _EmptyState()
        else
          ...schools.map((s) => _SchoolTile(school: s)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3C72).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.school_outlined,
              size: 50,
              color: const Color(0xFF1E3C72).withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "No Schools Yet",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3C72)),
          ),
          const SizedBox(height: 8),
          const Text(
            "Register your first school to get started",
            style: TextStyle(fontSize: 13, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SchoolTile extends StatefulWidget {
  final School school;

  const _SchoolTile({required this.school});

  @override
  State<_SchoolTile> createState() => _SchoolTileState();
}

class _SchoolTileState extends State<_SchoolTile> {
  bool _isHovered = false;

  // Fixed: Use string parsing to avoid enum const errors across files
  String get _typeString => widget.school.schoolType.toString().split('.').last.toLowerCase();
  
  Color get _typeColor {
    switch (_typeString) {
      case 'primary':
        return const Color(0xFF0984E3);
      case 'secondary':
        return const Color(0xFF6C5CE7);
      default:
        return Colors.grey;
    }
  }

  String get _typeLabel {
    final name = _typeString;
    return name.isEmpty ? '' : '${name[0].toUpperCase()}${name.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final logoUrl = widget.school.logoUrl;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isHovered ? _typeColor.withOpacity(0.3) : Colors.grey.shade100,
            width: _isHovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isHovered ? 0.06 : 0.02),
              blurRadius: _isHovered ? 12 : 4,
              offset: Offset(0, _isHovered ? 4 : 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_typeColor, _typeColor.withOpacity(0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  backgroundImage: (logoUrl != null && logoUrl.isNotEmpty) ? NetworkImage(logoUrl) : null,
                  child: (logoUrl == null || logoUrl.isEmpty) ? Icon(Icons.school, size: 24, color: _typeColor) : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.school.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3C72),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 13, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          widget.school.location ?? '',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.access_time, size: 13, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          _timeAgo(widget.school.createdAt),
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _typeLabel,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _typeColor),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: widget.school.isActive ? Colors.greenAccent : Colors.redAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (widget.school.isActive ? Colors.greenAccent : Colors.redAccent).withOpacity(0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return "Today";
    if (diff.inDays == 1) return "Yesterday";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    if (diff.inDays < 30) return "${(diff.inDays / 7).floor()}w ago";
    return "${(diff.inDays / 30).floor()}mo ago";
  }
}

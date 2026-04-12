// ==========================================
// File: lib/features/dashboard/school_admin/pages/page_students.dart
// ==========================================
import 'package:flutter/material.dart';

class PageStudents extends StatefulWidget {
  final List<Map<String, dynamic>> students;
  final void Function(String id) onDelete;
  final VoidCallback onAdd;

  const PageStudents({
    super.key,
    required this.students,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  State<PageStudents> createState() => _PageStudentsState();
}

class _PageStudentsState extends State<PageStudents> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool _showSearch = false;

  List<Map<String, dynamic>> get _filteredStudents {
    if (_searchQuery.isEmpty) return widget.students;
    final q = _searchQuery.toLowerCase();
    return widget.students.where((s) {
      final first = (s['first_name'] ?? '').toString().trim().toLowerCase();
      final last = (s['last_name'] ?? '').toString().trim().toLowerCase();
      final admNo = (s['admission_no'] ?? '').toString().trim().toLowerCase();
      final parent = (s['parent_name'] ?? '').toString().trim().toLowerCase();
      final fullName = '$first $last';
      return fullName.contains(q) ||
          first.contains(q) ||
          last.contains(q) ||
          admNo.contains(q) ||
          parent.contains(q);
    }).toList();
  }

  String _getName(Map<String, dynamic> s) {
    final first = (s['first_name'] ?? '').toString().trim();
    final last = (s['last_name'] ?? '').toString().trim();
    if (first.isNotEmpty && last.isNotEmpty) return '$first $last';
    if (first.isNotEmpty) return first;
    if (last.isNotEmpty) return last;
    return '';
  }

  String _getClassInfo(Map<String, dynamic> s) {
    final cls = (s['class'] ?? s['class_name'] ?? '').toString();
    final section = (s['section'] ?? '').toString();
    if (cls.isNotEmpty && section.isNotEmpty) return '$cls - $section';
    if (cls.isNotEmpty) return cls;
    return '';
  }

  String _getStudentId(Map<String, dynamic> s) {
    return (s['admission_no'] ?? s['studentId'] ?? s['id'] ?? '').toString();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredStudents;
    final hasSearch = _searchQuery.isNotEmpty;
    final totalCount = widget.students.length;
    final unassignedCount =
        widget.students.where((s) => s['class_id'] == null).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Column(
        children: [
          // ── Fixed Header ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.school_rounded,
                          size: 22, color: Color(0xFF1A237E)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Students',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasSearch
                                ? '${filtered.length} of $totalCount student${totalCount != 1 ? 's' : ''} found'
                                : '$totalCount registered student${totalCount != 1 ? 's' : ''}',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    // Search toggle button
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: _showSearch
                            ? const Color(0xFF1A237E)
                            : const Color(0xFFF7F8FA),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _showSearch
                              ? const Color(0xFF1A237E)
                              : const Color(0xFFE8EAED),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            setState(() {
                              _showSearch = !_showSearch;
                              if (!_showSearch) {
                                _searchController.clear();
                                _searchQuery = '';
                              }
                            });
                            if (_showSearch) {
                              FocusScope.of(context)
                                  .requestFocus(_searchFocusNode);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_rounded,
                                    size: 18,
                                    color: _showSearch
                                        ? Colors.white
                                        : Colors.grey.shade500),
                                if (!_showSearch) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    'Search',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Animated search bar
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: _showSearch
                      ? Padding(
                          padding: const EdgeInsets.only(top: 14, bottom: 16),
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F8FA),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _searchQuery.isNotEmpty
                                    ? const Color(0xFF1A237E)
                                    : const Color(0xFFE8EAED),
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              autofocus: true,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF111827),
                                height: 1.4,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value.trim();
                                });
                              },
                              decoration: InputDecoration(
                                hintText:
                                    'Search by name, admission no, parent...',
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade400,
                                  height: 1.4,
                                ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  size: 20,
                                  color: _searchQuery.isNotEmpty
                                      ? const Color(0xFF1A237E)
                                      : Colors.grey.shade400,
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close_rounded,
                                            size: 18,
                                            color: Color(0xFF9CA3AF)),
                                        padding:
                                            const EdgeInsets.only(right: 4),
                                        constraints: const BoxConstraints(
                                            minWidth: 32, minHeight: 32),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _searchQuery = '';
                                          });
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 14),
                                isDense: true,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(height: 16),
                ),
              ],
            ),
          ),

          // ── Stats strip ──
          if (!_showSearch)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8EAED)),
              ),
              child: Row(
                children: [
                  _statPill(
                    icon: Icons.people_rounded,
                    label: 'Total',
                    value: '$totalCount',
                    color: const Color(0xFF1A237E),
                    bgColor: const Color(0xFFF0F4FF),
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: const Color(0xFFE8EAED),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  _statPill(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Assigned',
                    value: '${totalCount - unassignedCount}',
                    color: const Color(0xFF2E7D32),
                    bgColor: const Color(0xFFF0FFF4),
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: const Color(0xFFE8EAED),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  _statPill(
                    icon: Icons.person_off_rounded,
                    label: 'Unassigned',
                    value: '$unassignedCount',
                    color: const Color(0xFFE65100),
                    bgColor: const Color(0xFFFFF3E0),
                  ),
                ],
              ),
            ),

          // ── Student List ──
          Expanded(
            child: widget.students.isEmpty
                ? _emptyState(
                    icon: Icons.people_outline_rounded,
                    iconBg: Colors.grey.shade100,
                    iconColor: Colors.grey.shade400,
                    title: 'No students added yet',
                    subtitle: 'Tap "Add New" to register a student',
                  )
                : hasSearch && filtered.isEmpty
                    ? _emptyState(
                        icon: Icons.search_off_rounded,
                        iconBg: const Color(0xFFFFF3E0),
                        iconColor: const Color(0xFFE65100),
                        title: 'No match found',
                        subtitle:
                            'Try a different name or admission number',
                        actionLabel: 'Clear search',
                        onAction: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final s = filtered[index];
                          return _studentCard(s, index);
                        },
                      ),
          ),
        ],
      ),
      // ── FAB ──
      floatingActionButton: Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF1A237E),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A237E).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: widget.onAdd,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 16),
                Icon(Icons.person_add_rounded,
                    color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Add New',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _statPill({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                  height: 1.2,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _studentCard(Map<String, dynamic> s, int index) {
    final name = _getName(s);
    final classInfo = _getClassInfo(s);
    final studentId = _getStudentId(s);
    final gender = (s['gender'] ?? '').toString().trim().toLowerCase();
    final parentName = (s['parent_name'] ?? '').toString().trim();
    final passportUrl = (s['passport_url'] ?? '').toString().trim();
    final hasSearch = _searchQuery.isNotEmpty;

    final bool isFemale = gender == 'female';
    final avatarBg =
        isFemale ? const Color(0xFFFCE4EC) : const Color(0xFFE3F2FD);
    final avatarIcon = isFemale ? Icons.girl : Icons.boy;
    final avatarColor =
        isFemale ? const Color(0xFFE91E63) : const Color(0xFF1565C0);

    TextSpan buildName() {
      if (!hasSearch || _searchQuery.isEmpty) {
        return TextSpan(
          text: name.isNotEmpty ? name : 'Unknown',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        );
      }
      final q = _searchQuery.toLowerCase();
      final lower = name.toLowerCase();
      final idx = lower.indexOf(q);
      if (idx == -1) {
        return TextSpan(
          text: name.isNotEmpty ? name : 'Unknown',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        );
      }
      return TextSpan(
        children: [
          if (idx > 0)
            TextSpan(
              text: name.substring(0, idx),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          TextSpan(
            text: name.substring(idx, idx + _searchQuery.length),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A237E),
              backgroundColor: Color(0xFFE8EAF6),
            ),
          ),
          if (idx + _searchQuery.length < name.length)
            TextSpan(
              text: name.substring(idx + _searchQuery.length),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: index.isOdd ? const Color(0xFFFAFBFC) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            _showStudentDetail(context, s);
          },
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Avatar
                passportUrl.isNotEmpty
                    ? CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: NetworkImage(passportUrl),
                        onBackgroundImageError: (_, __) {},
                      )
                    : CircleAvatar(
                        radius: 24,
                        backgroundColor: avatarBg,
                        child:
                            Icon(avatarIcon, size: 20, color: avatarColor),
                      ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: buildName(),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (studentId.isNotEmpty)
                            _miniBadge(
                              text: studentId,
                              color: const Color(0xFF1A237E),
                              bg: const Color(0xFFF0F4FF),
                            ),
                          if (classInfo.isNotEmpty)
                            _miniBadge(
                              text: classInfo,
                              color: const Color(0xFF7B1FA2),
                              bg: const Color(0xFFF3E5F5),
                            ),
                          if (parentName.isNotEmpty)
                            _miniBadge(
                              text: parentName,
                              color: Colors.grey.shade600,
                              bg: const Color(0xFFF5F5F5),
                              isParent: true,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                // Delete
                SizedBox(
                  width: 34,
                  height: 34,
                  child: IconButton(
                    icon: Icon(Icons.delete_outline,
                        size: 18, color: Colors.red.shade400),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 30, minHeight: 30),
                    onPressed: () => widget.onDelete(s['id']),
                    tooltip: 'Delete student',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniBadge({
    required String text,
    required Color color,
    required Color bg,
    bool isParent = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isParent ? 10 : 11,
          fontWeight: isParent ? FontWeight.w400 : FontWeight.w600,
          color: color,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, size: 32, color: iconColor),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A237E),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showStudentDetail(BuildContext context, Map<String, dynamic> s) {
    final name = _getName(s);
    final studentId = _getStudentId(s);
    final classInfo = _getClassInfo(s);
    final gender = (s['gender'] ?? '').toString().trim();
    final parentName = (s['parent_name'] ?? '').toString().trim();
    final parentPhone = (s['parent_phone'] ?? '').toString().trim();
    final parentEmail = (s['parent_email'] ?? '').toString().trim();
    final passportUrl = (s['passport_url'] ?? '').toString().trim();
    final dob = (s['date_of_birth'] ?? '').toString().trim();
    final admSession = (s['admission_session'] ?? '').toString().trim();

    final bool isFemale = gender == 'female';
    final avatarBg =
        isFemale ? const Color(0xFFFCE4EC) : const Color(0xFFE3F2FD);
    final avatarIcon = isFemale ? Icons.girl : Icons.boy;
    final avatarColor =
        isFemale ? const Color(0xFFE91E63) : const Color(0xFF1565C0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 20),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  passportUrl.isNotEmpty
                      ? CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: NetworkImage(passportUrl),
                          onBackgroundImageError: (_, __) {},
                        )
                      : CircleAvatar(
                          radius: 30,
                          backgroundColor: avatarBg,
                          child: Icon(avatarIcon,
                              size: 26, color: avatarColor),
                        ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isNotEmpty ? name : 'Unknown',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (studentId.isNotEmpty) ...[
                              _miniBadge(
                                text: studentId,
                                color: const Color(0xFF1A237E),
                                bg: const Color(0xFFF0F4FF),
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (classInfo.isNotEmpty)
                              _miniBadge(
                                text: classInfo,
                                color: const Color(0xFF7B1FA2),
                                bg: const Color(0xFFF3E5F5),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            // Detail rows
            _detailRow(
              icon: Icons.cake_rounded,
              iconBg: const Color(0xFFFFF3E0),
              iconColor: const Color(0xFFE65100),
              label: 'Date of Birth',
              value: dob.isNotEmpty ? dob : 'Not set',
            ),
            _detailRow(
              icon: Icons.calendar_today_rounded,
              iconBg: const Color(0xFFF3E5F5),
              iconColor: const Color(0xFF7B1FA2),
              label: 'Admission Session',
              value: admSession.isNotEmpty ? admSession : 'Not set',
            ),
            _detailRow(
              icon: Icons.family_restroom_rounded,
              iconBg: const Color(0xFFF0FFF4),
              iconColor: const Color(0xFF2E7D32),
              label: 'Parent / Guardian',
              value: parentName.isNotEmpty ? parentName : 'Not set',
            ),
            if (parentPhone.isNotEmpty)
              _detailRow(
                icon: Icons.phone_rounded,
                iconBg: const Color(0xFFF0F4FF),
                iconColor: const Color(0xFF1A237E),
                label: 'Parent Phone',
                value: parentPhone,
              ),
            if (parentEmail.isNotEmpty)
              _detailRow(
                icon: Icons.email_rounded,
                iconBg: const Color(0xFFFFF8E1),
                iconColor: const Color(0xFFF57F17),
                label: 'Parent Email',
                value: parentEmail,
              ),
            const SizedBox(height: 8),
            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          widget.onDelete(s['id']);
                        },
                        icon: Icon(Icons.delete_outline,
                            size: 18, color: Colors.red.shade400),
                        label: Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade400,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.shade300),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

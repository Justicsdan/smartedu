// ==========================================
// File: lib/features/dashboard/school_admin/pages/page_teachers.dart
// ==========================================
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartedu/core/providers/school_admin_provider.dart';

class PageTeachers extends StatefulWidget {
  final List<Map<String, dynamic>> teachers;
  final void Function(String id) onDelete;
  final VoidCallback onAdd;

  const PageTeachers({
    super.key,
    required this.teachers,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  State<PageTeachers> createState() => _PageTeachersState();
}

class _PageTeachersState extends State<PageTeachers> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool _showSearch = false;

  static const int _pageSize = 50;
  int _displayCount = _pageSize;
  bool _isExporting = false;

  List<Map<String, dynamic>> get _filteredTeachers {
    if (_searchQuery.isEmpty) return widget.teachers;
    final q = _searchQuery.toLowerCase();
    return widget.teachers.where((t) {
      final first = (t['first_name'] ?? '').toString().trim().toLowerCase();
      final last = (t['last_name'] ?? '').toString().trim().toLowerCase();
      final staffId = (t['staff_id'] ?? '').toString().trim().toLowerCase();
      final email = (t['email'] ?? '').toString().trim().toLowerCase();
      final dept = (t['department'] ?? '').toString().trim().toLowerCase();
      final fullName = '$first $last';
      return fullName.contains(q) || first.contains(q) || last.contains(q) || staffId.contains(q) || email.contains(q) || dept.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> get _displayedTeachers {
    final filtered = _filteredTeachers;
    if (filtered.length <= _displayCount) return filtered;
    return filtered.sublist(0, _displayCount);
  }

  bool get _hasMore => _filteredTeachers.length > _displayCount;

  String _getName(Map<String, dynamic> t) {
    final first = (t['first_name'] ?? '').toString().trim();
    final last = (t['last_name'] ?? '').toString().trim();
    if (first.isNotEmpty && last.isNotEmpty) return '$first $last';
    if (first.isNotEmpty) return first;
    if (last.isNotEmpty) return last;
    return '';
  }

  String _getStaffId(Map<String, dynamic> t) {
    return (t['staff_id'] ?? t['staffId'] ?? t['id'] ?? '').toString();
  }

  String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  void _exportCsv() {
    if (_filteredTeachers.isEmpty) return;
    setState(() => _isExporting = true);
    try {
      final buffer = StringBuffer();
      buffer.writeln('Staff ID,Full Name,Gender,Email,Phone,Department,Qualification,Role(s)');
      for (var i = 0; i < _filteredTeachers.length; i++) {
        final t = _filteredTeachers[i];
        final isFormTeacher = t['formTeacherClassId'] != null;
        final assigned = List<Map<String, dynamic>>.from(t['assignedSubjects'] ?? []);
        final roles = <String>[];
        if (isFormTeacher) roles.add('Form Teacher');
        if (assigned.isNotEmpty) roles.add('${assigned.length} Subject Teacher${assigned.length != 1 ? 's' : ''}');
        final roleStr = roles.isEmpty ? 'None' : roles.join(' / ');
        final row = [
          _csvEscape(_getStaffId(t)),
          _csvEscape(_getName(t)),
          _csvEscape((t['gender'] ?? '').toString().trim()),
          _csvEscape((t['email'] ?? '').toString().trim()),
          _csvEscape((t['phone'] ?? '').toString().trim()),
          _csvEscape((t['department'] ?? '').toString().trim()),
          _csvEscape((t['qualification'] ?? '').toString().trim()),
          _csvEscape(roleStr),
        ];
        buffer.writeln(row.join(','));
      }
      final bytes = Uint8List.fromList(buffer.toString().codeUnits);
      final blob = html.Blob([bytes], 'text/csv;charset=utf-8;');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final suffix = _searchQuery.isNotEmpty ? '_filtered' : '';
      final anchor = html.AnchorElement(href: url)..setAttribute('download', 'teachers${suffix}.csv')..click();
      html.Url.revokeObjectUrl(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export successful', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            backgroundColor: Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
          ),
        );
      }
    } catch (e) {
      debugPrint('CSV EXPORT ERR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _showManageSheet(BuildContext context, String teacherId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ManageSheet(teacherId: teacherId),
    );
  }

  Widget _buildTeacherAvatar(String name, String? passportUrl, {bool isFormTeacher = false}) {
    final url = (passportUrl ?? '').toString().trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'T';
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isFormTeacher ? const Color(0xFFF0FFF4) : const Color(0xFFF0F4FF),
        shape: BoxShape.circle,
      ),
      child: url.isNotEmpty
          ? CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey.shade100,
              backgroundImage: NetworkImage(url),
              onBackgroundImageError: url.isNotEmpty ? (_, __) {} : null,
            )
          : CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white,
              child: Text(
                initial,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isFormTeacher ? const Color(0xFF2E7D32) : const Color(0xFF1A237E),
                  fontSize: 17,
                ),
              ),
            ),
    );
  }

  TextSpan _buildHighlightedName(String text) {
    if (_searchQuery.isEmpty) {
      return TextSpan(
        text: text.isNotEmpty ? text : 'Unknown',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
      );
    }
    final q = _searchQuery.toLowerCase();
    final lower = text.toLowerCase();
    final idx = lower.indexOf(q);
    if (idx == -1) {
      return TextSpan(
        text: text.isNotEmpty ? text : 'Unknown',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
      );
    }
    return TextSpan(
      children: [
        if (idx > 0)
          TextSpan(
            text: text.substring(0, idx),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
          ),
        TextSpan(
          text: text.substring(idx, idx + _searchQuery.length),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A237E),
            backgroundColor: Color(0xFFE8EAF6),
          ),
        ),
        TextSpan(
          text: text.substring(idx + _searchQuery.length),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
        ),
      ],
    );
  }

  Widget _actionChip({required IconData icon, required String label, required VoidCallback onTap, bool active = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1A237E) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? const Color(0xFF1A237E) : const Color(0xFFE8EAED)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: active ? Colors.white : const Color(0xFF6B7280)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTeachers;
    final displayed = _displayedTeachers;
    final hasSearch = _searchQuery.isNotEmpty;
    final totalCount = widget.teachers.length;
    final formMasterCount = widget.teachers.where((t) => t['formTeacherClassId'] != null).length;
    final subjectTeacherCount = widget.teachers.where((t) => (List<Map<String, dynamic>>.from(t['assignedSubjects'] ?? [])).isNotEmpty).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Column(
        children: [
          // Flat header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            color: const Color(0xFFF7F8FA),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.person_rounded, size: 22, color: Color(0xFF1A237E)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Teachers', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827), letterSpacing: -0.5)),
                          const SizedBox(height: 2),
                          Text(
                            hasSearch
                                ? '${filtered.length} of $totalCount teacher${totalCount != 1 ? 's' : ''} found'
                                : '$totalCount registered teacher${totalCount != 1 ? 's' : ''}',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                          ),
                        ],
                      ),
                    ),
                    _actionChip(icon: Icons.download_rounded, label: _isExporting ? '...' : 'Export', onTap: _isExporting ? () {} : _exportCsv),
                    const SizedBox(width: 8),
                    _actionChip(
                      icon: Icons.search_rounded,
                      label: 'Search',
                      onTap: () {
                        setState(() {
                          _showSearch = !_showSearch;
                          if (!_showSearch) {
                            _searchController.clear();
                            _searchQuery = '';
                            _displayCount = _pageSize;
                          }
                        });
                        if (_showSearch) FocusScope.of(context).requestFocus(_searchFocusNode);
                      },
                      active: _showSearch,
                    ),
                  ],
                ),
                // Search field
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: _showSearch
                      ? Padding(
                          padding: const EdgeInsets.only(top: 14, bottom: 4),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE8EAED)),
                            ),
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              autofocus: true,
                              style: const TextStyle(fontSize: 14, color: Color(0xFF111827), height: 1.4),
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value.trim();
                                  _displayCount = _pageSize;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Search by name, staff ID, email, department...',
                                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400, height: 1.4),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  size: 20,
                                  color: _searchQuery.isNotEmpty ? const Color(0xFF1A237E) : Colors.grey.shade400,
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF9CA3AF)),
                                        padding: const EdgeInsets.only(right: 4),
                                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _searchQuery = '';
                                            _displayCount = _pageSize;
                                          });
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
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
          // Stat row
          if (!_showSearch)
            Container(
              margin: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Row(
                children: [
                  _statCard(icon: Icons.people_rounded, label: 'Total', value: '$totalCount', iconBg: const Color(0xFFF0F4FF), iconColor: const Color(0xFF1A237E)),
                  const SizedBox(width: 10),
                  _statCard(icon: Icons.supervisor_account_rounded, label: 'Form Masters', value: '$formMasterCount', iconBg: const Color(0xFFF0FFF4), iconColor: const Color(0xFF2E7D32)),
                  const SizedBox(width: 10),
                  _statCard(icon: Icons.menu_book_rounded, label: 'Subject Teachers', value: '$subjectTeacherCount', iconBg: const Color(0xFFFFF3E0), iconColor: const Color(0xFFE65100)),
                ],
              ),
            ),
          const SizedBox(height: 12),
          // List
          Expanded(
            child: widget.teachers.isEmpty
                ? _emptyState(icon: Icons.person_pin_outlined, title: 'No teachers registered yet', subtitle: 'Tap "Add New" to register a teacher')
                : hasSearch && filtered.isEmpty
                    ? _emptyState(
                        icon: Icons.search_off_rounded,
                        iconBg: const Color(0xFFFFF3E0),
                        iconColor: const Color(0xFFE65100),
                        title: 'No match found',
                        subtitle: 'Try a different name, staff ID or email',
                        actionLabel: 'Clear search',
                        onAction: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _displayCount = _pageSize;
                          });
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: displayed.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == displayed.length) return _loadMoreIndicator(filtered.length);
                          return _teacherCard(displayed[index], index);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF1A237E),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: const Color(0xFF1A237E).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: widget.onAdd,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Add New', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard({required IconData icon, required String label, required String value, required Color iconBg, required Color iconColor}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8EAED))),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF111827), height: 1.2)),
                Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadMoreIndicator(int totalFiltered) {
    final remaining = totalFiltered - _displayCount;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: TextButton.icon(
          onPressed: () {
            setState(() {
              _displayCount += _pageSize;
            });
          },
          icon: Icon(Icons.expand_more, size: 18, color: Colors.grey.shade500),
          label: Text('Show $remaining more', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade300)),
          ),
        ),
      ),
    );
  }

  Widget _teacherCard(Map<String, dynamic> t, int index) {
    final name = _getName(t);
    final staffId = _getStaffId(t);
    final passportUrl = (t['passport_url'] ?? '').toString();
    final isFormTeacher = t['formTeacherClassId'] != null;
    final assignedCount = List<Map<String, dynamic>>.from(t['assignedSubjects'] ?? []).length;
    final email = (t['email'] ?? '').toString().trim();
    final phone = (t['phone'] ?? '').toString().trim();
    final department = (t['department'] ?? '').toString().trim();
    final qualification = (t['qualification'] ?? '').toString().trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: index.isEven ? Colors.white : const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _showTeacherDetail(context, t),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildTeacherAvatar(name, passportUrl, isFormTeacher: isFormTeacher),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(text: _buildHighlightedName(name), overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 3),
                          Text('Staff ID: $staffId', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                          if (email.isNotEmpty || phone.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                children: [
                                  if (email.isNotEmpty) ...[
                                    Icon(Icons.email_outlined, size: 11, color: Colors.grey.shade400),
                                    const SizedBox(width: 3),
                                    Flexible(child: Text(email, style: TextStyle(fontSize: 11, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis)),
                                  ],
                                  if (email.isNotEmpty && phone.isNotEmpty) const SizedBox(width: 10),
                                  if (phone.isNotEmpty) ...[
                                    Icon(Icons.phone_outlined, size: 11, color: Colors.grey.shade400),
                                    const SizedBox(width: 3),
                                    Flexible(child: Text(phone, style: TextStyle(fontSize: 11, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis)),
                                  ],
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (isFormTeacher)
                          Container(
                            margin: const EdgeInsets.only(bottom: 5),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FFF4),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFC8E6C9)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.supervisor_account, size: 12, color: Color(0xFF2E7D32)),
                                SizedBox(width: 4),
                                Text('Form Teacher', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32))),
                              ],
                            ),
                          ),
                        if (assignedCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F4FF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFC5CAE9)),
                            ),
                            child: Text(
                              '$assignedCount Subject${assignedCount != 1 ? 's' : ''}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF1A237E)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                if (department.isNotEmpty || qualification.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        if (department.isNotEmpty) ...[
                          Icon(Icons.business_outlined, size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Flexible(child: Text(department, style: TextStyle(fontSize: 11, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis)),
                        ],
                        if (department.isNotEmpty && qualification.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(width: 3, height: 3, decoration: BoxDecoration(color: Colors.grey.shade400, shape: BoxShape.circle)),
                        ],
                        if (qualification.isNotEmpty)
                          Flexible(
                            child: Text(
                              qualification,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontStyle: FontStyle.italic),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Expanded(child: SizedBox()),
                    _smallButton(icon: Icons.delete_outline, label: 'Delete', color: Colors.red.shade400, onTap: () => widget.onDelete(t['id'])),
                    const SizedBox(width: 8),
                    _smallButton(icon: Icons.assignment_ind_rounded, label: 'Assign', color: const Color(0xFF1A237E), onTap: () => _showManageSheet(context, t['id'].toString())),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _smallButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _emptyState({required IconData icon, Color? iconBg, Color? iconColor, required String title, required String subtitle, String? actionLabel, VoidCallback? onAction}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: iconBg ?? const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(18)),
            child: Icon(icon, size: 32, color: iconColor ?? const Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)), textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A237E))),
            ),
          ],
        ],
      ),
    );
  }

  void _showTeacherDetail(BuildContext context, Map<String, dynamic> t) {
    final name = _getName(t);
    final staffId = _getStaffId(t);
    final passportUrl = (t['passport_url'] ?? '').toString().trim();
    final email = (t['email'] ?? '').toString().trim();
    final phone = (t['phone'] ?? '').toString().trim();
    final department = (t['department'] ?? '').toString().trim();
    final qualification = (t['qualification'] ?? '').toString().trim();
    final gender = (t['gender'] ?? '').toString().trim();
    final homeAddress = (t['home_address'] ?? '').toString().trim();
    final isFormTeacher = t['formTeacherClassId'] != null;
    final assignedSubjects = List<Map<String, dynamic>>.from(t['assignedSubjects'] ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, -4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Flat header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Column(
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(color: const Color(0xFFF0F4FF), shape: BoxShape.circle),
                        child: passportUrl.isNotEmpty
                            ? CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: NetworkImage(passportUrl),
                                onBackgroundImageError: passportUrl.isNotEmpty ? (_, __) {} : null,
                              )
                            : CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.white,
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'T',
                                  style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1A237E), fontSize: 22),
                                ),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name.isNotEmpty ? name : 'Unknown', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827), letterSpacing: -0.3)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              children: [
                                if (staffId.isNotEmpty) _miniBadge(text: staffId, color: const Color(0xFF1A237E), bg: const Color(0xFFF0F4FF)),
                                if (isFormTeacher) _miniBadge(text: 'Form Teacher', color: const Color(0xFF2E7D32), bg: const Color(0xFFF0FFF4)),
                                if (assignedSubjects.isNotEmpty) _miniBadge(text: '${assignedSubjects.length} Subject${assignedSubjects.length != 1 ? 's' : ''}', color: const Color(0xFFE65100), bg: const Color(0xFFFFF3E0)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF)), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE8EAED)),
            // Detail rows
            if (gender.isNotEmpty) _detailRow(icon: Icons.wc_rounded, iconBg: const Color(0xFFF3E5F5), iconColor: const Color(0xFF7B1FA2), label: 'Gender', value: gender[0].toUpperCase() + gender.substring(1)),
            if (email.isNotEmpty) _detailRow(icon: Icons.email_rounded, iconBg: const Color(0xFFF0F4FF), iconColor: const Color(0xFF1A237E), label: 'Email', value: email),
            if (phone.isNotEmpty) _detailRow(icon: Icons.phone_rounded, iconBg: const Color(0xFFF0FFF4), iconColor: const Color(0xFF2E7D32), label: 'Phone', value: phone),
            if (department.isNotEmpty) _detailRow(icon: Icons.business_outlined, iconBg: const Color(0xFFFFF3E0), iconColor: const Color(0xFFE65100), label: 'Department', value: department),
            if (qualification.isNotEmpty) _detailRow(icon: Icons.school_rounded, iconBg: const Color(0xFFFFF8E1), iconColor: const Color(0xFFF57F17), label: 'Qualification', value: qualification),
            if (homeAddress.isNotEmpty) _detailRow(icon: Icons.location_on_rounded, iconBg: const Color(0xFFFEF2F2), iconColor: const Color(0xFFC62828), label: 'Home Address', value: homeAddress),
            if (assignedSubjects.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('SUBJECT ASSIGNMENTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.5)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: assignedSubjects.map((a) {
                    final subjName = (a['subjectName'] ?? 'Unknown').toString();
                    final clsName = (a['className'] ?? '').toString();
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFC5CAE9)),
                      ),
                      child: Text(
                        clsName.isNotEmpty ? '$subjName ($clsName)' : subjName,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A237E)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: 8),
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
                          widget.onDelete(t['id']);
                        },
                        icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
                        label: Text('Delete', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.red.shade400)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (mounted) _showManageSheet(context, t['id'].toString());
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Manage Roles', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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

  Widget _miniBadge({required String text, required Color color, required Color bg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _detailRow({required IconData icon, required Color iconBg, required Color iconColor, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================
// MANAGE SHEET
// =========================================================

class _ManageSheet extends StatefulWidget {
  final String teacherId;
  const _ManageSheet({required this.teacherId});

  @override
  State<_ManageSheet> createState() => _ManageSheetState();
}

class _ManageSheetState extends State<_ManageSheet> {
  String? _selectedClassIdForSubject;
  List<Map<String, dynamic>>? _classSubjects;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SchoolAdminProvider>().loadTeacherAssignments(widget.teacherId);
    });
  }

  Future<void> _loadClassSubjects(String classId) async {
    setState(() => _classSubjects = null);
    try {
      final schoolId = context.read<SchoolAdminProvider>().schoolId;
      final result = await Supabase.instance.client
          .from('class_subjects')
          .select('id, subject_id, teacher_id, subjects(name, code)')
          .eq('class_id', classId)
          .eq('school_id', schoolId);
      setState(() => _classSubjects = List<Map<String, dynamic>>.from(result));
    } catch (e) {
      debugPrint('Error loading class subjects: $e');
      setState(() => _classSubjects = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SchoolAdminProvider>();
    final teacher = provider.getTeacherById(widget.teacherId);

    if (teacher == null) {
      return Container(
        height: 200,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: const Center(child: Text('Teacher not found')),
      );
    }

    final teacherName = _getName(teacher);
    final teacherStaffId = _getStaffId(teacher);
    final formTeacherClassId = teacher['formTeacherClassId']?.toString();
    final assignedSubjects = List<Map<String, dynamic>>.from(teacher['assignedSubjects'] ?? []);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, -4))],
          ),
          child: Column(
            children: [
              // Flat header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                child: Column(
                  children: [
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.person_rounded, size: 24, color: Color(0xFF1A237E)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(teacherName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827), letterSpacing: -0.3)),
                              const SizedBox(height: 2),
                              Text('Staff ID: $teacherStaffId', style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
                            ],
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF)), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE8EAED)),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  children: [
                    // Form Teacher section
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FFF4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFC8E6C9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.supervisor_account_rounded, size: 18, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('ASSIGN AS FORM TEACHER', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32))),
                                  Text('One form teacher per class', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            value: formTeacherClassId,
                            decoration: InputDecoration(
                              labelText: 'Select Class (None = Remove)',
                              labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                              border: const OutlineInputBorder(),
                              enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFC8E6C9))),
                              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2)),
                              prefixIcon: const Icon(Icons.class_rounded, color: Color(0xFF2E7D32)),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              isDense: true,
                            ),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Not a Form Teacher')),
                              ...provider.classes.map((c) => DropdownMenuItem(
                                    value: c['id'].toString(),
                                    child: Text("${c['name']} - ${c['section']} (${c['student_count']} students)"),
                                  )),
                            ],
                            onChanged: (val) => provider.assignFormTeacher(widget.teacherId, val),
                          ),
                          if (formTeacherClassId != null)
                            Container(
                              margin: const EdgeInsets.only(top: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFC8E6C9)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 16),
                                  SizedBox(width: 8),
                                  Text('Currently assigned as Form Teacher', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600, fontSize: 13)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Subject Teacher section
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFC5CAE9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(color: const Color(0xFF1A237E), borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.menu_book_rounded, size: 18, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('ASSIGN AS SUBJECT TEACHER', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A237E))),
                                  Text('Multiple subjects in multiple classes', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            value: _selectedClassIdForSubject,
                            decoration: InputDecoration(
                              hintText: 'Step 1: Pick a class',
                              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                              border: const OutlineInputBorder(),
                              enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFC5CAE9))),
                              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF1A237E), width: 2)),
                              prefixIcon: const Icon(Icons.layers_rounded, color: Color(0xFF1A237E)),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              isDense: true,
                            ),
                            items: provider.classes
                                .map((c) => DropdownMenuItem(
                                      value: c['id'].toString(),
                                      child: Text("${c['name']} - ${c['section']}"),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedClassIdForSubject = val;
                              });
                              if (val != null) {
                                _loadClassSubjects(val);
                              } else {
                                setState(() => _classSubjects = null);
                              }
                            },
                          ),
                          if (_selectedClassIdForSubject != null) ...[
                            const SizedBox(height: 14),
                            const Text('Step 2: Click subjects to assign/unassign:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF111827))),
                            const SizedBox(height: 12),
                            if (_classSubjects == null)
                              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF1A237E))))
                            else if (_classSubjects!.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF8E1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFFFE082)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100), size: 20),
                                    SizedBox(width: 10),
                                    Expanded(child: Text('No subjects linked to this class. Go to Classes > add subjects first.', style: TextStyle(color: Color(0xFFE65100), fontSize: 13))),
                                  ],
                                ),
                              )
                            else
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: _classSubjects!.map((cs) {
                                  final subjData = cs['subjects'] as Map<String, dynamic>?;
                                  final subjName = subjData?['name'] ?? 'Unknown';
                                  final subjCode = subjData?['code'] ?? '';
                                  final subjId = cs['subject_id']?.toString() ?? '';
                                  final assigned = assignedSubjects.any((a) => a['classId'] == _selectedClassIdForSubject && a['subjectId'] == subjId);
                                  return GestureDetector(
                                    onTap: () {
                                      if (assigned) {
                                        provider.removeSubjectFromTeacher(widget.teacherId, subjId, _selectedClassIdForSubject!);
                                      } else {
                                        provider.assignSubjectToTeacher(widget.teacherId, subjId, _selectedClassIdForSubject!);
                                      }
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: assigned ? const Color(0xFF1A237E) : Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: assigned ? const Color(0xFF1A237E) : Colors.grey.shade300),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(assigned ? Icons.check_circle_rounded : Icons.circle_outlined, size: 18, color: assigned ? Colors.white : Colors.grey),
                                          const SizedBox(width: 8),
                                          Text(
                                            subjCode.isNotEmpty ? '$subjName ($subjCode)' : subjName,
                                            style: TextStyle(fontWeight: FontWeight.w600, color: assigned ? Colors.white : const Color(0xFF111827)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('DONE', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getName(Map<String, dynamic> t) {
    final first = (t['first_name'] ?? '').toString().trim();
    final last = (t['last_name'] ?? '').toString().trim();
    if (first.isNotEmpty && last.isNotEmpty) return '$first $last';
    if (first.isNotEmpty) return first;
    if (last.isNotEmpty) return last;
    return '';
  }

  String _getStaffId(Map<String, dynamic> t) {
    return (t['staff_id'] ?? t['staffId'] ?? t['id'] ?? '').toString();
  }
}

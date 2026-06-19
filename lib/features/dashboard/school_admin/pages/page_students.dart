import 'package:smartedu/core/services/db_proxy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// ==========================================
// File: lib/features/dashboard/school_admin/pages/page_students.dart
// ==========================================
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartedu/core/providers/school_admin_provider.dart';

class PageStudents extends StatefulWidget {
  final List<Map<String, dynamic>> students;
  final void Function(String id) onDelete;
  final VoidCallback onAdd;
  final VoidCallback? onRefresh;

  const PageStudents({
    super.key,
    required this.students,
    required this.onDelete,
    required this.onAdd,
    this.onRefresh,
  });

  @override
  State<PageStudents> createState() => _PageStudentsState();
}

class _PageStudentsState extends State<PageStudents> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool _showSearch = false;
  static const int _pageSize = 50;
  int _displayCount = _pageSize;
  bool _isExporting = false;

  List<Map<String, dynamic>> get _filteredStudents {
    if (_searchQuery.isEmpty) return widget.students;
    final q = _searchQuery.toLowerCase();
    return widget.students.where((s) {
      final first = (s['first_name'] ?? '').toString().trim().toLowerCase();
      final last = (s['last_name'] ?? '').toString().trim().toLowerCase();
      final admNo = (s['admission_no'] ?? '').toString().trim().toLowerCase();
      final parent = (s['parent_name'] ?? '').toString().trim().toLowerCase();
      return '$first $last'.contains(q) || first.contains(q) || last.contains(q) || admNo.contains(q) || parent.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> get _displayedStudents {
    final filtered = _filteredStudents;
    if (filtered.length <= _displayCount) return filtered;
    return filtered.sublist(0, _displayCount);
  }

  bool get _hasMore => _filteredStudents.length > _displayCount;

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
    return (s['admission_no'] ?? s['id'] ?? '').toString();
  }

  String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  void _exportCsv() {
    if (_filteredStudents.isEmpty) return;
    setState(() => _isExporting = true);
    try {
      final buffer = StringBuffer();
      buffer.writeln('Admission No,Full Name,Gender,Class,Parent Name,Parent Phone');
      for (final s in _filteredStudents) {
        buffer.writeln([
          _csvEscape(_getStudentId(s)),
          _csvEscape(_getName(s)),
          _csvEscape((s['gender'] ?? '').toString()),
          _csvEscape(_getClassInfo(s)),
          _csvEscape((s['parent_name'] ?? '').toString()),
          _csvEscape((s['parent_phone'] ?? '').toString()),
        ].join(','));
      }
      final bytes = Uint8List.fromList(buffer.toString().codeUnits);
      final blob = html.Blob([bytes], 'text/csv;charset=utf-8;');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)..setAttribute('download', 'students.csv')..click();
      html.Url.revokeObjectUrl(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export successful', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)), backgroundColor: Color(0xFF2E7D32), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8)))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e', style: const TextStyle(color: Colors.white)), backgroundColor: const Color(0xFFD32F2F), behavior: SnackBarBehavior.floating, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8)))));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showPromoteSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PromoteSheetBody(onComplete: () { widget.onRefresh?.call(); }),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Widget _buildStudentAvatar(String name, String photo, bool isFemale) {
    final url = photo.trim();
    final ringColor = isFemale ? const Color(0xFFE91E63) : const Color(0xFF1565C0);
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isFemale ? const Color(0xFFFFECF3) : const Color(0xFFF0F4FF),
        shape: BoxShape.circle,
      ),
      child: url.isNotEmpty
          ? CircleAvatar(
              radius: 22,
              backgroundColor: Colors.grey.shade100,
              backgroundImage: NetworkImage(url),
              onBackgroundImageError: url.isNotEmpty ? (_, __) {} : null)
          : CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white,
              child: Icon(isFemale ? Icons.girl : Icons.boy, size: 18, color: ringColor)),
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
          TextSpan(text: text.substring(0, idx), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
        TextSpan(text: text.substring(idx, idx + _searchQuery.length), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A237E), backgroundColor: Color(0xFFE8EAF6))),
        TextSpan(text: text.substring(idx + _searchQuery.length), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
      ],
    );
  }

  Widget _studentCard(Map<String, dynamic> s, int index) {
    final name = _getName(s);
    final classInfo = _getClassInfo(s);
    final admNo = _getStudentId(s);
    final gender = (s['gender'] ?? '').toString().trim().toLowerCase();
    final parent = (s['parent_name'] ?? '').toString().trim();
    final photo = (s['passport_url'] ?? '').toString().trim();
    final isFemale = gender == 'female';

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
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                _buildStudentAvatar(name, photo, isFemale),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(text: _buildHighlightedName(name), overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (admNo.isNotEmpty)
                            _badge(admNo, const Color(0xFF1A237E), const Color(0xFFF0F4FF)),
                          if (classInfo.isNotEmpty)
                            _badge(classInfo, const Color(0xFF7B1FA2), const Color(0xFFF3E5F5)),
                          if (parent.isNotEmpty)
                            _badge(parent, Colors.grey.shade600, const Color(0xFFF5F5F5)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                    color: const Color(0xFFFEF2F2),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.delete_outline, size: 16, color: Colors.red.shade400),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    onPressed: () => widget.onDelete(s['id']),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color), overflow: TextOverflow.ellipsis, maxLines: 1),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? iconBg,
    Color? iconColor,
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
            decoration: BoxDecoration(color: iconBg ?? const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(18)),
            child: Icon(icon, size: 32, color: iconColor ?? const Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)), textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            TextButton(onPressed: onAction, child: Text(actionLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A237E)))),
          ],
        ],
      ),
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
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? Colors.white : const Color(0xFF6B7280))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayed = _displayedStudents;
    final hasSearch = _searchQuery.isNotEmpty;
    final total = widget.students.length;
    final unassigned = widget.students.where((s) => s['class_id'] == null).length;

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
                      child: const Icon(Icons.school_rounded, size: 22, color: Color(0xFF1A237E)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Students', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827), letterSpacing: -0.5)),
                          const SizedBox(height: 2),
                          Text(hasSearch ? '${_filteredStudents.length} of $total found' : '$total registered', style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
                        ],
                      ),
                    ),
                    _actionChip(icon: Icons.trending_up_rounded, label: 'Promote', onTap: _showPromoteSheet),
                    const SizedBox(width: 8),
                    _actionChip(icon: Icons.download_rounded, label: _isExporting ? '...' : 'Export', onTap: _isExporting ? () {} : _exportCsv),
                    const SizedBox(width: 8),
                    _actionChip(icon: Icons.search_rounded, label: 'Search', onTap: () {
                      setState(() {
                        _showSearch = !_showSearch;
                        if (!_showSearch) { _searchController.clear(); _searchQuery = ''; _displayCount = _pageSize; }
                      });
                      if (_showSearch) FocusScope.of(context).requestFocus(_searchFocusNode);
                    }, active: _showSearch),
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
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE8EAED))),
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              autofocus: true,
                              style: const TextStyle(fontSize: 14, color: Color(0xFF111827), height: 1.4),
                              onChanged: (v) { setState(() { _searchQuery = v.trim(); _displayCount = _pageSize; }); },
                              decoration: InputDecoration(
                                hintText: 'Search by name, admission no, parent...',
                                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400, height: 1.4),
                                prefixIcon: Icon(Icons.search_rounded, size: 20, color: _searchQuery.isNotEmpty ? const Color(0xFF1A237E) : Colors.grey.shade400),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF9CA3AF)), padding: const EdgeInsets.only(right: 4), constraints: const BoxConstraints(minWidth: 32, minHeight: 32), onPressed: () { _searchController.clear(); setState(() { _searchQuery = ''; _displayCount = _pageSize; }); })
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
                  _statCard(icon: Icons.people_rounded, label: 'Total', value: '$total', iconBg: const Color(0xFFF0F4FF), iconColor: const Color(0xFF1A237E)),
                  const SizedBox(width: 10),
                  _statCard(icon: Icons.check_circle_outline, label: 'Assigned', value: '${total - unassigned}', iconBg: const Color(0xFFF0FFF4), iconColor: const Color(0xFF2E7D32)),
                  const SizedBox(width: 10),
                  _statCard(icon: Icons.person_off_rounded, label: 'Unassigned', value: '$unassigned', iconBg: const Color(0xFFFFF3E0), iconColor: const Color(0xFFE65100)),
                ],
              ),
            ),
          const SizedBox(height: 12),
          // List
          Expanded(
            child: widget.students.isEmpty
                ? _emptyState(icon: Icons.people_outline_rounded, title: 'No students yet', subtitle: 'Tap Add New to register')
                : hasSearch && _filteredStudents.isEmpty
                    ? _emptyState(icon: Icons.search_off_rounded, iconBg: const Color(0xFFFFF3E0), iconColor: const Color(0xFFE65100), title: 'No match found', subtitle: 'Try different search', actionLabel: 'Clear search', onAction: () { _searchController.clear(); setState(() { _searchQuery = ''; _displayCount = _pageSize; }); })
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: displayed.length + (_hasMore ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i == displayed.length) {
                            final remaining = _filteredStudents.length - _displayCount;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: TextButton.icon(
                                  onPressed: () => setState(() => _displayCount += _pageSize),
                                  icon: Icon(Icons.expand_more, size: 18, color: Colors.grey.shade500),
                                  label: Text('Show $remaining more', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade300))),
                                ),
                              ),
                            );
                          }
                          return _studentCard(displayed[i], i);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: Container(
        height: 52,
        decoration: BoxDecoration(color: const Color(0xFF1A237E), borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: const Color(0xFF1A237E).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]),
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
            Container(width: 38, height: 38, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: iconColor)),
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
}

// =========================================================
// PROMOTE SHEET
// =========================================================

class _PromoteSheetBody extends StatefulWidget {
  final VoidCallback onComplete;
  const _PromoteSheetBody({required this.onComplete});

  @override
  State<_PromoteSheetBody> createState() => _PromoteSheetBodyState();
}

class _PromoteSheetBodyState extends State<_PromoteSheetBody> {
  String? _fromId;
  String? _toId;
  List<Map<String, dynamic>> _classes = [];
  bool _loading = true;
  bool _promoting = false;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      final p = context.read<SchoolAdminProvider>();
      final r = await DbProxy.instance.from('classes').select('id, name, section, student_count, tier').eq('school_id', p.schoolId).order('name').get();
      if (mounted) setState(() { _classes = List<Map<String, dynamic>>.from(r); _loading = false; });
    } catch (e) {
      debugPrint('ERR: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  String _label(Map<String, dynamic> c) {
    final n = (c['name'] ?? '').toString();
    final s = (c['section'] ?? '').toString();
    final t = (c['tier'] ?? '').toString();
    final cnt = (c['student_count'] ?? 0).toString();
    String l = s.isNotEmpty ? '$n ($s)' : n;
    if (t.isNotEmpty) l += ' [$t]';
    return '$l - $cnt students';
  }

  int get _fromCount {
    final p = context.read<SchoolAdminProvider>();
    if (_fromId == null) return 0;
    return p.students.where((s) => s['class_id'].toString() == _fromId).length;
  }

  List<Map<String, dynamic>> get _toOptions {
    if (_fromId == null) return [];
    return _classes.where((c) => c['id'].toString() != _fromId).toList();
  }

  Future<void> _doPromote() async {
    if (_fromId == null || _toId == null || _fromCount == 0) return;
    final fromId = _fromId!;
    final toId = _toId!;
    setState(() => _promoting = true);
    try {
      await DbProxy.instance.from('students').eq('class_id', fromId).update({'class_id': toId});
      if (mounted) {
        Navigator.pop(context);
        widget.onComplete();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Students promoted!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)), backgroundColor: Color(0xFF2E7D32), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8)))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e', style: const TextStyle(color: Colors.white)), backgroundColor: const Color(0xFFD32F2F), behavior: SnackBarBehavior.floating, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8)))));
      }
    } finally {
      if (mounted) setState(() => _promoting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: 300,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
      );
    }

    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24)), boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, -4))]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Flat header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: Column(
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFF0FFF4), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.trending_up_rounded, size: 22, color: Color(0xFF2E7D32))),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                      Text('Bulk Promote Students', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827), letterSpacing: -0.3)),
                      SizedBox(height: 2),
                      Text('Move all students from one class to another', style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
                    ])),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8EAED)),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(alignment: Alignment.centerLeft, child: Text('FROM CLASS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF9CA3AF), letterSpacing: 0.5))),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  value: _fromId,
                  decoration: InputDecoration(hintText: 'Select source class', hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400), border: const OutlineInputBorder(), enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFE8EAED))), focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2)), prefixIcon: const Icon(Icons.arrow_upward_rounded, color: Color(0xFF2E7D32)), filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), isDense: true),
                  items: _classes.map((c) => DropdownMenuItem(value: c['id'].toString(), child: Text(_label(c), style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) { setState(() { _fromId = v; _toId = null; }); },
                ),
                if (_fromId != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFF0FFF4), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFC8E6C9))),
                    child: Text('$_fromCount student${_fromCount != 1 ? 's' : ''} will be moved', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32))),
                  ),
                const SizedBox(height: 16),
                const Align(alignment: Alignment.centerLeft, child: Text('TO CLASS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF9CA3AF), letterSpacing: 0.5))),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  value: _toId,
                  decoration: InputDecoration(hintText: _fromId == null ? 'Select source first' : 'Select destination', hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400), border: const OutlineInputBorder(), enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFE8EAED))), focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2)), prefixIcon: const Icon(Icons.arrow_downward_rounded, color: Color(0xFF2E7D32)), filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), isDense: true),
                  items: _toOptions.map((c) => DropdownMenuItem(value: c['id'].toString(), child: Text(_label(c), style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: _fromId == null ? null : (v) { setState(() => _toId = v); },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          child: Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: (_fromId != null && _toId != null && _fromCount > 0 && !_promoting) ? _doPromote : null,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), disabledBackgroundColor: Colors.grey.shade200, disabledForegroundColor: Colors.grey.shade400, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          child: _promoting
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text('Promote${_fromCount > 0 ? ' $_fromCount Students' : ''}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

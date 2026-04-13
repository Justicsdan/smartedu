// ==========================================
// File: lib/features/dashboard/school_admin/pages/page_students.dart
// ==========================================
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
      return '$first $last'.contains(q) ||
          first.contains(q) ||
          last.contains(q) ||
          admNo.contains(q) ||
          parent.contains(q);
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
      html.AnchorElement(href: url)
        ..setAttribute('download', 'students.csv')
        ..click();
      html.Url.revokeObjectUrl(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export successful'),
            backgroundColor: Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
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
      builder: (ctx) {
        return _PromoteSheetBody(onComplete: () {
          widget.onRefresh?.call();
        });
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Widget _headerBtn({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(
    IconData icon,
    String label,
    String value,
    Color color,
    Color bg,
  ) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bg,
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

  Widget _loadMoreBtn() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: TextButton(
          onPressed: () => setState(() => _displayCount += _pageSize),
          child: const Text(
            'Show more',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(Map<String, dynamic> s, int i) {
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
        color: i.isOdd ? const Color(0xFFFAFBFC) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: isFemale
                    ? const Color(0xFFFCE4EC)
                    : const Color(0xFFE3F2FD),
                backgroundImage:
                    photo.isNotEmpty ? NetworkImage(photo) : null,
                onBackgroundImageError: photo.isNotEmpty ? (_, __) {} : null,
                child: photo.isEmpty
                    ? Icon(
                        isFemale ? Icons.girl : Icons.boy,
                        size: 20,
                        color: isFemale
                            ? const Color(0xFFE91E63)
                            : const Color(0xFF1565C0),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isNotEmpty ? name : 'Unknown',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (admNo.isNotEmpty)
                          _badge(
                            admNo,
                            const Color(0xFF1A237E),
                            const Color(0xFFF0F4FF),
                          ),
                        if (classInfo.isNotEmpty)
                          _badge(
                            classInfo,
                            const Color(0xFF7B1FA2),
                            const Color(0xFFF3E5F5),
                          ),
                        if (parent.isNotEmpty)
                          _badge(
                            parent,
                            Colors.grey.shade600,
                            const Color(0xFFF5F5F5),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 34,
                height: 34,
                child: IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.red.shade400,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 30,
                  ),
                  onPressed: () => widget.onDelete(s['id']),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Widget _empty(IconData icon, String title, String sub) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, size: 32, color: Colors.grey.shade400),
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
            sub,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF9CA3AF),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayed = _displayedStudents;
    final hasSearch = _searchQuery.isNotEmpty;
    final total = widget.students.length;
    final unassigned = widget.students
        .where((s) => s['class_id'] == null)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        size: 22,
                        color: Color(0xFF1A237E),
                      ),
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
                                ? '${_filteredStudents.length} of $total found'
                                : '$total registered',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _headerBtn(
                      icon: Icons.trending_up_rounded,
                      label: 'Promote',
                      color: const Color(0xFF2E7D32),
                      onTap: _showPromoteSheet,
                    ),
                    const SizedBox(width: 8),
                    _headerBtn(
                      icon: Icons.download_rounded,
                      label: 'Export',
                      color: const Color(0xFF2E7D32),
                      onTap: _isExporting ? null : _exportCsv,
                    ),
                    const SizedBox(width: 8),
                    _headerBtn(
                      icon: Icons.search_rounded,
                      label: _showSearch ? 'Close' : 'Search',
                      color: _showSearch
                          ? const Color(0xFF1A237E)
                          : const Color(0xFF6B7280),
                      onTap: () {
                        setState(() {
                          _showSearch = !_showSearch;
                          if (!_showSearch) {
                            _searchController.clear();
                            _searchQuery = '';
                            _displayCount = _pageSize;
                          }
                        });
                        if (_showSearch) {
                          FocusScope.of(context)
                              .requestFocus(_searchFocusNode);
                        }
                      },
                    ),
                  ],
                ),
                if (_showSearch)
                  Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 16),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      autofocus: true,
                      onChanged: (v) {
                        setState(() {
                          _searchQuery = v.trim();
                          _displayCount = _pageSize;
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Search by name, admission no...',
                        prefixIcon: Icon(Icons.search_rounded, size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 10, horizontal: 14),
                        isDense: true,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 16),
              ],
            ),
          ),
          if (!_showSearch)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8EAED)),
              ),
              child: Row(
                children: [
                  _stat(
                    Icons.people_rounded,
                    'Total',
                    '$total',
                    const Color(0xFF1A237E),
                    const Color(0xFFF0F4FF),
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: const Color(0xFFE8EAED),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  _stat(
                    Icons.check_circle_outline_rounded,
                    'Assigned',
                    '${total - unassigned}',
                    const Color(0xFF2E7D32),
                    const Color(0xFFF0FFF4),
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: const Color(0xFFE8EAED),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  _stat(
                    Icons.person_off_rounded,
                    'Unassigned',
                    '$unassigned',
                    const Color(0xFFE65100),
                    const Color(0xFFFFF3E0),
                  ),
                ],
              ),
            ),
          Expanded(
            child: widget.students.isEmpty
                ? _empty(
                    Icons.people_outline_rounded,
                    'No students yet',
                    'Tap Add New to register',
                  )
                : hasSearch && _filteredStudents.isEmpty
                    ? _empty(
                        Icons.search_off_rounded,
                        'No match found',
                        'Try different search',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                            16,
                            12,
                            16,
                            90,
                        ),
                        itemCount:
                            displayed.length + (_hasMore ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i == displayed.length) {
                            return _loadMoreBtn();
                          }
                          return _card(displayed[i], i);
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
                Icon(
                  Icons.person_add_rounded,
                  color: Colors.white,
                  size: 20,
                ),
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
}

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
      final r = await Supabase.instance.client
          .from('classes')
          .select('id, name, section, student_count, tier')
          .eq('school_id', p.schoolId)
          .order('name');
      if (mounted) {
        setState(() {
          _classes = List<Map<String, dynamic>>.from(r);
          _loading = false;
        });
      }
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
    return p.students
        .where((s) => s['class_id'].toString() == _fromId)
        .length;
  }

  List<Map<String, dynamic>> get _toOptions {
    if (_fromId == null) return [];
    return _classes
        .where((c) => c['id'].toString() != _fromId)
        .toList();
  }

  Future<void> _doPromote() async {
    if (_fromId == null || _toId == null || _fromCount == 0) return;
    final fromId = _fromId!;
    final toId = _toId!;
    setState(() => _promoting = true);
    try {
      await Supabase.instance.client
          .from('students')
          .update({'class_id': toId})
          .eq('class_id', fromId);
      if (mounted) {
        Navigator.pop(context);
        widget.onComplete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Students promoted!'),
            backgroundColor: Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2E7D32),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
            const Row(
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  size: 28,
                  color: Color(0xFF2E7D32),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bulk Promote Students',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Text(
                        'Move all students from one class to another',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(
              height: 1,
              color: Color(0xFFF0F0F0),
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'FROM CLASS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF9CA3AF),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              value: _fromId,
              decoration: const InputDecoration(
                hintText: 'Select source class',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
              ),
              items: _classes
                  .map((c) => DropdownMenuItem(
                        value: c['id'].toString(),
                        child: Text(
                          _label(c),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _fromId = v;
                  _toId = null;
                });
              },
            ),
            if (_fromId != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FFF4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_fromCount student${_fromCount != 1 ? 's' : ''} will be moved',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'TO CLASS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF9CA3AF),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              value: _toId,
              decoration: InputDecoration(
                hintText: _fromId == null
                    ? 'Select source first'
                    : 'Select destination',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
              ),
              items: _toOptions
                  .map((c) => DropdownMenuItem(
                        value: c['id'].toString(),
                        child: Text(
                          _label(c),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ))
                  .toList(),
              onChanged: _fromId == null
                  ? null
                  : (v) {
                      setState(() => _toId = v);
                    },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: (_fromId != null &&
                              _toId != null &&
                              _fromCount > 0 &&
                              !_promoting)
                          ? _doPromote
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        disabledBackgroundColor: Colors.grey.shade200,
                        disabledForegroundColor: Colors.grey.shade400,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _promoting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Promote${_fromCount > 0 ? ' $_fromCount Students' : ''}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

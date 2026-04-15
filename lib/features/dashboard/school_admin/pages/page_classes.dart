// ==========================================
// File: lib/features/dashboard/school_admin/pages/page_classes.dart
// ==========================================
import 'package:flutter/material.dart';

class PageClasses extends StatefulWidget {
  final List<Map<String, dynamic>> classes;
  final List<Map<String, dynamic>> subjects;
  final List<Map<String, dynamic>> assignments;
  final List<Map<String, dynamic>> teachers;
  final List<Map<String, dynamic>> students;
  final List<Map<String, dynamic>> classSubjects;
  final Future<bool> Function(String classId, String subjectId)? onAddClassSubject;
  final Future<bool> Function(String classSubjectId)? onRemoveClassSubject;
  final void Function(Map<String, dynamic>) onAddClass;
  final void Function(Map<String, dynamic>) onDeleteClass;
  final void Function(Map<String, dynamic>) onAddSubject;
  final void Function(Map<String, dynamic>) onDeleteSubject;
  final void Function(Map<String, dynamic>) onAddAssignment;
  final void Function(Map<String, dynamic>) onDeleteAssignment;

  const PageClasses({
    super.key,
    required this.classes,
    required this.subjects,
    required this.assignments,
    required this.teachers,
    this.students = const [],
    this.classSubjects = const [],
    this.onAddClassSubject,
    this.onRemoveClassSubject,
    required this.onAddClass,
    required this.onDeleteClass,
    required this.onAddSubject,
    required this.onDeleteSubject,
    required this.onAddAssignment,
    required this.onDeleteAssignment,
  });

  @override
  State<PageClasses> createState() => _PageClassesState();
}

class _PageClassesState extends State<PageClasses>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _hoveredClass = -1;
  int _hoveredSubject = -1;
  int _hoveredAssignment = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────

  List<Map<String, dynamic>> _getLinksForClass(String? classId) {
    if (classId == null) return [];
    return widget.classSubjects
        .where((cs) => cs['class_id']?.toString() == classId)
        .toList();
  }

  Set<String> _linkedSubjectIds(String? classId) {
    return _getLinksForClass(classId)
        .map((cs) => cs['subject_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  List<Map<String, dynamic>> _unlinkedSubjects(String? classId) {
    final linked = _linkedSubjectIds(classId);
    return widget.subjects
        .where((s) => !linked.contains(s['id']?.toString()))
        .toList();
  }

  String _getClassName(String? id) {
    if (id == null) return 'Unassigned';
    try {
      final cls = widget.classes.firstWhere((c) => c['id'].toString() == id);
      return '${cls['name']} - ${cls['section'] ?? ''}';
    } catch (_) {
      return 'Unknown Class';
    }
  }

  String _getSubjectName(String? id) {
    if (id == null) return 'Unassigned';
    try {
      final subj = widget.subjects.firstWhere((s) => s['id'].toString() == id);
      return subj['name'].toString();
    } catch (_) {
      return 'Unknown Subject';
    }
  }

  String _getTeacherName(String? id) {
    if (id == null) return 'Unassigned';
    try {
      final t = widget.teachers.firstWhere((t) => t['id'].toString() == id);
      return '${t['first_name']} ${t['last_name']}';
    } catch (_) {
      return 'Unknown Teacher';
    }
  }

  bool _classExists(String name, String section) {
    return widget.classes.any((c) =>
        c['name']?.toString().trim().toLowerCase() == name.trim().toLowerCase() &&
        c['section']?.toString().trim().toLowerCase() == section.trim().toLowerCase());
  }

  bool _subjectExists(String name) {
    return widget.subjects.any((s) =>
        s['name']?.toString().trim().toLowerCase() == name.trim().toLowerCase());
  }

  Color _tierColor(String tier) {
    switch (tier.toUpperCase()) {
      case 'JSS':
        return const Color(0xFFE65100);
      case 'PRIMARY':
        return const Color(0xFF7B1FA2);
      default:
        return const Color(0xFF1565C0);
    }
  }

  Color _tierBg(String tier) {
    switch (tier.toUpperCase()) {
      case 'JSS':
        return const Color(0xFFFFF3E0);
      case 'PRIMARY':
        return const Color(0xFFF3E5F5);
      default:
        return const Color(0xFFE3F2FD);
    }
  }

  // ── Bottom Sheet: Class Details (Students) ───────────────

  void _showClassDetails(Map<String, dynamic> classData) {
    final classId = classData['id']?.toString();
    final classStudents = widget.students
        .where((s) => s['class_id']?.toString() == classId)
        .toList();
    final tier = (classData['tier'] ?? '').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(color: Color(0x1A000000), blurRadius: 24, offset: Offset(0, -6)),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.class_rounded, size: 24, color: Color(0xFF1A237E)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${classData['name']} - ${classData['section']}",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827), letterSpacing: -0.3),
                          ),
                          if (classData['formTeacherName'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Row(
                                children: [
                                  Icon(Icons.person_outline_rounded, size: 13, color: Colors.grey.shade400),
                                  const SizedBox(width: 4),
                                  Text('Form Teacher: ${classData['formTeacherName']}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (tier.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: _tierBg(tier), borderRadius: BorderRadius.circular(6)),
                            child: Text(tier, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _tierColor(tier), letterSpacing: 0.5)),
                          ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(20)),
                          child: Text("${classStudents.length} Student${classStudents.length != 1 ? 's' : ''}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A237E))),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Divider(height: 1, color: Color(0xFFF0F0F0))),
              Expanded(
                child: classStudents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
                              child: Icon(Icons.people_outline_rounded, size: 28, color: Colors.grey.shade400),
                            ),
                            const SizedBox(height: 14),
                            Text('No students in this class yet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade500)),
                            const SizedBox(height: 4),
                            Text('Add students from the Students page', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                        itemCount: classStudents.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 2),
                        itemBuilder: (ctx, i) {
                          final s = classStudents[i];
                          final fname = (s['first_name'] ?? '').toString().trim();
                          final lname = (s['last_name'] ?? '').toString().trim();
                          final name = [fname, lname].where((p) => p.isNotEmpty).join(' ');
                          final gender = (s['gender'] ?? '').toString().trim();
                          final admNo = (s['admission_no'] ?? '').toString().trim();

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            decoration: BoxDecoration(
                              color: i.isEven ? const Color(0xFFFAFBFC) : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 28,
                                  child: Text('${i + 1}', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade400)),
                                ),
                                const SizedBox(width: 10),
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: gender == 'Female' ? const Color(0xFFFCE4EC) : const Color(0xFFE3F2FD),
                                  child: Icon(gender == 'Female' ? Icons.girl : Icons.boy, size: 16, color: gender == 'Female' ? const Color(0xFFE91E63) : const Color(0xFF1565C0)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name.isNotEmpty ? name : '—', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF111827))),
                                      if (admNo.isNotEmpty)
                                        Text(admNo, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom Sheet: Manage Subjects ────────────────────────

  void _showManageSubjects(Map<String, dynamic> classData) {
    final classId = classData['id']?.toString();
    if (classId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final links = _getLinksForClass(classId);
          final unlinked = _unlinkedSubjects(classId);
          String? selectedSubjectId;

          return DraggableScrollableSheet(
            initialChildSize: 0.55,
            minChildSize: 0.3,
            maxChildSize: 0.85,
            expand: false,
            builder: (ctx, scrollCtrl) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Color(0x1A000000), blurRadius: 24, offset: Offset(0, -6)),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(color: const Color(0xFFF0FFF4), borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.menu_book_rounded, size: 24, color: Color(0xFF2E7D32)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${classData['name']} - ${classData['section']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827), letterSpacing: -0.3)),
                              Text("${links.length} subject${links.length != 1 ? 's' : ''} assigned", style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Divider(height: 1, color: Color(0xFFF0F0F0))),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8EAED))),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedSubjectId,
                              decoration: InputDecoration(
                                labelText: 'Add Subject',
                                labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                border: const OutlineInputBorder(),
                                enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFE0E0E0))),
                                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF2E7D32))),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                isDense: true,
                                prefixIcon: const Icon(Icons.add_circle_outline, size: 18, color: Color(0xFF2E7D32)),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              items: unlinked
                                  .map((s) => DropdownMenuItem(
                                      value: s['id']?.toString(),
                                      child: Text(s['name'] ?? '', style: const TextStyle(fontSize: 14, color: Color(0xFF111827)), overflow: TextOverflow.ellipsis)))
                                  .toList(),
                              onChanged: unlinked.isEmpty ? null : (v) => setSheetState(() => selectedSubjectId = v),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: (selectedSubjectId != null && widget.onAddClassSubject != null)
                                  ? () async {
                                      final ok = await widget.onAddClassSubject!(classId, selectedSubjectId!);
                                      if (ok) {
                                        setSheetState(() => selectedSubjectId = null);
                                      } else if (ctx.mounted) {
                                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                          content: const Text('Failed to add subject'),
                                          backgroundColor: const Color(0xFFD32F2F),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ));
                                      }
                                    }
                                  : null,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add', style: TextStyle(fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (unlinked.isEmpty && links.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(14)),
                            child: Icon(Icons.library_books_outlined, size: 24, color: Colors.grey.shade400),
                          ),
                          const SizedBox(height: 12),
                          Text('No subjects created yet.\nGo to the Subjects tab to add subjects first.', style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.5), textAlign: TextAlign.center),
                        ],
                      ),
                    )
                  else if (unlinked.isEmpty && links.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_rounded, size: 16, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            Text('All subjects assigned to this class.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.green.shade800)),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: links.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(14)),
                                  child: Icon(Icons.link_off_rounded, size: 24, color: Colors.grey.shade400),
                                ),
                                const SizedBox(height: 12),
                                Text('No subjects assigned yet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade500)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            controller: scrollCtrl,
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                            itemCount: links.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 2),
                            itemBuilder: (ctx, i) {
                              final cs = links[i];
                              final subjId = cs['subject_id']?.toString() ?? '';
                              final subjName = _getSubjectName(subjId);
                              final csId = cs['id']?.toString() ?? '';
                              final isCompulsory = cs['is_compulsory'] == true;
                              final teacherId = cs['teacher_id']?.toString();
                              String teacherLabel = 'No teacher';
                              if (teacherId != null && teacherId.isNotEmpty) {
                                teacherLabel = _getTeacherName(teacherId);
                              }

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                decoration: BoxDecoration(
                                  color: i.isEven ? const Color(0xFFFAFBFC) : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 28,
                                      child: Text('${i + 1}', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade400)),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(color: const Color(0xFFF0FFF4), borderRadius: BorderRadius.circular(8)),
                                      child: const Icon(Icons.menu_book_rounded, size: 16, color: Color(0xFF2E7D32)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(subjName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF111827))),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: isCompulsory ? const Color(0xFFE3F2FD) : const Color(0xFFFFF8E1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  isCompulsory ? 'Core' : 'Elective',
                                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isCompulsory ? const Color(0xFF1565C0) : const Color(0xFFF57F17)),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(Icons.person_outline_rounded, size: 11, color: Colors.grey.shade400),
                                              const SizedBox(width: 3),
                                              Text(teacherLabel, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: IconButton(
                                        icon: Icon(Icons.close_rounded, size: 16, color: Colors.red.shade400),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                        tooltip: 'Remove subject',
                                        onPressed: widget.onRemoveClassSubject != null
                                            ? () async {
                                                final ok = await widget.onRemoveClassSubject!(csId);
                                                if (!ok && ctx.mounted) {
                                                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                                    content: const Text('Failed to remove'),
                                                    backgroundColor: const Color(0xFFD32F2F),
                                                    behavior: SnackBarBehavior.floating,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  ));
                                                }
                                              }
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Dialog: Add Class / Subject / Assignment ─────────────

  void _showAddDialog(String type) {
    final nameCtrl = TextEditingController();
    final sectionCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          String? selectedClass, selectedSubject, selectedTeacher;
          String? selectedCategory = 'Senior School (SSS)';
          String? dialogError;

          final accentColor = type == 'Class'
              ? const Color(0xFF1A237E)
              : type == 'Subject'
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFF57F17);

          final accentBg = type == 'Class'
              ? const Color(0xFFF0F4FF)
              : type == 'Subject'
                  ? const Color(0xFFF0FFF4)
                  : const Color(0xFFFFF8E1);

          final dialogIcon = type == 'Class'
              ? Icons.class_rounded
              : type == 'Subject'
                  ? Icons.menu_book_rounded
                  : Icons.assignment_rounded;

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            title: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: accentBg, borderRadius: BorderRadius.circular(12)),
                  child: Icon(dialogIcon, size: 22, color: accentColor),
                ),
                const SizedBox(width: 12),
                Text("Add $type", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFF111827), letterSpacing: -0.3)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (dialogError != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFECACA))),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, size: 18, color: Color(0xFFDC2626)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(dialogError, style: const TextStyle(fontSize: 13, color: Color(0xFFDC2626), height: 1.3))),
                        ],
                      ),
                    ),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(fontSize: 15, color: Color(0xFF111827)),
                    decoration: InputDecoration(
                      labelText: type == "Class" ? "Class Name (e.g SS1)" : type == "Subject" ? "Subject Name" : "Assignment Title",
                      labelStyle: TextStyle(color: Colors.grey.shade600),
                      border: const OutlineInputBorder(),
                      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFE0E0E0))),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: accentColor)),
                    ),
                  ),
                  if (type == "Class") ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        labelText: "School Category",
                        labelStyle: TextStyle(color: Colors.grey.shade600),
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFE0E0E0))),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: accentColor)),
                        prefixIcon: Icon(Icons.school, color: accentColor),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Senior School (SSS)', child: Text('Senior School (SSS) — WAEC Template')),
                        DropdownMenuItem(value: 'Junior School (JSS)', child: Text('Junior School (JSS) — BECE Template')),
                      ],
                      onChanged: (v) => setDialogState(() => selectedCategory = v),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: sectionCtrl,
                      style: const TextStyle(fontSize: 15, color: Color(0xFF111827)),
                      decoration: InputDecoration(
                        labelText: "Section (e.g A)",
                        labelStyle: TextStyle(color: Colors.grey.shade600),
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFE0E0E0))),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: accentColor)),
                      ),
                    ),
                  ],
                  if (type == "Assignment") ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedClass,
                      decoration: InputDecoration(
                        labelText: "Class",
                        labelStyle: TextStyle(color: Colors.grey.shade600),
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFE0E0E0))),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: accentColor)),
                      ),
                      items: widget.classes.map((c) => DropdownMenuItem(value: c['id'].toString(), child: Text("${c['name']} - ${c['section']}"))).toList(),
                      onChanged: (v) => setDialogState(() => selectedClass = v),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedSubject,
                      decoration: InputDecoration(
                        labelText: "Subject",
                        labelStyle: TextStyle(color: Colors.grey.shade600),
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFE0E0E0))),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: accentColor)),
                      ),
                      items: widget.subjects.map((s) => DropdownMenuItem(value: s['id'].toString(), child: Text(s['name']))).toList(),
                      onChanged: (v) => setDialogState(() => selectedSubject = v),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedTeacher,
                      decoration: InputDecoration(
                        labelText: "Teacher",
                        labelStyle: TextStyle(color: Colors.grey.shade600),
                        border: const OutlineInputBorder(),
                        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFE0E0E0))),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: accentColor)),
                      ),
                      items: widget.teachers.map((t) => DropdownMenuItem(value: t['id'].toString(), child: Text("${t['first_name']} ${t['last_name']}"))).toList(),
                      onChanged: (v) => setDialogState(() => selectedTeacher = v),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) {
                    setDialogState(() => dialogError = 'Name is required.');
                    return;
                  }
                  if (type == "Class") {
                    final section = sectionCtrl.text.trim().isEmpty ? 'A' : sectionCtrl.text.trim();
                    if (_classExists(name, section)) {
                      setDialogState(() => dialogError = 'Class "$name - $section" already exists.');
                      return;
                    }
                    final id = DateTime.now().millisecondsSinceEpoch.toString();
                    widget.onAddClass({'id': id, 'name': name, 'section': section, 'studentCount': 0, 'category': selectedCategory == 'Junior School (JSS)' ? 'JSS' : 'SSS'});
                    Navigator.pop(ctx);
                  } else if (type == "Subject") {
                    if (_subjectExists(name)) {
                      setDialogState(() => dialogError = 'Subject "$name" already exists.');
                      return;
                    }
                    final id = DateTime.now().millisecondsSinceEpoch.toString();
                    widget.onAddSubject({'id': id, 'name': name});
                    Navigator.pop(ctx);
                  } else {
                    final id = DateTime.now().millisecondsSinceEpoch.toString();
                    widget.onAddAssignment({'id': id, 'title': name, 'classId': selectedClass, 'subjectId': selectedSubject, 'teacherId': selectedTeacher});
                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text("Add", style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Confirm Delete Dialog ────────────────────────────────

  void _confirmDelete(String type, Map<String, dynamic> data, VoidCallback onConfirm) {
    final name = type == 'Class'
        ? "${data['name']} - ${data['section']}"
        : type == 'Subject'
            ? data['name']
            : data['title'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.delete_outline_rounded, size: 22, color: Color(0xFFD32F2F)),
            ),
            const SizedBox(width: 12),
            Text("Delete $type", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFF111827), letterSpacing: -0.3)),
          ],
        ),
        content: Text('Are you sure you want to delete "$name"? This action cannot be undone.', style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text("Delete", style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F8FA),
      child: Column(
        children: [
          Container(
            height: 3,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF3949AB), Color(0xFF7B1FA2), Color(0xFFE65100)]),
            ),
          ),
          // ── Header ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Classes & Subjects', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF111827), letterSpacing: -0.5)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _headerChip('${widget.classes.length} Classes', Icons.layers_rounded, const Color(0xFF7B1FA2)),
                    _headerChip('${widget.subjects.length} Subjects', Icons.menu_book_rounded, const Color(0xFF2E7D32)),
                    _headerChip('${widget.assignments.length} Assignments', Icons.assignment_rounded, const Color(0xFFF57F17)),
                  ],
                ),
              ],
            ),
          ),
          // ── Tab Bar ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(top: 18),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF1A237E),
              unselectedLabelColor: Colors.grey.shade500,
              indicatorColor: const Color(0xFF1A237E),
              indicatorWeight: 2.5,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              dividerColor: const Color(0xFFF0F0F0),
              tabs: const [
                Tab(text: "Classes"),
                Tab(text: "Subjects"),
                Tab(text: "Assignments"),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          // ── Tab Content ──
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildClassesTab(),
                _buildSubjectsTab(),
                _buildAssignmentsTab(),
              ],
            ),
          ),
          // ── FAB ──
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: const Color(0xFF1A237E).withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 5))],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _showAddDialog(["Class", "Subject", "Assignment"][_tabController.index]),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 16),
                        Icon(Icons.add, color: Colors.white, size: 22),
                        SizedBox(width: 8),
                        Text('Add New', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                        SizedBox(width: 16),
                      ],
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

  // ── Classes Tab ──────────────────────────────────────────

  Widget _buildClassesTab() {
    if (widget.classes.isEmpty) {
      return _buildEmptyState(icon: Icons.class_outlined, label: 'No classes yet', sublabel: 'Tap "Add New" to create your first class');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: widget.classes.length,
      itemBuilder: (context, index) {
        final c = widget.classes[index];
        final classId = c['id']?.toString();
        final studentCount = widget.students.where((s) => s['class_id']?.toString() == classId).length;
        final subjCount = _getLinksForClass(classId).length;
        final tier = (c['tier'] ?? '').toString();
        final tierClr = tier.isNotEmpty ? _tierColor(tier) : const Color(0xFF9E9E9E);
        final hovered = _hoveredClass == index;

        return MouseRegion(
          onEnter: (_) => setState(() => _hoveredClass = index),
          onExit: (_) => setState(() => _hoveredClass = -1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: hovered ? tierClr.withOpacity(0.03) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: hovered ? tierClr.withOpacity(0.3) : const Color(0xFFE8EAED)),
              boxShadow: hovered ? [BoxShadow(color: tierClr.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))] : [],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 44,
                    decoration: BoxDecoration(color: tierClr, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.class_rounded, size: 22, color: Color(0xFF1A237E)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${c['name']} - ${c['section']}", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 10,
                          runSpacing: 4,
                          children: [
                            _miniStat(Icons.people_outline_rounded, '$studentCount Student${studentCount != 1 ? 's' : ''}'),
                            _miniStat(Icons.menu_book_outlined, '$subjCount Subject${subjCount != 1 ? 's' : ''}'),
                            if (tier.isNotEmpty) _tierBadge(tier),
                          ],
                        ),
                        if (c['formTeacherName'] != null) ...[
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(Icons.person_outline_rounded, size: 12, color: Colors.grey.shade400),
                              const SizedBox(width: 4),
                              Text('FT: ${c['formTeacherName']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  _hoverActionButton(
                    icon: Icons.library_books_outlined,
                    tooltip: 'Manage subjects',
                    accentColor: const Color(0xFF2E7D32),
                    hovered: hovered,
                    onTap: () => _showManageSubjects(c),
                  ),
                  _hoverActionButton(
                    icon: Icons.people_outline_rounded,
                    tooltip: 'View students',
                    accentColor: const Color(0xFF1A237E),
                    hovered: hovered,
                    onTap: () => _showClassDetails(c),
                  ),
                  _hoverActionButton(
                    icon: Icons.delete_outline_rounded,
                    tooltip: 'Delete class',
                    accentColor: Colors.red.shade400,
                    hovered: hovered,
                    onTap: () => _confirmDelete('Class', c, () => widget.onDeleteClass(c)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Subjects Tab ─────────────────────────────────────────

  Widget _buildSubjectsTab() {
    if (widget.subjects.isEmpty) {
      return _buildEmptyState(icon: Icons.menu_book_outlined, label: 'No subjects yet', sublabel: 'Tap "Add New" to create your first subject');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: widget.subjects.length,
      itemBuilder: (context, index) {
        final s = widget.subjects[index];
        final linkedCount = widget.classSubjects.where((cs) => cs['subject_id']?.toString() == s['id']?.toString()).length;
        final hovered = _hoveredSubject == index;
        final code = s['code']?.toString().trim() ?? '';

        return MouseRegion(
          onEnter: (_) => setState(() => _hoveredSubject = index),
          onExit: (_) => setState(() => _hoveredSubject = -1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: hovered ? const Color(0xFF2E7D32).withOpacity(0.03) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: hovered ? const Color(0xFF2E7D32).withOpacity(0.3) : const Color(0xFFE8EAED)),
              boxShadow: hovered ? [BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))] : [],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Container(width: 4, height: 44, decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 14),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: const Color(0xFFF0FFF4), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.menu_book_rounded, size: 22, color: Color(0xFF2E7D32)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['name'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.link_rounded, size: 12, color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Text('$linkedCount class${linkedCount != 1 ? 'es' : ''} linked', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                            if (code.isNotEmpty) ...[
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(4)),
                                child: Text(code, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade600, letterSpacing: 0.5)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  _hoverActionButton(
                    icon: Icons.delete_outline_rounded,
                    tooltip: 'Delete subject',
                    accentColor: Colors.red.shade400,
                    hovered: hovered,
                    onTap: () => _confirmDelete('Subject', s, () => widget.onDeleteSubject(s)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Assignments Tab ──────────────────────────────────────

  Widget _buildAssignmentsTab() {
    if (widget.assignments.isEmpty) {
      return _buildEmptyState(icon: Icons.assignment_outlined, label: 'No assignments yet', sublabel: 'Tap "Add New" to create your first assignment');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: widget.assignments.length,
      itemBuilder: (context, index) {
        final a = widget.assignments[index];
        final hovered = _hoveredAssignment == index;

        return MouseRegion(
          onEnter: (_) => setState(() => _hoveredAssignment = index),
          onExit: (_) => setState(() => _hoveredAssignment = -1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: hovered ? const Color(0xFFF57F17).withOpacity(0.03) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: hovered ? const Color(0xFFF57F17).withOpacity(0.3) : const Color(0xFFE8EAED)),
              boxShadow: hovered ? [BoxShadow(color: const Color(0xFFF57F17).withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))] : [],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Container(width: 4, height: 44, decoration: BoxDecoration(color: const Color(0xFFF57F17), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 14),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.assignment_rounded, size: 22, color: Color(0xFFF57F17)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a['title'] ?? 'Assignment', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                        const SizedBox(height: 4),
                        Text("${_getClassName(a['classId'])}  ·  ${_getSubjectName(a['subjectId'])}", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  _hoverActionButton(
                    icon: Icons.delete_outline_rounded,
                    tooltip: 'Delete assignment',
                    accentColor: Colors.red.shade400,
                    hovered: hovered,
                    onTap: () => _confirmDelete('Assignment', a, () => widget.onDeleteAssignment(a)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Reusable Widgets ────────────────────────────────────

  Widget _headerChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE8EAED))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade400),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _tierBadge(String tier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: _tierBg(tier), borderRadius: BorderRadius.circular(5)),
      child: Text(tier, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _tierColor(tier), letterSpacing: 0.5)),
    );
  }

  Widget _hoverActionButton({
    required IconData icon,
    required String tooltip,
    required Color accentColor,
    required bool hovered,
    required VoidCallback onTap,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: hovered ? 1.0 : 0.5,
      child: SizedBox(
        width: 36,
        height: 36,
        child: IconButton(
          icon: Icon(icon, size: 18, color: hovered ? accentColor : Colors.grey.shade400),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          tooltip: tooltip,
          onPressed: onTap,
        ),
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String label, required String sublabel}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(18)),
              child: Icon(icon, size: 32, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            const SizedBox(height: 6),
            Text(sublabel, style: TextStyle(fontSize: 13, color: Colors.grey.shade400), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

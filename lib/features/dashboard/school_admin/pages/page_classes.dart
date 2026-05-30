import 'package:flutter/material.dart';

class PageClasses extends StatefulWidget {
  final List<Map<String, dynamic>> classes;
  final List<Map<String, dynamic>> subjects;
  final List<Map<String, dynamic>> assignments;
  final List<Map<String, dynamic>> students;
  final List<Map<String, dynamic>> classSubjects;
  final List<Map<String, dynamic>> teachers;
  final Function(Map<String, dynamic>) onAddClass;
  final Function(Map<String, dynamic>) onAddSubject;
  final Function(Map<String, dynamic>) onAddAssignment;
  final Function(Map<String, dynamic>) onDeleteClass;
  final Function(Map<String, dynamic>) onDeleteSubject;
  final Function(Map<String, dynamic>) onDeleteAssignment;
  final Future<bool> Function(String classId, String subjectId)?
      onAddClassSubject;
  final Future<bool> Function(String classSubjectId)? onRemoveClassSubject;

  const PageClasses({
    super.key,
    required this.classes,
    required this.subjects,
    required this.assignments,
    required this.students,
    required this.classSubjects,
    required this.teachers,
    required this.onAddClass,
    required this.onAddSubject,
    required this.onAddAssignment,
    required this.onDeleteClass,
    required this.onDeleteSubject,
    required this.onDeleteAssignment,
    this.onAddClassSubject,
    this.onRemoveClassSubject,
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

  Color _tierColor(String tier) {
    switch (tier) {
      case 'JSS':
        return const Color(0xFFE65100);
      case 'PRIMARY':
        return const Color(0xFF7B1FA2);
      default:
        return const Color(0xFF1565C0);
    }
  }

  Color _tierBg(String tier) {
    switch (tier) {
      case 'JSS':
        return const Color(0xFFFFF3E0);
      case 'PRIMARY':
        return const Color(0xFFF3E5F5);
      default:
        return const Color(0xFFE3F2FD);
    }
  }

  String _getClassName(dynamic classId) {
    if (classId == null) return '-';
    final cid = classId.toString();
    for (final c in widget.classes) {
      if (c['id']?.toString() == cid) {
        return '${c['name']} - ${c['section']}';
      }
    }
    return '-';
  }

  String _getSubjectName(dynamic subjectId) {
    if (subjectId == null) return '-';
    final sid = subjectId.toString();
    for (final s in widget.subjects) {
      if (s['id']?.toString() == sid) return s['name'] ?? '-';
    }
    return '-';
  }

  String _getTeacherName(dynamic teacherId) {
    if (teacherId == null) return '';
    final tid = teacherId.toString();
    for (final t in widget.teachers) {
      if (t['id']?.toString() == tid) {
        return '${t['first_name'] ?? ''} ${t['last_name'] ?? ''}'.trim();
      }
    }
    return '';
  }

  List<Map<String, dynamic>> _getLinksForClass(String classId) {
    return widget.classSubjects
        .where((cs) => cs['class_id']?.toString() == classId)
        .toList();
  }

  bool _classExists(String name, String section) {
    return widget.classes.any((c) =>
        c['name']?.toString().toLowerCase() == name.toLowerCase() &&
        c['section']?.toString().toLowerCase() == section.toLowerCase());
  }

  bool _subjectExists(String name) {
    return widget.subjects.any(
        (s) => s['name']?.toString().toLowerCase() == name.toLowerCase());
  }

  Widget _tierPill(String tier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _tierBg(tier),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        tier,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _tierColor(tier),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _headerChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.grey.shade400),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: accentColor.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: accentColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _deleteBtn(VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red.shade400.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.delete_outline_rounded,
            size: 16, color: Colors.red.shade400),
      ),
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: const Color(0xFFD0D5DD)),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280))),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }

  void _showClassDetails(Map<String, dynamic> classData) {
    final classId = classData['id'].toString();
    final classStudents = widget.students
        .where((s) => s['class_id']?.toString() == classId)
        .toList();
    final tier = classData['tier']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (ctx, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 24,
                offset: Offset(0, -6),
              )
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.class_rounded,
                              size: 24, color: Color(0xFF1A237E)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "${classData['name']} - ${classData['section']}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        if (tier.isNotEmpty) _tierPill(tier),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${classStudents.length} Student${classStudents.length != 1 ? 's' : ''}",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Divider(height: 1, color: Color(0xFFF0F0F0)),
              ),
              Expanded(
                child: classStudents.isEmpty
                    ? const Center(
                        child: Text('No students in this class',
                            style:
                                TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))))
                    : ListView.builder(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: classStudents.length,
                        itemBuilder: (ctx, i) {
                          final s = classStudents[i];
                          final gender = s['gender']?.toString() ?? '';
                          final name =
                              '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'
                                  .trim();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: i.isEven
                                  ? const Color(0xFFFAFBFC)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: gender == 'Female'
                                        ? const Color(0xFFFCE4EC)
                                        : const Color(0xFFE3F2FD),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    gender == 'Female'
                                        ? Icons.girl
                                        : Icons.boy,
                                    size: 16,
                                    color: gender == 'Female'
                                        ? const Color(0xFFE91E63)
                                        : const Color(0xFF1565C0),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    name.isNotEmpty ? name : '-',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                ),
                                Text(
                                  s['admission_no'] ?? '',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showManageSubjects(Map<String, dynamic> classData) {
    final classId = classData['id'].toString();
    final links = _getLinksForClass(classId);
    final linkedIds =
        links.map((cs) => cs['subject_id']?.toString()).toSet();
    final unlinked = widget.subjects
        .where((s) => !linkedIds.contains(s['id']?.toString()))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (ctx, scrollCtrl) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 24,
                  offset: Offset(0, -6),
                )
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FFF4),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.menu_book_rounded,
                                size: 24, color: Color(0xFF2E7D32)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "${classData['name']} - ${classData['section']}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Divider(height: 1, color: Color(0xFFF0F0F0)),
                ),
                if (unlinked.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE8EAED)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              value: null,
                              hint: const Text(
                                'Add a subject...',
                                style: TextStyle(
                                    fontSize: 14, color: Color(0xFF9CA3AF)),
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 0, vertical: 8),
                              ),
                              items: unlinked
                                  .map((s) => DropdownMenuItem<String?>(
                                        value: s['id']?.toString(),
                                        child: Text(
                                          s['name'] ?? '',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF111827)),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (val) async {
                                if (val == null ||
                                    widget.onAddClassSubject == null) return;
                                final ok = await widget
                                    .onAddClassSubject!(classId, val);
                                if (!ctx.mounted) return;
                                if (ok) {
                                  Navigator.pop(ctx);
                                  _showManageSubjects(classData);
                                } else {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                          'Failed to link subject'),
                                      backgroundColor:
                                          const Color(0xFFD32F2F),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (unlinked.isEmpty && links.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.library_books_outlined,
                            size: 48, color: Color(0xFFD0D5DD)),
                        SizedBox(height: 12),
                        Text(
                          'No subjects created yet.\nGo to the Subjects tab to add subjects first.',
                          style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF9CA3AF),
                              height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else if (unlinked.isEmpty && links.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              size: 16, color: Color(0xFF2E7D32)),
                          const SizedBox(width: 8),
                          Text(
                            'All subjects assigned to this class.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.green.shade800,
                            ),
                          ),
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
                              Icon(Icons.link_off_rounded,
                                  size: 40, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text(
                                'No subjects assigned yet',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          controller: scrollCtrl,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: links.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 2),
                          itemBuilder: (ctx, i) {
                            final cs = links[i];
                            final subjId =
                                cs['subject_id']?.toString() ?? '';
                            final csId = cs['id']?.toString() ?? '';
                            final subjName =
                                _getSubjectName(subjId);
                            final isComp =
                                cs['is_compulsory'] == true ||
                                    cs['is_compulsory']
                                        ?.toString() ==
                                        'true';
                            final tId =
                                cs['teacher_id']?.toString();
                            String tLabel =
                                'No teacher assigned';
                            if (tId != null && tId.isNotEmpty) {
                              final tn = _getTeacherName(tId);
                              if (tn.isNotEmpty) tLabel = tn;
                            }
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: i.isEven
                                    ? const Color(0xFFFAFBFC)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: Center(
                                      child: Text(
                                        '${i + 1}',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0FFF4),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                        Icons.menu_book_rounded,
                                        size: 16,
                                        color: Color(0xFF2E7D32)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Text(
                                          subjName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration:
                                                  BoxDecoration(
                                                color: isComp
                                                    ? const Color(
                                                        0xFFE3F2FD)
                                                    : const Color(
                                                        0xFFFFF8E1),
                                                borderRadius:
                                                    BorderRadius
                                                        .circular(
                                                            4),
                                              ),
                                              child: Text(
                                                isComp
                                                    ? 'Core'
                                                    : 'Elective',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight:
                                                      FontWeight
                                                          .w600,
                                                  color: isComp
                                                      ? const Color(
                                                          0xFF1565C0)
                                                      : const Color(
                                                          0xFFF57F17),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(
                                                Icons
                                                    .person_outline_rounded,
                                                size: 11,
                                                color: Colors
                                                    .grey
                                                    .shade400),
                                            const SizedBox(width: 2),
                                            Text(
                                              tLabel,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors
                                                    .grey.shade500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (widget
                                      .onRemoveClassSubject !=
                                      null)
                                    IconButton(
                                      icon: Icon(
                                          Icons.close_rounded,
                                          size: 16,
                                          color: Colors
                                              .red.shade400),
                                      padding: EdgeInsets.zero,
                                      constraints:
                                          const BoxConstraints(),
                                      onPressed: () async {
                                        final ok =
                                            await widget
                                                .onRemoveClassSubject!(
                                                    csId);
                                        if (!ctx.mounted) return;
                                        if (ok) {
                                          Navigator.pop(ctx);
                                          _showManageSubjects(
                                              classData);
                                        } else {
                                          ScaffoldMessenger
                                                  .of(ctx)
                                              .showSnackBar(
                                            SnackBar(
                                              content: const Text(
                                                  'Failed to unlink'),
                                              backgroundColor:
                                                  const Color(
                                                      0xFFD32F2F),
                                              behavior:
                                                  SnackBarBehavior
                                                      .floating,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(
                                                              8)),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddDialog(String type) {
    String name = '';
    String section = '';
    String selectedCategory = 'Senior School (SSS)';
    String? selectedClass;
    String? selectedSubject;
    String? selectedTeacher;
    String dialogError = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: type == 'Class'
                      ? const Color(0xFFF0F4FF)
                      : type == 'Subject'
                          ? const Color(0xFFF0FFF4)
                          : const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  type == 'Class'
                      ? Icons.class_rounded
                      : type == 'Subject'
                          ? Icons.menu_book_rounded
                          : Icons.assignment_rounded,
                  color: type == 'Class'
                      ? const Color(0xFF1A237E)
                      : type == 'Subject'
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFF57F17),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Add $type",
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Color(0xFF111827),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dialogError.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            size: 18, color: Color(0xFFDC2626)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(dialogError,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFDC2626),
                                  height: 1.3)),
                        ),
                      ],
                    ),
                  ),
                if (type == 'Class') ...[
                  const Text('Class Name',
                      style: TextStyle(
                          fontSize: 15, color: Color(0xFF111827))),
                  const SizedBox(height: 6),
                  TextField(
                    onChanged: (v) => name = v.trim(),
                    decoration: InputDecoration(
                      hintText: 'e.g. JSS 1',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      enabledBorder: const OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xFF1A237E)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Section',
                      style: TextStyle(
                          fontSize: 15, color: Color(0xFF111827))),
                  const SizedBox(height: 6),
                  TextField(
                    onChanged: (v) => section = v.trim(),
                    decoration: InputDecoration(
                      hintText: 'e.g. A, B, Science',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      enabledBorder: const OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xFF1A237E)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Category',
                      style: TextStyle(
                          fontSize: 15, color: Color(0xFF111827))),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xFF1A237E)),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'Senior School (SSS)',
                          child: Text('Senior School (SSS)')),
                      DropdownMenuItem(
                          value: 'Junior School (JSS)',
                          child: Text('Junior School (JSS)')),
                      DropdownMenuItem(
                          value: 'Primary School',
                          child: Text('Primary School')),
                    ],
                    onChanged: (v) {
                      if (v != null) selectedCategory = v;
                      setDlg(() {});
                    },
                  ),
                ] else if (type == 'Subject') ...[
                  const Text('Subject Name',
                      style: TextStyle(
                          fontSize: 15, color: Color(0xFF111827))),
                  const SizedBox(height: 6),
                  TextField(
                    onChanged: (v) => name = v.trim(),
                    decoration: InputDecoration(
                      hintText: 'e.g. Mathematics',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      enabledBorder: const OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xFF1A237E)),
                      ),
                    ),
                  ),
                ] else ...[
                  const Text('Assignment Title',
                      style: TextStyle(
                          fontSize: 15, color: Color(0xFF111827))),
                  const SizedBox(height: 6),
                  TextField(
                    onChanged: (v) => name = v.trim(),
                    decoration: InputDecoration(
                      hintText: 'e.g. Chapter 1 Homework',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      enabledBorder: const OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xFF1A237E)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Class',
                      style: TextStyle(
                          fontSize: 15, color: Color(0xFF111827))),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String?>(
                    value: selectedClass,
                    hint: const Text('Select class'),
                    decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xFF1A237E)),
                      ),
                    ),
                    items: widget.classes
                        .map((c) => DropdownMenuItem(
                              value: c['id'].toString(),
                              child: Text(
                                  "${c['name']} - ${c['section']}"),
                            ))
                        .toList(),
                    onChanged: (v) {
                      selectedClass = v;
                      setDlg(() {});
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text('Subject',
                      style: TextStyle(
                          fontSize: 15, color: Color(0xFF111827))),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String?>(
                    value: selectedSubject,
                    hint: const Text('Select subject'),
                    decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xFF1A237E)),
                      ),
                    ),
                    items: widget.subjects
                        .map((s) => DropdownMenuItem(
                              value: s['id'].toString(),
                              child: Text(s['name'] ?? ''),
                            ))
                        .toList(),
                    onChanged: (v) {
                      selectedSubject = v;
                      setDlg(() {});
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text('Teacher',
                      style: TextStyle(
                          fontSize: 15, color: Color(0xFF111827))),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String?>(
                    value: selectedTeacher,
                    hint: const Text('Select teacher'),
                    decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xFF1A237E)),
                      ),
                    ),
                    items: widget.teachers
                        .map((t) => DropdownMenuItem(
                              value: t['id'].toString(),
                              child: Text(
                                  "${t['first_name']} ${t['last_name']}"),
                            ))
                        .toList(),
                    onChanged: (v) {
                      selectedTeacher = v;
                      setDlg(() {});
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (name.isEmpty) {
                  setDlg(() =>
                      dialogError = 'Please fill in the name field');
                  return;
                }
                if (type == 'Class' && section.isEmpty) {
                  setDlg(() =>
                      dialogError = 'Please fill in the section field');
                  return;
                }
                final id = DateTime.now()
                    .millisecondsSinceEpoch
                    .toString();
                if (type == 'Class') {
                  if (_classExists(name, section)) {
                    setDlg(() =>
                        dialogError = 'This class already exists');
                    return;
                  }
                  widget.onAddClass({
                    'id': id,
                    'name': name,
                    'section': section,
                    'studentCount': 0,
                    'class_level':
                        selectedCategory == 'Junior School (JSS)'
                            ? 'JSS'
                            : selectedCategory == 'Primary School'
                                ? 'PRIMARY'
                                : 'SSS',
                  });
                } else if (type == 'Subject') {
                  if (_subjectExists(name)) {
                    setDlg(() =>
                        dialogError = 'This subject already exists');
                    return;
                  }
                  widget.onAddSubject({'id': id, 'name': name});
                } else {
                  widget.onAddAssignment({
                    'id': id,
                    'title': name,
                    'classId': selectedClass,
                    'subjectId': selectedSubject,
                    'teacherId': selectedTeacher,
                  });
                }
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
      String type, Map<String, dynamic> data, VoidCallback onDelete) {
    final name = type == 'Class'
        ? "${data['name']} - ${data['section']}"
        : type == 'Subject'
            ? data['name']
            : data['title'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  size: 22, color: Color(0xFFD32F2F)),
            ),
            const SizedBox(width: 12),
            Text(
              "Delete $type",
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Color(0xFF111827),
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "$name"? This action cannot be undone.',
          style: TextStyle(
              fontSize: 14, color: Colors.grey.shade700, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              onDelete();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [
                Color(0xFF1A237E),
                Color(0xFF3949AB),
                Color(0xFF7B1FA2),
                Color(0xFFE65100)
              ]),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Classes & Subjects',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _headerChip(
                        '${widget.classes.length} Classes',
                        Icons.layers_rounded,
                        const Color(0xFF7B1FA2)),
                    const SizedBox(width: 8),
                    _headerChip(
                        '${widget.subjects.length} Subjects',
                        Icons.menu_book_rounded,
                        const Color(0xFF2E7D32)),
                    const SizedBox(width: 8),
                    _headerChip(
                        '${widget.assignments.length} Assignments',
                        Icons.assignment_rounded,
                        const Color(0xFFF57F17)),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF1A237E),
              unselectedLabelColor: Colors.grey.shade500,
              indicatorColor: const Color(0xFF1A237E),
              indicatorSize: TabBarIndicatorSize.label,
              indicatorWeight: 2.5,
              dividerColor: const Color(0xFFF0F0F0),
              tabs: const [
                Tab(text: 'Classes'),
                Tab(text: 'Subjects'),
                Tab(text: 'Assignments'),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
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
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A237E),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A237E).withOpacity(0.3),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddDialog(
              ['Class', 'Subject', 'Assignment'][_tabController.index]),
          backgroundColor: const Color(0xFF1A237E),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          icon: const Icon(Icons.add, color: Colors.white, size: 22),
          label: const Text(
            'Add New',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  
  Widget _buildClassesTab() {
    if (widget.classes.isEmpty) {
      return _emptyState(Icons.class_rounded, 'No classes yet',
          'Tap "Add New" to create your first class');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.classes.length,
      itemBuilder: (ctx, index) {
        final c = widget.classes[index];
        final classId = c['id'].toString();
        final tier = c['tier']?.toString() ?? '';
        final sCount = widget.students
            .where((s) => s['class_id']?.toString() == classId)
            .length;
        final subCount = _getLinksForClass(classId).length;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8EAED)),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
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
                    Row(
                      children: [
                        Text("${c['name']} - ${c['section']}", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                        if (tier.isNotEmpty) ...[const SizedBox(width: 8), _tierPill(tier)],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('$sCount students  \u00B7  $subCount subjects', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              _actionBtn(label: 'Subjects', icon: Icons.menu_book_rounded, accentColor: const Color(0xFF2E7D32), onTap: () => _showManageSubjects(c)),
              const SizedBox(width: 6),
              _actionBtn(label: 'Students', icon: Icons.people_outline_rounded, accentColor: const Color(0xFF1A237E), onTap: () => _showClassDetails(c)),
              const SizedBox(width: 6),
              _deleteBtn(() => _confirmDelete('Class', c, () => widget.onDeleteClass(c))),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubjectsTab() {
    if (widget.subjects.isEmpty) {
      return _emptyState(Icons.menu_book_rounded, 'No subjects yet',
          'Tap "Add New" to create your first subject');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.subjects.length,
      itemBuilder: (ctx, index) {
        final s = widget.subjects[index];
        final linkedCount = widget.classSubjects.where((cs) => cs['subject_id']?.toString() == s['id']?.toString()).length;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8EAED)),
          ),
          child: Row(
            children: [
              Container(width: 4, height: 44, decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 12),
              Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFF0FFF4), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.menu_book_rounded, size: 22, color: Color(0xFF2E7D32))),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s['name'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(4)),
                      child: Text('$linkedCount class${linkedCount != 1 ? 'es' : ''}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ),
                  ],
                ),
              ),
              _deleteBtn(() => _confirmDelete('Subject', s, () => widget.onDeleteSubject(s))),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAssignmentsTab() {
    if (widget.assignments.isEmpty) {
      return _emptyState(Icons.assignment_rounded, 'No assignments yet',
          'Tap "Add New" to create your first assignment');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.assignments.length,
      itemBuilder: (ctx, index) {
        final a = widget.assignments[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8EAED)),
          ),
          child: Row(
            children: [
              Container(width: 4, height: 44, decoration: BoxDecoration(color: const Color(0xFFF57F17), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 12),
              Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.assignment_rounded, size: 22, color: Color(0xFFF57F17))),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a['title'] ?? 'Assignment', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                    const SizedBox(height: 4),
                    Text("${_getClassName(a['classId'])}  \u00B7  ${_getSubjectName(a['subjectId'])}", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              _deleteBtn(() => _confirmDelete('Assignment', a, () => widget.onDeleteAssignment(a))),
            ],
          ),
        );
      },
    );
  }
}
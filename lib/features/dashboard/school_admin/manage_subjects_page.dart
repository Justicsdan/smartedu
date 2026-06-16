import 'package:smartedu/core/services/db_proxy.dart';
// ==========================================
// File: lib/features/dashboard/school_admin/manage_subjects_page.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartedu/core/providers/school_admin_provider.dart';

class ManageSubjectsPage extends StatefulWidget {
  const ManageSubjectsPage({super.key});

  @override
  State<ManageSubjectsPage> createState() =>
      _ManageSubjectsPageState();
}

class _ManageSubjectsPageState extends State<ManageSubjectsPage> {
  final _subjectController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _classSubjects = [];
  bool _isLoading = true;
  String _schoolId = '';
  String _schoolName = '';
  String? _selectedClassId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _init());
  }

  void _init() {
    final provider = context.read<SchoolAdminProvider>();
    _schoolId = provider.schoolId;
    _schoolName = provider.schoolName;
    if (_schoolId.isEmpty) {
      setState(() => _isLoading = false);
    } else {
      _fetchAll();
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  void _snack(String message, {bool success = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor:
            success ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.only(
            bottom: 24, left: 16, right: 16),
      ),
    );
  }

  Future<void> _fetchAll() async {
    if (_schoolId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        Supabase.instance.client
            .from('subjects')
            .select()
            .eq('school_id', _schoolId)
            .order('name'),
        Supabase.instance.client
            .from('classes')
            .select('id, name, section, tier')
            .eq('school_id', _schoolId)
            .order('name'),
        Supabase.instance.client
            .from('class_subjects')
            .select(
                'id, class_id, subject_id, teacher_id, is_compulsory')
            .eq('school_id', _schoolId),
      ]);
      setState(() {
        _subjects = List<Map<String, dynamic>>.from(results[0]);
        _classes = List<Map<String, dynamic>>.from(results[1]);
        _classSubjects =
            List<Map<String, dynamic>>.from(results[2]);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching data: $e');
      setState(() => _isLoading = false);
      _snack('Error: $e', success: false);
    }
  }

  Set<String> _getLinkedSubjectIds() {
    if (_selectedClassId == null) return {};
    return _classSubjects
        .where((cs) =>
            cs['class_id']?.toString() == _selectedClassId)
        .map((cs) => cs['subject_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  String _className(String? classId) {
    if (classId == null) return '';
    try {
      final c = _classes
          .firstWhere((c) => c['id'] == classId);
      final n = (c['name'] ?? '').toString();
      final s = (c['section'] ?? '').toString();
      return s.isNotEmpty ? '$n — $s' : n;
    } catch (_) {
      return '';
    }
  }

  String _teacherName(String? teacherId) {
    if (teacherId == null) return '';
    try {
      return context
          .read<SchoolAdminProvider>()
          .teachers
          .cast<Map<String, dynamic>?>()
          .firstWhere(
              (t) =>
                  t?['id']?.toString() == teacherId,
              orElse: () => null)
          ?.let((t) =>
              '${t['first_name']} ${t['last_name']}') ??
          '';
    } catch (_) {
      return '';
    }
  }

  List<String> _subjectClassNames(String subjectId) {
    return _classSubjects
        .where((cs) =>
            cs['subject_id']?.toString() == subjectId)
        .map((cs) =>
            _className(cs['class_id']?.toString()))
        .where((n) => n.isNotEmpty)
        .toList();
  }

  Future<void> _addSubject() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _subjectController.text.trim();
    if (name.isEmpty) return;
    try {
      final exists = await DbProxy.instance.from('subjects').select('id').eq('school_id', _schoolId).eq('name', name).maybeSingle();
      if (exists != null) {
        _snack('Subject already exists!', success: false);
        return;
      }
      await DbProxy.instance.from('subjects').insert({
        'name': name,
        'school_id': _schoolId,
      });
      _subjectController.clear();
      _fetchAll();
      if (mounted) {
        Navigator.pop(context);
        _snack('Subject added successfully!');
      }
    } catch (e) {
      debugPrint('Error adding subject: $e');
      _snack('Error: $e', success: false);
    }
  }

  Future<void> _deleteSubject(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    size: 24, color: Color(0xFFDC2626)),
              ),
              const SizedBox(height: 16),
              const Text('Delete Subject?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827)),
              ),
              const SizedBox(height: 8),
              Text(
                  'Delete "$name"? This cannot be undone.\n\nNote: This will also remove the subject from all classes.',
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600),
                      textAlign: TextAlign.center),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Delete',
                          style: TextStyle(
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true) return;
    try {
      await DbProxy.instance.from('class_subjects').eq('subject_id', id).eq('school_id', _schoolId).delete();
      await DbProxy.instance.from('subjects').eq('id', id).eq('school_id', _schoolId).delete();
      _fetchAll();
      _snack('Subject deleted successfully!');
    } catch (e) {
      debugPrint('Error deleting subject: $e');
      _snack('Error: $e', success: false);
    }
  }

  void _showAddDialog() {
    _subjectController.clear();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FFF4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.menu_book_rounded,
                        size: 22, color: Color(0xFF2E7D32)),
                  ),
                  const SizedBox(width: 14),
                  const Text('Add New Subject',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827)),
                ],
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _subjectController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Subject Name',
                    labelStyle: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                    hintText: 'e.g. Mathematics',
                    hintStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.book_outlined,
                        size: 20,
                        color: Color(0xFF1A237E)),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color(0xFF1A237E), width: 2),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFAFBFC),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  validator: (val) =>
                      val == null || val.trim().isEmpty
                          ? 'Enter subject name'
                          : null,
                  onFieldSubmitted: (_) => _addSubject(),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10)),
                        padding:
                            const EdgeInsets.symmetric(
                                vertical: 12),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _addSubject();
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10)),
                        padding:
                            const EdgeInsets.symmetric(
                                vertical: 12),
                      ),
                      child: const Text('Add Subject',
                          style: TextStyle(
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_schoolId.isEmpty && !_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: AppBar(
          title: const Text('Manage Subjects',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
          backgroundColor: const Color(0xFF1A237E),
          foregroundColor: Colors.white,
          elevation: 0,
          iconTheme:
              const IconThemeData(color: Colors.white),
        ),
        body: Center(
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
                child: Icon(Icons.error_outline_rounded,
                    size: 36, color: Colors.red.shade400),
              ),
              const SizedBox(height: 16),
              const Text('Session error',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  )),
              const SizedBox(height: 8),
              Text('Log out and log in again.',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  )),
            ],
          ),
        ),
      );
    }

    final linkedIds = _getLinkedSubjectIds();
    final isFiltered = _selectedClassId != null;
    final displaySubjects = isFiltered
        ? _subjects
              .where(
                  (s) =>
                      linkedIds.contains(s['id']?.toString()))
              .toList()
        : _subjects;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text(
          _schoolName.isNotEmpty
              ? 'Subjects — $_schoolName'
              : 'Manage Subjects',
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 16),
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme:
            const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _showAddDialog,
              child: Container(
                height: 36,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded,
                        size: 18, color: Colors.white),
                    SizedBox(width: 6),
                    Text('Add Subject',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 3))
          : Column(
              children: [
                // Class filter
                Container(
                  margin: const EdgeInsets.fromLTRB(
                      16, 0, 16, 12),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: const Color(0xFFE8EAED)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.only(
                              left: 12, right: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAFBFC),
                            borderRadius:
                                BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFFE8EAED)),
                          ),
                          alignment: Alignment.centerLeft,
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedClassId,
                              hint: Text('Filter by Class',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        Colors.grey.shade500)),
                              icon: const Icon(Icons.filter_list_rounded,
                                  size: 18,
                                  color:
                                      Color(0xFF1A237E)
                                          .withOpacity(0.7)),
                              isExpanded: true,
                              items: [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text('All Subjects',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight:
                                              FontWeight.w600,
                                          color: Color(
                                              0xFF111827))),
                                ),
                                ..._classes.map((c) {
                                  final display =
                                      _className(
                                          c['id']
                                              ?.toString());
                                  return DropdownMenuItem(
                                    value:
                                        c['id']
                                            ?.toString(),
                                    child: Text(display,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight:
                                                FontWeight.w600,
                                            color: Color(
                                                0xFF111827)),
                                        overflow:
                                            TextOverflow
                                                .ellipsis)),
                                  );
                                }),
                              ],
                              onChanged: (v) => setState(
                                  () =>
                                      _selectedClassId = v),
                            ),
                          ),
                        ),
                      ),
                      if (isFiltered)
                        InkWell(
                          borderRadius:
                              BorderRadius.circular(6),
                          onTap: () => setState(
                              () =>
                                  _selectedClassId =
                                      null),
                          child: Container(
                            height: 28,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A237E)
                                  .withOpacity(0.08),
                              borderRadius:
                                  BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize:
                                  MainAxisSize.min,
                              children: [
                                Icon(
                                    Icons.clear_rounded,
                                    size: 14,
                                    color: const Color(
                                        0xFF1A237E)),
                                SizedBox(width: 4),
                                Text('Clear',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight:
                                          FontWeight.w600,
                                      color: const Color(
                                          0xFF1A237E)),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Filter info
                if (isFiltered) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A237E)
                          .withOpacity(0.06),
                      borderRadius:
                          BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFF1A237E)
                              .withOpacity(0.12)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 15,
                            color: const Color(0xFF1A237E)
                                .withOpacity(0.6)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Showing ${displaySubjects.length} of ${_subjects.length} subjects assigned to ${_className(_selectedClassId)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A237E)
                                  .withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // List
                Expanded(
                  child: displaySubjects.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color:
                                      Colors.grey.shade100,
                                  borderRadius:
                                      BorderRadius.circular(18),
                                ),
                                child: Icon(
                                    Icons
                                        .menu_book_outlined,
                                    size: 36,
                                    color:
                                        Colors.grey.shade400),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                  isFiltered
                                      ? 'No subjects assigned to this class'
                                      : 'No subjects yet',
                                  style: TextStyle(
                                    color:
                                        Colors.grey.shade700,
                                    fontSize: 15,
                                    fontWeight:
                                        FontWeight.w500,
                                  ),
                              ),
                              if (!isFiltered) ...[
                                const SizedBox(height: 12),
                                InkWell(
                                  borderRadius:
                                      BorderRadius.circular(8),
                                  onTap: _showAddDialog,
                                  child: Container(
                                    height: 42,
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 20),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                          0xFF1A237E),
                                      borderRadius:
                                          BorderRadius
                                              .circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize:
                                          MainAxisSize.min,
                                      children: [
                                        Icon(
                                            Icons.add_rounded,
                                            size: 18,
                                            color: Colors.white),
                                        SizedBox(width: 8),
                                        Text(
                                            'Add Subject',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight:
                                                  FontWeight.w600,
                                              color: Colors
                                                  .white),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12),
                          itemCount:
                              displaySubjects.length,
                          itemBuilder:
                              (context, index) {
                            final subject =
                                displaySubjects[index];
                            final name = subject['name']
                                    ?.toString() ??
                                'Unknown';
                            final id = subject['id']
                                    ?.toString() ??
                                '';
                            final code =
                                (subject['code'] ?? '')
                                    .toString()
                                    .trim();

                            Map<String, dynamic>?
                                csRow;
                            if (isFiltered &&
                                _selectedClassId !=
                                    null) {
                              try {
                                csRow = _classSubjects
                                    .firstWhere((cs) =>
                                        cs['subject_id']
                                                ?.toString() ==
                                            id &&
                                        cs['class_id']
                                                ?.toString() ==
                                            _selectedClassId);
                              } catch (_) {}
                            }

                            final isCompulsory =
                                csRow?['is_compulsory'] ==
                                    true;
                            final teacherId =
                                csRow?['teacher_id']
                                    ?.toString();
                            final teacherName =
                                _teacherName(teacherId);

                            final bgColor = index % 2 == 0
                                ? Colors.white
                                : const Color(0xFFFAFBFC);

                            return Container(
                              margin:
                                  const EdgeInsets.only(
                                      bottom: 8),
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius:
                                    BorderRadius.circular(10),
                                border: Border.all(
                                    color: const Color(
                                        0xFFE8EAED)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration:
                                        BoxDecoration(
                                      color: isCompulsory
                                          ? const Color(
                                              0xFF1A237E)
                                          : const Color(
                                              0xFFFFF3E0),
                                      borderRadius:
                                          BorderRadius
                                              .circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        name.isNotEmpty
                                            ? name.substring(
                                                0, 1)
                                                .toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight:
                                              FontWeight.bold,
                                          color: isCompulsory
                                              ? Colors.white
                                              : const Color(
                                                  0xFFE65100),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight:
                                                FontWeight.w600,
                                            color: Color(
                                                0xFF111827)),
                                        overflow:
                                            TextOverflow
                                                .ellipsis,
                                      ),
                                        if (code.isNotEmpty)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(
                                                    top: 2),
                                            child: Text(
                                              code,
                                              style:
                                                  const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(
                                                        0xFF9CA3AF)),
                                            ),
                                          ),
                                        if (isFiltered) ...[
                                          const SizedBox(
                                              height: 6),
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
                                                  color: isCompulsory
                                                      ? const Color(
                                                          0xFF1A237E)
                                                          .withOpacity(
                                                              0.1)
                                                      : Colors
                                                          .orange
                                                              .shade50,
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(
                                                              4),
                                                ),
                                                child: Text(
                                                  isCompulsory
                                                      ? 'Core'
                                                      : 'Elective',
                                                  style: TextStyle(
                                                    fontSize:
                                                        10,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: isCompulsory
                                                        ? const Color(
                                                            0xFF1A237E)
                                                        : const Color(
                                                            0xFFE65100),
                                                  ),
                                                ),
                                              ),
                                              if (teacherName
                                                  .isNotEmpty) ...[
                                                const SizedBox(
                                                    width: 6),
                                                Icon(
                                                    Icons
                                                        .person_outline,
                                                    size: 13,
                                                    color: Colors
                                                        .grey
                                                        .shade500),
                                                ),
                                                const SizedBox(
                                                    width: 3),
                                                Expanded(
                                                  child: Text(
                                                    teacherName,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          Color(
                                                              0xFF555555),
                                                      overflow:
                                                          TextOverflow
                                                              .ellipsis),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(
                                      width: 8),
                                  InkWell(
                                    borderRadius:
                                        BorderRadius
                                            .circular(6),
                                    onTap: () =>
                                        _deleteSubject(
                                            id, name),
                                    child: Container(
                                      height: 32,
                                      width: 32,
                                      decoration:
                                          BoxDecoration(
                                            border: Border.all(
                                              color: Colors
                                                  .red.shade400
                                                  .withOpacity(
                                                      0.3)),
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                          6),
                                            ),
                                      child: const Icon(
                                        Icons
                                            .delete_outline_rounded,
                                        size: 16,
                                        color: Colors
                                            .red.shade400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                  },
                ),
              ],
            );
      ),
    );
  }
}

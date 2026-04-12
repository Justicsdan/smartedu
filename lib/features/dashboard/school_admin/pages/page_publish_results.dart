import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartedu/core/providers/school_admin_provider.dart';
import 'package:smartedu/utils/grading_utils.dart';

class PagePublishResults extends StatefulWidget {
  const PagePublishResults({super.key});

  @override
  State<PagePublishResults> createState() => _PagePublishResultsState();
}

class _PagePublishResultsState extends State<PagePublishResults> {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? _selectedClassId;
  bool _isLoadingData = false;
  bool _isComputing = false;
  bool _isPublishing = false;

  // Fetched from DB
  List<Map<String, dynamic>> _summaries = [];
  List<Map<String, dynamic>> _comments = [];

  // Editable student data: key = student_id
  final Map<String, Map<String, dynamic>> _studentData = {};

  // =========================================================
  // PROVIDER SHORTCUTS
  // =========================================================

  SchoolAdminProvider get _provider => context.read<SchoolAdminProvider>();
  String get _sessionId => _provider.currentSession?['id']?.toString() ?? '';
  String get _termId => _provider.currentTerm?['id']?.toString() ?? '';

  // =========================================================
  // FILTERED DATA
  // =========================================================

  List<Map<String, dynamic>> get _studentsInClass {
    if (_selectedClassId == null) return [];
    return _provider.students
        .where((s) => s['class_id']?.toString() == _selectedClassId)
        .toList();
  }

  Map<String, dynamic>? get _selectedClass {
    if (_selectedClassId == null) return null;
    try {
      return _provider.classes.firstWhere((c) => c['id'] == _selectedClassId);
    } catch (_) {
      return null;
    }
  }

  String get _classTier => (_selectedClass?['tier'] ?? '').toString();

  List<Map<String, dynamic>> get _gradingSystem =>
      GradingUtils.getGradingSystemForTier(
          _classTier, _provider.schoolSettings ?? {});

  Map<String, dynamic>? _summaryFor(String? studentId) {
    if (studentId == null) return null;
    try {
      return _summaries.firstWhere((s) => s['student_id'] == studentId);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _commentFor(String? studentId) {
    if (studentId == null) return null;
    try {
      return _comments.firstWhere((c) => c['student_id'] == studentId);
    } catch (_) {
      return null;
    }
  }

  // =========================================================
  // NAME HELPERS (Iron Rule #8)
  // =========================================================

  String _sName(Map<String, dynamic> s) {
    final f = (s['first_name'] ?? '').toString().trim();
    final l = (s['last_name'] ?? '').toString().trim();
    if (f.isNotEmpty && l.isNotEmpty) return '$f $l';
    if (f.isNotEmpty) return f;
    if (l.isNotEmpty) return l;
    return '';
  }

  // =========================================================
  // DATA LOADING
  // =========================================================

  Future<void> _loadData() async {
    if (_selectedClassId == null || _sessionId.isEmpty || _termId.isEmpty) {
      return;
    }
    setState(() => _isLoadingData = true);
    try {
      await Future.wait([
        _loadSummaries(),
        _loadComments(),
      ]);
      _prefillStudentData();
    } catch (e) {
      debugPrint('Error loading publish data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _loadSummaries() async {
    final r = await _supabase
        .from('student_term_summaries')
        .select()
        .eq('school_id', _provider.schoolId)
        .eq('class_id', _selectedClassId!)
        .eq('session_id', _sessionId)
        .eq('term_id', _termId);
    _summaries = List<Map<String, dynamic>>.from(r);
  }

  Future<void> _loadComments() async {
    final r = await _supabase
        .from('term_comments')
        .select()
        .eq('school_id', _provider.schoolId)
        .eq('class_id', _selectedClassId!)
        .eq('session_id', _sessionId)
        .eq('term_id', _termId);
    _comments = List<Map<String, dynamic>>.from(r);
  }

  void _prefillStudentData() {
    _studentData.clear();
    for (final s in _studentsInClass) {
      final sid = s['id']?.toString() ?? '';
      final summary = _summaryFor(sid);
      final comment = _commentFor(sid);
      _studentData[sid] = {
        'days_present': summary?['days_present'] ?? 0,
        'days_absent': summary?['days_absent'] ?? 0,
        'teacher_comment': comment?['teacher_comment'] ?? '',
        'principal_comment': comment?['principal_comment'] ?? '',
        'conduct': comment?['conduct'] ?? 'Good',
        'attitude': comment?['attitude'] ?? 'Good',
        'interest': comment?['interest'] ?? 'Good',
        'attendance_remark': comment?['attendance_remark'] ?? '',
      };
    }
  }

  // =========================================================
  // COMPUTE SUMMARIES
  // =========================================================

  Future<void> _computeSummaries() async {
    if (_selectedClassId == null) return;
    setState(() => _isComputing = true);
    try {
      final students = _studentsInClass;
      if (students.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('No students in this class')));
        }
        return;
      }

      int withScores = 0;
      final allStudentSummaries = <Map<String, dynamic>>[];

      for (final student in students) {
        final sid = student['id'];
        final studentScores = _provider.scores.where((s) =>
            s['student_id'] == sid &&
            s['session_id']?.toString() == _sessionId &&
            s['term_id']?.toString() == _termId).toList();

        if (studentScores.isNotEmpty) withScores++;

        final summary = GradingUtils.computeStudentSummary(
          studentScores: studentScores,
          gradingSystem: _gradingSystem,
        );

        allStudentSummaries.add({'student_id': sid, ...summary});
      }

      // Warn if some students have no scores
      if (withScores < students.length) {
        if (!mounted) return;
        final shouldContinue = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Incomplete Scores'),
            content: Text(
                '$withScores of ${students.length} students have scores. '
                'Students without scores will get 0 total.\n\nContinue?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Continue')),
            ],
          ),
        );
        if (shouldContinue != true) return;
      }

      // Rank positions
      final ranked =
          GradingUtils.computeClassPositions(allStudentSummaries);

      // Delete existing summaries for this class/session/term
      await _supabase
          .from('student_term_summaries')
          .delete()
          .eq('school_id', _provider.schoolId)
          .eq('class_id', _selectedClassId!)
          .eq('session_id', _sessionId)
          .eq('term_id', _termId);

      // Insert new summaries
      final inserts = ranked.map((r) {
        final sid = (r['student_id'] as String?) ?? '';
        final data = _studentData[sid] ?? {};
        final existingSummary = _summaryFor(sid);
        return {
          'school_id': _provider.schoolId,
          'student_id': sid,
          'class_id': _selectedClassId,
          'session_id': _sessionId,
          'term_id': _termId,
          'total_score': r['total_score'],
          'subjects_taken': r['subjects_taken'],
          'average_score': r['average_score'],
          'grade': r['grade'],
          'position': r['position'],
          'position_out_of': r['position_out_of'],
          'days_present': data['days_present'] ?? 0,
          'days_absent': data['days_absent'] ?? 0,
          'is_published': existingSummary?['is_published'] ?? false,
          'published_at': existingSummary?['published_at'],
          'published_by': existingSummary?['published_by'],
        };
      }).toList();

      if (inserts.isNotEmpty) {
        await _supabase.from('student_term_summaries').insert(inserts);
      }

      await _loadSummaries();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Summaries computed successfully!'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      debugPrint('Compute error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Compute error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isComputing = false);
    }
  }

  // =========================================================
  // PUBLISH / UNPUBLISH
  // =========================================================

  Future<void> _publishAll() async {
    if (_selectedClassId == null) return;
    setState(() => _isPublishing = true);
    try {
      await _supabase
          .from('student_term_summaries')
          .update({
            'is_published': true,
            'published_at': DateTime.now().toIso8601String(),
            'published_by': _provider.currentUserId,
          })
          .eq('school_id', _provider.schoolId)
          .eq('class_id', _selectedClassId!)
          .eq('session_id', _sessionId)
          .eq('term_id', _termId);

      await _loadSummaries();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Results published!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Publish error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  Future<void> _unpublishAll() async {
    if (_selectedClassId == null) return;
    setState(() => _isPublishing = true);
    try {
      await _supabase
          .from('student_term_summaries')
          .update({
            'is_published': false,
            'published_at': null,
            'published_by': null,
          })
          .eq('school_id', _provider.schoolId)
          .eq('class_id', _selectedClassId!)
          .eq('session_id', _sessionId)
          .eq('term_id', _termId);

      await _loadSummaries();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Results unpublished.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  Future<void> _togglePublishOne(String studentId, bool publish) async {
    try {
      await _supabase
          .from('student_term_summaries')
          .update({
            'is_published': publish,
            'published_at': publish ? DateTime.now().toIso8601String() : null,
            'published_by': publish ? _provider.currentUserId : null,
          })
          .eq('school_id', _provider.schoolId)
          .eq('student_id', studentId)
          .eq('class_id', _selectedClassId!)
          .eq('session_id', _sessionId)
          .eq('term_id', _termId);

      await _loadSummaries();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  // =========================================================
  // SAVE COMMENTS & ATTENDANCE
  // =========================================================

  Future<void> _saveStudentData(String studentId) async {
    final data = _studentData[studentId];
    if (data == null) return;
    try {
      // Upsert term_comments
      final existing = _commentFor(studentId);
      if (existing != null) {
        await _supabase.from('term_comments').update({
          'teacher_comment': data['teacher_comment'] ?? '',
          'principal_comment': data['principal_comment'] ?? '',
          'conduct': data['conduct'] ?? '',
          'attitude': data['attitude'] ?? '',
          'interest': data['interest'] ?? '',
          'attendance_remark': data['attendance_remark'] ?? '',
        }).eq('id', existing['id']);
      } else {
        await _supabase.from('term_comments').insert({
          'school_id': _provider.schoolId,
          'student_id': studentId,
          'class_id': _selectedClassId,
          'session_id': _sessionId,
          'term_id': _termId,
          'teacher_comment': data['teacher_comment'] ?? '',
          'principal_comment': data['principal_comment'] ?? '',
          'conduct': data['conduct'] ?? '',
          'attitude': data['attitude'] ?? '',
          'interest': data['interest'] ?? '',
          'attendance_remark': data['attendance_remark'] ?? '',
        });
      }

      // Update days in summary if it exists
      final summary = _summaryFor(studentId);
      if (summary != null) {
        await _supabase.from('student_term_summaries').update({
          'days_present': data['days_present'] ?? 0,
          'days_absent': data['days_absent'] ?? 0,
        }).eq('id', summary['id']);
        await _loadSummaries();
      }

      await _loadComments();
      if (mounted) setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Saved!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Save error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  // =========================================================
  // EDIT BOTTOM SHEET
  // =========================================================

  void _showEditSheet(Map<String, dynamic> student) {
    final sid = student['id']?.toString() ?? '';
    final name = _sName(student);
    final data = Map<String, dynamic>.from(_studentData[sid] ?? {});

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => _StudentEditSheet(
        studentName: name,
        initialData: data,
        showConduct: _provider.showConduct,
        showTeacherComment: _provider.showTeacherComment,
        showPrincipalComment: _provider.showPrincipalComment,
        showAttendance: _provider.showAttendanceSummary,
        onSave: (updated) {
          setState(() => _studentData[sid] = updated);
          _saveStudentData(sid);
        },
      ),
    );
  }

  // =========================================================
  // STATUS HELPERS
  // =========================================================

  String _statusOf(String? studentId) {
    final s = _summaryFor(studentId);
    if (s == null) return 'none';
    return (s['is_published'] == true) ? 'published' : 'draft';
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SchoolAdminProvider>();
    final students = _studentsInClass;
    final sessionName = provider.currentSession?['name'] ?? '';
    final termName = provider.currentTerm?['name'] ?? '';

    int computed = 0;
    int published = 0;
    for (final s in students) {
      final st = _statusOf(s['id']?.toString());
      if (st == 'published') {
        computed++;
        published++;
      } else if (st == 'draft') {
        computed++;
      }
    }

    return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(children: [
              const Text('Publish Results',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E))),
              const Spacer(),
              if (_isLoadingData || _isComputing || _isPublishing)
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
            ]),
            const SizedBox(height: 4),
            Text('$sessionName — $termName',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),

            // Class selector
            DropdownButtonFormField<String>(
              value: _selectedClassId,
              decoration: InputDecoration(
                labelText: 'Select Class',
                labelStyle: const TextStyle(fontSize: 12),
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                isDense: true,
                prefixIcon:
                    const Icon(Icons.layers, color: Color(0xFF1A237E)),
              ),
              items: provider.classes.map((c) {
                final n = (c['name'] ?? '').toString();
                final sec = (c['section'] ?? '').toString();
                final tier = (c['tier'] ?? '').toString();
                final label = sec.isNotEmpty ? '$n - $sec' : n;
                final tierLabel = tier.isNotEmpty ? ' [$tier]' : '';
                return DropdownMenuItem(
                    value: c['id']?.toString(),
                    child: Text('$label$tierLabel',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis));
              }).toList(),
              onChanged: (v) {
                setState(() {
                  _selectedClassId = v;
                  _summaries = [];
                  _comments = [];
                  _studentData.clear();
                });
                if (v != null) _loadData();
              },
            ),
            const SizedBox(height: 12),

            // Action buttons
            if (_selectedClassId != null) ...[
              Row(children: [
                Expanded(
                    child: ElevatedButton.icon(
                  onPressed: _isComputing ? null : _computeSummaries,
                  icon: _isComputing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.calculate, size: 16),
                  label: Text(_isComputing ? 'Computing...' : 'Compute',
                      style: const TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  ),
                )),
                const SizedBox(width: 6),
                Expanded(
                    child: ElevatedButton.icon(
                  onPressed:
                      (_isPublishing || computed == 0) ? null : _publishAll,
                  icon: const Icon(Icons.check_circle, size: 16),
                  label: Text('Publish ($published/$computed)',
                      style: const TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  ),
                )),
                const SizedBox(width: 6),
                Expanded(
                    child: OutlinedButton.icon(
                  onPressed:
                      (_isPublishing || published == 0) ? null : _unpublishAll,
                  icon: const Icon(Icons.undo, size: 16),
                  label: const Text('Unpublish',
                      style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  ),
                )),
              ]),
              const SizedBox(height: 8),

              // Info banner
              Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(
                      '${students.length} students • $computed computed • $published published • Tier: $_classTier',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF1A237E)))),
              const SizedBox(height: 12),

              // Table
              if (_isLoadingData)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator()))
              else if (students.isEmpty)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('No students in this class',
                            style: TextStyle(color: Colors.grey))))
              else ...[
                // Header row
                Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 8),
                    decoration: const BoxDecoration(
                        color: Color(0xFF1A237E),
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(8))),
                    child: const Row(children: [
                      SizedBox(
                          width: 28,
                          child: Text('#',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10))),
                      SizedBox(
                          width: 130,
                          child: Text('Student',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10))),
                      SizedBox(
                          width: 42,
                          child: Text('Total',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10))),
                      SizedBox(
                          width: 42,
                          child: Text('Avg',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10))),
                      SizedBox(
                          width: 32,
                          child: Text('Grade',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10))),
                      SizedBox(
                          width: 32,
                          child: Text('Pos',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10))),
                      SizedBox(
                          width: 65,
                          child: Text('Days',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10))),
                      SizedBox(
                          width: 70,
                          child: Text('Status',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10))),
                      SizedBox(width: 32, child: SizedBox()),
                    ])),

                // Student rows
                ...students.asMap().entries.map((entry) {
                  final s = entry.value;
                  final sid = s['id']?.toString() ?? '';
                  final summary = _summaryFor(sid);
                  final status = _statusOf(sid);
                  final total =
                      (summary?['total_score'] as num?)?.toInt() ?? 0;
                  final avg =
                      (summary?['average_score'] as num?)?.toDouble() ?? 0;
                  final grade = (summary?['grade'] ?? '').toString();
                  final pos = summary?['position'];
                  final posOut = summary?['position_out_of'];
                  final daysP =
                      (summary?['days_present'] as num?)?.toInt() ?? 0;
                  final daysA =
                      (summary?['days_absent'] as num?)?.toInt() ?? 0;

                  return Container(
                      margin: const EdgeInsets.only(bottom: 1),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: entry.key % 2 == 0
                              ? Colors.white
                              : Colors.grey.shade50),
                      child: Row(children: [
                        SizedBox(
                            width: 28,
                            child: Text('${entry.key + 1}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.grey))),
                        SizedBox(
                            width: 130,
                            child: Text(_sName(s),
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis)),
                        SizedBox(
                            width: 42,
                            child: Text(summary != null ? '$total' : '-',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: summary != null
                                        ? Colors.black87
                                        : Colors.grey))),
                        SizedBox(
                            width: 42,
                            child: Text(
                                summary != null
                                    ? avg.toStringAsFixed(1)
                                    : '-',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: summary != null
                                        ? Colors.black87
                                        : Colors.grey))),
                        SizedBox(
                            width: 32,
                            child: Text(
                                grade.isNotEmpty ? grade : '-',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: grade.isNotEmpty
                                        ? (GradingUtils.isPassingGrade(
                                                grade, _gradingSystem)
                                            ? Colors.green
                                            : Colors.red)
                                        : Colors.grey))),
                        SizedBox(
                            width: 32,
                            child: Text(
                                pos != null ? '$pos/$posOut' : '-',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 10))),
                        SizedBox(
                            width: 65,
                            child: Text(
                                summary != null
                                    ? 'P:$daysP A:$daysA'
                                    : '-',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 9,
                                    color: summary != null
                                        ? Colors.black87
                                        : Colors.grey))),
                        SizedBox(
                            width: 70,
                            child: Center(
                                child: _buildStatusBadge(status))),
                        SizedBox(
                            width: 32,
                            height: 32,
                            child: IconButton(
                                icon: const Icon(Icons.edit,
                                    size: 14, color: Color(0xFF1A237E)),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 24, minHeight: 24),
                                onPressed: () => _showEditSheet(s),
                                tooltip: 'Edit comments & attendance')),
                      ]));
                }),

                // Bottom border
                Container(
                    height: 4,
                    decoration: const BoxDecoration(
                        color: Color(0xFF1A237E),
                        borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(8)))),
              ],
            ] else
              Container(
                  padding: const EdgeInsets.all(40),
                  child: Column(children: [
                    Icon(Icons.publish, size: 56, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text('Select a class to manage results',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade500)),
                  ])),
            const SizedBox(height: 24),
          ],
        ));
  }

  Widget _buildStatusBadge(String status) {
    switch (status) {
      case 'published':
        return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10)),
            child: const Text('Published',
                style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green)));
      case 'draft':
        return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10)),
            child: const Text('Draft',
                style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.bold, color: Colors.orange)));
      default:
        return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10)),
            child: const Text('Not Set',
                style: TextStyle(fontSize: 9, color: Colors.grey)));
    }
  }
}

// =========================================================
// STUDENT EDIT SHEET (Comments, Attendance, Behavior)
// =========================================================

class _StudentEditSheet extends StatefulWidget {
  final String studentName;
  final Map<String, dynamic> initialData;
  final bool showConduct;
  final bool showTeacherComment;
  final bool showPrincipalComment;
  final bool showAttendance;
  final void Function(Map<String, dynamic> updated) onSave;

  const _StudentEditSheet({
    required this.studentName,
    required this.initialData,
    required this.showConduct,
    required this.showTeacherComment,
    required this.showPrincipalComment,
    required this.showAttendance,
    required this.onSave,
  });

  @override
  State<_StudentEditSheet> createState() => _StudentEditSheetState();
}

class _StudentEditSheetState extends State<_StudentEditSheet> {
  late TextEditingController _teacherCommentCtrl;
  late TextEditingController _principalCommentCtrl;
  late TextEditingController _attendanceRemarkCtrl;
  late TextEditingController _daysPresentCtrl;
  late TextEditingController _daysAbsentCtrl;
  late String _conduct;
  late String _attitude;
  late String _interest;

  @override
  void initState() {
    super.initState();
    _teacherCommentCtrl =
        TextEditingController(text: (widget.initialData['teacher_comment'] ?? '').toString());
    _principalCommentCtrl =
        TextEditingController(text: (widget.initialData['principal_comment'] ?? '').toString());
    _attendanceRemarkCtrl =
        TextEditingController(text: (widget.initialData['attendance_remark'] ?? '').toString());
    _daysPresentCtrl =
        TextEditingController(text: (widget.initialData['days_present'] ?? 0).toString());
    _daysAbsentCtrl =
        TextEditingController(text: (widget.initialData['days_absent'] ?? 0).toString());
    _conduct = (widget.initialData['conduct'] ?? 'Good').toString();
    _attitude = (widget.initialData['attitude'] ?? 'Good').toString();
    _interest = (widget.initialData['interest'] ?? 'Good').toString();
  }

  @override
  void dispose() {
    _teacherCommentCtrl.dispose();
    _principalCommentCtrl.dispose();
    _attendanceRemarkCtrl.dispose();
    _daysPresentCtrl.dispose();
    _daysAbsentCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.onSave({
      'teacher_comment': _teacherCommentCtrl.text.trim(),
      'principal_comment': _principalCommentCtrl.text.trim(),
      'attendance_remark': _attendanceRemarkCtrl.text.trim(),
      'days_present': int.tryParse(_daysPresentCtrl.text.trim()) ?? 0,
      'days_absent': int.tryParse(_daysAbsentCtrl.text.trim()) ?? 0,
      'conduct': _conduct,
      'attitude': _attitude,
      'interest': _interest,
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
              // Header
              Row(children: [
                Expanded(
                    child: Text(widget.studentName,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E)))),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ]),
              const Divider(),

              // Attendance
              if (widget.showAttendance) ...[
                const Text('Attendance',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E))),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                      child: TextField(
                    controller: _daysPresentCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Days Present',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 8, vertical: 10)),
                  )),
                  const SizedBox(width: 12),
                  Expanded(
                      child: TextField(
                    controller: _daysAbsentCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Days Absent',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 8, vertical: 10)),
                  )),
                ]),
                const SizedBox(height: 8),
                TextField(
                  controller: _attendanceRemarkCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Attendance Remark',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10)),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
              ],

              // Behavioral ratings
              if (widget.showConduct) ...[
                const Text('Behavioral Ratings',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E))),
                const SizedBox(height: 8),
                _buildDropdown(
                    'Conduct', _conduct, (v) => setState(() => _conduct = v)),
                const SizedBox(height: 8),
                _buildDropdown('Attitude', _attitude,
                    (v) => setState(() => _attitude = v)),
                const SizedBox(height: 8),
                _buildDropdown('Interest', _interest,
                    (v) => setState(() => _interest = v)),
                const SizedBox(height: 16),
              ],

              // Teacher comment
              if (widget.showTeacherComment) ...[
                const Text('Teacher Comment',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E))),
                const SizedBox(height: 8),
                TextField(
                  controller: _teacherCommentCtrl,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10)),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
              ],

              // Principal comment
              if (widget.showPrincipalComment) ...[
                const Text('Principal Comment',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E))),
                const SizedBox(height: 8),
                TextField(
                  controller: _principalCommentCtrl,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10)),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
              ],

              // Save button
              SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save, size: 18),
                    label: const Text('SAVE',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  )),
              const SizedBox(height: 8),
            ])));
  }

  Widget _buildDropdown(
      String label, String value, Function(String) onChanged) {
    return DropdownButtonFormField<String>(
      value: GradingUtils.defaultBehavioralOptions
              .any((o) => o['value'] == value)
          ? value
          : 'Good',
      decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 10)),
      items: GradingUtils.defaultBehavioralOptions
          .map((o) => DropdownMenuItem(
              value: o['value'] as String,
              child: Text(o['label'] as String,
                  style: const TextStyle(fontSize: 12))))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

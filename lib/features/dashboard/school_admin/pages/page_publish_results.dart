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

  List<Map<String, dynamic>> _summaries = [];
  List<Map<String, dynamic>> _comments = [];
  List<Map<String, dynamic>> _behavioralRatings = [];

  final Map<String, Map<String, dynamic>> _studentData = {};

  SchoolAdminProvider get _provider => context.read<SchoolAdminProvider>();
  String get _sessionId => _provider.currentSession?['id']?.toString() ?? '';
  String get _termId => _provider.currentTerm?['id']?.toString() ?? '';

  List<Map<String, dynamic>> get _studentsInClass {
    if (_selectedClassId == null) return [];
    return _provider.students
        .where((s) => s['class_id']?.toString() == _selectedClassId)
        .toList();
  }

  Map<String, dynamic>? get _selectedClass {
    if (_selectedClassId == null) return null;
    try {
      return _provider.classes
          .firstWhere((c) => c['id'] == _selectedClassId);
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

  Map<String, dynamic>? _behavioralFor(String? studentId) {
    if (studentId == null) return null;
    try {
      return _behavioralRatings
          .firstWhere((b) => b['student_id'] == studentId);
    } catch (_) {
      return null;
    }
  }

  String _sName(Map<String, dynamic> s) {
    final f = (s['first_name'] ?? '').toString().trim();
    final l = (s['last_name'] ?? '').toString().trim();
    if (f.isNotEmpty && l.isNotEmpty) return '$f $l';
    if (f.isNotEmpty) return f;
    if (l.isNotEmpty) return l;
    return '';
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

  Future<void> _loadData() async {
    if (_selectedClassId == null ||
        _sessionId.isEmpty ||
        _termId.isEmpty) {
      return;
    }
    setState(() => _isLoadingData = true);
    try {
      await Future.wait([
        _loadSummaries(),
        _loadComments(),
        _loadBehavioralRatings(),
      ]);
      _prefillStudentData();
    } catch (e) {
      debugPrint('Error loading publish data: $e');
      _snack('Error loading data: $e', success: false);
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

  Future<void> _loadBehavioralRatings() async {
    final r = await _supabase
        .from('student_behavioural_ratings')
        .select()
        .eq('school_id', _provider.schoolId)
        .eq('class_id', _selectedClassId!)
        .eq('session_id', _sessionId)
        .eq('term_id', _termId);
    _behavioralRatings = List<Map<String, dynamic>>.from(r);
  }

  void _prefillStudentData() {
    _studentData.clear();
    for (final s in _studentsInClass) {
      final sid = s['id']?.toString() ?? '';
      final summary = _summaryFor(sid);
      final comment = _commentFor(sid);
      final behavioral = _behavioralFor(sid);

      final Map<String, String> ratings = {};
      if (behavioral != null) {
        for (final key in GradingUtils.behavioralFieldKeys) {
          final val = (behavioral[key] ?? '').toString().trim();
          if (val.isNotEmpty) ratings[key] = val;
        }
      }

      _studentData[sid] = {
        'days_present': summary?['days_present'] ?? 0,
        'days_absent': summary?['days_absent'] ?? 0,
        'teacher_comment': comment?['teacher_comment'] ?? '',
        'principal_comment': comment?['principal_comment'] ?? '',
        'conduct': comment?['conduct'] ?? '',
        'attitude': comment?['attitude'] ?? '',
        'interest': comment?['interest'] ?? '',
        'attendance_remark': comment?['attendance_remark'] ?? '',
        'behavioral_ratings': ratings,
      };
    }
  }

  Future<void> _computeSummaries() async {
    if (_selectedClassId == null) return;
    setState(() => _isComputing = true);
    try {
      final students = _studentsInClass;
      if (students.isEmpty) {
        _snack('No students in this class', success: false);
        return;
      }

      int withScores = 0;
      final allStudentSummaries = <Map<String, dynamic>>[];

      for (final student in students) {
        final sid = student['id'];
        final studentScores = _provider.scores
            .where((s) =>
                s['student_id'] == sid &&
                s['session_id']?.toString() == _sessionId &&
                s['term_id']?.toString() == _termId)
            .toList();

        if (studentScores.isNotEmpty) withScores++;

        final summary = GradingUtils.computeStudentSummary(
          studentScores: studentScores,
          gradingSystem: _gradingSystem,
        );

        allStudentSummaries
            .add({'student_id': sid, ...summary});
      }

      if (withScores < students.length) {
        if (!mounted) return;
        final shouldContinue = await showDialog<bool>(
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
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFE65100), size: 24),
                  ),
                  const SizedBox(height: 16),
                  const Text('Incomplete Scores',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      )),
                  const SizedBox(height: 8),
                  Text(
                      '$withScores of ${students.length} students have scores. Students without scores will get 0 total.\n\nContinue?',
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey.shade600),
                      textAlign: TextAlign.center),
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
                            padding: const EdgeInsets.symmetric(
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
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE65100),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12),
                          ),
                          child: const Text('Continue',
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
        if (shouldContinue != true) return;
      }

      final ranked =
          GradingUtils.computeClassPositions(allStudentSummaries);

      await _supabase
          .from('student_term_summaries')
          .delete()
          .eq('school_id', _provider.schoolId)
          .eq('class_id', _selectedClassId!)
          .eq('session_id', _sessionId)
          .eq('term_id', _termId);

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
          'is_published':
              existingSummary?['is_published'] ?? false,
          'published_at': existingSummary?['published_at'],
          'published_by': existingSummary?['published_by'],
        };
      }).toList();

      if (inserts.isNotEmpty) {
        await _supabase
            .from('student_term_summaries')
            .insert(inserts);
      }

      await _loadSummaries();
      _snack('Summaries computed successfully!');
    } catch (e) {
      debugPrint('Compute error: $e');
      _snack('Compute error: $e', success: false);
    } finally {
      if (mounted) setState(() => _isComputing = false);
    }
  }

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
      _snack('Results published!');
    } catch (e) {
      _snack('Publish error: $e', success: false);
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
      _snack('Results unpublished.');
    } catch (e) {
      _snack('Error: $e', success: false);
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  Future<void> _togglePublishOne(
      String studentId, bool publish) async {
    try {
      await _supabase
          .from('student_term_summaries')
          .update({
            'is_published': publish,
            'published_at': publish
                ? DateTime.now().toIso8601String()
                : null,
            'published_by':
                publish ? _provider.currentUserId : null,
          })
          .eq('school_id', _provider.schoolId)
          .eq('student_id', studentId)
          .eq('class_id', _selectedClassId!)
          .eq('session_id', _sessionId)
          .eq('term_id', _termId);

      await _loadSummaries();
    } catch (e) {
      _snack('Error: $e', success: false);
    }
  }

  Future<void> _saveStudentData(String studentId) async {
    final data = _studentData[studentId];
    if (data == null) return;
    try {
      final existing = _commentFor(studentId);
      if (existing != null) {
        await _supabase.from('term_comments').update({
          'teacher_comment': data['teacher_comment'] ?? '',
          'principal_comment':
              data['principal_comment'] ?? '',
          'conduct': data['conduct'] ?? '',
          'attitude': data['attitude'] ?? '',
          'interest': data['interest'] ?? '',
          'attendance_remark':
              data['attendance_remark'] ?? '',
        }).eq('id', existing['id']);
      } else {
        await _supabase.from('term_comments').insert({
          'school_id': _provider.schoolId,
          'student_id': studentId,
          'class_id': _selectedClassId,
          'session_id': _sessionId,
          'term_id': _termId,
          'teacher_comment': data['teacher_comment'] ?? '',
          'principal_comment':
              data['principal_comment'] ?? '',
          'conduct': data['conduct'] ?? '',
          'attitude': data['attitude'] ?? '',
          'interest': data['interest'] ?? '',
          'attendance_remark':
              data['attendance_remark'] ?? '',
        });
      }

      final summary = _summaryFor(studentId);
      if (summary != null) {
        await _supabase.from('student_term_summaries').update({
          'days_present': data['days_present'] ?? 0,
          'days_absent': data['days_absent'] ?? 0,
        }).eq('id', summary['id']);
        await _loadSummaries();
      }

      final behavioralRatings = data['behavioral_ratings'];
      if (behavioralRatings is Map &&
          behavioralRatings.isNotEmpty) {
        try {
          await _provider.saveBehavioralRatings(
            studentId: studentId,
            classId: _selectedClassId ?? '',
            sessionId: _sessionId,
            termId: _termId,
            ratingsMap: Map<String, String>.from(behavioralRatings),
          );
        } catch (e) {
          debugPrint(
              'Behavioral ratings save skipped: $e');
        }
      }

      await _loadComments();
      await _loadBehavioralRatings();
      if (mounted) setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved!'),
            backgroundColor: Color(0xFF2E7D32),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.all(Radius.circular(8))),
          ),
        );
      }
    } catch (e) {
      _snack('Save error: $e', success: false);
    }
  }

  void _showEditSheet(Map<String, dynamic> student) {
    final sid = student['id']?.toString() ?? '';
    final name = _sName(student);
    final data = Map<String, dynamic>.from(
        _studentData[sid] ?? {});

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (ctx) => _StudentEditSheet(
        studentName: name,
        initialData: data,
        behavioralRatings: data.containsKey('behavioral_ratings')
            ? Map<String, String>.from(
                data['behavioral_ratings'] as Map? ?? {})
            : <String, String>{},
        showConduct: _provider.showConduct,
        showTeacherComment: _provider.showTeacherComment,
        showPrincipalComment:
            _provider.showPrincipalComment,
        showAttendance: _provider.showAttendanceSummary,
        onSave: (updated) {
          setState(() => _studentData[sid] = updated);
          _saveStudentData(sid);
        },
      ),
    );
  }

  String _statusOf(String? studentId) {
    final s = _summaryFor(studentId);
    if (s == null) return 'none';
    return (s['is_published'] == true)
        ? 'published'
        : 'draft';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SchoolAdminProvider>();
    final students = _studentsInClass;
    final sessionName =
        provider.currentSession?['name'] ?? '';
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

    final isBusy =
        _isLoadingData || _isComputing || _isPublishing;

    return Container(
      color: const Color(0xFFF7F8FA),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Text(
                  'Publish Results',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                if (isBusy)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$sessionName — $termName',
              style: const TextStyle(
                  fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Class selector
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFE8EAED)),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedClassId,
                decoration: InputDecoration(
                  labelText: 'Select Class',
                  labelStyle: TextStyle(
                      color: Colors.grey.shade600, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  prefixIcon: const Icon(Icons.layers_rounded,
                      color: Color(0xFF1A237E), size: 20),
                ),
                items: provider.classes.map((c) {
                  final n = (c['name'] ?? '').toString();
                  final sec =
                      (c['section'] ?? '').toString();
                  final tier =
                      (c['tier'] ?? '').toString();
                  final label =
                      sec.isNotEmpty ? '$n — $sec' : n;
                  final tierLabel =
                      tier.isNotEmpty ? ' [$tier]' : '';
                  return DropdownMenuItem(
                    value: c['id']?.toString(),
                    child: Text('$label$tierLabel',
                        style: const TextStyle(
                            color: Color(0xFF111827),
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                        overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedClassId = v;
                    _summaries = [];
                    _comments = [];
                    _behavioralRatings = [];
                    _studentData.clear();
                  });
                  if (v != null) _loadData();
                },
              ),
            ),
            const SizedBox(height: 16),

            // Content when class selected
            if (_selectedClassId != null) ...[
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: _isComputing
                            ? null
                            : _computeSummaries,
                        icon: _isComputing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2))
                            : const Icon(Icons.calculate,
                                size: 18),
                        label: Text(
                          _isComputing
                              ? 'Computing...'
                              : 'Compute',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFFE65100),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              const Color(0xFFE65100)
                                  .withOpacity(0.5),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: (_isPublishing ||
                                computed == 0)
                            ? null
                            : _publishAll,
                        icon: const Icon(Icons.check_circle,
                            size: 18),
                        label: Text(
                          'Publish ($published/$computed)',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              const Color(0xFF2E7D32)
                                  .withOpacity(0.5),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: (_isPublishing ||
                                published == 0)
                            ? null
                            : _unpublishAll,
                        icon: const Icon(Icons.undo, size: 18),
                        label: const Text('Unpublish',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280))),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Info banner
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFF1A237E)
                          .withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 16,
                        color:
                            const Color(0xFF1A237E).withOpacity(0.6)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${students.length} students  •  $computed computed  •  $published published  •  Tier: $_classTier',
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
              const SizedBox(height: 16),

              // Loading state
              if (_isLoadingData)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(60),
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                          child: const CircularProgressIndicator(
                              strokeWidth: 3),
                        ),
                      ],
                    ),
                  ),
                )
              // Empty class
              else if (students.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(60),
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius:
                                BorderRadius.circular(18),
                          ),
                          child: Icon(Icons.people_outline,
                              size: 36,
                              color: Colors.grey.shade400),
                        ),
                        const SizedBox(height: 16),
                        Text('No students in this class',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            )),
                      ],
                    ),
                  ),
                )
              // Student table
              else ...[
                // Table header
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 36,
                        child: Text('#',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 11)),
                      ),
                      SizedBox(
                        width: 150,
                        child: Text('Student',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 11)),
                      ),
                      SizedBox(
                        width: 52,
                        child: Text('Total',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 11)),
                      ),
                      SizedBox(
                        width: 52,
                        child: Text('Avg',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 11)),
                      ),
                      SizedBox(
                        width: 48,
                        child: Text('Grade',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 11)),
                      ),
                      SizedBox(
                        width: 52,
                        child: Text('Pos',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 11)),
                      ),
                      SizedBox(
                        width: 80,
                        child: Text('Days',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 11)),
                      ),
                      SizedBox(
                        width: 80,
                        child: Text('Status',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 11)),
                      ),
                      SizedBox(width: 36),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                // Table body
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: const Color(0xFFE8EAED)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: students
                        .asMap()
                        .entries
                        .map((entry) {
                      final s = entry.value;
                      final sid =
                          s['id']?.toString() ?? '';
                      final summary =
                          _summaryFor(sid);
                      final status = _statusOf(sid);
                      final total =
                          (summary?['total_score']
                                  as num?)
                              ?.toInt() ??
                          0;
                      final avg =
                          (summary?['average_score']
                                  as num?)
                              ?.toDouble() ??
                          0;
                      final grade =
                          (summary?['grade'] ?? '')
                              .toString();
                      final pos =
                          summary?['position'];
                      final posOut =
                          summary?['position_out_of'];
                      final daysP =
                          (summary?['days_present']
                                  as num?)
                              ?.toInt() ??
                          0;
                      final daysA =
                          (summary?['days_absent']
                                  as num?)
                              ?.toInt() ??
                          0;
                      final bgColor = entry.key % 2 == 0
                          ? Colors.white
                          : const Color(0xFFFAFBFC);

                      return Container(
                        color: bgColor,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 36,
                              child: Text(
                                '${entry.key + 1}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 150,
                              child: Padding(
                                padding: const EdgeInsets
                                    .symmetric(
                                    horizontal: 10,
                                    vertical: 10),
                                child: Text(
                                  _sName(s),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1B2A4A),
                                  ),
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 52,
                              child: Text(
                                summary != null
                                    ? '$total'
                                    : '—',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: summary != null
                                      ? const Color(
                                          0xFF111827)
                                      : Colors.grey.shade400,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 52,
                              child: Text(
                                summary != null
                                    ? avg.toStringAsFixed(1)
                                    : '—',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: summary != null
                                      ? const Color(
                                          0xFF111827)
                                      : Colors.grey.shade400,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 48,
                              child: Center(
                                child: grade.isNotEmpty
                                    ? Container(
                                        padding:
                                            const EdgeInsets
                                                .symmetric(
                                                horizontal: 6,
                                                vertical: 2),
                                        decoration: BoxDecoration(
                                          color: GradingUtils.isPassingGrade(grade, _gradingSystem)
                                              ? const Color(
                                                  0xFFDCFCE7)
                                              : const Color(
                                                  0xFFFEE2E2),
                                          borderRadius:
                                              BorderRadius.circular(
                                                  6),
                                        ),
                                        child: Text(
                                          grade,
                                          textAlign: TextAlign
                                              .center,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight:
                                                FontWeight.bold,
                                            color: GradingUtils.isPassingGrade(grade, _gradingSystem)
                                                ? const Color(
                                                    0xFF166534)
                                                : const Color(
                                                    0xFF991B1B),
                                          ),
                                        ),
                                      )
                                    : const Text('—',
                                        style: TextStyle(
                                            color: Color(
                                                0xFF9CA3AF))),
                              ),
                            ),
                            SizedBox(
                              width: 52,
                              child: Text(
                                pos != null
                                    ? '$pos/$posOut'
                                    : '—',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: pos != null
                                      ? const Color(
                                          0xFF111827)
                                      : Colors.grey.shade400,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: Text(
                                summary != null
                                    ? 'P:$daysP  A:$daysA'
                                    : '—',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: summary != null
                                      ? const Color(
                                          0xFF111827)
                                      : Colors.grey.shade400,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: Center(
                                child: _buildStatusBadge(
                                    status),
                              ),
                            ),
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: IconButton(
                                icon: const Icon(Icons.edit,
                                    size: 15,
                                    color: Color(0xFF1A237E)),
                                padding: EdgeInsets.zero,
                                constraints:
                                    const BoxConstraints(
                                        minWidth: 28,
                                        minHeight: 28),
                                onPressed: () =>
                                    _showEditSheet(s),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ]
            // No class selected
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(60),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius:
                              BorderRadius.circular(18),
                        ),
                        child: Icon(Icons.publish,
                            size: 36,
                            color: Colors.grey.shade400),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Select a class to manage results',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    switch (status) {
      case 'published':
        return Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded,
                  size: 12, color: Color(0xFF2E7D32)),
              SizedBox(width: 4),
              Text('Published',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E7D32),
                  )),
            ],
          ),
        );
      case 'draft':
        return Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_note_rounded,
                  size: 12, color: Color(0xFFE65100)),
              SizedBox(width: 4),
              Text('Draft',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE65100),
                  )),
            ],
          ),
        );
      default:
        return Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('Not Set',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              )),
        );
    }
  }
}

// =========================================================
// STUDENT EDIT SHEET
// =========================================================

class _StudentEditSheet extends StatefulWidget {
  final String studentName;
  final Map<String, dynamic> initialData;
  final Map<String, String> behavioralRatings;
  final bool showConduct;
  final bool showTeacherComment;
  final bool showPrincipalComment;
  final bool showAttendance;
  final void Function(Map<String, dynamic> updated) onSave;

  const _StudentEditSheet({
    required this.studentName,
    required this.initialData,
    required this.behavioralRatings,
    required this.showConduct,
    required this.showTeacherComment,
    required this.showPrincipalComment,
    required this.showAttendance,
    required this.onSave,
  });

  @override
  State<_StudentEditSheet> createState() =>
      _StudentEditSheetState();
}

class _StudentEditSheetState extends State<_StudentEditSheet> {
  late TextEditingController _teacherCommentCtrl;
  late TextEditingController _principalCommentCtrl;
  late TextEditingController _attendanceRemarkCtrl;
  late TextEditingController _daysPresentCtrl;
  late TextEditingController _daysAbsentCtrl;
  late Map<String, String> _ratings;

  @override
  void initState() {
    super.initState();
    _teacherCommentCtrl = TextEditingController(
        text: (widget.initialData['teacher_comment'] ??
            '')
            .toString());
    _principalCommentCtrl = TextEditingController(
        text: (widget.initialData['principal_comment'] ??
            '')
            .toString());
    _attendanceRemarkCtrl = TextEditingController(
        text: (widget.initialData['attendance_remark'] ??
            '')
            .toString());
    _daysPresentCtrl = TextEditingController(
        text: (widget.initialData['days_present'] ?? 0)
            .toString());
    _daysAbsentCtrl = TextEditingController(
        text: (widget.initialData['days_absent'] ?? 0)
            .toString());
    _ratings = Map<String, String>.from(widget.behavioralRatings);
    for (final key in GradingUtils.behavioralFieldKeys) {
      _ratings.putIfAbsent(key, () => 'Good');
    }
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
      'principal_comment':
          _principalCommentCtrl.text.trim(),
      'attendance_remark':
          _attendanceRemarkCtrl.text.trim(),
      'days_present':
          int.tryParse(_daysPresentCtrl.text.trim()) ?? 0,
      'days_absent':
          int.tryParse(_daysAbsentCtrl.text.trim()) ?? 0,
      'behavioral_ratings':
          Map<String, String>.from(_ratings),
    });
    Navigator.pop(context);
  }

  Widget _sectionTitle(
      String title, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField(TextEditingController controller,
      String label,
      {TextInputType? keyboardType,
      int? maxLines}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            color: Colors.grey.shade600, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
              color: Color(0xFF1A237E), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFFAFBFC),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _ratingDropdown(
      String label, String value, Function(String) onChanged) {
    return DropdownButtonFormField<String>(
      value: GradingUtils.defaultBehavioralOptions
              .any((o) => o['value'] == value)
          ? value
          : 'Good',
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            color: Colors.grey.shade600, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
              color: Color(0xFF1A237E), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFFAFBFC),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
      ),
      items: GradingUtils.defaultBehavioralOptions
          .map((o) => DropdownMenuItem(
              value: o['value'] as String,
              child: Text(o['label'] as String,
                  style: const TextStyle(fontSize: 13))))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x15000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_rounded,
                        size: 20, color: Color(0xFF1A237E)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.studentName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.close,
                          size: 16,
                          color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Attendance section
              if (widget.showAttendance) ...[
                _sectionTitle('Attendance',
                    Icons.calendar_today_rounded, Color(0xFFE65100)),
                Row(
                  children: [
                    Expanded(
                      child: _inputField(
                          _daysPresentCtrl, 'Days Present',
                          keyboardType: TextInputType.number),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _inputField(
                          _daysAbsentCtrl, 'Days Absent',
                          keyboardType: TextInputType.number),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _inputField(_attendanceRemarkCtrl,
                    'Attendance Remark', maxLines: 2),
                const SizedBox(height: 20),
              ],

              // Behavioral ratings section
              if (widget.showConduct) ...[
                _sectionTitle(
                    'Behavioral Ratings (Nigerian Standard)',
                    Icons.star_rounded, Color(0xFF2E7D32)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFF2E7D32)
                            .withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 14,
                          color: const Color(0xFF2E7D32)
                              .withOpacity(0.6)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Rate each trait: Excellent / Very Good / Good / Fair / Poor',
                          style: TextStyle(
                            fontSize: 11,
                            color: const Color(0xFF2E7D32)
                                .withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ...GradingUtils.behavioralFieldKeys
                    .map((key) => Padding(
                          padding: const EdgeInsets.only(
                              bottom: 8),
                          child: _ratingDropdown(
                            GradingUtils.getBehavioralFieldLabel(
                                key),
                            _ratings[key] ?? 'Good',
                            (v) =>
                                setState(() => _ratings[key] = v),
                          ),
                        )),
                const SizedBox(height: 20),
              ],

              // Teacher comment
              if (widget.showTeacherComment) ...[
                _sectionTitle('Teacher Comment',
                    Icons.chat_bubble_outline_rounded, Color(0xFF1A237E)),
                _inputField(_teacherCommentCtrl, '',
                    maxLines: 3),
                const SizedBox(height: 20),
              ],

              // Principal comment
              if (widget.showPrincipalComment) ...[
                _sectionTitle(
                    'Principal Comment',
                    Icons.admin_panel_settings_rounded,
                    Color(0xFF1A237E)),
                _inputField(_principalCommentCtrl, '',
                    maxLines: 3),
                const SizedBox(height: 24),
              ],

              // Save button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded,
                      size: 20),
                  label: const Text('Save Changes',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      )),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

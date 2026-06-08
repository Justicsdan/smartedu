import 'dart:html' as html;
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
  bool _isLocked = false;

  List<Map<String, dynamic>> _summaries = [];
  List<Map<String, dynamic>> _comments = [];
  List<Map<String, dynamic>> _behavioralRatings = [];

  final Map<String, Map<String, dynamic>> _studentData = {};

  SchoolAdminProvider get _provider => context.read<SchoolAdminProvider>();

  Future<void> _loadLockStatus() async {
    if (_selectedClassId == null || _sessionId.isEmpty || _termId.isEmpty) return;
    try {
      final res = await _supabase
          .from('score_locks')
          .select('is_locked')
          .eq('school_id', _provider.schoolId)
          .eq('class_id', _selectedClassId!)
          .eq('session_id', _sessionId)
          .eq('term_id', _termId)
          .maybeSingle();
      if (mounted) setState(() => _isLocked = res?['is_locked'] == true);
    } catch (_) {
      if (mounted) setState(() => _isLocked = false);
    }
  }

  Future<void> _toggleLock() async {
    if (_selectedClassId == null) return;
    final wasLocked = _isLocked;
    final now = DateTime.now().toIso8601String();
    try {
      final existing = await _supabase.from('score_locks').select('id').eq('school_id', _provider.schoolId).eq('class_id', _selectedClassId!).eq('session_id', _sessionId).eq('term_id', _termId).maybeSingle();
      if (existing != null) {
        await _supabase.from('score_locks').update({'is_locked': !wasLocked, 'locked_at': !wasLocked ? now : null, 'updated_at': now}).eq('id', existing['id']);
      } else {
        await _supabase.from('score_locks').insert({'school_id': _provider.schoolId, 'class_id': _selectedClassId!, 'session_id': _sessionId, 'term_id': _termId, 'is_locked': true, 'locked_at': now});
      }
      if (mounted) {
        setState(() => _isLocked = !wasLocked);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(!wasLocked ? 'Scores locked for this term' : 'Scores unlocked for this term'), backgroundColor: !wasLocked ? Color(0xFFE65100) : Color(0xFF2E7D32), behavior: SnackBarBehavior.floating, shape: StadiumBorder()));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ' + e.toString()), backgroundColor: Color(0xFFD32F2F), behavior: SnackBarBehavior.floating, shape: StadiumBorder()));
    }
  }
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
        content: Text(message,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor:
            success ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

        allStudentSummaries.add({'student_id': sid, ...summary});
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
            'published_at':
                publish ? DateTime.now().toIso8601String() : null,
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
          debugPrint('Behavioral ratings save skipped: $e');
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

  String _getClassName() {
    if (_selectedClassId == null) return '';
    try {
      final cls = _provider.classes.firstWhere((c) => c['id'].toString() == _selectedClassId);
      final name = (cls['name'] ?? '').toString().trim();
      final section = (cls['section'] ?? '').toString().trim();
      return section.isNotEmpty ? '$name $section' : name;
    } catch (_) { return ''; }
  }

  String _statusOf(String? studentId) {
    final s = _summaryFor(studentId);
    if (s == null) return 'none';
    return (s['is_published'] == true)
        ? 'published'
        : 'draft';
  }

  Future<void> _printAllReportCards() async {
    if (_selectedClassId == null) return;
    final published = _summaries.where((s) => s['is_published'] == true).toList();
    if (published.isEmpty) {
      _snack('No published results to print', success: false);
      return;
    }
    setState(() => _isPublishing = true);
    try {
      final sn = _provider.schoolName;
      final sl = _provider.schoolLogoUrl;
      final sm = _provider.schoolMotto;
      final sa = _provider.schoolAddress;
      final pn = _provider.principalName;
      final psig = _provider.principalSignatureUrl;
      final cn = _getClassName();
      final sen = _provider.currentSession?['name']?.toString() ?? '';
      final tn = _provider.currentTerm?['name']?.toString() ?? '';
      final tier = _classTier;
      final grading = _gradingSystem;
      final atypes = GradingUtils.getAssessmentTypesForTier(tier, _provider.schoolSettings ?? {});
      final ah = atypes.map((a) => {'n': a['name'].toString(), 'm': a['max'].toString()}).toList();
      final ath = ah.map((a) => "<th>${a['n']}<br/>(${a['m']})</th>").join('');
      final grow = grading.map((g) => "<tr><td>${g['grade']}</td><td>${g['min']}-${g['max']}</td><td>${g['remark'] ?? ''}</td></tr>").join('');
      final bkeys = GradingUtils.behavioralFieldKeys;
      final blabels = GradingUtils.behavioralFieldLabels;
      final bcol = {'Excellent': '#166534', 'Very Good': '#2E7D32', 'Good': '#1565C0', 'Fair': '#E65100', 'Poor': '#D32F2F'};
      final csList = await _supabase.from('class_subjects').select('subject_id,subjects(name,code)').eq('class_id', _selectedClassId!).eq('school_id', _provider.schoolId);
      final sMap = <String, Map<String, String>>{};
      for (final cs in csList) {
        final s = cs['subjects'] as Map<String, dynamic>?;
        if (s != null) {
          sMap[cs['subject_id'].toString()] = {'name': s['name'].toString(), 'code': (s['code'] ?? '').toString()};
        }
      }
      final allSc = await _supabase.from('scores').select().eq('school_id', _provider.schoolId).eq('class_id', _selectedClassId!).eq('session_id', _sessionId).eq('term_id', _termId);
      final scBySt = <String, List<Map<String, dynamic>>>{};
      for (final sc in allSc) {
        final sid = (sc['student_id'] ?? '').toString();
        scBySt.putIfAbsent(sid, () => []).add(sc);
      }
      final cards = <String>[];
      for (final sum in published) {
        final stId = (sum['student_id'] ?? '').toString();
        final st = _studentsInClass.firstWhere((s) => s['id'].toString() == stId, orElse: () => <String, dynamic>{});
        final nm = _sName(st);
        final adm = (st['admission_no'] ?? '').toString();
        final pp = (st['passport_url'] ?? '').toString();
        final scs = scBySt[stId] ?? [];
        final com = _commentFor(stId);
        final beh = _behavioralFor(stId);
        final tot = (sum['total_score'] as num?)?.toInt() ?? 0;
        final avg = (sum['average_score'] as num?)?.toDouble() ?? 0;
        final gr = (sum['grade'] ?? '').toString();
        final pos = sum['position'];
        final po = sum['position_out_of'];
        final dp = (sum['days_present'] as num?)?.toInt() ?? 0;
        final da = (sum['days_absent'] as num?)?.toInt() ?? 0;
        final brows = bkeys.asMap().entries.map((e) {
          final v = (beh?[e.value] ?? 'Good').toString();
          final cl = bcol[v] ?? '#1565C0';
          return "<tr><td>${blabels[e.value]}</td><td style=\"color:$cl;font-weight:700\">$v</td></tr>";
        }).join('');
        final srows = scs.map((sc) {
          final si = (sc['subject_id'] ?? '').toString();
          final su = sMap[si] ?? {'name': 'Unknown', 'code': ''};
          final sj = sc['scores_json'] as Map<String, dynamic>? ?? {};
          final ac = ah.map((a) {
            final k = a['n'].toString().toLowerCase();
            final v = sj[k] ?? 0;
            return "<td>${v is num ? v : 0}</td>";
          }).join('');
          final st2 = (sc['total'] as num?)?.toInt() ?? 0;
          final sg = (sc['grade'] ?? '').toString();
          final codeStr = (su['code'] ?? '').toString();
          return "<tr><td style=\"text-align:left;font-weight:600\">${su['name']}${codeStr.isNotEmpty ? ' ($codeStr)' : ''}</td>$ac<td style=\"font-weight:700\">$st2</td><td>$sg</td></tr>";
        }).join('');
        final tc = ah.length + 1;
        final psigStr = (psig ?? '').toString();
        cards.add(
            '<div class="c">'
            '<div class="hd"><div class="hl"><div class="sn">$sn</div>${sm.isNotEmpty ? "<div class=\"mt\">$sm</div>" : ""}${sa.isNotEmpty ? "<div class=\"ad\">$sa</div>" : ""}</div>${sl.isNotEmpty ? "<img class=\"lo\" src=\"$sl\"/>" : ""}</div>'
            '<div class="si"><div class="sl"><table><tr><td class="l">Name:</td><td class="v">$nm</td></tr><tr><td class="l">Adm No:</td><td class="v">$adm</td></tr><tr><td class="l">Class:</td><td class="v">$cn</td></tr><tr><td class="l">Session:</td><td class="v">$sen</td></tr><tr><td class="l">Term:</td><td class="v">$tn</td></tr></table></div>'
            '${pp.isNotEmpty ? "<img class=\"pp\" src=\"$pp\"/>" : "<div class=\"pph\">${nm.isNotEmpty ? nm[0].toUpperCase() : ''}</div>"}'
            '</div>'
            '<table class="st"><thead><tr><th style="text-align:left;width:170px">Subject</th>$ath<th>Total</th><th>Grade</th></tr></thead><tbody>$srows</tbody>'
            '<tfoot><tr style="font-weight:700;background:#F0F4FF"><td style="text-align:left">TOTAL</td>${ah.map((_) => "<td></td>").join("")}<td>$tot</td><td>$gr</td></tr>'
            '<tr style="background:#F0F4FF"><td style="text-align:left">Position</td><td colspan="$tc"></td><td colspan="2" style="font-weight:700">${pos ?? '-'}${po != null ? '/$po' : ''}</td></tr>'
            '<tr style="background:#F0F4FF"><td style="text-align:left">Average</td><td colspan="$tc"></td><td colspan="2" style="font-weight:700">${avg.toStringAsFixed(1)}</td></tr></tfoot></table>'
            '<div class="tw"><div class="co"><div class="ct">Attendance</div><table><tr><td>Present</td><td class="b">$dp</td></tr><tr><td>Absent</td><td class="b r">$da</td></tr></table></div>'
            '<div class="co"><div class="ct">Behavioural Ratings</div><table>$brows</table></div></div>'
            '${(com?["teacher_comment"] ?? "").toString().isNotEmpty ? "<div class=\"cm\"><div class=\"ct\">Teacher Comment</div><div class=\"ct2\">${com!["teacher_comment"] ?? ""}</div></div>" : ""}'
            '${(com?["principal_comment"] ?? "").toString().isNotEmpty ? "<div class=\"cm\"><div class=\"ct\">Principal Comment</div><div class=\"ct2\">${com!["principal_comment"] ?? ""}</div></div>" : ""}'
            '<div class="gk"><div class="ct">Grading Key</div><table><tr><th>Grade</th><th>Range</th><th>Remark</th></tr>$grow</table></div>'
            '<div class="sg2"><div class="s"><div class="sl2"></div><div>Class Teacher</div></div>'
            '${psigStr.isNotEmpty ? "<div class=\"s\"><img class=\"si2\" src=\"$psigStr\"/><div>Principal</div></div>" : "<div class=\"s\"><div class=\"sl2\"></div><div>Principal</div></div>"}'
            '</div></div>'
        );
      }
      final h = '<!DOCTYPE html><html><head><meta charset="utf-8"><title>Report Cards</title>'
          '<style>@page{size:A4 portrait;margin:12mm}*{margin:0;padding:0;box-sizing:border-box}body{font-family:Arial,sans-serif;font-size:11px;color:#111}'
          '.c{page-break-after:always;padding:0 4mm;min-height:270mm}.c:last-child{page-break-after:auto}'
          '.hd{display:flex;justify-content:space-between;align-items:center;border-bottom:3px double #1A237E;padding-bottom:10px;margin-bottom:10px}'
          '.sn{font-size:18px;font-weight:800;color:#1A237E}.mt{font-size:11px;color:#4B5563;font-style:italic}.ad{font-size:10px;color:#6B7280}'
          '.lo{height:60px}.pp{width:80px;height:95px;object-fit:cover;border-radius:8px;border:2px solid #E5E7EB}'
          '.pph{width:80px;height:95px;border-radius:8px;border:2px solid #E5E7EB;display:flex;align-items:center;justify-content:center;font-size:28px;font-weight:800;color:#1A237E;background:#F0F4FF}'
          '.si{display:flex;justify-content:space-between;margin-bottom:12px}.sl table td{padding:2px 8px 2px 0;font-size:11px}.l{color:#6B7280;width:90px}.v{font-weight:600}'
          '.st{width:100%;border-collapse:collapse;margin-bottom:12px}.st th,.st td{border:1px solid #D1D5DB;padding:5px 6px;text-align:center;font-size:10px}'
          '.st th{background:#1E293B;color:white;font-weight:700;font-size:9px}.st tfoot td{font-size:11px;padding:6px}'
          '.tw{display:flex;gap:16px;margin-bottom:12px}.co{flex:1;border:1px solid #E5E7EB;border-radius:8px;padding:10px;overflow:hidden}'
          '.ct{font-size:11px;font-weight:700;color:#1A237E;background:#F0F4FF;padding:6px 10px;margin:-10px -10px 10px -10px;text-transform:uppercase;letter-spacing:0.5px}'
          '.co table{width:100%;border-collapse:collapse}.co td{padding:3px 8px;font-size:10px;border-bottom:1px solid #F3F4F6}.b{font-weight:700}.r{color:#D32F2F}'
          '.cm{border:1px solid #E5E7EB;border-radius:8px;padding:10px;margin-bottom:12px;overflow:hidden}.ct2{font-size:11px;color:#374151;line-height:1.5;min-height:24px}'
          '.gk{margin-bottom:12px}.gk table{width:100%;border-collapse:collapse;border:1px solid #E5E7EB;border-radius:8px;overflow:hidden}'
          '.gk th{background:#1E293B;color:white;font-size:9px;padding:5px 8px}.gk td{padding:4px 8px;font-size:10px;border-bottom:1px solid #F3F4F6;text-align:center}'
          '.sg2{display:flex;justify-content:space-between;margin-top:30px;padding:0 40px}.s{text-align:center;width:150px}.sl2{border-top:1px solid #111;margin-top:40px}.s div:last-child{font-size:10px;margin-top:4px;color:#374151}'
          '.si2{height:40px;margin-bottom:4px}</style></head><body>'
          '<div class="no-print" style="position:fixed;top:10px;right:10px;z-index:999"><button onclick="window.print()" style="padding:10px 24px;background:#1A237E;color:white;border:none;border-radius:8px;font-size:15px;cursor:pointer;box-shadow:0 2px 8px rgba(0,0,0,0.2)">Print All Cards</button></div>'
          '${cards.join("")}'
          '</body></html>';
      final blob = html.Blob([h], 'text/html');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.window.open(url, '_blank');
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      debugPrint('Print err: $e');
      _snack('Print error: $e', success: false);
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
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
              '$sessionName - $termName',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE8EAED)),
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
                      sec.isNotEmpty ? '$n - $sec' : n;
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
                  if (v != null) { _loadData(); _loadLockStatus(); }
                },
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedClassId != null) ...[
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
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.undo, size: 18),
                        label: const Text('Unpublish',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: (published == 0 || _isPublishing)
                            ? null
                            : _printAllReportCards,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Color(0xFFC5CAE9)),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.print_rounded,
                            size: 18),
                        label: const Text('Print Cards',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A237E))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: _isLocked
                          ? ElevatedButton.icon(
                              onPressed: _isPublishing ? null : _toggleLock,
                              icon: const Icon(Icons.lock_rounded, size: 18),
                              label: const Text('Locked', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFE65100), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                            )
                          : OutlinedButton.icon(
                              onPressed: _isPublishing ? null : _toggleLock,
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF2E7D32)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                              icon: const Icon(Icons.lock_open_rounded, size: 18, color: Color(0xFF2E7D32)),
                              label: const Text('Lock', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32))),
                            ),
                    ),
                  ),
                ],
              ),
              if (_isLocked)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: const Color(0xFFFFF3E0), border: Border.all(color: const Color(0xFFFFE082)), borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    Icon(Icons.lock_rounded, size: 16, color: Color(0xFFE65100)),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Scores are locked — teachers cannot edit scores for this class this term', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFE65100)))),
                  ]),
                ),
              const SizedBox(height: 12),
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
                        '${students.length} students  |  $computed computed  |  $published published  |  Tier: $_classTier',
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
                          child:
                              const CircularProgressIndicator(
                                  strokeWidth: 3),
                        ),
                      ],
                    ),
                  ),
                )
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
              else ...[
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
                                    : '-',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: summary != null
                                      ? const Color(
                                          0xFF111827)
                                      : Colors
                                          .grey.shade400,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 52,
                              child: Text(
                                summary != null
                                    ? avg
                                        .toStringAsFixed(
                                            1)
                                    : '-',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: summary != null
                                      ? const Color(
                                          0xFF111827)
                                      : Colors
                                          .grey.shade400,
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
                                                horizontal:
                                                    6,
                                                vertical: 2),
                                        decoration:
                                            BoxDecoration(
                                          color: GradingUtils
                                              .isPassingGrade(
                                                  grade,
                                                  _gradingSystem)
                                              ? const Color(
                                                  0xFFDCFCE7)
                                              : const Color(
                                                  0xFFFEE2E2),
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                                      6),
                                        ),
                                        child: Text(
                                          grade,
                                          textAlign:
                                              TextAlign
                                                  .center,
                                          style:
                                              TextStyle(
                                            fontSize: 11,
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                            color: GradingUtils
                                                .isPassingGrade(
                                                    grade,
                                                    _gradingSystem)
                                                ? const Color(
                                                    0xFF166534)
                                                : const Color(
                                                    0xFF991B1B),
                                          ),
                                        ),
                                      )
                                    : Text(
                                        '-',
                                        style: TextStyle(
                                            color:
                                                Color(
                                                    0xFF9CA3AF))),
                              ),
                            ),
                            SizedBox(
                              width: 52,
                              child: Text(
                                pos != null
                                    ? '$pos/$posOut'
                                    : '-',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: pos != null
                                      ? const Color(
                                          0xFF111827)
                                      : Colors
                                          .grey.shade400,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: Text(
                                summary != null
                                    ? 'P:$daysP  A:$daysA'
                                    : '-',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: summary != null
                                      ? const Color(
                                          0xFF111827)
                                      : Colors
                                          .grey.shade400,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: Center(
                                child:
                                    _buildStatusBadge(
                                        status),
                              ),
                            ),
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: IconButton(
                                icon: const Icon(
                                    Icons.edit,
                                    size: 15,
                                    color:
                                        Color(0xFF1A237E)),
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
              if (widget.showConduct) ...[
                _sectionTitle(
                    'Behavioral Ratings (Nigerian Standard)',
                    Icons.star_rounded, Color(0xFF2E7D32)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFF2E7D32).withOpacity(0.05),
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
                            GradingUtils
                                .getBehavioralFieldLabel(key),
                            _ratings[key] ?? 'Good',
                            (v) =>
                                setState(() => _ratings[key] = v),
                          ),
                        )),
                const SizedBox(height: 20),
              ],
              if (widget.showTeacherComment) ...[
                _sectionTitle('Teacher Comment',
                    Icons.chat_bubble_outline_rounded,
                    Color(0xFF1A237E)),
                _inputField(_teacherCommentCtrl, '',
                    maxLines: 3),
                const SizedBox(height: 20),
              ],
              if (widget.showPrincipalComment) ...[
                _sectionTitle(
                    'Principal Comment',
                    Icons.admin_panel_settings_rounded,
                    Color(0xFF1A237E)),
                _inputField(_principalCommentCtrl, '',
                    maxLines: 3),
                const SizedBox(height: 24),
              ],
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

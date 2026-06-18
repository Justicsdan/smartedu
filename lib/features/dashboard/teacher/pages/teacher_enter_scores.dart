import 'package:smartedu/core/services/db_proxy.dart';
// ==========================================
// File: lib/features/dashboard/teacher/pages/teacher_enter_scores.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:smartedu/core/providers/teacher/teacher_provider.dart';
import 'package:smartedu/utils/grading_utils.dart';

class TeacherEnterScoresPage extends StatefulWidget {
  const TeacherEnterScoresPage({super.key});

  @override
  State<TeacherEnterScoresPage> createState() => _TeacherEnterScoresPageState();
}

class _TeacherEnterScoresPageState extends State<TeacherEnterScoresPage> {
  String? _selectedClassId;
  String? _selectedSubjectId;
  bool _isSaving = false;
  bool _isPrefilling = false;
  bool _isLocked = false;
  final Map<String, TextEditingController> _controllers = {};

  String _studentName(Map<String, dynamic> s) {
    final first = (s['first_name'] ?? '').toString().trim();
    final last = (s['last_name'] ?? '').toString().trim();
    return '$first $last'.trim();
  }

  List<Map<String, dynamic>> get _myClasses {
    final provider = context.read<TeacherProvider>();
    final classIds = <String>{};
    for (final a in provider.mySubjectAssignments) {
      final cid = a['class_id']?.toString();
      if (cid != null) classIds.add(cid);
    }
    final ftClass = provider.getFormTeacherClass();
    if (ftClass != null) {
      classIds.add(ftClass['id']?.toString() ?? '');
    }
    return provider.myClasses
        .where((c) => classIds.contains(c['id']?.toString()))
        .toList();
  }

  List<Map<String, dynamic>> get _subjectsForSelectedClass {
    if (_selectedClassId == null) return [];
    final provider = context.read<TeacherProvider>();
    return provider.mySubjectAssignments
        .where((a) => a['class_id']?.toString() == _selectedClassId)
        .toList();
  }

  List<Map<String, dynamic>> _cachedStudents = [];
  List<Map<String, dynamic>> get _studentsInClass => _cachedStudents;

  String _getClassTier() {
    if (_selectedClassId == null) return 'SSS';
    try {
      final provider = context.read<TeacherProvider>();
      final cls = provider.myClasses
          .firstWhere((c) => c['id'].toString() == _selectedClassId);
      return (cls['tier'] as String?) ?? 'SSS';
    } catch (_) {
      return 'SSS';
    }
  }

  List<Map<String, dynamic>> get _assessmentTypes {
    final tier = _getClassTier();
    final provider = context.read<TeacherProvider>();
    final settings = provider.schoolSettings;
    if (settings != null) {
      if (tier == 'JSS' && settings['assessment_types_jss'] != null) {
        return List<Map<String, dynamic>>.from(settings['assessment_types_jss']);
      }
      if (tier == 'PRIMARY' &&
          settings['assessment_types_primary'] != null) {
        return List<Map<String, dynamic>>.from(
            settings['assessment_types_primary']);
      }
      if (settings['assessment_types'] != null) {
        return List<Map<String, dynamic>>.from(settings['assessment_types']);
      }
    }
    return GradingUtils.getDefaultAssessmentTypes('WAEC');
  }

  double get _totalMaxScore {
    return _assessmentTypes.fold<double>(
        0, (sum, at) => sum + ((at['max'] as num?)?.toDouble() ?? 0));
  }

  String _assessKey(Map<String, dynamic> at) {
    return (at['id'] ?? '').toString().toLowerCase();
  }

  TextEditingController _getController(String studentId, String key) {
    final k = '${studentId}_$key';
    _controllers[k] ??= TextEditingController();
    return _controllers[k]!;
  }

  void _clearControllers() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
  }

  Listenable _studentListenable(String studentId) {
    return Listenable.merge(_assessmentTypes.map((at) => _getController(studentId, _assessKey(at))));
  }

  double _getTotal(String studentId) {
    double total = 0;
    for (final at in _assessmentTypes) {
      final key = _assessKey(at);
      total += double.tryParse(_getController(studentId, key).text) ?? 0;
    }
    return total;
  }

  String _getGrade(double score) {
    final tier = _getClassTier();
    final provider = context.read<TeacherProvider>();
    final settings = provider.schoolSettings;
    List<Map<String, dynamic>> grading = [];
    if (settings != null) {
      if (tier == 'JSS' && settings['grading_system_jss'] != null) {
        grading =
            List<Map<String, dynamic>>.from(settings['grading_system_jss']);
      } else if (tier == 'PRIMARY' &&
          settings['grading_system_primary'] != null) {
        grading = List<Map<String, dynamic>>.from(
            settings['grading_system_primary']);
      } else if (settings['grading_system'] != null) {
        grading =
            List<Map<String, dynamic>>.from(settings['grading_system']);
      }
    }
    if (grading.isEmpty) grading = GradingUtils.getDefaultGradingSystem('WAEC');
    for (final g in grading) {
      final min = (g['min'] as num?)?.toDouble() ?? 0;
      final max = (g['max'] as num?)?.toDouble() ?? 100;
      if (score >= min && score <= max) return (g['grade'] ?? 'F').toString();
    }
    return 'F';
  }

  Future<void> _checkLockStatus() async {
    if (_selectedClassId == null) return;
    final provider = context.read<TeacherProvider>();
    final session = provider.currentSession;
    final term = provider.currentTerm;
    if (session == null || term == null) return;
    try {
      final res = await DbProxy.instance.from('score_locks').select('is_locked').eq('school_id', provider.schoolId).eq('class_id', _selectedClassId!).eq('session_id', session['id'].toString()).eq('term_id', term['id'].toString()).eq('is_locked', true).maybeSingle();
      if (mounted) setState(() => _isLocked = res != null);
    } catch (_) {
      if (mounted) setState(() => _isLocked = false);
    }
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _prefill() async {
    if (_selectedClassId == null || _selectedSubjectId == null) return;
    final provider = context.read<TeacherProvider>();
    final session = provider.currentSession;
    final term = provider.currentTerm;
    if (session == null || term == null) return;
    final sid = session['id'].toString();
    final tid = term['id'].toString();
    if (sid.isEmpty || tid.isEmpty) return;
    final classId = _selectedClassId!;
    final subjectId = _selectedSubjectId!;
    final schoolId = provider.schoolId;

    setState(() => _isPrefilling = true);

    try {
      final rows = await DbProxy.instance.from('scores').select().eq('school_id', schoolId).eq('class_id', classId).eq('subject_id', subjectId).eq('session_id', sid).eq('term_id', tid).get();

      final Map<String, Map<String, dynamic>> scoreMap = {};
      for (final r in rows) {
        final stId = r['student_id']?.toString() ?? '';
        scoreMap[stId] = r['scores_json'] as Map<String, dynamic>? ?? {};
      }

      _cachedStudents = provider.students.where((s) => s['class_id']?.toString() == classId).toList();
      debugPrint('PREFILL: ${_cachedStudents.length} students, ${_assessmentTypes.length} types, ${scoreMap.length} scores');
      for (final student in _cachedStudents) {
        final studentId = student['id'].toString();
        final sj = scoreMap[studentId] ?? {};
        for (final at in _assessmentTypes) {
          final key = _assessKey(at);
          final val = sj[key] ?? sj[at['name']];
          final txt = val != null ? (val is num ? val : 0).toString() : '';
          debugPrint('PREFILL: student=$studentId key=$key val=$val txt="$txt"');
          _getController(studentId, key).text = txt;
        }
      }
    } catch (e) {
      debugPrint('Prefill error: $e');
    }

    if (mounted) setState(() => _isPrefilling = false);
  }

  Future<void> _save() async {
    if (_selectedClassId == null || _selectedSubjectId == null) return;
    final classId = _selectedClassId!;
    final subjectId = _selectedSubjectId!;
    final provider = context.read<TeacherProvider>();
    final session = provider.currentSession;
    final term = provider.currentTerm;
    if (session == null || term == null) return;
    final sid = session['id'].toString();
    final tid = term['id'].toString();
    if (sid.isEmpty || tid.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      _cachedStudents = provider.students.where((s) => s['class_id']?.toString() == classId).toList();
      for (final student in _cachedStudents) {
        final studentId = student['id'].toString();
        final sj = <String, dynamic>{};
        for (final at in _assessmentTypes) {
          final key = _assessKey(at);
          sj[key] = double.tryParse(_getController(studentId, key).text) ?? 0;
        }
        final total = _getTotal(studentId);
        final grade = _getGrade(total);

        final existing = await DbProxy.instance.from('scores').select('id').eq('school_id', provider.schoolId).eq('student_id', studentId).eq('class_id', classId).eq('subject_id', subjectId).eq('session_id', sid).eq('term_id', tid).maybeSingle();

        final scoreData = {
          'school_id': provider.schoolId,
          'student_id': studentId,
          'class_id': classId,
          'subject_id': subjectId,
          'session_id': sid,
          'term_id': tid,
          'scores_json': sj,
          'total': total,
          'grade': grade,
          'recorded_by': provider.teacherId,
        };

        if (existing != null) {
          await DbProxy.instance.from('scores').eq('id', existing['id']).update(scoreData);
        } else {
          await DbProxy.instance.from('scores').insert(scoreData);
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scores saved successfully!'),
            backgroundColor: Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TeacherProvider>();

    if (!provider.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!provider.isSubjectTeacher) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(Icons.edit_off_rounded,
                  size: 32, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 20),
            Text('Score entry requires subject assignment',
                style: TextStyle(
                    fontSize: 16,
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Contact your admin to get assigned to a subject.',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      );
    }

    final myClasses = _myClasses;
    if (myClasses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(18),
              ),
              child:
                  Icon(Icons.class_rounded, size: 32, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 20),
            Text('No classes assigned yet',
                style: TextStyle(
                    fontSize: 16,
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Enter Scores',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                  letterSpacing: -0.5)),
          const SizedBox(height: 4),
          const Text('Select a class and subject to enter or edit scores',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE8EAED)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedClassId,
                    hint: const Text('Select Class', style: TextStyle(fontSize: 14)),
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.class_rounded,
                        color: Color(0xFF1A237E)),
                    items: myClasses
                        .map((c) => DropdownMenuItem<String>(
                              value: c['id'].toString(),
                              child: Text(
                                  '${c['name'] ?? ''} ${c['section'] ?? ''}'
                                      .trim(),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14)),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedClassId = v;
                        _selectedSubjectId = null;
                        _isLocked = false;
                        _cachedStudents = [];
                        _clearControllers();
                      });
                      _checkLockStatus();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE8EAED)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedSubjectId,
                    hint:
                        const Text('Select Subject', style: TextStyle(fontSize: 14)),
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.menu_book,
                        color: Color(0xFF1A237E)),
                    items: _subjectsForSelectedClass.map((cs) {
                      final subj =
                          cs['subjects'] as Map<String, dynamic>? ?? {};
                      return DropdownMenuItem<String>(
                        value: cs['subject_id'].toString(),
                        child: Text(subj['name']?.toString() ?? '',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedSubjectId = v;
                        _clearControllers();
                      });
                      if (v != null) {
                        _checkLockStatus();
                        _prefill();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_assessmentTypes.isNotEmpty && _selectedClassId != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 18, color: Color(0xFFF57F17)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                        'Assessment: ${_assessmentTypes.map((a) => "${a['name']}(${a['max']})").join(" + ")} = $_totalMaxScore',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFFF57F17))),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          if (_selectedClassId != null && _selectedSubjectId != null)
            _isPrefilling
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(60),
                      child: CircularProgressIndicator(),
                    ))
                : _studentsInClass.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(60),
                          child: Column(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F8FA),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Icon(Icons.people_outline,
                                    size: 32, color: Colors.grey.shade400),
                              ),
                              const SizedBox(height: 16),
                              const Text('No students in this class',
                                  style: TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF111827),
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      )
                    : _isLocked ? _buildLockedState() : _buildScoreTable()
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
                        color: const Color(0xFFF7F8FA),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(Icons.touch_app_outlined,
                          size: 32, color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 16),
                    const Text('Select class and subject to begin',
                        style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF111827),
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScoreTable() {
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A237E),
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12), topRight: Radius.circular(12)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const SizedBox(
                    width: 40,
                    child: Center(
                        child: Text('#',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)))),
                const SizedBox(
                    width: 160,
                    child: Center(
                        child: Text('Student Name',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)))),
                ..._assessmentTypes.map((at) => SizedBox(
                      width: 90,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text('${at['name']}\n(${at['max']})',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11)),
                        ),
                      ),
                    )),
                const SizedBox(
                    width: 70,
                    child: Center(
                        child: Text('Total',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)))),
                const SizedBox(
                    width: 60,
                    child: Center(
                        child: Text('Grade',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)))),
              ],
            ),
          ),
        ),
        ..._studentsInClass.asMap().entries.map((entry) {
          final index = entry.key;
          final student = entry.value;
          final sid = student['id'].toString();
          final bgColor =
              index % 2 == 0 ? Colors.white : const Color(0xFFFAFBFC);
          return Container(
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(
                bottom: BorderSide(
                    color: index == _studentsInClass.length - 1
                        ? const Color(0xFFE8EAED)
                        : Colors.grey.shade100,
                    width: index == _studentsInClass.length - 1 ? 1 : 0.5),
                left: const BorderSide(color: Color(0xFFE8EAED)),
                right: const BorderSide(color: Color(0xFFE8EAED)),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(
                      width: 40,
                      child: Center(
                          child: Text('${index + 1}',
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF111827))))),
                  SizedBox(
                    width: 160,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      child: Text(_studentName(student),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1B2A4A)),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  ..._assessmentTypes.map((at) {
                    final key = _assessKey(at);
                    return SizedBox(
                      width: 90,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 4),
                        child: TextField(
                          controller: _getController(sid, key),
                          readOnly: _isLocked,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF111827),
                              fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(
                                    color: Color(0xFF1A237E), width: 1.5)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 8),
                            isDense: true,
                          ),
                          // no setState — prevents web TextField rebuild bug
                        ),
                      ),
                    );
                  }),
                  ListenableBuilder(
                    listenable: _studentListenable(sid),
                    builder: (ctx, _) {
                      final t = _getTotal(sid);
                      final g = _getGrade(t);
                      final tColor = t >= _totalMaxScore * 0.5 ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F);
                      final tBg = t >= _totalMaxScore * 0.5 ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
                      return Row(
                        children: [
                          SizedBox(width: 70, child: Container(margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6), padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: tBg, borderRadius: BorderRadius.circular(6)), child: Text(t.toStringAsFixed(0), textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: tColor)))),
                          SizedBox(width: 60, child: Container(margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6), padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: tBg, borderRadius: BorderRadius.circular(6)), child: Text(g, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: tColor)))),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save_rounded),
            label: Text(_isSaving ? "Saving..." : "Save All Scores",
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLockedState() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(color: const Color(0xFFFFF3E0), border: Border.all(color: const Color(0xFFFFE082)), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFFFE082), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.lock_rounded, color: Color(0xFFE65100), size: 22)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Scores Locked', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFE65100))),
                const SizedBox(height: 4),
                Text('Scores have been locked by the admin for this class and term. Contact your admin to unlock.', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
              ])),
            ],
          ),
        ),
        _buildScoreTable(),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    return provider.myClasses.where((c) => classIds.contains(c['id']?.toString())).toList();
  }

  List<Map<String, dynamic>> get _subjectsForSelectedClass {
    if (_selectedClassId == null) return [];
    final provider = context.read<TeacherProvider>();
    return provider.mySubjectAssignments
        .where((a) => a['class_id']?.toString() == _selectedClassId)
        .toList();
  }

  List<Map<String, dynamic>> get _studentsInClass {
    if (_selectedClassId == null) return [];
    final provider = context.read<TeacherProvider>();
    return provider.students.where((s) => s['class_id']?.toString() == _selectedClassId).toList();
  }

  String _getClassTier() {
    if (_selectedClassId == null) return 'SSS';
    try {
      final provider = context.read<TeacherProvider>();
      final cls = provider.myClasses.firstWhere((c) => c['id'].toString() == _selectedClassId);
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
      if (tier == 'PRIMARY' && settings['assessment_types_primary'] != null) {
        return List<Map<String, dynamic>>.from(settings['assessment_types_primary']);
      }
      if (settings['assessment_types'] != null) {
        return List<Map<String, dynamic>>.from(settings['assessment_types']);
      }
    }
    return GradingUtils.getDefaultAssessmentTypes('WAEC');
  }

  double get _totalMaxScore {
    return _assessmentTypes.fold<double>(0, (sum, at) => sum + ((at['max'] as num?)?.toDouble() ?? 0));
  }

  TextEditingController _getController(String studentId, String key) {
    final k = '${studentId}_$key';
    _controllers[k] ??= TextEditingController();
    return _controllers[k]!;
  }

  void _clearControllers() {
    for (var c in _controllers.values) { c.dispose(); }
    _controllers.clear();
  }

  double _getTotal(String studentId) {
    double total = 0;
    for (final at in _assessmentTypes) {
      final key = (at['id'] ?? '').toString();
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
        grading = List<Map<String, dynamic>>.from(settings['grading_system_jss']);
      } else if (tier == 'PRIMARY' && settings['grading_system_primary'] != null) {
        grading = List<Map<String, dynamic>>.from(settings['grading_system_primary']);
      } else if (settings['grading_system'] != null) {
        grading = List<Map<String, dynamic>>.from(settings['grading_system']);
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

  @override
  void dispose() {
    for (var c in _controllers.values) { c.dispose(); }
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

    for (final student in _studentsInClass) {
      final studentId = student['id'].toString();
      try {
        final r = await Supabase.instance.client.from('scores')
            .select()
            .eq('school_id', schoolId)
            .eq('student_id', studentId)
            .eq('class_id', classId)
            .eq('subject_id', subjectId)
            .eq('session_id', sid)
            .eq('term_id', tid)
            .maybeSingle();
        if (r != null) {
          final sj = r['scores_json'] as Map<String, dynamic>? ?? {};
          for (final at in _assessmentTypes) {
            final key = (at['id'] ?? '').toString().toLowerCase();
            final val = sj[key] ?? sj[at['name']] ?? 0;
            _getController(studentId, key).text = (val is num ? val : 0).toString();
          }
        }
      } catch (e) {
        debugPrint('Prefill error: $e');
      }
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
      for (final student in _studentsInClass) {
        final studentId = student['id'].toString();
        final sj = <String, dynamic>{};
        for (final at in _assessmentTypes) {
          final key = (at['id'] ?? '').toString().toLowerCase();
          sj[key] = double.tryParse(_getController(studentId, key).text) ?? 0;
        }
        final total = _getTotal(studentId);
        final grade = _getGrade(total);

        final existing = await Supabase.instance.client.from('scores')
            .select('id')
            .eq('school_id', provider.schoolId)
            .eq('student_id', studentId)
            .eq('class_id', classId)
            .eq('subject_id', subjectId)
            .eq('session_id', sid)
            .eq('term_id', tid)
            .maybeSingle();

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
          await Supabase.instance.client.from('scores').update(scoreData).eq('id', existing['id']);
        } else {
          await Supabase.instance.client.from('scores').insert(scoreData);
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scores saved successfully!'), backgroundColor: Color(0xFF2E7D32)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFD32F2F)),
        );
      }
    } finally {
      if (mounted) { setState(() => _isSaving = false); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TeacherProvider>();

    if (!provider.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!provider.isSubjectTeacher) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_off_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Score entry requires subject assignment', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text('Contact your admin to get assigned to a subject.', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
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
            Icon(Icons.class_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No classes assigned yet', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Enter Scores', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
          const SizedBox(height: 4),
          const Text('Select a class and subject to enter scores', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                  child: DropdownButton<String>(
                    value: _selectedClassId,
                    hint: const Text('Select Class', style: TextStyle(fontSize: 14)),
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.class_rounded, color: Color(0xFF0D47A1)),
                    items: myClasses.map((c) => DropdownMenuItem<String>(
                      value: c['id'].toString(),
                      child: Text('${c['name'] ?? ''} ${c['section'] ?? ''}'.trim(), overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                    )).toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedClassId = v;
                        _selectedSubjectId = null;
                        _clearControllers();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                  child: DropdownButton<String>(
                    value: _selectedSubjectId,
                    hint: const Text('Select Subject', style: TextStyle(fontSize: 14)),
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.menu_book, color: Color(0xFF0D47A1)),
                    items: _subjectsForSelectedClass.map((cs) {
                      final subj = cs['subjects'] as Map<String, dynamic>? ?? {};
                      return DropdownMenuItem<String>(
                        value: cs['subject_id'].toString(),
                        child: Text(subj['name']?.toString() ?? '', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedSubjectId = v;
                        _clearControllers();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_assessmentTypes.isNotEmpty && _selectedClassId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Assessment: ${_assessmentTypes.map((a) => "${a['name']}(${a['max']})").join(" + ")} = $_totalMaxScore', style: TextStyle(fontSize: 12, color: Colors.orange.shade900))),
                ],
              ),
            ),
          const SizedBox(height: 24),
          if (_selectedClassId != null && _selectedSubjectId != null)
            _isPrefilling
                ? const Center(child: Padding(padding: EdgeInsets.all(60), child: CircularProgressIndicator()))
                : _studentsInClass.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(60),
                          child: Column(
                            children: [
                              Icon(Icons.people_outline, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('No students in this class', style: TextStyle(fontSize: 16, color: Colors.grey)),
                            ],
                          ),
                        ),
                      )
                    : _buildScoreTable()
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(60),
                child: Column(
                  children: [
                    Icon(Icons.touch_app_outlined, size: 56, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Select class and subject to begin', style: TextStyle(fontSize: 15, color: Colors.grey)),
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
          decoration: const BoxDecoration(color: Color(0xFF0D47A1), borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10))),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const SizedBox(width: 40, child: Center(child: Text('#', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))),
                const SizedBox(width: 160, child: Center(child: Text('Student Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))),
                ..._assessmentTypes.map((at) => SizedBox(
                  width: 90,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('${at['name']}\n(${at['max']})', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ),
                )),
                const SizedBox(width: 70, child: Center(child: Text('Total', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))),
                const SizedBox(width: 60, child: Center(child: Text('Grade', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))),
              ],
            ),
          ),
        ),
        ..._studentsInClass.asMap().entries.map((entry) {
          final index = entry.key;
          final student = entry.value;
          final sid = student['id'].toString();
          final total = _getTotal(sid);
          final grade = _getGrade(total);
          final bgColor = index % 2 == 0 ? Colors.white : Colors.grey.shade50;
          return Container(
            color: bgColor,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(width: 40, child: Center(child: Text('${index + 1}', style: const TextStyle(fontSize: 12, color: Color(0xFF111827))))),
                  SizedBox(
                    width: 160,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Text(_studentName(student), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1B2A4A)), overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  ..._assessmentTypes.map((at) {
                    final key = (at['id'] ?? '').toString();
                    return SizedBox(
                      width: 90,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: TextField(
                          controller: _getController(sid, key),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF111827), fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 1.5)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            isDense: true,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    );
                  }),
                  SizedBox(
                    width: 70,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: total >= _totalMaxScore * 0.5 ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                      child: Text(total.toStringAsFixed(0), textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: total >= _totalMaxScore * 0.5 ? Colors.green.shade700 : Colors.red.shade700)),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: total >= _totalMaxScore * 0.5 ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                      child: Text(grade, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: total >= _totalMaxScore * 0.5 ? Colors.green.shade700 : Colors.red.shade700)),
                    ),
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
            icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save_rounded),
            label: Text(_isSaving ? "Saving..." : "Save All Scores", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white, shape: const StadiumBorder()),
          ),
        ),
      ],
    );
  }
}

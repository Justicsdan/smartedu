import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartedu/core/providers/school_admin_provider.dart';
import 'package:smartedu/utils/grading_utils.dart';

class PageResults extends StatefulWidget {
  final List<Map<String, dynamic>> classes;
  final List<Map<String, dynamic>> subjects;
  final List<Map<String, dynamic>> classSubjects;
  final List<Map<String, dynamic>> students;
  final List<Map<String, dynamic>> assignments;
  final List<Map<String, dynamic>> scores;
  final bool resultsVisible;
  final Function(List<Map<String, dynamic>>) onSaveScores;
  final Function(bool) onToggleVisibility;

  const PageResults({
    super.key,
    required this.classes,
    required this.subjects,
    required this.classSubjects,
    required this.students,
    required this.assignments,
    required this.scores,
    required this.resultsVisible,
    required this.onSaveScores,
    required this.onToggleVisibility,
  });

  @override
  State<PageResults> createState() => _PageResultsState();
}

class _PageResultsState extends State<PageResults> {
  String? _selectedClassId;
  String? _selectedSubjectId;
  bool _isSaving = false;
  bool _isExporting = false;
  final Map<String, TextEditingController> _controllers = {};

  String _studentName(Map<String, dynamic> s) {
    final first = (s['first_name'] ?? '').toString().trim();
    final last = (s['last_name'] ?? '').toString().trim();
    return '$first $last'.trim();
  }

  String _resolveSubjectName(Map<String, dynamic> cs) {
    final subj = cs['subjects'] as Map<String, dynamic>?;
    if (subj != null &&
        subj['name'] != null &&
        subj['name'].toString().isNotEmpty) {
      return subj['name'].toString();
    }
    final sid = cs['subject_id']?.toString() ?? '';
    if (sid.isEmpty) return 'Unknown';
    try {
      final found = widget.subjects
          .firstWhere((s) => s['id'].toString() == sid);
      return (found['name']?.toString() ?? '').isNotEmpty
          ? found['name'].toString()
          : 'Unknown';
    } catch (_) {
      return 'Unknown';
    }
  }

  List<Map<String, dynamic>> get _subjectsForClass {
    if (_selectedClassId == null) return [];
    return widget.classSubjects
        .where((cs) => cs['class_id'].toString() == _selectedClassId)
        .toList();
  }

  List<Map<String, dynamic>> get _studentsInClass {
    if (_selectedClassId == null) return [];
    return widget.students
        .where((s) => s['class_id'].toString() == _selectedClassId)
        .toList();
  }

  String _getClassName() {
    if (_selectedClassId == null) return '';
    try {
      final cls = widget.classes
          .firstWhere((c) => c['id'].toString() == _selectedClassId);
      final name = (cls['name'] ?? '').toString().trim();
      final section = (cls['section'] ?? '').toString().trim();
      return section.isNotEmpty ? '$name $section' : name;
    } catch (_) {
      return '';
    }
  }

  String _getSubjectName() {
    if (_selectedClassId == null || _selectedSubjectId == null) return '';
    try {
      final cs = _subjectsForClass
          .firstWhere((c) => c['subject_id'].toString() == _selectedSubjectId);
      return _resolveSubjectName(cs);
    } catch (_) {
      return '';
    }
  }

  String _getClassTier() {
    if (_selectedClassId == null) return 'SSS';
    try {
      final cls = widget.classes
          .firstWhere((c) => c['id'].toString() == _selectedClassId);
      return (cls['tier'] as String?) ?? 'SSS';
    } catch (_) {
      return 'SSS';
    }
  }

  List<Map<String, dynamic>> get _assessmentTypes {
    final tier = _getClassTier();
    final provider = context.read<SchoolAdminProvider>();
    final settings = provider.schoolSettings;
    if (settings != null) {
      if (tier == 'JSS' && settings['assessment_types_jss'] != null) {
        return List<Map<String, dynamic>>.from(
            settings['assessment_types_jss']);
      }
      if (tier == 'PRIMARY' && settings['assessment_types_primary'] != null) {
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

  double _getTotal(String studentId) {
    double total = 0;
    for (final at in _assessmentTypes) {
      final key = (at['id'] ?? '').toString();
      total +=
          double.tryParse(_getController(studentId, key).text) ?? 0;
    }
    return total;
  }

  String _getGrade(double score) {
    final tier = _getClassTier();
    final provider = context.read<SchoolAdminProvider>();
    final settings = provider.schoolSettings;
    List<Map<String, dynamic>> grading = [];
    if (settings != null) {
      if (tier == 'JSS' && settings['grading_system_jss'] != null) {
        grading = List<Map<String, dynamic>>.from(
            settings['grading_system_jss']);
      } else if (tier == 'PRIMARY' &&
          settings['grading_system_primary'] != null) {
        grading = List<Map<String, dynamic>>.from(
            settings['grading_system_primary']);
      } else if (settings['grading_system'] != null) {
        grading = List<Map<String, dynamic>>.from(
            settings['grading_system']);
      }
    }
    if (grading.isEmpty) {
      grading = GradingUtils.getDefaultGradingSystem('WAEC');
    }
    for (final g in grading) {
      final min = (g['min'] as num?)?.toDouble() ?? 0;
      final max = (g['max'] as num?)?.toDouble() ?? 100;
      if (score >= min && score <= max) {
        return (g['grade'] ?? 'F').toString();
      }
    }
    return 'F';
  }

  bool _isPassingGrade(double score) {
    final grade = _getGrade(score);
    final tier = _getClassTier();
    final provider = context.read<SchoolAdminProvider>();
    final gs = provider.getEffectiveGradingForTier(tier);
    return GradingUtils.isPassingGrade(grade, gs);
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
    final session = context.read<SchoolAdminProvider>().currentSession;
    final term = context.read<SchoolAdminProvider>().currentTerm;
    if (session == null || term == null) return;
    final sid = session['id'].toString();
    final tid = term['id'].toString();
    if (sid.isEmpty || tid.isEmpty) return;
    final classId = _selectedClassId!;
    final subjectId = _selectedSubjectId!;
    final schoolId = context.read<SchoolAdminProvider>().schoolId;
    for (final student in _studentsInClass) {
      final studentId = student['id'].toString();
      try {
        final r = await Supabase.instance.client
            .from('scores')
            .select()
            .eq('school_id', schoolId)
            .eq('student_id', studentId)
            .eq('class_id', classId)
            .eq('subject_id', subjectId)
            .eq('session_id', sid)
            .eq('term_id', tid)
            .maybeSingle();
        if (r != null) {
          final sj =
              r['scores_json'] as Map<String, dynamic>? ?? {};
          for (final at in _assessmentTypes) {
            final key = (at['id'] ?? '').toString().toLowerCase();
            final val = sj[key] ?? sj[at['name']] ?? 0;
            _getController(studentId, key).text =
                (val is num ? val : 0).toString();
          }
        }
      } catch (e) {
        debugPrint('Prefill error: $e');
      }
    }
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

  void _exportCsv() {
    if (_studentsInClass.isEmpty) return;
    setState(() => _isExporting = true);
    try {
      final className = _getClassName();
      final subjectName = _getSubjectName();
      final provider = context.read<SchoolAdminProvider>();
      final session = provider.currentSession;
      final term = provider.currentTerm;
      final sessionName = session?['name']?.toString() ?? '';
      final termName = term?['name']?.toString() ?? '';
      final assessmentHeaders = _assessmentTypes
          .map((a) => '${a['name']}(${a['max']})')
          .toList();
      final buffer = StringBuffer();
      buffer.writeln('Class: $className');
      buffer.writeln('Subject: $subjectName');
      buffer.writeln('Session: $sessionName');
      buffer.writeln('Term: $termName');
      buffer.writeln('Total: $_totalMaxScore');
      buffer.writeln();
      buffer.writeln(
          ['#', 'Student Name', ...assessmentHeaders, 'Total', 'Grade']
              .join(','));
      for (var i = 0; i < _studentsInClass.length; i++) {
        final student = _studentsInClass[i];
        final sid = student['id'].toString();
        final name = _studentName(student);
        final values = <String>[];
        values.add((i + 1).toString());
        final escapedName = name.contains(',') || name.contains('"')
            ? '"${name.replaceAll('"', '""')}"'
            : name;
        values.add(escapedName);
        for (final at in _assessmentTypes) {
          final key = (at['id'] ?? '').toString();
          values.add(_getController(sid, key).text.trim());
        }
        final total = _getTotal(sid);
        values.add(total.toStringAsFixed(0));
        values.add(_getGrade(total));
        buffer.writeln(values.join(','));
      }
      final bytes =
          Uint8List.fromList(buffer.toString().codeUnits);
      final blob = html.Blob([bytes], 'text/csv;charset=utf-8;');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download',
            '${className.replaceAll(' ', '_')}_${subjectName.replaceAll(' ', '_')}_scores.csv')
        ..click();
      html.Url.revokeObjectUrl(url);
      _snack('CSV exported successfully!');
    } catch (e) {
      debugPrint('CSV EXPORT ERR: $e');
      _snack('Export failed: $e', success: false);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _save() async {
    final session = context.read<SchoolAdminProvider>().currentSession;
    final term = context.read<SchoolAdminProvider>().currentTerm;
    final provider = context.read<SchoolAdminProvider>();
    if (session == null || term == null) return;
    final sid = session['id'].toString();
    final tid = term['id'].toString();
    if (sid.isEmpty || tid.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      final toSave = <Map<String, dynamic>>[];
      for (final student in _studentsInClass) {
        final studentId = student['id'].toString();
        final sj = <String, dynamic>{};
        for (final at in _assessmentTypes) {
          final key = (at['id'] ?? '').toString().toLowerCase();
          sj[key] =
              double.tryParse(_getController(studentId, key).text) ?? 0;
        }
        final total = _getTotal(studentId);
        toSave.add({
          'school_id': provider.schoolId,
          'student_id': studentId,
          'class_id': _selectedClassId,
          'subject_id': _selectedSubjectId,
          'session_id': sid,
          'term_id': tid,
          'scores_json': sj,
          'total': total,
          'grade': _getGrade(total),
          'recorded_by': provider.currentUserId,
        });
      }
      widget.onSaveScores(toSave);
      _snack('Scores saved successfully!');
    } catch (e) {
      _snack('Error: $e', success: false);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  static final _dropdownTheme = ThemeData.light().copyWith(
    canvasColor: Colors.white,
    textTheme: ThemeData.light().textTheme.apply(
      bodyColor: const Color(0xFF111827),
      displayColor: const Color(0xFF111827),
    ),
    hoverColor: const Color(0xFFF3F4F6),
    focusColor: const Color(0xFFF3F4F6),
    highlightColor: const Color(0xFFE0E7FF),
  );

  @override
  Widget build(BuildContext context) {
    if (!widget.resultsVisible) {
      return Container(
        color: const Color(0xFFF7F8FA),
        child: Center(
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
                child: const Icon(Icons.lock_outline,
                    size: 32, color: Color(0xFF4B5563)),
              ),
              const SizedBox(height: 16),
              const Text('Results are currently hidden',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827))),
              const SizedBox(height: 8),
              Text('Toggle visibility to enter scores',
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade700)),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => widget.onToggleVisibility(true),
                  icon: const Icon(Icons.visibility_rounded, size: 20),
                  label: const Text('Show Results',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFFF7F8FA),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Results / Score Entry',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                  letterSpacing: -0.5,
                )),
            const SizedBox(height: 4),
            const Text('Enter scores per subject per class',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 24),
            // Dropdowns row
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    value: _selectedClassId,
                    hint: 'Select Class',
                    items: widget.classes.map((c) {
                      final label =
                          '${c['name'] ?? ''} ${c['section'] ?? ''}'
                              .trim();
                      return DropdownMenuItem<String>(
                        value: c['id'].toString(),
                        child: Text(label,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Color(0xFF111827),
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedClassId = v;
                        _selectedSubjectId = null;
                        _clearControllers();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdown(
                    value: _selectedSubjectId,
                    hint: 'Select Subject',
                    items: _subjectsForClass.map((cs) {
                      final name = _resolveSubjectName(cs);
                      return DropdownMenuItem<String>(
                        value: cs['subject_id'].toString(),
                        child: Text(name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Color(0xFF111827),
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
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
                const SizedBox(width: 12),
                _buildHideButton(),
              ],
            ),
            const SizedBox(height: 12),
            // Assessment info
            if (_assessmentTypes.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 18, color: Color(0xFFB45309)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Assessment: ${_assessmentTypes.map((a) => "${a['name']}(${a['max']})").join(" + ")} = $_totalMaxScore',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            // Content
            if (_selectedClassId != null &&
                _selectedSubjectId != null)
              FutureBuilder(
                future: _prefill(),
                builder: (ctx, snapshot) {
                  if (_studentsInClass.isEmpty) {
                    return _buildEmptyState(
                      Icons.people_outline,
                      'No students in this class',
                    );
                  }
                  return _buildScoreTable();
                },
              )
            else
              _buildEmptyState(
                Icons.touch_app_outlined,
                'Select class and subject to begin',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.only(left: 14, right: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      alignment: Alignment.centerLeft,
      child: Theme(
        data: _dropdownTheme,
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            hint: Text(hint,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                )),
            icon: const Icon(Icons.arrow_drop_down,
                color: Color(0xFF6B7280), size: 22),
            isExpanded: true,
            items: items,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildHideButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => widget.onToggleVisibility(false),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.visibility_off,
                size: 18, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('Hide',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFFDC2626),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(60),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(18),
              ),
              child:
                  Icon(icon, size: 36, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreTable() {
    return Column(
      children: [
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _headerCell('#', 40),
                _headerCell('Student Name', 180),
                ..._assessmentTypes.map((at) => _headerCell(
                    '${at['name']}\n(${at['max']})', 100)),
                _headerCell('Total', 80),
                _headerCell('Grade', 70),
              ],
            ),
          ),
        ),
        const SizedBox(height: 2),
        // Table rows
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE8EAED)),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: _studentsInClass.asMap().entries.map((entry) {
              final index = entry.key;
              final student = entry.value;
              final sid = student['id'].toString();
              final total = _getTotal(sid);
              final grade = _getGrade(total);
              final passing = _isPassingGrade(total);
              final bgColor = index % 2 == 0
                  ? Colors.white
                  : const Color(0xFFFAFBFC);
              return Container(
                color: bgColor,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _indexCell(index, 40),
                      _nameCell(_studentName(student), 180),
                      ..._assessmentTypes.map((at) {
                        final key = (at['id'] ?? '').toString();
                        return _scoreInputCell(
                            sid, key, 100);
                      }),
                      _totalCell(total, passing, 80),
                      _gradeCell(grade, passing, 70),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
        // Action buttons
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save_rounded, size: 20),
                  label: Text(
                    _isSaving ? 'Saving...' : 'Save All Scores',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        const Color(0xFF1A237E).withOpacity(0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _isExporting ? null : _exportCsv,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFA5D6A7)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isExporting)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Color(0xFF2E7D32),
                            strokeWidth: 2),
                      )
                    else
                      const Icon(Icons.download_rounded,
                          size: 20, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 8),
                    Text(
                      _isExporting ? 'Exporting...' : 'Export CSV',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _headerCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _indexCell(int index, double width) {
    return SizedBox(
      width: width,
      child: Center(
        child: Text(
          '${index + 1}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }

  Widget _nameCell(String name, double width) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 10),
        child: Text(
          name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B2A4A),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _scoreInputCell(String studentId, String key, double width) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 6, vertical: 6),
        child: TextField(
          controller: _getController(studentId, key),
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(
                  color: Color(0xFF1A237E), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 6, vertical: 10),
            isDense: true,
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
    );
  }

  Widget _totalCell(double total, bool passing, double width) {
    final bgColor =
        passing ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
    final fgColor =
        passing ? const Color(0xFF166534) : const Color(0xFF991B1B);
    return SizedBox(
      width: width,
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: 6, vertical: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          total.toStringAsFixed(0),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: fgColor,
          ),
        ),
      ),
    );
  }

  Widget _gradeCell(String grade, bool passing, double width) {
    final bgColor =
        passing ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
    final fgColor =
        passing ? const Color(0xFF166534) : const Color(0xFF991B1B);
    return SizedBox(
      width: width,
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: 6, vertical: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          grade,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: fgColor,
          ),
        ),
      ),
    );
  }
}

import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:smartedu/core/services/db_proxy.dart';
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
  Future<void>? _prefillFuture;
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

  Listenable _studentListenable(String studentId) {
    return Listenable.merge(_assessmentTypes.map((at) => _getController(studentId, (at['id'] ?? '').toString())));
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
    try {
      final allScores = await DbProxy.instance.from('scores').select('student_id, scores_json').eq('school_id', schoolId).eq('class_id', classId).eq('subject_id', subjectId).eq('session_id', sid).eq('term_id', tid).get();
      final Map<String, Map<String, dynamic>> scoreMap = {};
      for (final row in allScores) {
        final sid2 = row['student_id'].toString();
        scoreMap[sid2] = row['scores_json'] as Map<String, dynamic>? ?? {};
      }
      for (final student in _studentsInClass) {
        final studentId = student['id'].toString();
        final sj = scoreMap[studentId] ?? {};
        for (final at in _assessmentTypes) {
          final key = (at['id'] ?? '').toString().toLowerCase();
          final val = sj[key] ?? sj[at['name']];
          _getController(studentId, key).text = val != null ? (val is num ? val : 0).toString() : '';
        }
      }
    } catch (e) {
      debugPrint('Prefill error: $e');
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

  void _printBlankSheet() {
    if (_studentsInClass.isEmpty) return;
    final provider = context.read<SchoolAdminProvider>();
    final className = _getClassName();
    final subjectName = _getSubjectName();
    final sessionName = provider.currentSession?['name']?.toString() ?? '';
    final termName = provider.currentTerm?['name']?.toString() ?? '';
    final schoolName = provider.schoolName;
    final schoolLogo = provider.schoolLogoUrl;
    final tier = _getClassTier();
    final sortedStudents = List<Map<String, dynamic>>.from(_studentsInClass);
    sortedStudents.sort((a, b) => _studentName(a).compareTo(_studentName(b)));
    final aHeaders = _assessmentTypes.map((a) => {'name': a['name'].toString(), 'max': a['max'].toString()}).toList();
    final assessmentSummary = aHeaders.map((a) => "${a['name']}(${a['max']})").join(' + ');
    final thCells = aHeaders.map((a) => "<th style=\"width:80px;\">${a['name']}<br/>(${a['max']})</th>").join('');
    final rows = sortedStudents.asMap().entries.map((e) =>
      '<tr><td>${e.key + 1}</td><td class="name">${_studentName(e.value)}</td>${aHeaders.map((_) => '<td></td>').join('')}<td></td><td></td></tr>'
    ).join('\n          ');
    final htmlContent = '''<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>Score Sheet - $className - $subjectName</title>
<style>
@page{size:A4 landscape;margin:10mm}
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:Arial,sans-serif;font-size:11px;color:#111}
.header{display:flex;align-items:center;justify-content:space-between;margin-bottom:8px;border-bottom:2px solid #1A237E;padding-bottom:8px}
.school-name{font-size:16px;font-weight:700;color:#1A237E}
.logo{height:50px}
.info{display:flex;gap:24px;margin-bottom:10px;font-size:12px;color:#374151}
.info span{font-weight:600}
table{width:100%;border-collapse:collapse}
th,td{border:1px solid #9CA3AF;padding:7px 8px;text-align:center}
th{background:#1E293B;color:white;font-weight:700;font-size:10px;text-transform:uppercase}
td.name{text-align:left;font-weight:600}
tr:nth-child(even) td{background:#F9FAFB}
.footer{margin-top:12px;display:flex;justify-content:space-between;font-size:10px;color:#6B7280}
.signature{margin-top:30px;display:flex;justify-content:flex-end;gap:80px}
.sig-line{text-align:center}
.sig-line .line{border-top:1px solid #111;width:150px;margin-top:30px}
.sig-line .label{font-size:10px;margin-top:4px}
.no-print{margin-bottom:10px}
@media print{.no-print{display:none}}
</style></head><body>
<div class="no-print"><button onclick="window.print()" style="padding:8px 20px;background:#1A237E;color:white;border:none;border-radius:6px;font-size:14px;cursor:pointer">Print This Sheet</button></div>
<div class="header"><div class="school-name">$schoolName</div>${schoolLogo.isNotEmpty ? '<img class="logo" src="$schoolLogo"/>' : ''}</div>
<div class="info"><div>Class: <span>$className</span>${tier.isNotEmpty ? ' [$tier]' : ''}</div><div>Subject: <span>$subjectName</span></div><div>Session: <span>$sessionName</span></div><div>Term: <span>$termName</span></div><div>Total: <span>$_totalMaxScore</span></div></div>
<table><thead><tr><th style="width:35px">#</th><th style="width:180px;text-align:left">Student Name</th>$thCells<th style="width:65px">Total</th><th style="width:55px">Grade</th></tr></thead>
<tbody>$rows</tbody></table>
<div class="footer"><div>Assessment: $assessmentSummary = $_totalMaxScore</div><div>${sortedStudents.length} students</div><div>Printed: ${DateTime.now().toString().split('.').first}</div></div>
<div class="signature"><div class="sig-line"><div class="line"></div><div class="label">Class Teacher</div></div><div class="sig-line"><div class="line"></div><div class="label">Subject Teacher</div></div><div class="sig-line"><div class="line"></div><div class="label">Principal</div></div></div>
</body></html>''';
    final blob = html.Blob([htmlContent], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    html.Url.revokeObjectUrl(url);
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
                        _prefillFuture = null;
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
                        _prefillFuture = null;
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
            if (_selectedClassId != null &&
                _selectedSubjectId != null)
              FutureBuilder(
                future: _prefillFuture ??= _prefill(),
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
                      ListenableBuilder(
                        listenable: _studentListenable(sid),
                        builder: (ctx, _) {
                          final t = _getTotal(sid);
                          final g = _getGrade(t);
                          final p = _isPassingGrade(t);
                          return Row(children: [_totalCell(t, p, 80), _gradeCell(g, p, 70)]);
                        },
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
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
              onTap: _studentsInClass.isEmpty ? null : _printBlankSheet,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFC5CAE9)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.print_rounded,
                        size: 20, color: Color(0xFF1A237E)),
                    SizedBox(width: 8),
                    Text(
                      'Blank Sheet',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                  ],
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
          // no setState — prevents web TextField rebuild bug
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

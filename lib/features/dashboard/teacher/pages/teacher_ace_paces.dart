import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartedu/core/providers/teacher/teacher_provider.dart';
import 'package:smartedu/core/services/db_proxy.dart';

class TeacherAcePacesPage extends StatefulWidget {
  const TeacherAcePacesPage({super.key});

  @override
  State<TeacherAcePacesPage> createState() => _TeacherAcePacesPageState();
}

class _TeacherAcePacesPageState extends State<TeacherAcePacesPage> {
  String? _selectedClassId;
  List<Map<String, dynamic>> _paceScores = [];
  Map<String, dynamic>? _selectedStudent;
  Map<String, List<Map<String, dynamic>>> _scoresBySubject = {};
  List<Map<String, dynamic>> _formMasterSubjects = [];
  bool _isLoadingStudent = false;
  bool _saving = false;

  List<Map<String, dynamic>> get _myClasses {
    final p = context.read<TeacherProvider>();
    final seen = <String>{};
    final classes = <Map<String, dynamic>>[];
    if (p.isFormMaster && p.formTeacherAssignment != null) {
      final cls = p.formTeacherAssignment!;
      final id = cls['id']?.toString() ?? '';
      if (id.isNotEmpty && !seen.contains(id)) {
        seen.add(id);
        classes.add(cls);
      }
    }
    for (final a in p.mySubjectAssignments) {
      final cls = a['classes'] as Map<String, dynamic>? ?? {};
      final id = cls['id']?.toString() ?? '';
      if (id.isNotEmpty && !seen.contains(id)) {
        seen.add(id);
        classes.add(cls);
      }
    }
    return classes;
  }

  Future<void> _loadFormMasterSubjects() async {
    if (_selectedClassId == null) {
      if (mounted) setState(() => _formMasterSubjects = []);
      return;
    }
    try {
      final result = await DbProxy.instance
          .from('class_subjects')
          .select('*, subjects(name, code)')
          .eq('class_id', _selectedClassId)
          .get();
      if (mounted) {
        setState(() {
          _formMasterSubjects = result
              .map((r) => r['subjects'] as Map<String, dynamic>? ?? {})
              .where((s) => s.isNotEmpty)
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading class subjects: $e');
    }
  }

  List<Map<String, dynamic>> get _mySubjectsInClass {
    final p = context.read<TeacherProvider>();
    if (_selectedClassId == null) return [];
    if (p.isFormMaster && p.formTeacherClassId == _selectedClassId) {
      return _formMasterSubjects;
    }
    return p.mySubjectAssignments
        .where((a) =>
            (a['class_id']?.toString() ?? '') == _selectedClassId ||
            (a['classes']?['id']?.toString() ?? '') == _selectedClassId)
        .map((a) => a['subjects'] as Map<String, dynamic>? ?? {})
        .where((s) => s.isNotEmpty)
        .toList();
  }

  List<Map<String, dynamic>> get _studentsInClass {
    final p = context.read<TeacherProvider>();
    if (_selectedClassId == null) return [];
    return p.students
        .where((s) => s['class_id']?.toString() == _selectedClassId)
        .toList();
  }

  String _name(Map<String, dynamic> s) {
    final f = (s['first_name'] ?? '').toString().trim();
    final l = (s['last_name'] ?? '').toString().trim();
    if (f.isNotEmpty && l.isNotEmpty) return '$f $l';
    return f.isNotEmpty ? f : l;
  }

  Future<void> _loadAndShow(Map<String, dynamic> student) async {
    setState(() {
      _isLoadingStudent = true;
      _selectedStudent = student;
    });
    final p = context.read<TeacherProvider>();
    final sid = p.currentSession?['id']?.toString() ?? '';
    final tid = p.currentTerm?['id']?.toString() ?? '';
    if (sid.isEmpty || tid.isEmpty) {
      if (mounted) setState(() => _isLoadingStudent = false);
      return;
    }
    try {
      final result = await DbProxy.instance
          .from('ace_pace_scores')
          .select()
          .eq('student_id', student['id'])
          .eq('session_id', sid)
          .eq('term_id', tid)
          .get();
      final scores = List<Map<String, dynamic>>.from(result);
      final bySub = <String, List<Map<String, dynamic>>>{};
      for (final sc in scores) {
        final subId = sc['subject_id']?.toString() ?? '';
        bySub.putIfAbsent(subId, () => []).add(sc);
      }
      for (final sub in _mySubjectsInClass) {
        bySub.putIfAbsent(sub['id']?.toString() ?? '', () => []);
      }
      if (mounted) {
        setState(() {
          _paceScores = scores;
          _scoresBySubject = bySub;
          _isLoadingStudent = false;
        });
        _showSheet();
      }
    } catch (e) {
      debugPrint('Error loading PACE scores: $e');
      if (mounted) setState(() => _isLoadingStudent = false);
    }
  }

  void _showSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE8EAED))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_name(_selectedStudent!),
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          const Text('Enter PACE scores per subject',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF9CA3AF))),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 22),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final sub in _mySubjectsInClass) ...[
                      _buildSubjectBlock(sub, setModal),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFE8EAED))),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saving ? null : () => _save(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Save PACE Scores',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectBlock(
      Map<String, dynamic> sub, StateSetter setModal) {
    final subId = sub['id']?.toString() ?? '';
    final subName = (sub['name'] ?? 'Unknown').toString();
    final paces = _scoresBySubject[subId] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0D47A1).withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.menu_book,
                  size: 16, color: Color(0xFF0D47A1)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(subName,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0D47A1)),
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _scoresBySubject.putIfAbsent(subId, () => []);
                    _scoresBySubject[subId]!.add({
                      'subject_id': subId,
                      'pace_no': '',
                      'pt_score': null,
                    });
                  });
                  setModal(() {});
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D47A1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('+ PACE',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        for (int i = 0; i < paces.length; i++) ...[
          _buildPaceRow(subId, i, setModal),
          const SizedBox(height: 6),
        ],
        if (paces.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('No PACE entries \u2014 tap "+ PACE" to add',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                    fontStyle: FontStyle.italic)),
          ),
      ],
    );
  }

  Widget _buildPaceRow(String subId, int index, StateSetter setModal) {
    final paces = _scoresBySubject[subId] ?? [];
    final pace = paces[index];
    final ptScore = pace['pt_score'];
    final isLow = ptScore != null && (ptScore as num).toDouble() < 80;
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: TextFormField(
            initialValue: (pace['pace_no'] ?? '').toString(),
            decoration: const InputDecoration(
              hintText: 'PACE No.',
              hintStyle: TextStyle(fontSize: 12),
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(fontSize: 13),
            onChanged: (v) {
              pace['pace_no'] = v;
              setModal(() {});
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: TextFormField(
            initialValue:
                ptScore != null ? (ptScore as num).toString() : '',
            decoration: InputDecoration(
              hintText: 'PT %',
              hintStyle: TextStyle(
                  fontSize: 12,
                  color: isLow ? const Color(0xFFDC2626) : null),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              border: OutlineInputBorder(
                borderSide: isLow
                    ? const BorderSide(color: Color(0xFFDC2626))
                    : const BorderSide(color: Color(0xFFE8EAED)),
              ),
            ),
            style: TextStyle(
                fontSize: 13,
                color: isLow ? const Color(0xFFDC2626) : null),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) {
              final parsed = double.tryParse(v);
              if (parsed != null) pace['pt_score'] = parsed;
              setModal(() {});
            },
          ),
        ),
        if (paces.length > 1) ...[
          const SizedBox(width: 4),
          InkWell(
            onTap: () {
              setState(() => _scoresBySubject[subId]?.removeAt(index));
              setModal(() {});
            },
            child: const Icon(Icons.remove_circle_outline,
                size: 20, color: Color(0xFFDC2626)),
          ),
        ],
        if (isLow) ...[
          const SizedBox(width: 4),
          const Icon(Icons.warning_amber, size: 18, color: Color(0xFFDC2626)),
        ],
      ],
    );
  }

  Future<void> _save(BuildContext sheetCtx) async {
    if (_selectedStudent == null) return;
    setState(() => _saving = true);
    final p = context.read<TeacherProvider>();
    final sid = p.currentSession?['id']?.toString() ?? '';
    final tid = p.currentTerm?['id']?.toString() ?? '';
    try {
      for (final entry in _scoresBySubject.entries) {
        final subId = entry.key;
        final paces = entry.value;
        for (final pace in paces) {
          final paceNo = (pace['pace_no'] ?? '').toString().trim();
          if (paceNo.isEmpty) continue;
          final ptScore = pace['pt_score'] != null
              ? (pace['pt_score'] as num).toDouble()
              : null;
          if (pace['id'] != null) {
            await DbProxy.instance
                .from('ace_pace_scores')
                .eq('id', pace['id'])
                .update({'pace_no': paceNo, 'pt_score': ptScore});
          } else {
            await DbProxy.instance.from('ace_pace_scores').insert({
              'school_id': p.schoolId,
              'student_id': _selectedStudent!['id'],
              'subject_id': subId,
              'session_id': sid,
              'term_id': tid,
              'pace_no': paceNo,
              'pt_score': ptScore,
              'recorded_by': p.teacherId,
            });
          }
        }
      }
      if (mounted) {
        Navigator.pop(sheetCtx);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('PACE scores saved successfully'),
          backgroundColor: Color(0xFF2E7D32),
        ));
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Color(0xFFD32F2F),
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TeacherProvider>();
    final classes = _myClasses;
    final subjects = _mySubjectsInClass;
    final students = _studentsInClass;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PACE Score Entry',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827))),
            const SizedBox(height: 4),
            Text(
                'Session: ${p.currentSession?['name'] ?? 'N/A'}  \u00B7  Term: ${p.currentTerm?['name'] ?? 'N/A'}',
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF9CA3AF))),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8EAED)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Class',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280))),
                  const SizedBox(height: 8),
                  if (classes.isEmpty)
                    const Text('No classes assigned yet',
                        style: TextStyle(
                            fontSize: 13, color: Color(0xFF9CA3AF)))
                  else
                    DropdownButtonFormField<String>(
                      value: _selectedClassId,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      items: classes.map((c) {
                        final name =
                            '${c['name'] ?? ''} ${c['section'] ?? ''}'.trim();
                        return DropdownMenuItem(
                            value: c['id']?.toString(), child: Text(name));
                      }).toList(),
                      onChanged: (v) {
                        setState(() {
                          _selectedClassId = v;
                          _selectedStudent = null;
                          _paceScores = [];
                          _scoresBySubject = {};
                          _formMasterSubjects = [];
                        });
                        _loadFormMasterSubjects();
                      },
                    ),
                ],
              ),
            ),
            if (_selectedClassId != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                    '${subjects.length} subject${subjects.length != 1 ? 's' : ''}  \u00B7  ${students.length} student${students.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF9CA3AF))),
              ),
              const SizedBox(height: 12),
              if (students.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE8EAED)),
                  ),
                  child: const Center(
                      child: Text('No students in this class',
                          style: TextStyle(
                              fontSize: 14, color: Color(0xFF9CA3AF)))),
                )
              else
                for (final s in students) _buildStudentCard(s),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> s) {
    final stuId = s['id']?.toString() ?? '';
    final stuScores = _paceScores
        .where((sc) => sc['student_id']?.toString() == stuId)
        .toList();
    final ptVals = stuScores
        .map((sc) => sc['pt_score'] as num?)
        .where((v) => v != null)
        .cast<num>();
    final avg = ptVals.isNotEmpty
        ? ptVals.reduce((a, b) => a + b) / ptVals.length
        : 0.0;
    final isLow = avg > 0 && avg < 80;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFF0D47A1).withOpacity(0.1),
          child: Text(
            _name(s)[0].toUpperCase(),
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D47A1),
                fontSize: 14),
          ),
        ),
        title: Text(_name(s),
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Text((s['admission_no'] ?? '').toString(),
            style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (stuScores.isNotEmpty) ...[
              Text('${stuScores.length} PACEs',
                  style: TextStyle(
                      fontSize: 11,
                      color: isLow
                          ? const Color(0xFFD32F2F)
                          : const Color(0xFF2E7D32),
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isLow
                      ? const Color(0xFFFFEBEE)
                      : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(avg.toStringAsFixed(1),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isLow
                            ? const Color(0xFFD32F2F)
                            : const Color(0xFF2E7D32))),
              ),
            ] else
              const Text('No scores',
                  style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
            const SizedBox(width: 8),
            if (_isLoadingStudent &&
                _selectedStudent?['id'] == s['id'])
              const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(strokeWidth: 2))
            else
              const Icon(Icons.chevron_right,
                  size: 18, color: Color(0xFF9CA3AF)),
          ],
        ),
        onTap:
            _isLoadingStudent ? null : () => _loadAndShow(s),
      ),
    );
  }
}

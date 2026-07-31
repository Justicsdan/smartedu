import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/school_admin_provider.dart';
import '../../../../core/services/db_proxy.dart';

class PageAcePaces extends StatefulWidget {
  const PageAcePaces({super.key});

  @override
  State<PageAcePaces> createState() => _PageAcePacesState();
}

class _PageAcePacesState extends State<PageAcePaces> {
  String? _selectedClassId;
  bool _loading = false;
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _subjects = [];
  Map<String, List<Map<String, dynamic>>> _allPaceScores = {};

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final provider = context.read<SchoolAdminProvider>();
    try {
      final result = await DbProxy.instance
          .from('subjects')
          .eq('school_id', provider.schoolId)
          .order('name', ascending: true)
          .get();
      setState(() => _subjects = List<Map<String, dynamic>>.from(result));
    } catch (_) {}
  }

  Future<void> _loadStudents() async {
    if (_selectedClassId == null) return;
    setState(() => _loading = true);
    final provider = context.read<SchoolAdminProvider>();
    try {
      final studentResult = await DbProxy.instance
          .from('students')
          .eq('class_id', _selectedClassId)
          .eq('is_active', true)
          .order('first_name', ascending: true)
          .select('id, first_name, middle_name, last_name, admission_no')
          .get();
      final students = List<Map<String, dynamic>>.from(studentResult);

      final Map<String, List<Map<String, dynamic>>> scoreMap = {};
      for (final s in students) {
        final sid = s['id'].toString();
        try {
          final scores = await DbProxy.instance
              .from('ace_pace_scores')
              .eq('student_id', sid)
              .eq('session_id', provider.currentSession?['id']?.toString() ?? '')
              .eq('term_id', provider.currentTerm?['id']?.toString() ?? '')
              .get();
          scoreMap[sid] = List<Map<String, dynamic>>.from(scores);
        } catch (_) {
          scoreMap[sid] = [];
        }
      }

      setState(() {
        _students = students;
        _allPaceScores = scoreMap;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  String _studentName(Map<String, dynamic> s) {
    return '${s['first_name'] ?? ''} ${s['middle_name'] ?? ''} ${s['last_name'] ?? ''}'.trim();
  }

  int _paceCountForStudent(String studentId) {
    return _allPaceScores[studentId]?.length ?? 0;
  }

  double? _avgScoreForStudent(String studentId) {
    final scores = _allPaceScores[studentId] ?? [];
    final valid = scores.where((s) => s['pt_score'] != null).toList();
    if (valid.isEmpty) return null;
    final sum = valid.fold<double>(0, (a, s) => a + (s['pt_score'] as num).toDouble());
    return sum / valid.length;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SchoolAdminProvider>();
    final classes = provider.classes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PACE Scores'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE8EAED)),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedClassId,
                hint: const Text('Select Class'),
                isExpanded: true,
                decoration: const InputDecoration(border: InputBorder.none),
                items: classes.map((c) {
                  return DropdownMenuItem(
                    value: c['id'].toString(),
                    child: Text('${c['name'] ?? ''}${(c['section'] ?? '').toString().isNotEmpty ? ' ${c['section']}' : ''}'),
                  );
                }).toList(),
                onChanged: (v) {
                  setState(() => _selectedClassId = v);
                  _loadStudents();
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Session: ${provider.currentSession?['name'] ?? '-'} | Term: ${provider.currentTerm?['name'] ?? '-'}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_selectedClassId == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Text('Select a class to begin', style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
                ),
              )
            else if (_students.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Text('No students in this class', style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _students.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    if (index >= _students.length) return const SizedBox.shrink();
                    final s = _students[index];
                    final sid = s['id'].toString();
                    final paceCount = _paceCountForStudent(sid);
                    final avg = _avgScoreForStudent(sid);

                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFFF0F4FF),
                          child: Text(
                            _studentName(s).isEmpty ? '?' : _studentName(s)[0].toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A237E)),
                          ),
                        ),
                        title: Text(
                          _studentName(s),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Text(s['admission_no'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$paceCount PACE${paceCount != 1 ? 's' : ''}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                                ),
                                if (avg != null)
                                  Text(
                                    'Avg: ${avg.toStringAsFixed(1)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: avg < 80 ? const Color(0xFFDC2626) : const Color(0xFF2E7D32),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
                          ],
                        ),
                        onTap: () => _openPaceSheet(s),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openPaceSheet(Map<String, dynamic> student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      isDismissible: false,
      builder: (ctx) => _PaceEntrySheet(
        student: student,
        subjects: _subjects,
        existingScores: _allPaceScores[student['id'].toString()] ?? [],
        onSave: (scoresToDelete, scoresToSave) async {
          for (final id in scoresToDelete) {
            await DbProxy.instance.from('ace_pace_scores').eq('id', id).delete();
          }
          for (final s in scoresToSave) {
            final provider = context.read<SchoolAdminProvider>();
            await provider.savePaceScore(
              id: s['id']?.toString(),
              studentId: student['id'].toString(),
              subjectId: s['subject_id'] as String,
              sessionId: provider.currentSession?['id']?.toString() ?? '',
              termId: provider.currentTerm?['id']?.toString() ?? '',
              paceNo: s['pace_no'] as String,
              ptScore: (s['pt_score'] as num).toDouble(),
            );
          }
        },
        onSaved: () {
          Navigator.pop(ctx);
          _loadStudents();
        },
      ),
    );
  }
}

class _PaceEntrySheet extends StatefulWidget {
  final Map<String, dynamic> student;
  final List<Map<String, dynamic>> subjects;
  final List<Map<String, dynamic>> existingScores;
  final Future<void> Function(List<String> deleted, List<Map<String, dynamic>> saved) onSave;
  final VoidCallback onSaved;

  const _PaceEntrySheet({
    required this.student,
    required this.subjects,
    required this.existingScores,
    required this.onSave,
    required this.onSaved,
  });

  @override
  State<_PaceEntrySheet> createState() => _PaceEntrySheetState();
}

class _PaceEntrySheetState extends State<_PaceEntrySheet> {
  late Map<String, List<Map<String, dynamic>>> _subjectPaces;
  bool _saving = false;

  String _studentName() {
    return '${widget.student['first_name'] ?? ''} ${widget.student['middle_name'] ?? ''} ${widget.student['last_name'] ?? ''}'.trim();
  }

  @override
  void initState() {
    super.initState();
    _subjectPaces = {};
    for (final sub in widget.subjects) {
      final subId = sub['id'].toString();
      final paces = widget.existingScores
          .where((s) => s['subject_id'].toString() == subId)
          .toList();
      if (paces.isEmpty) {
        _subjectPaces[subId] = [
          {'subject_id': subId, 'pace_no': '', 'pt_score': null, 'is_new': true}
        ];
      } else {
        _subjectPaces[subId] = paces.map((p) => Map<String, dynamic>.from(p)).toList();
      }
    }
  }

  void _addPaceSlot(String subjectId) {
    setState(() {
      _subjectPaces[subjectId]!.add({
        'subject_id': subjectId,
        'pace_no': '',
        'pt_score': null,
        'is_new': true,
      });
    });
  }

  final List<String> _pendingDeletes = [];

  void _removePaceSlot(String subjectId, int index) {
    final pace = _subjectPaces[subjectId]![index];
    if (pace['id'] != null) _pendingDeletes.add(pace['id'].toString());
    setState(() {
      _subjectPaces[subjectId]!.removeAt(index);
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final List<String> toDelete = [];
      final List<Map<String, dynamic>> toSave = [];

      for (final entry in _subjectPaces.entries) {
        for (final pace in entry.value) {
          final paceNo = (pace['pace_no'] as String?)?.trim() ?? '';
          final ptScore = pace['pt_score'];

          if (paceNo.isEmpty && ptScore == null) continue;

          if (pace['is_new'] == true) {
            if (paceNo.isNotEmpty && ptScore != null) {
              toSave.add({
                'subject_id': entry.key,
                'pace_no': paceNo,
                'pt_score': ptScore,
              });
            }
          } else {
            if (paceNo.isEmpty && ptScore == null) {
              toDelete.add(pace['id'].toString());
            } else {
              toSave.add({
                'id': pace['id'],
                'subject_id': entry.key,
                'pace_no': paceNo,
                'pt_score': ptScore,
              });
            }
          }
        }
      }

      toDelete.addAll(_pendingDeletes);
      await widget.onSave(toDelete, toSave);
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _studentName(),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                      ),
                      Text(
                        widget.student['admission_no'] ?? '',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: widget.subjects.length,
                itemBuilder: (context, index) {
                  if (index >= widget.subjects.length) return const SizedBox.shrink();
                  final sub = widget.subjects[index];
                  final subId = sub['id'].toString();
                  final paces = _subjectPaces[subId] ?? [];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              sub['name'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF111827)),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: () => _addPaceSlot(subId),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_circle_outline, size: 18, color: Color(0xFF1A237E)),
                                  SizedBox(width: 4),
                                  Text('Add PACE', style: TextStyle(fontSize: 12, color: Color(0xFF1A237E))),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...paces.asMap().entries.map((entry) {
                          final i = entry.key;
                          if (i >= paces.length) return const SizedBox.shrink();
                          final pace = entry.value;
                          final ptScore = pace['pt_score'];
                          final isLow = ptScore != null && (ptScore as num).toDouble() < 80;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 120,
                                  child: TextFormField(
                                    initialValue: pace['pace_no'] ?? '',
                                    decoration: const InputDecoration(
                                      hintText: 'PACE No.',
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                      border: OutlineInputBorder(),
                                    ),
                                    style: const TextStyle(fontSize: 13),
                                    onChanged: (v) => pace['pace_no'] = v,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 80,
                                  child: TextFormField(
                                    initialValue: ptScore != null ? (ptScore as num).toString() : '',
                                    decoration: InputDecoration(
                                      hintText: 'PT %',
                                      hintStyle: TextStyle(fontSize: 12, color: isLow ? const Color(0xFFDC2626) : null),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                      border: OutlineInputBorder(
                                        borderSide: isLow ? const BorderSide(color: Color(0xFFDC2626)) : const BorderSide(color: Color(0xFFE8EAED)),
                                      ),
                                    ),
                                    style: TextStyle(fontSize: 13, color: isLow ? const Color(0xFFDC2626) : null),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    onChanged: (v) {
                                      final parsed = double.tryParse(v);
                                      if (parsed != null) { pace['pt_score'] = parsed; setState(() {}); }
                                    },
                                  ),
                                ),
                                if (paces.length > 1) ...[
                                  const SizedBox(width: 4),
                                  InkWell(
                                    onTap: () => _removePaceSlot(subId, i),
                                    child: const Icon(Icons.remove_circle_outline, size: 20, color: Color(0xFFDC2626)),
                                  ),
                                ],
                                if (isLow) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.warning_amber, size: 18, color: Color(0xFFDC2626)),
                                ],
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save All PACE Scores', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

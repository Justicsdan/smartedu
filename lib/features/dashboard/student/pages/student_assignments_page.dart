// ==========================================
// File: lib/features/dashboard/student/pages/student_assignments_page.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartedu/core/services/db_proxy.dart';
import 'package:smartedu/core/providers/student/student_provider.dart';

class StudentAssignmentsPage extends StatefulWidget {
  const StudentAssignmentsPage({super.key});

  @override
  State<StudentAssignmentsPage> createState() => _StudentAssignmentsPageState();
}

class _StudentAssignmentsPageState extends State<StudentAssignmentsPage> {
  List<Map<String, dynamic>> _assignments = [];
  Set<String> _submittedIds = {};
  Map<String, Map<String, dynamic>> _mySubmissions = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final provider = context.read<StudentProvider>();

      // Get student's class_id
      final classId = provider.classId;
      if (classId.isEmpty) {
        if (mounted) setState(() { _loading = false; });
        return;
      }

      // Fetch published assignments for this class
      final assignR = await DbProxy.instance
          .from('assignments')
          .select('*, subjects(name, code), classes(name, section)')
          .eq('class_id', classId)
          .eq('is_published', true)
          .order('created_at', ascending: false)
          .get();

      final assigns = List<Map<String, dynamic>>.from(assignR);

      // Fetch this student's submissions for these assignments
      if (assigns.isNotEmpty) {
        final assignIds = assigns.map((a) => a['id'].toString()).toList();
        final subR = await DbProxy.instance
            .from('assignment_submissions')
            .select()
            .eq('student_id', provider.studentId)
            .inFilter('assignment_id', assignIds)
            .get();

        final subs = List<Map<String, dynamic>>.from(subR);
        final subMap = <String, Map<String, dynamic>>{};
        final subIds = <String>{};
        for (final s in subs) {
          final aid = s['assignment_id']?.toString() ?? '';
          if (aid.isNotEmpty) {
            subMap[aid] = s;
            subIds.add(aid);
          }
        }

        if (mounted) {
          setState(() {
            _assignments = assigns;
            _submittedIds = subIds;
            _mySubmissions = subMap;
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() { _assignments = assigns; _loading = false; });
      }
    } catch (e) {
      debugPrint('Load assignments error: $e');
      if (mounted) setState(() { _error = 'Failed to load assignments'; _loading = false; });
    }
  }

  String _getClassName(Map<String, dynamic> a) {
    final cls = a['classes'] as Map<String, dynamic>? ?? {};
    final name = cls['name'] ?? '';
    final section = cls['section'] ?? '';
    return section.isNotEmpty ? '$name $section' : name;
  }

  String _getSubjectName(Map<String, dynamic> a) {
    final subj = a['subjects'] as Map<String, dynamic>? ?? {};
    return subj['name']?.toString() ?? '';
  }

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return '';
    final dt = DateTime.tryParse(dateVal.toString());
    if (dt == null) return '';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  bool _isOverdue(dynamic dateVal) {
    if (dateVal == null) return false;
    final dt = DateTime.tryParse(dateVal.toString());
    if (dt == null) return false;
    return dt.isBefore(DateTime.now());
  }

  void _showSubmitSheet(BuildContext context, Map<String, dynamic> assignment) {
    final textCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: const Color(0xFFF0FFF4), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.send_outlined, size: 18, color: Color(0xFF2E7D32)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      assignment['title'] ?? 'Submit Assignment',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('${_getSubjectName(assignment)}  ·  ${_getClassName(assignment)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 20),
              TextField(
                controller: textCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Your Answer *',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    if (textCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Write your answer first'), backgroundColor: Color(0xFFD32F2F)),
                      );
                      return;
                    }
                    try {
                      final provider = context.read<StudentProvider>();
                      await DbProxy.instance.from('assignment_submissions').insert({
                        'school_id': provider.schoolId,
                        'assignment_id': assignment['id'],
                        'student_id': provider.studentId,
                        'submission_text': textCtrl.text.trim(),
                      });
                      if (mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Submitted successfully'), backgroundColor: Color(0xFF2E7D32)),
                        );
                        _loadData();
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Submission failed: $e'), backgroundColor: Color(0xFFD32F2F)),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Submit', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)));
    }
    if (_error != null) {
      return Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Assignments', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827), letterSpacing: -0.5)),
          const SizedBox(height: 4),
          const Text('Homework from your teachers', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 20),
          if (_assignments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(60),
                child: Column(
                  children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.assignment_outlined, size: 32, color: Color(0xFFF57F17)),
                    ),
                    const SizedBox(height: 16),
                    const Text('No assignments yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                    const SizedBox(height: 4),
                    const Text('Your assignments will appear here when published', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            ..._assignments.map((a) {
              final aid = a['id'].toString();
              final isSubmitted = _submittedIds.contains(aid);
              final sub = _mySubmissions[aid];
              final isGraded = sub != null && sub['graded_at'] != null;
              final overdue = _isOverdue(a['due_date']);
              final dueStr = _formatDate(a['due_date']);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isGraded ? const Color(0xFF2E7D32) : const Color(0xFFE8EAED)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: isGraded ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.assignment, size: 22, color: isGraded ? const Color(0xFF2E7D32) : const Color(0xFFF57F17)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a['title'] ?? 'Untitled', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                              const SizedBox(height: 4),
                              Text('${_getSubjectName(a)}  ·  ${_getClassName(a)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        if (isGraded)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(6)),
                            child: Text('${sub?['score'] ?? ''}/${a['total_marks'] ?? ''}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32))),
                          )
                        else if (isSubmitted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(6)),
                            child: const Text('Submitted', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1A237E))),
                          )
                        else if (overdue)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                            child: Text('Overdue', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.red.shade700)),
                          ),
                      ],
                    ),
                    if (a['description'] != null && (a['description'] as String).isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFFFAFBFC), borderRadius: BorderRadius.circular(8)),
                        child: Text(a['description'], style: const TextStyle(fontSize: 13, color: Color(0xFF555555), height: 1.4)),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (dueStr.isNotEmpty) ...[
                          Icon(Icons.schedule, size: 14, color: overdue ? Colors.red.shade400 : Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text('Due: $dueStr', style: TextStyle(fontSize: 11, color: overdue ? Colors.red.shade400 : Colors.grey.shade500)),
                          const SizedBox(width: 16),
                        ],
                        Icon(Icons.star_outline, size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text('${a['total_marks'] ?? ''} marks', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        const Spacer(),
                        if (!isSubmitted)
                          GestureDetector(
                            onTap: () => _showSubmitSheet(context, a),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(border: Border.all(color: const Color(0xFF1A237E)), borderRadius: BorderRadius.circular(6)),
                              child: const Text('Submit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A237E))),
                            ),
                          ),
                        if (isGraded && sub?['teacher_remark'] != null && (sub!['teacher_remark'] as String).isNotEmpty)
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.comment_outlined, size: 14, color: Color(0xFF2E7D32)),
                              SizedBox(width: 4),
                              Text('See feedback', style: TextStyle(fontSize: 11, color: Color(0xFF2E7D32), fontWeight: FontWeight.w500)),
                            ],
                          ),
                      ],
                    ),
                    if (isGraded && sub?['teacher_remark'] != null && (sub!['teacher_remark'] as String).isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.rate_review_outlined, size: 16, color: Color(0xFF2E7D32)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(sub!['teacher_remark'], style: const TextStyle(fontSize: 12, color: Color(0xFF2E7D32), height: 1.4))),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

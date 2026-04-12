// ==========================================
// File: lib/features/dashboard/teacher/pages/teacher_assignments.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartedu/core/providers/teacher/teacher_provider.dart';

class TeacherAssignmentsPage extends StatefulWidget {
  const TeacherAssignmentsPage({super.key});

  @override
  State<TeacherAssignmentsPage> createState() => _TeacherAssignmentsPageState();
}

class _TeacherAssignmentsPageState extends State<TeacherAssignmentsPage> {
  String _filterClassId = 'all';

  String _getClassName(Map<String, dynamic> a) {
    final cls = a['classes'] as Map<String, dynamic>? ?? {};
    final name = cls['name'] ?? '';
    final section = cls['section'] ?? '';
    return section.isNotEmpty ? '$name $section' : name;
  }

  String _getSubjectName(Map<String, dynamic> a) {
    final subj = a['subjects'] as Map<String, dynamic>? ?? {};
    return subj['name']?.toString() ?? 'Unknown';
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

  void _showAddSheet(BuildContext context, TeacherProvider provider) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final marksCtrl = TextEditingController(text: '20');
    String? selectedClassId;
    String? selectedSubjectId;
    DateTime? dueDate;

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
                    decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.assignment_outlined, size: 18, color: Color(0xFFF57F17)),
                  ),
                  const SizedBox(width: 12),
                  const Text('New Assignment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  prefixIcon: Icon(Icons.title_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: selectedClassId,
                decoration: const InputDecoration(
                  labelText: 'Class *',
                  prefixIcon: Icon(Icons.class_outlined),
                  border: OutlineInputBorder(),
                ),
                items: provider.assignedClassIds
                    .map((id) => DropdownMenuItem(value: id, child: Text(provider.getClassName(id))))
                    .toList(),
                onChanged: (v) => setSt(() { selectedClassId = v; selectedSubjectId = null; }),
              ),
              const SizedBox(height: 14),
              if (selectedClassId != null)
                DropdownButtonFormField<String>(
                  value: selectedSubjectId,
                  decoration: const InputDecoration(
                    labelText: 'Subject *',
                    prefixIcon: Icon(Icons.book_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: provider.assignedSubjects
                      .where((a) => a['class_id']?.toString() == selectedClassId)
                      .map((a) => DropdownMenuItem(
                            value: a['subject_id']?.toString(),
                            child: Text(provider.getSubjectName(a['subject_id'])),
                          ))
                      .toList(),
                  onChanged: (v) => setSt(() => selectedSubjectId = v),
                ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: marksCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Total Marks',
                        prefixIcon: Icon(Icons.star_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) setSt(() => dueDate = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Due Date',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          dueDate != null ? _formatDate(dueDate!.toIso8601String()) : 'Pick a date',
                          style: TextStyle(fontSize: 14, color: dueDate != null ? const Color(0xFF111827) : Colors.grey.shade500),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty || selectedClassId == null || selectedSubjectId == null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Fill required fields'), backgroundColor: Color(0xFFD32F2F)),
                      );
                      return;
                    }
                    provider.addAssignment({
                      'title': titleCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                      'class_id': selectedClassId,
                      'subject_id': selectedSubjectId,
                      'due_date': dueDate?.toIso8601String(),
                      'total_marks': int.tryParse(marksCtrl.text) ?? 20,
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Assignment created'), backgroundColor: Color(0xFF2E7D32)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Create Assignment', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, TeacherProvider provider, Map<String, dynamic> a) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red, size: 24),
            SizedBox(width: 10),
            Text('Delete Assignment'),
          ],
        ),
        content: Text('Delete "${a['title'] ?? 'this assignment'}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              provider.deleteAssignment(a['id'].toString());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Assignment deleted'), backgroundColor: Color(0xFFD32F2F)),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TeacherProvider>();
    final all = provider.assignments;

    final filtered = _filterClassId == 'all'
        ? all
        : all.where((a) => a['class_id']?.toString() == _filterClassId).toList();

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  const Text('Assignments', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827), letterSpacing: -0.5)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(12)),
                    child: Text('${all.length} total', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFF57F17))),
                  ),
                  const SizedBox(width: 12),
                  if (provider.assignedClassIds.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE8EAED)), borderRadius: BorderRadius.circular(8)),
                      child: DropdownButton<String>(
                        value: _filterClassId,
                        underline: const SizedBox(),
                        isDense: true,
                        items: [
                          const DropdownMenuItem(value: 'all', child: Text('All Classes', style: TextStyle(fontSize: 12))),
                          ...provider.assignedClassIds.map((id) => DropdownMenuItem(value: id, child: Text(provider.getClassName(id), style: const TextStyle(fontSize: 12)))),
                        ],
                        onChanged: (v) => setState(() => _filterClassId = v ?? 'all'),
                      ),
                    ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 4, 24, 0),
              child: Text('Create and manage homework for your classes', style: TextStyle(fontSize: 13, color: Colors.grey)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64, height: 64,
                            decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(16)),
                            child: const Icon(Icons.assignment_outlined, size: 32, color: Color(0xFFF57F17)),
                          ),
                          const SizedBox(height: 16),
                          const Text('No assignments yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                          const SizedBox(height: 4),
                          const Text('Tap the button below to create one', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final a = filtered[index];
                        final isPublished = a['is_published'] == true;
                        final overdue = !isPublished && _isOverdue(a['due_date']);
                        final dueStr = _formatDate(a['due_date']);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: overdue ? Colors.red.shade300 : const Color(0xFFE8EAED)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: overdue ? Colors.red.shade50 : const Color(0xFFFFF8E1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.assignment, size: 22, color: overdue ? Colors.red.shade400 : const Color(0xFFF57F17)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            a['title'] ?? 'Untitled',
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isPublished ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            isPublished ? 'Published' : 'Draft',
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isPublished ? const Color(0xFF2E7D32) : Colors.grey.shade600),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_getSubjectName(a)}  ·  ${_getClassName(a)}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        if (dueStr.isNotEmpty) ...[
                                          Icon(Icons.schedule, size: 12, color: overdue ? Colors.red.shade400 : Colors.grey.shade400),
                                          const SizedBox(width: 3),
                                          Text(
                                            'Due: $dueStr',
                                            style: TextStyle(fontSize: 11, color: overdue ? Colors.red.shade400 : Colors.grey.shade500),
                                          ),
                                          const SizedBox(width: 12),
                                        ],
                                        Icon(Icons.star_outline, size: 12, color: Colors.grey.shade400),
                                        const SizedBox(width: 3),
                                        Text('${a['total_marks'] ?? 20} marks', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(isPublished ? Icons.unpublished_outlined : Icons.publish_outlined, size: 20, color: isPublished ? Colors.orange : const Color(0xFF2E7D32)),
                                tooltip: isPublished ? 'Unpublish' : 'Publish',
                                onPressed: () => provider.toggleAssignmentPublished(a['id'].toString(), !isPublished),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade400),
                                tooltip: 'Delete',
                                onPressed: () => _showDeleteConfirm(context, provider, a),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        Positioned(
          bottom: 24,
          right: 24,
          child: GestureDetector(
            onTap: () => _showAddSheet(context, provider),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: const Color(0xFF1A237E).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Add New', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

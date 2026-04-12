// ==========================================
// File: lib/features/dashboard/school_admin/manage_subjects_page.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartedu/core/providers/school_admin_provider.dart';

class ManageSubjectsPage extends StatefulWidget {
  const ManageSubjectsPage({super.key});

  @override
State<ManageSubjectsPage> createState() => _ManageSubjectsPageState();
}

class _ManageSubjectsPageState extends State<ManageSubjectsPage> {
  final _subjectController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _classSubjects = [];
  bool _isLoading = true;
  String _schoolId = '';
  String _schoolName = '';
  String? _selectedClassId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  void _init() {
    final provider = context.read<SchoolAdminProvider>();
    _schoolId = provider.schoolId;
    _schoolName = provider.schoolName;
    if (_schoolId.isEmpty) {
      setState(() => _isLoading = false);
    } else {
      _fetchAll();
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    if (_schoolId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        Supabase.instance.client
            .from('subjects')
            .select()
            .eq('school_id', _schoolId)
            .order('name'),
        Supabase.instance.client
            .from('classes')
            .select('id, name, section, tier')
            .eq('school_id', _schoolId)
            .order('name'),
        Supabase.instance.client
            .from('class_subjects')
            .select('id, class_id, subject_id, teacher_id, is_compulsory')
            .eq('school_id', _schoolId),
      ]);

      setState(() {
        _subjects = List<Map<String, dynamic>>.from(results[0]);
        _classes = List<Map<String, dynamic>>.from(results[1]);
        _classSubjects = List<Map<String, dynamic>>.from(results[2]);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching data: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Get subject IDs linked to the selected class.
  Set<String> _getLinkedSubjectIds() {
    if (_selectedClassId == null) return {};
    return _classSubjects
        .where((cs) => cs['class_id']?.toString() == _selectedClassId)
        .map((cs) => cs['subject_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  /// Get class display name by class_id.
  String _className(String? classId) {
    if (classId == null) return '';
    try {
      final c = _classes.firstWhere((c) => c['id'] == classId);
      final n = (c['name'] ?? '').toString();
      final s = (c['section'] ?? '').toString();
      return s.isNotEmpty ? '$n - $s' : n;
    } catch (_) {
      return '';
    }
  }

  /// Get teacher name by teacher_id.
  String _teacherName(String? teacherId) {
    if (teacherId == null) return '';
    try {
      return context
          .read<SchoolAdminProvider>()
          .teachers
          .cast<Map<String, dynamic>?>()
          .firstWhere((t) => t?['id']?.toString() == teacherId,
              orElse: () => null)
          ?.let((t) =>
              '${t['first_name']} ${t['last_name']}') ??
          '';
    } catch (_) {
      return '';
    }
  }

  /// Get list of class names a subject belongs to (for non-filtered view).
  List<String> _subjectClassNames(String subjectId) {
    return _classSubjects
        .where((cs) => cs['subject_id']?.toString() == subjectId)
        .map((cs) => _className(cs['class_id']?.toString()))
        .where((n) => n.isNotEmpty)
        .toList();
  }

  Future<void> _addSubject() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _subjectController.text.trim();
    if (name.isEmpty) return;

    try {
      final exists = await Supabase.instance.client
          .from('subjects')
          .select('id')
          .eq('school_id', _schoolId)
          .eq('name', name)
          .maybeSingle();

      if (exists != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subject already exists'), backgroundColor: Colors.orange),
          );
        }
        return;
      }

      await Supabase.instance.client.from('subjects').insert({
        'name': name,
        'school_id': _schoolId,
      });

      _subjectController.clear();
      _fetchAll();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subject added'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('Error adding subject: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteSubject(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subject?'),
        content: Text('Delete "$name"? This cannot be undone.\n\nNote: This will also remove the subject from all classes.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await Supabase.instance.client
          .from('class_subjects')
          .delete()
          .eq('subject_id', id)
          .eq('school_id', _schoolId);
      await Supabase.instance.client
          .from('subjects')
          .delete()
          .eq('id', id)
          .eq('school_id', _schoolId);

      _fetchAll();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subject deleted'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('Error deleting subject: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddDialog() {
    _subjectController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Subject', style: TextStyle(fontSize: 16)),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _subjectController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Subject Name',
              labelStyle: TextStyle(fontSize: 13),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 14),
            validator: (val) => val == null || val.trim().isEmpty ? 'Enter subject name' : null,
            onFieldSubmitted: (_) => _addSubject(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: _addSubject,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3C72),
                foregroundColor: Colors.white,
              ),
              child: const Text('Add', style: TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_schoolId.isEmpty && !_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Manage Subjects', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF1E3C72),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: Text('Session error. Log out and log in again.', style: TextStyle(color: Colors.red)),
        ),
      );
    }

    final linkedIds = _getLinkedSubjectIds();
    final isFiltered = _selectedClassId != null;

    // When filtered, show only subjects linked to the selected class
    final displaySubjects = isFiltered
        ? _subjects.where((s) => linkedIds.contains(s['id']?.toString())).toList()
        : _subjects;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _schoolName.isNotEmpty ? 'Subjects - $_schoolName' : 'Manage Subjects',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: const Color(0xFF1E3C72),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showAddDialog,
            tooltip: 'Add Subject',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Class filter dropdown
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.filter_list, size: 20, color: const Color(0xFF1E3C72)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedClassId,
                          decoration: InputDecoration(
                            labelText: 'Filter by Class',
                            labelStyle: const TextStyle(fontSize: 12),
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All Subjects',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black)),
                            ),
                            ..._classes.map((c) {
                              final display = _className(c['id']?.toString());
                              return DropdownMenuItem(
                                value: c['id']?.toString(),
                                child: Text(display,
                                    style: const TextStyle(fontSize: 13)),
                              );
                            }),
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedClassId = v),
                        ),
                      ),
                      if (isFiltered)
                        TextButton.icon(
                          onPressed: () =>
                              setState(() => _selectedClassId = null),
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('Clear',
                              style: TextStyle(fontSize: 12, color: Color(0xFF1E3C72)),
                        ),
                    ],
                  ),
                ),
                // Info bar when filtered
                if (isFiltered) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3C72).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: const Color(0xFF1E3C72)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Showing ${displaySubjects.length} of ${_subjects.length} subjects assigned to ${_className(_selectedClassId)}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E3C72)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Subject list
                Expanded(
                  child: displaySubjects.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.menu_book, size: 56, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                isFiltered
                                    ? 'No subjects assigned to this class'
                                    : 'No subjects yet',
                                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                              ),
                              if (!isFiltered) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 36,
                                  child: ElevatedButton(
                                    onPressed: _showAddDialog,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E3C72),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Add Subject',
                                        style: TextStyle(fontSize: 13)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          itemCount: displaySubjects.length,
                          itemBuilder: (context, index) {
                            final subject = displaySubjects[index];
                            final name = subject['name']?.toString() ?? 'Unknown';
                            final id = subject['id']?.toString() ?? '';
                            final code = (subject['code'] ?? '').toString().trim();

                            // Find the class_subjects row for this subject+class combo
                            Map<String, dynamic>? csRow;
                            if (isFiltered && _selectedClassId != null) {
                              try {
                                csRow = _classSubjects.firstWhere((cs) =>
                                    cs['subject_id']?.toString() == id &&
                                    cs['class_id']?.toString() == _selectedClassId);
                              } catch (_) {}
                            }

                            final isCompulsory = csRow?['is_compulsory'] == true;
                            final teacherId = csRow?['teacher_id']?.toString();
                            final teacherName = _teacherName(teacherId);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor:
                                          isCompulsory
                                              ? const Color(0xFF1E3C72)
                                              : Colors.orange.shade100,
                                      child: Text(
                                        name.substring(0, 1).toUpperCase(),
                                        style: TextStyle(
                                            color: isCompulsory
                                                ? Colors.white
                                                : Colors.orange.shade800,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.black),
                                          ),
                                          if (code.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              code,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF555555)),
                                            ),
                                          ],
                                          if (isFiltered) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: isCompulsory
                                                        ? const Color(0xFF1E3C72)
                                                            .withOpacity(0.1)
                                                        : Colors.orange.shade50,
                                                    borderRadius:
                                                        BorderRadius.circular(4),
                                                  child: Text(
                                                    isCompulsory
                                                        ? 'Core'
                                                        : 'Elective',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: isCompulsory
                                                          ? const Color(0xFF1E3C72)
                                                          : Colors.orange),
                                                  ),
                                                ),
                                                if (teacherName.isNotEmpty) ...[
                                                  const SizedBox(width: 6),
                                                  Icon(Icons.person_outline,
                                                      size: 13,
                                                      color: Colors.grey.shade500),
                                                  const SizedBox(width: 3),
                                                  Expanded(
                                                    child: Text(
                                                      teacherName,
                                                      style: const TextStyle(
                                                          fontSize: 11,
                                                          color:
                                                              Color(0xFF555555),
                                                      overflow:
                                                          TextOverflow
                                                              .ellipsis),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.red, size: 20),
                                      onPressed: () =>
                                          _deleteSubject(id, name),
                                      tooltip: 'Delete subject from all classes',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                ],
              ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF1E3C72),
        child: const Icon(Icons.add, color: Colors.white, size: 20),
      ),
    );
  }
}

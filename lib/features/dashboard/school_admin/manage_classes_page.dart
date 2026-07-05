import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartedu/core/providers/school_admin_provider.dart';
import 'package:smartedu/core/services/db_proxy.dart';

class ManageClassesPage extends StatefulWidget {
  const ManageClassesPage({super.key});

  @override
  State<ManageClassesPage> createState() => _ManageClassesPageState();
}

class _ManageClassesPageState extends State<ManageClassesPage> {
  List<Map<String, dynamic>> _classes = [];
  bool _isLoading = true;
  String _schoolId = '';
  String _schoolName = '';

  final _nameController = TextEditingController();
  final _sectionController = TextEditingController();
  String _selectedTier = 'SSS';

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
      _fetchClasses();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sectionController.dispose();
    super.dispose();
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

  Future<void> _fetchClasses() async {
    if (_schoolId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await DbProxy.instance
          .from('classes')
          .select()
          .eq('school_id', _schoolId)
          .order('name')
          .get();
      setState(() {
        _classes = List<Map<String, dynamic>>.from(result);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching classes: $e');
      setState(() => _isLoading = false);
      _snack('Error: $e', success: false);
    }
  }

  String _teacherName(String? teacherId) {
    if (teacherId == null || teacherId.isEmpty) return '';
    try {
      final teachers = context.read<SchoolAdminProvider>().teachers;
      for (final t in teachers) {
        if (t['id']?.toString() == teacherId) {
          final first = (t['first_name'] ?? '').toString();
          final last = (t['last_name'] ?? '').toString();
          return '$first $last'.trim();
        }
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  Color _tierColor(String? tier) {
    switch (tier) {
      case 'SSS':
        return const Color(0xFF1565C0);
      case 'JSS':
        return const Color(0xFF2E7D32);
      case 'PRIMARY':
        return const Color(0xFFE65100);
      default:
        return Colors.grey;
    }
  }

  Future<void> _addClass() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _snack('Please enter class name', success: false);
      return;
    }
    try {
      await DbProxy.instance.from('classes').insert({
        'name': name,
        'section':
            _sectionController.text.trim().isEmpty
                ? null
                : _sectionController.text.trim(),
        'tier': _selectedTier,
        'school_id': _schoolId,
        'student_count': 0,
      });
      _nameController.clear();
      _sectionController.clear();
      if (mounted) {
        Navigator.pop(context);
        _fetchClasses();
        _snack('Class added successfully!');
      }
    } catch (e) {
      debugPrint('Error adding class: $e');
      _snack('Error: $e', success: false);
    }
  }

  Future<void> _deleteClass(String id, String displayName) async {
    final confirmed = await showDialog<bool>(
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
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    size: 24, color: Color(0xFFDC2626)),
              ),
              const SizedBox(height: 16),
              const Text('Delete Class?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  )),
              const SizedBox(height: 8),
              Text(
                  'Delete "$displayName"? This cannot be undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14, color: Colors.grey.shade600)),
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
                        backgroundColor:
                            const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12),
                      ),
                      child: const Text('Delete',
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
    if (confirmed != true) return;
    try {
      await DbProxy.instance
          .from('classes')
          .eq('id', id)
          .eq('school_id', _schoolId)
          .delete();
      _fetchClasses();
      _snack('Class deleted successfully!');
    } catch (e) {
      debugPrint('Error deleting class: $e');
      _snack('Error: $e', success: false);
    }
  }

  void _showAddDialog() {
    _nameController.clear();
    _sectionController.clear();
    _selectedTier = 'SSS';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EAF6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.school_rounded,
                          size: 22, color: Color(0xFF1A237E)),
                    ),
                    const SizedBox(width: 14),
                    const Text('Add New Class',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        )),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Class Name',
                    labelStyle: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                    hintText: 'e.g. Grade 1, JSS 1',
                    hintStyle: TextStyle(
                        fontSize: 13, color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.school_outlined,
                        size: 20, color: Color(0xFF1A237E)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color(0xFF1A237E), width: 2),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFAFBFC),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _sectionController,
                  decoration: InputDecoration(
                    labelText: 'Section (optional)',
                    labelStyle: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                    hintText: 'e.g. A, B, Science',
                    hintStyle: TextStyle(
                        fontSize: 13, color: Colors.grey.shade400),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color(0xFF1A237E), width: 2),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFAFBFC),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0xFFFAFBFC),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedTier,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                          value: 'SSS',
                          child: Text('SSS (Senior Secondary)'),
                        ),
                        DropdownMenuItem(
                          value: 'JSS',
                          child: Text('JSS (Junior Secondary)'),
                        ),
                        DropdownMenuItem(
                          value: 'PRIMARY',
                          child: Text('Primary'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() => _selectedTier = v);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
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
                        onPressed: _addClass,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF1A237E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12),
                        ),
                        child: const Text('Add Class',
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_schoolId.isEmpty && !_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: AppBar(
          title: const Text('Manage Classes',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
          backgroundColor: const Color(0xFF1A237E),
          foregroundColor: Colors.white,
          elevation: 0,
          iconTheme:
              const IconThemeData(color: Colors.white),
        ),
        body: Center(
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
                child: Icon(Icons.error_outline_rounded,
                    size: 36, color: Colors.red.shade400),
              ),
              const SizedBox(height: 16),
              Text('Session error',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  )),
              const SizedBox(height: 8),
              Text('Log out and log in again.',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  )),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text(
          _schoolName.isNotEmpty
              ? 'Classes — $_schoolName'
              : 'Manage Classes',
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 16),
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme:
            const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _showAddDialog,
              child: Container(
                height: 36,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded,
                        size: 18, color: Colors.white),
                    SizedBox(width: 6),
                    Text('Add Class',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 3))
          : _classes.isEmpty
              ? Center(
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
                        child: Icon(Icons.school_outlined,
                            size: 36,
                            color: Colors.grey.shade400),
                      ),
                      const SizedBox(height: 16),
                      Text('No classes yet',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          )),
                      const SizedBox(height: 8),
                      Text(
                          'Tap "Add Class" to create your first one',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          )),
                      const SizedBox(height: 20),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: _showAddDialog,
                        child: Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A237E),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded,
                                  size: 18, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Add Class',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                      24, 16, 24, 24),
                  itemCount: _classes.length,
                  itemBuilder: (context, index) {
                    final cls = _classes[index];
                    final name =
                        (cls['name'] ?? '').toString();
                    final section =
                        (cls['section'] ?? '').toString();
                    final tier =
                        (cls['tier'] ?? 'SSS').toString();
                    final studentCount =
                        cls['student_count'] ?? 0;
                    final teacherId =
                        cls['class_teacher_id']?.toString();
                    final teacher = _teacherName(teacherId);
                    final displayName = section.isNotEmpty
                        ? '$name — $section'
                        : name;
                    final bgColor = index % 2 == 0
                        ? Colors.white
                        : const Color(0xFFFAFBFC);
                    final tierClr = _tierColor(tier);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFE8EAED)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: tierClr.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                name.isNotEmpty
                                    ? name
                                        .substring(0, 1)
                                        .toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: tierClr,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding:
                                          const EdgeInsets
                                              .symmetric(
                                              horizontal: 8,
                                              vertical: 2),
                                      decoration: BoxDecoration(
                                        color: tierClr
                                            .withOpacity(
                                                0.1),
                                        borderRadius:
                                            BorderRadius
                                                .circular(4),
                                      ),
                                      child: Text(
                                        tier,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight:
                                              FontWeight
                                                  .w700,
                                          color: tierClr,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                        '$studentCount students',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors
                                                .grey
                                                .shade500)),
                                    if (teacher.isNotEmpty) ...[
                                      const SizedBox(
                                          width: 8),
                                      Flexible(
                                        child: Text(
                                          '• $teacher',
                                          style: TextStyle(
                                              fontSize:
                                                  11,
                                              color: Colors
                                                  .grey
                                                  .shade500),
                                          overflow:
                                              TextOverflow
                                                  .ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () => _deleteClass(
                                cls['id'].toString(),
                                displayName),
                            child: Container(
                              height: 32,
                              width: 32,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors
                                      .red.shade400
                                      .withOpacity(0.3),
                                ),
                                borderRadius:
                                    BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons
                                    .delete_outline_rounded,
                                size: 16,
                                color:
                                    Colors.red.shade400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

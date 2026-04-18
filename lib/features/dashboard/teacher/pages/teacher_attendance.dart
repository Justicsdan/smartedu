import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/teacher/teacher_provider.dart';

class TeacherAttendancePage extends StatefulWidget {
  const TeacherAttendancePage({super.key});

  @override
  State<TeacherAttendancePage> createState() => _TeacherAttendancePageState();
}

class _TeacherAttendancePageState extends State<TeacherAttendancePage>
    with TickerProviderStateMixin {
  String? _selectedClassId;
  String? _selectedClassName;
  DateTime _selectedDate = DateTime.now();
  final Map<String, String> _attendanceStatus = {};
  final Map<String, String> _attendanceRemarks = {};
  bool _loading = false;
  bool _saving = false;
  List<Map<String, dynamic>> _students = [];
  bool _showSummary = false;
  List<Map<String, dynamic>> _summaryData = [];
  String _searchQuery = '';
  final _searchController = TextEditingController();
  late AnimationController _progressController;
  late Animation<double> _progressAnim;

  static const _statuses = ['present', 'absent', 'late'];
  static const _statusLabels = {
    'present': 'Present',
    'absent': 'Absent',
    'late': 'Late',
  };
  static const _statusColors = {
    'present': Color(0xFF2E7D32),
    'absent': Color(0xFFD32F2F),
    'late': Color(0xFFE65100),
  };
  static const _statusBgColors = {
    'present': Color(0xFFE8F5E9),
    'absent': Color(0xFFFFEBEE),
    'late': Color(0xFFFFF3E0),
  };

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _progressAnim = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickClass());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _animateProgress() {
    _progressController.reset();
    _progressController.forward();
  }

  double get _progressFraction =>
      _students.isEmpty ? 0.0 : _attendanceStatus.length / _students.length;

  int get _presentCount =>
      _attendanceStatus.values.where((s) => s == 'present').length;
  int get _absentCount =>
      _attendanceStatus.values.where((s) => s == 'absent').length;
  int get _lateCount =>
      _attendanceStatus.values.where((s) => s == 'late').length;

  List<Map<String, dynamic>> get _filteredStudents {
    if (_searchQuery.isEmpty) return _students;
    final q = _searchQuery.toLowerCase();
    return _students.where((s) {
      final first = (s['first_name']?.toString() ?? '').toLowerCase();
      final last = (s['last_name']?.toString() ?? '').toLowerCase();
      final adm = (s['admission_no']?.toString() ?? '').toLowerCase();
      return first.contains(q) ||
          last.contains(q) ||
          '$first $last'.contains(q) ||
          adm.contains(q);
    }).toList();
  }

  void _pickClass() {
    final p = context.read<TeacherProvider>();
    final classes = p.myClasses;
    if (classes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No classes assigned to you'),
          backgroundColor: Color(0xFFE65100),
        ),
      );
      return;
    }
    if (classes.length == 1) {
      _selectClass(classes[0]);
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ClassPickerSheet(
        classes: classes,
        onSelect: _selectClass,
      ),
    );
  }

  void _selectClass(Map<String, dynamic> cls) {
    final name = cls['name']?.toString() ?? '';
    final section = cls['section']?.toString() ?? '';
    final full = section.isNotEmpty ? '$name ($section)' : name;
    setState(() {
      _selectedClassId = cls['id']?.toString();
      _selectedClassName = full;
      _showSummary = false;
      _attendanceStatus.clear();
      _attendanceRemarks.clear();
      _summaryData.clear();
      _searchQuery = '';
      _searchController.clear();
    });
    _animateProgress();
    _loadStudents();
    _loadExistingAttendance();
  }

  void _loadStudents() {
    final p = context.read<TeacherProvider>();
    setState(() {
      _students = p.getStudentsInClass(_selectedClassId!);
    });
    _animateProgress();
  }

  Future<void> _loadExistingAttendance() async {
    if (_selectedClassId == null) return;
    final p = context.read<TeacherProvider>();
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    try {
      final existing = await p.getAttendanceForClass(
        classId: _selectedClassId!,
        date: dateStr,
      );
      if (existing.isNotEmpty) {
        setState(() {
          for (final r in existing) {
            final sid = r['student_id']?.toString();
            if (sid != null) {
              _attendanceStatus[sid] =
                  r['status']?.toString() ?? 'present';
              _attendanceRemarks[sid] = r['remark']?.toString() ?? '';
            }
          }
        });
        _animateProgress();
      }
    } catch (_) {}
  }

  Future<void> _saveAttendance() async {
    if (_selectedClassId == null || _students.isEmpty) return;
    setState(() => _saving = true);
    final p = context.read<TeacherProvider>();
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    try {
      final records = _students.map((s) {
        final sid = s['id']?.toString() ?? '';
        return {
          'student_id': sid,
          'status': _attendanceStatus[sid] ?? 'present',
          'remark': _attendanceRemarks[sid] ?? '',
        };
      }).toList();
      final ok = await p.markAttendance(
        classId: _selectedClassId!,
        date: dateStr,
        records: records,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(ok ? Icons.check_circle : Icons.error,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(ok ? 'Attendance saved!' : 'Failed to save'),
              ],
            ),
            backgroundColor:
                ok ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Error: $e'),
              ],
            ),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _loadSummary() async {
    if (_selectedClassId == null) return;
    setState(() => _loading = true);
    final p = context.read<TeacherProvider>();
    try {
      final data =
          await p.getClassAttendanceSummary(classId: _selectedClassId!);
      setState(() {
        _summaryData = data;
        _showSummary = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setAll(String status) {
    setState(() {
      for (final s in _students) {
        final sid = s['id']?.toString();
        if (sid != null) _attendanceStatus[sid] = status;
      }
    });
    _animateProgress();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1A237E),
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _attendanceStatus.clear();
        _attendanceRemarks.clear();
      });
      _animateProgress();
      _loadExistingAttendance();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedClassId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _iconBox(80, 36, const Color(0xFFF0F4FF),
                  const Color(0xFF1A237E), Icons.event_note),
              const SizedBox(height: 20),
              const Text(
                'Select a Class',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a class to mark attendance',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _pickClass,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.class_, size: 18),
                    SizedBox(width: 8),
                    Text('Pick Class',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _selectedClassName ?? 'Attendance',
          style: const TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 4),
            child: _SummaryBtn(),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(color: Color(0xFF1A237E)))
          : _showSummary
              ? _buildSummaryView()
              : _buildMarkingView(),
    );
  }

  Widget _buildSaveBar() {
    final allMarked = _attendanceStatus.length == _students.length;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EAED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (allMarked)
                      const Icon(Icons.check_circle,
                          size: 16, color: Color(0xFF2E7D32))
                    else
                      Icon(Icons.radio_button_unchecked,
                          size: 16, color: Colors.grey.shade400),
                    const SizedBox(width: 6),
                    Text(
                      '${_attendanceStatus.length}/${_students.length}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: allMarked
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  allMarked ? 'All marked — ready to save' : 'Tap P · A · L on each row',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            height: 42,
            child: ElevatedButton(
              onPressed: _saving ? null : _saveAttendance,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                elevation: 0,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.save, size: 18),
                        SizedBox(width: 6),
                        Text('Save',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                      ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkingView() {
    final filtered = _filteredStudents;
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Hero card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A237E), Color(0xFF283593)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A237E).withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: AnimatedBuilder(
                    listenable: _progressAnim,
                    builder: (context, child) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: _progressFraction,
                            strokeWidth: 5,
                            backgroundColor: Colors.white.withOpacity(0.15),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _progressFraction >= 1.0
                                  ? const Color(0xFF66BB6A)
                                  : Colors.white.withOpacity(0.9),
                            ),
                          ),
                          Center(
                            child: Text(
                              '${(_progressFraction * 100).round()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today,
                                  size: 14, color: Colors.white70),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  DateFormat('EEE, MMM d, yyyy')
                                      .format(_selectedDate),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.edit_calendar,
                                  size: 12, color: Colors.white54),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _miniStat('${_students.length}', 'Students',
                              Colors.white.withOpacity(0.7), Colors.white),
                          const SizedBox(width: 16),
                          _miniStat(
                              '${_attendanceStatus.length}',
                              'Marked',
                              const Color(0xFF66BB6A).withOpacity(0.8),
                              Colors.white),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Stat chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _statChip(_presentCount, 'Present', const Color(0xFF2E7D32),
                    const Color(0xFFE8F5E9)),
                const SizedBox(width: 8),
                _statChip(_absentCount, 'Absent', const Color(0xFFD32F2F),
                    const Color(0xFFFFEBEE)),
                const SizedBox(width: 8),
                _statChip(_lateCount, 'Late', const Color(0xFFE65100),
                    const Color(0xFFFFF3E0)),
                const Spacer(),
                if (_students.isNotEmpty &&
                    _attendanceStatus.length < _students.length)
                  _quickMarkAllBtn(),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Search
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style:
                  const TextStyle(fontSize: 14, color: Color(0xFF111827)),
              decoration: InputDecoration(
                hintText: 'Search by name or admission no...',
                hintStyle:
                    TextStyle(color: Colors.grey.shade400, fontSize: 13),
                prefixIcon: const Icon(Icons.search,
                    color: Colors.grey, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: const Icon(Icons.close,
                            color: Colors.grey, size: 18))
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: Color(0xFF1A237E), width: 1.5)),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Students
          filtered.isEmpty
              ? _buildEmptyState(
                  _searchQuery.isNotEmpty
                      ? 'No students match "$_searchQuery"'
                      : 'No students found in this class',
                  _searchQuery.isNotEmpty
                      ? Icons.search_off
                      : Icons.people_outline)
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (ctx, i) =>
                      _buildStudentCard(i, filtered),
                ),
          const SizedBox(height: 8),
          // Save bar — inside scrollable content, above AI button area
          _buildSaveBar(),
        ],
      ),
    );
  }

  Widget _quickMarkAllBtn() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (ctx) => Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Mark All Students As',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  ..._statuses.map((status) {
                    final color = _statusColors[status]!;
                    final bg = _statusBgColors[status]!;
                    return InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _setAll(status);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Icon(
                                status == 'present'
                                    ? Icons.check_circle
                                    : status == 'absent'
                                        ? Icons.cancel
                                        : Icons.schedule,
                                color: color,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _statusLabels[status]!,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_students.length} students',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.done_all,
                  size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text('Mark All',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(int i, List<Map<String, dynamic>> list) {
    final s = list[i];
    final sid = s['id']?.toString() ?? '';
    final firstName = s['first_name']?.toString() ?? '';
    final lastName = s['last_name']?.toString() ?? '';
    final name = '$firstName $lastName'.trim();
    final admNo = s['admission_no']?.toString() ?? '';
    final currentStatus = _attendanceStatus[sid] ?? '';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: currentStatus.isNotEmpty
              ? (_statusColors[currentStatus] ??
                      Colors.grey.shade200)
                  .withOpacity(0.3)
              : Colors.grey.shade200,
          width: currentStatus.isNotEmpty ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${i + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                    height: 1.3,
                  ),
                ),
                if (admNo.isNotEmpty)
                  Text(
                    admNo,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade400),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: _statuses.map((status) {
              final selected = currentStatus == status;
              final color = _statusColors[status]!;
              final bg = _statusBgColors[status]!;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selected)
                      _attendanceStatus.remove(sid);
                    else
                      _attendanceStatus[sid] = status;
                  });
                  _animateProgress();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    color: selected ? color : bg.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? color
                          : color.withOpacity(0.2),
                      width: selected ? 0 : 1,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: selected
                          ? Icon(
                              status == 'present'
                                  ? Icons.check
                                  : status == 'absent'
                                      ? Icons.close
                                      : Icons.schedule,
                              key: ValueKey('$sid-$status'),
                              size: 16,
                              color: Colors.white,
                            )
                          : Text(
                              status[0].toUpperCase(),
                              key: ValueKey('$sid-$status-text'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: color.withOpacity(0.5),
                              )),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryView() {
    final totalPresent = _summaryData.fold<int>(
        0, (sum, r) => sum + ((r['present'] ?? 0) as num).toInt());
    final totalAbsent = _summaryData.fold<int>(
        0, (sum, r) => sum + ((r['absent'] ?? 0) as num).toInt());
    final totalLate = _summaryData.fold<int>(
        0, (sum, r) => sum + ((r['late'] ?? 0) as num).toInt());
    final totalDays = totalPresent + totalAbsent + totalLate;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8EAED)),
            ),
            child: Row(
              children: [
                _iconBox(44, 22, const Color(0xFFF0F4FF),
                    const Color(0xFF1A237E), Icons.summarize),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedClassName ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_summaryData.length} student${_summaryData.length != 1 ? 's' : ''} • $totalDays total days',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _showSummary = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: const Color(0xFFE8EAED)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back,
                            size: 14, color: Color(0xFF1A237E)),
                        SizedBox(width: 4),
                        Text(
                          'Back',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _summaryStatCard(totalPresent, 'Present',
                    const Color(0xFF2E7D32), const Color(0xFFE8F5E9),
                    Icons.check_circle),
                const SizedBox(width: 8),
                _summaryStatCard(totalAbsent, 'Absent',
                    const Color(0xFFD32F2F), const Color(0xFFFFEBEE),
                    Icons.cancel),
                const SizedBox(width: 8),
                _summaryStatCard(totalLate, 'Late',
                    const Color(0xFFE65100), const Color(0xFFFFF3E0),
                    Icons.schedule),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E).withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                SizedBox(width: 28),
                Expanded(
                    child: Text('Student',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A237E)))),
                SizedBox(
                    width: 52,
                    child: Text('Present',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2E7D32)))),
                SizedBox(
                    width: 52,
                    child: Text('Absent',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFD32F2F)))),
                SizedBox(
                    width: 52,
                    child: Text('Late',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE65100)))),
                SizedBox(
                    width: 52,
                    child: Text('Total',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A237E)))),
              ],
            ),
          ),
          _summaryData.isEmpty
              ? _buildEmptyState(
                  'No attendance data yet', Icons.bar_chart)
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  itemCount: _summaryData.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 4),
                  itemBuilder: (ctx, i) {
                    final row = _summaryData[i];
                    final name =
                        '${row['first_name'] ?? ''} ${row['last_name'] ?? ''}'
                            .trim();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: i.isEven
                            ? Colors.white
                            : const Color(0xFFFAFBFC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 28,
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 52,
                            child: Text(
                              '${row['present'] ?? 0}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2E7D32)),
                            ),
                          ),
                          SizedBox(
                            width: 52,
                            child: Text(
                              '${row['absent'] ?? 0}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFD32F2F)),
                            ),
                          ),
                          SizedBox(
                            width: 52,
                            child: Text(
                              '${row['late'] ?? 0}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFE65100)),
                            ),
                          ),
                          SizedBox(
                            width: 52,
                            child: Text(
                              '${row['total_days'] ?? 0}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111827)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _iconBox(double size, double iconSize, Color bgColor,
      Color iconColor, IconData icon) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      child: Icon(icon, size: iconSize, color: iconColor),
    );
  }

  Widget _miniStat(
      String value, String label, Color valueColor, Color labelColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: valueColor)),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: labelColor.withOpacity(0.8))),
      ],
    );
  }

  Widget _statChip(int count, String label, Color color, Color bg) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color)),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.8))),
        ],
      ),
    );
  }

  Widget _summaryStatCard(int value, String label, Color color, Color bg,
      IconData icon) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text('$value',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color)),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color.withOpacity(0.7))),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child:
                Icon(icon, size: 30, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text(
            text,
            style:
                TextStyle(fontSize: 15, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SummaryBtn extends StatelessWidget {
  const _SummaryBtn();

  @override
  Widget build(BuildContext context) {
    final page =
        context.findAncestorStateOfType<_TeacherAttendancePageState>();
    return IconButton(
      onPressed: page?._loadSummary,
      tooltip: 'View Summary',
      icon: const Icon(
          Icons.bar_chart, color: Color(0xFF1A237E), size: 22),
    );
  }
}

class _ClassPickerSheet extends StatelessWidget {
  final List<Map<String, dynamic>> classes;
  final void Function(Map<String, dynamic>) onSelect;

  const _ClassPickerSheet(
      {required this.classes, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.only(
          top: 12, bottom: 24, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.class_,
                    size: 20, color: Color(0xFF1A237E)),
              ),
              const SizedBox(width: 12),
              const Text(
                'Select Class',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${classes.length}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A237E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...classes.map((c) {
            final name = c['name']?.toString() ?? '';
            final section = c['section']?.toString() ?? '';
            final tier = c['tier']?.toString() ?? '';
            final studentCount = c['student_count'] ?? 0;
            final label =
                section.isNotEmpty ? '$name ($section)' : name;
            final tierColor = tier == 'SSS'
                ? const Color(0xFF1A237E)
                : tier == 'JSS'
                    ? const Color(0xFFE65100)
                    : const Color(0xFF7B1FA2);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.pop(context);
                    onSelect(c);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFBFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$studentCount student${studentCount != 1 ? 's' : ''}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade400),
                              ),
                            ],
                          ),
                        ),
                        if (tier.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: tierColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tier,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: tierColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right,
                            size: 20, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;

  const AnimatedBuilder(
      {super.key, required super.listenable, required this.builder});

  @override
  Widget build(BuildContext context) => builder(context, null);
}

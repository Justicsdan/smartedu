import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartedu/core/teacher_provider.dart';

class TeacherAttendancePage extends StatefulWidget {
  const TeacherAttendancePage({super.key});
  @override
  State<TeacherAttendancePage> createState() =>
      _TeacherAttendancePageState();
}

class _TeacherAttendancePageState extends State<TeacherAttendancePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedClassId;
  DateTime _selectedDate = DateTime.now();
  Map<String, String> _statusMap = {};
  bool _isLoading = false;
  bool _isSaving = false;
  List<Map<String, dynamic>> _summaryData = [];
  bool _summaryLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDefaults();
    });
  }

  void _initDefaults() {
    final p = context.read<TeacherProvider>();
    final c = _getClasses(p);
    if (c.isNotEmpty) {
      setState(() => _selectedClassId = c.first['id'] as String?);
      _loadExisting();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getClasses(TeacherProvider p) {
    final seen = <String>{};
    final out = <Map<String, dynamic>>[];
    for (final a in p.mySubjectAssignments) {
      final c = a['classes'];
      if (c is Map<String, dynamic> &&
          c['id'] != null &&
          !seen.contains(c['id'])) {
        seen.add(c['id'] as String);
        out.add(c);
      }
    }
    final ft = p.getFormTeacherClass();
    if (ft != null && ft['id'] != null && !seen.contains(ft['id'])) {
      seen.add(ft['id'] as String);
      out.add(ft);
    }
    return out;
  }

  String _cl(Map<String, dynamic> c) =>
      '${c['name'] ?? ''} ${c['section'] ?? ''}'.trim();

  List<Map<String, dynamic>> _getSts(TeacherProvider p) {
    if (_selectedClassId == null) return [];
    return p.students
        .where((s) => s['class_id']?.toString() == _selectedClassId)
        .toList()
      ..sort((a, b) =>
          ((a['last_name'] ?? '') as String)
              .compareTo((b['last_name'] ?? '') as String));
  }

  String _sn(Map<String, dynamic> s) =>
      '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim();

  String _dateStr() {
    return '${_selectedDate.year}-'
        '${_selectedDate.month.toString().padLeft(2, '0')}-'
        '${_selectedDate.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadExisting() async {
    if (_selectedClassId == null) return;
    setState(() => _isLoading = true);
    final p = context.read<TeacherProvider>();
    final d = _dateStr();
    final rows =
        await p.getAttendanceForClass(classId: _selectedClassId!, date: d);
    final m = <String, String>{};
    for (final r in rows) {
      m[r['student_id']?.toString() ?? ''] =
          (r['status'] as String?)?.toLowerCase() ?? 'present';
    }
    setState(() {
      _statusMap = m;
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    if (_selectedClassId == null) return;
    setState(() => _isSaving = true);
    final p = context.read<TeacherProvider>();
    final st = _getSts(p);
    final d = _dateStr();
    final recs = st.map((s) {
      return {
        'student_id': s['id'],
        'status': _statusMap[s['id']?.toString()] ?? 'present',
        'remark': '',
      };
    }).toList();
    final ok = await p.markAttendance(
      classId: _selectedClassId!,
      date: d,
      records: recs,
    );
    setState(() => _isSaving = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Attendance saved!' : 'Failed to save'),
      backgroundColor:
          ok ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
      behavior: SnackBarBehavior.floating,
      shape: const StadiumBorder(),
    ));
  }

  Future<void> _loadSummary() async {
    if (_selectedClassId == null) return;
    setState(() => _summaryLoading = true);
    final p = context.read<TeacherProvider>();
    final data = await p.getClassAttendanceSummary(
      classId: _selectedClassId!,
    );
    setState(() {
      _summaryData = data;
      _summaryLoading = false;
    });
  }

  void _onClass(String? v) {
    setState(() {
      _selectedClassId = v;
      _statusMap = {};
      _summaryData = [];
    });
    if (v != null) {
      if (_tabController.index == 0) {
        _loadExisting();
      } else {
        _loadSummary();
      }
    }
  }

  void _onDate(DateTime pk) {
    setState(() => _selectedDate = pk);
    _loadExisting();
  }

  void _allPresent() {
    final st = _getSts(context.read<TeacherProvider>());
    setState(() {
      for (final s in st) {
        _statusMap[s['id']?.toString() ?? ''] = 'present';
      }
    });
  }

  static const _sc = {
    'present': Color(0xFF2E7D32),
    'absent': Color(0xFFD32F2F),
    'late': Color(0xFFE65100),
    'excused': Color(0xFF1565C0),
  };
  static const _sb = {
    'present': Color(0xFFE8F5E9),
    'absent': Color(0xFFFFEBEE),
    'late': Color(0xFFFFF3E0),
    'excused': Color(0xFFE3F2FD),
  };

  Widget _chip(String sid, String cur) {
    final s = cur.toLowerCase();
    final clr = _sc[s] ?? Colors.grey;
    final bg = _sb[s] ?? Colors.grey.shade100;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: clr.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: s,
          isDense: true,
          icon: const Icon(Icons.arrow_drop_down, size: 16),
          style: TextStyle(
            color: clr,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          items: const [
            DropdownMenuItem(value: 'present', child: Text('Present')),
            DropdownMenuItem(value: 'absent', child: Text('Absent')),
            DropdownMenuItem(value: 'late', child: Text('Late')),
            DropdownMenuItem(value: 'excused', child: Text('Excused')),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _statusMap[sid] = v);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TeacherProvider>();
    final classes = _getClasses(p);
    final students = _getSts(p);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Attendance',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Mark and track daily class attendance',
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                            color: const Color(0xFFE8EAED)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _selectedClassId,
                          hint: Text(
                            'Select class',
                            style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 14),
                          ),
                          isExpanded: true,
                          items: classes
                              .map((c) => DropdownMenuItem<String?>(
                                    value: c['id'] as String?,
                                    child: Text(
                                      _cl(c),
                                      style: const TextStyle(
                                          fontSize: 14),
                                    ),
                                  ))
                              .toList(),
                          onChanged: _onClass,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                          color: const Color(0xFFE8EAED)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () async {
                          final pk = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (pk != null) _onDate(pk);
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 16, color: Color(0xFF1A237E)),
                            const SizedBox(width: 8),
                            Text(
                              '${_selectedDate.day}/'
                              '${_selectedDate.month}/'
                              '${_selectedDate.year}',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF111827)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF1A237E),
                  unselectedLabelColor: Colors.grey.shade500,
                  indicatorColor: const Color(0xFF1A237E),
                  indicatorWeight: 2.5,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                  unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.normal, fontSize: 14),
                  onTap: (i) {
                    if (i == 1 && _selectedClassId != null) {
                      _loadSummary();
                    }
                  },
                  tabs: const [
                    Tab(text: 'Mark Attendance'),
                    Tab(text: 'Summary'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_markTab(students), _summaryTab()],
          ),
        ),
        if (_tabController.index == 0 && _selectedClassId != null)
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isSaving ? null : _save,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _isSaving
                          ? const Color(0xFF1A237E)
                              .withOpacity(0.5)
                          : const Color(0xFF1A237E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isSaving)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else
                          const Icon(Icons.check_circle_outline,
                              size: 18, color: Colors.white),
                        const SizedBox(width: 10),
                        Text(
                          _isSaving
                              ? 'Saving...'
                              : 'Save Attendance',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _markTab(List<Map<String, dynamic>> students) {
    if (_selectedClassId == null) {
      return _empty('Select a class to begin',
          Icons.fact_check_outlined);
    }
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (students.isEmpty) {
      return _empty('No students found in this class',
          Icons.people_outline);
    }
    final pr = _statusMap.values.where((s) => s == 'present').length;
    final ab = _statusMap.values.where((s) => s == 'absent').length;
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE8EAED)),
          ),
          child: Row(
            children: [
              Text('$students.length Students',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  )),
              const SizedBox(width: 16),
              _pill('$pr Present',
                  const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
              const SizedBox(width: 8),
              _pill('$ab Absent',
                  const Color(0xFFFFEBEE), const Color(0xFFD32F2F)),
              const Spacer(),
              InkWell(
                onTap: _allPresent,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: const Color(0xFF2E7D32)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('All Present',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D32),
                      )),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            itemCount: students.length,
            itemBuilder: (_, i) {
              final s = students[i];
              final sid = s['id']?.toString() ?? '';
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: i.isEven
                      ? Colors.white
                      : const Color(0xFFFAFBFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF0F0F0)),
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
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            _sn(s),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF111827),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if ((s['admission_no'] ?? '')
                              .toString()
                              .isNotEmpty)
                            Text(
                              s['admission_no'].toString(),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade400,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _chip(sid, _statusMap[sid] ?? 'present'),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _summaryTab() {
    if (_selectedClassId == null) {
      return _empty('Select a class to view summary',
          Icons.bar_chart_outlined);
    }
    if (_summaryLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_summaryData.isEmpty) {
      return _empty('No attendance records yet',
          Icons.history_outlined,
          sub: 'Mark attendance for at least one day.');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      itemCount: _summaryData.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                SizedBox(width: 28),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Student',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A237E),
                      )),
                ),
                SizedBox(
                  width: 60,
                  child: Text('Present',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A237E),
                      )),
                ),
                SizedBox(
                  width: 60,
                  child: Text('Absent',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A237E),
                      )),
                ),
                SizedBox(
                  width: 60,
                  child: Text('Late',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A237E),
                      )),
                ),
                SizedBox(
                  width: 60,
                  child: Text('Total',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A237E),
                      )),
                ),
              ],
            ),
          );
        }
        final s = _summaryData[i - 1];
        final nm =
            '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim();
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: (i - 1).isEven
                ? Colors.white
                : const Color(0xFFFAFBFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFF0F0F0)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '$i',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  nm,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111827),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  '${s['present'] ?? 0}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  '${s['absent'] ?? 0}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD32F2F),
                  ),
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  '${s['late'] ?? 0}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE65100),
                  ),
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  '${s['total_days'] ?? 0}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _empty(String msg, IconData ic, {String? sub}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(ic,
                size: 32, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 14),
          Text(msg,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              )),
          if (sub != null) ...[
            const SizedBox(height: 6),
            Text(sub,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade400,
                )),
          ],
        ],
      ),
    );
  }

  Widget _pill(String t, Color bg, Color fg) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(t,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: fg,
          )),
    );
  }
}

import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartedu/core/providers/school_admin_provider.dart';

class PageAttendance extends StatefulWidget {
  final List<Map<String, dynamic>> classes;
  final List<Map<String, dynamic>> students;

  const PageAttendance({
    super.key,
    required this.classes,
    required this.students,
  });

  @override
  State<PageAttendance> createState() => _PageAttendanceState();
}

class _PageAttendanceState extends State<PageAttendance> {
  final SupabaseClient _supabase = Supabase.instance.client;
  String? _selectedClassId;
  String _selectedDate = '';
  int _activeTab = 0;
  bool _isLoading = false;
  bool _isExporting = false;
  List<Map<String, dynamic>> _dailyRecords = [];
  List<Map<String, dynamic>> _summaryData = [];
  int _thresholdPercent = 75;

  SchoolAdminProvider get _p => context.read<SchoolAdminProvider>();

  List<Map<String, dynamic>> get _studentsInClass {
    if (_selectedClassId == null) return [];
    return widget.students.where((s) => s['class_id']?.toString() == _selectedClassId).toList();
  }

  String _getClassName() {
    if (_selectedClassId == null) return '';
    try {
      final c = widget.classes.firstWhere((c) => c['id'].toString() == _selectedClassId);
      final n = (c['name'] ?? '').toString().trim();
      final s = (c['section'] ?? '').toString().trim();
      return s.isNotEmpty ? '$n $s' : n;
    } catch (_) { return ''; }
  }

  String _sName(Map<String, dynamic> s) {
    final f = (s['first_name'] ?? '').toString().trim();
    final l = (s['last_name'] ?? '').toString().trim();
    if (f.isNotEmpty && l.isNotEmpty) return '$f $l';
    if (f.isNotEmpty) return f;
    if (l.isNotEmpty) return l;
    return '';
  }

  void _snack(String msg, {bool success = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor: success ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
    ));
  }

  Future<void> _loadDaily() async {
    if (_selectedClassId == null || _selectedDate.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final r = await _supabase
          .from('attendance')
          .select('id, student_id, status, remark, students(first_name, last_name, admission_no)')
          .eq('school_id', _p.schoolId)
          .eq('class_id', _selectedClassId!)
          .eq('date', _selectedDate);
      _dailyRecords = List<Map<String, dynamic>>.from(r);
    } catch (e) {
      debugPrint('Daily load err: $e');
      _dailyRecords = [];
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSummary() async {
    if (_selectedClassId == null) return;
    setState(() => _isLoading = true);
    try {
      final students = _studentsInClass;
      final session = _p.currentSession;
      final term = _p.currentTerm;
      if (session == null || term == null) { _summaryData = []; if (mounted) setState(() => _isLoading = false); return; }
      final sid = session['id'].toString();
      final tid = term['id'].toString();
      final r = await _supabase
          .from('attendance')
          .select('student_id, status')
          .eq('school_id', _p.schoolId)
          .eq('class_id', _selectedClassId!)
          .eq('session_id', sid)
          .eq('term_id', tid);
      final Map<String, Map<String, int>> counts = {};
      for (final student in students) {
        final studentId = student['id'].toString();
        counts[studentId] = {'present': 0, 'absent': 0, 'late': 0, 'excused': 0};
      }
      for (final row in r) {
        final studentId = (row['student_id'] ?? '').toString();
        final status = (row['status'] ?? '').toString().toLowerCase();
        if (counts.containsKey(studentId)) {
          if (status == 'present') counts[studentId]!['present'] = counts[studentId]!['present']! + 1;
          else if (status == 'absent') counts[studentId]!['absent'] = counts[studentId]!['absent']! + 1;
          else if (status == 'late') counts[studentId]!['late'] = counts[studentId]!['late']! + 1;
          else if (status == 'excused') counts[studentId]!['excused'] = counts[studentId]!['excused']! + 1;
        }
      }
      _summaryData = students.map((s) {
        final studentId = s['id'].toString();
        final c = counts[studentId] ?? {'present': 0, 'absent': 0, 'late': 0, 'excused': 0};
        final total = c['present']! + c['absent']! + c['late']! + c['excused']!;
        final attended = c['present']! + c['late']!;
        final pct = total > 0 ? (attended / total * 100).round() : 0;
        return {
          'student': s, 'present': c['present']!, 'absent': c['absent']!,
          'late': c['late']!, 'excused': c['excused']!, 'total_days': total,
          'attended': attended, 'percentage': pct,
        };
      }).toList();
      _summaryData.sort((a, b) => (a['percentage'] as int).compareTo(b['percentage'] as int));
    } catch (e) {
      debugPrint('Summary err: $e');
      _summaryData = [];
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _exportSummaryCsv() {
    if (_summaryData.isEmpty) return;
    setState(() => _isExporting = true);
    try {
      final className = _getClassName();
      final sessionName = _p.currentSession?['name']?.toString() ?? '';
      final termName = _p.currentTerm?['name']?.toString() ?? '';
      final buf = StringBuffer();
      buf.writeln('Attendance Summary - $className');
      buf.writeln('Session: $sessionName | Term: $termName');
      buf.writeln('Threshold: ${_thresholdPercent}%');
      buf.writeln();
      buf.writeln(['#,Student Name,Admission No,Present,Absent,Late,Excused,Total Days,Attended,Percentage,Status'].join(','));
      for (var i = 0; i < _summaryData.length; i++) {
        final d = _summaryData[i];
        final s = d['student'] as Map<String, dynamic>;
        final name = _sName(s);
        final adm = (s['admission_no'] ?? '').toString();
        final pct = d['percentage'] as int;
        final status = pct >= _thresholdPercent ? 'OK' : 'BELOW THRESHOLD';
        final escaped = name.contains(',') || name.contains('"') ? '"${name.replaceAll('"', '""')}"' : name;
        buf.writeln([i + 1, escaped, adm, d['present'], d['absent'], d['late'], d['excused'], d['total_days'], d['attended'], '$pct%', status].join(','));
      }
      final bytes = Uint8List.fromList(buf.toString().codeUnits);
      final blob = html.Blob([bytes], 'text/csv;charset=utf-8;');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)..setAttribute('download', '${className.replaceAll(' ', '_')}_attendance_summary.csv')..click();
      html.Url.revokeObjectUrl(url);
      _snack('Exported!');
    } catch (e) {
      _snack('Export failed: $e', success: false);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      builder: (ctx, child) => Theme(data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF1A237E))), child: child!),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked.toIso8601String().split('T').first);
      if (_selectedClassId != null) _loadDaily();
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present': return const Color(0xFF2E7D32);
      case 'absent': return const Color(0xFFD32F2F);
      case 'late': return const Color(0xFFE65100);
      case 'excused': return const Color(0xFF1565C0);
      default: return Colors.grey.shade400;
    }
  }

  Color _pctColor(int pct) {
    if (pct >= _thresholdPercent) return const Color(0xFF2E7D32);
    if (pct >= 50) return const Color(0xFFE65100);
    return const Color(0xFFD32F2F);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F8FA),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFE0F7FA), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.calendar_month_rounded, size: 22, color: Color(0xFF00838F))),
                const SizedBox(width: 14),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Attendance Overview', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827), letterSpacing: -0.5)),
                  SizedBox(height: 2),
                  Text('View daily attendance and term summaries', style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
                ])),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.only(left: 14, right: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE8EAED))),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedClassId,
                  hint: Text('Select Class', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade500)),
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6B7280), size: 22),
                  isExpanded: true,
                  items: widget.classes.map((c) {
                    final label = '${c['name'] ?? ''} ${c['section'] ?? ''}'.trim();
                    return DropdownMenuItem(value: c['id'].toString(), child: Text(label, style: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w600, fontSize: 14)));
                  }).toList(),
                  onChanged: (v) {
                    setState(() { _selectedClassId = v; _dailyRecords = []; _summaryData = []; _selectedDate = ''; });
                    if (v != null && _activeTab == 1) _loadSummary();
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedClassId != null) ...[
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE8EAED))),
                child: Row(children: [
                  _tabButton('Daily View', 0, Icons.today_rounded),
                  _tabButton('Term Summary', 1, Icons.bar_chart_rounded),
                ]),
              ),
              const SizedBox(height: 16),
              if (_activeTab == 0) _buildDailyView() else _buildSummaryView(),
            ] else
              Center(child: Padding(padding: const EdgeInsets.all(60), child: Column(children: [
                Container(width: 72, height: 72, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(18)), child: Icon(Icons.calendar_today_outlined, size: 36, color: Colors.grey.shade400)),
                const SizedBox(height: 16),
                Text('Select a class to view attendance', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
              ]))),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(String label, int index, IconData icon) {
    final active = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _activeTab = index);
          if (index == 0 && _selectedDate.isNotEmpty) _loadDaily();
          if (index == 1) _loadSummary();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF1A237E) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 18, color: active ? Colors.white : const Color(0xFF6B7280)),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: active ? Colors.white : const Color(0xFF6B7280))),
          ]),
        ),
      ),
    );
  }

  Widget _buildDailyView() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _pickDate,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE8EAED))),
            child: Row(children: [
              const Icon(Icons.calendar_today_rounded, size: 20, color: Color(0xFF00838F)),
              const SizedBox(width: 10),
              Text(_selectedDate.isEmpty ? 'Pick a date' : _selectedDate, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _selectedDate.isEmpty ? Colors.grey.shade500 : const Color(0xFF111827))),
            ]),
          ),
        )),
        const SizedBox(width: 12),
        if (_selectedDate.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFFE0F7FA), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF80DEEA))),
            child: Text('${_dailyRecords.length} of ${_studentsInClass.length} recorded', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF00838F))),
          ),
      ]),
      const SizedBox(height: 16),
      if (_isLoading)
        const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Color(0xFF00838F))))
      else if (_selectedDate.isEmpty)
        Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(children: [
          Container(width: 56, height: 56, decoration: BoxDecoration(color: const Color(0xFFE0F7FA), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.event_available_rounded, size: 28, color: Color(0xFF00838F))),
          const SizedBox(height: 14),
          Text('Pick a date to view attendance', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        ])))
      else if (_dailyRecords.isEmpty && _studentsInClass.isNotEmpty)
        Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(children: [
          Container(width: 56, height: 56, decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.event_busy_rounded, size: 28, color: Color(0xFFE65100))),
          const SizedBox(height: 14),
          const Text('No attendance recorded for this date', style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 4),
          Text('Teachers mark attendance via their dashboard', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
        ])))
      else ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
          child: const Row(children: [
            SizedBox(width: 40, child: Text('#', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11))),
            SizedBox(width: 180, child: Text('Student', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11))),
            SizedBox(width: 100, child: Text('Status', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11))),
            SizedBox(width: 200, child: Text('Remark', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11))),
          ]),
        ),
        const SizedBox(height: 2),
        Container(
          decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE8EAED)), borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: Column(children: _dailyRecords.asMap().entries.map((e) {
            final r = e.value;
            final st = r['students'] as Map<String, dynamic>?;
            final name = st != null ? '${st['first_name'] ?? ''} ${st['last_name'] ?? ''}'.trim() : 'Unknown';
            final status = (r['status'] ?? '').toString();
            final remark = (r['remark'] ?? '').toString();
            return Container(
              color: e.key % 2 == 0 ? Colors.white : const Color(0xFFFAFBFC),
              child: Row(children: [
                SizedBox(width: 40, child: Text('${e.key + 1}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)))),
                SizedBox(width: 180, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1B2A4A)), overflow: TextOverflow.ellipsis))),
                SizedBox(width: 100, child: Center(child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: _statusColor(status).withOpacity(0.3))),
                  child: Text(status.toUpperCase(), textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor(status), letterSpacing: 0.5)),
                ))),
                SizedBox(width: 200, child: Center(child: Text(remark.isNotEmpty ? remark : '-', style: TextStyle(fontSize: 12, color: remark.isNotEmpty ? const Color(0xFF111827) : Colors.grey.shade400)))),
              ]),
            );
          }).toList()),
        ),
      ],
    ]);
  }

  Widget _buildSummaryView() {
    final sessionName = _p.currentSession?['name']?.toString() ?? '';
    final termName = _p.currentTerm?['name']?.toString() ?? '';
    final belowThreshold = _summaryData.where((d) => (d['percentage'] as int) < _thresholdPercent).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: const Color(0xFFE0F7FA), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF80DEEA))),
        child: Row(children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF00838F)),
          const SizedBox(width: 8),
          Expanded(child: Text('$sessionName - $termName  |  ${_summaryData.length} students  |  $belowThreshold below ${_thresholdPercent}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF00838F)))),
          const SizedBox(width: 8),
          Text('Threshold:', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(width: 6),
          SizedBox(
            width: 58,
            child: TextField(
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              controller: TextEditingController(text: _thresholdPercent.toString()),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF80DEEA))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF80DEEA))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF00838F), width: 2)),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (v) { setState(() => _thresholdPercent = int.tryParse(v) ?? 75); },
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: _isExporting ? null : _exportSummaryCsv,
            child: Container(height: 32, padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(color: const Color(0xFFE0F7FA), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF80DEEA))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (_isExporting) const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Color(0xFF00838F), strokeWidth: 2))
                else const Icon(Icons.download_rounded, size: 16, color: Color(0xFF00838F)),
                const SizedBox(width: 6),
                Text(_isExporting ? '...' : 'CSV', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF00838F))),
              ]),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      if (_isLoading)
        const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Color(0xFF00838F))))
      else if (_summaryData.isEmpty)
        Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(children: [
          Container(width: 56, height: 56, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(14)), child: Icon(Icons.bar_chart_rounded, size: 28, color: Colors.grey.shade400)),
          const SizedBox(height: 14),
          Text('No attendance data for this term', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        ])))
      else ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
          child: const Row(children: [
            SizedBox(width: 36, child: Text('#', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11))),
            SizedBox(width: 160, child: Text('Student', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11))),
            SizedBox(width: 60, child: Text('Present', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11))),
            SizedBox(width: 55, child: Text('Absent', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11))),
            SizedBox(width: 50, child: Text('Late', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11))),
            SizedBox(width: 55, child: Text('Days', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11))),
            SizedBox(width: 80, child: Text('Attendance %', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11))),
            SizedBox(width: 90, child: Text('Status', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11))),
          ]),
        ),
        const SizedBox(height: 2),
        Container(
          decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE8EAED)), borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: Column(children: _summaryData.asMap().entries.map((e) {
            final d = e.value;
            final s = d['student'] as Map<String, dynamic>;
            final name = _sName(s);
            final pct = d['percentage'] as int;
            final ok = pct >= _thresholdPercent;
            final pctColor = _pctColor(pct);
            return Container(
              color: e.key % 2 == 0 ? Colors.white : const Color(0xFFFAFBFC),
              child: Row(children: [
                SizedBox(width: 36, child: Text('${e.key + 1}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)))),
                SizedBox(width: 160, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10), child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1B2A4A)), overflow: TextOverflow.ellipsis))),
                SizedBox(width: 60, child: Text('${d['present']}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)))),
                SizedBox(width: 55, child: Text('${d['absent']}', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: (d['absent'] as int) > 0 ? const Color(0xFFD32F2F) : Colors.grey.shade400))),
                SizedBox(width: 50, child: Text('${d['late']}', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: (d['late'] as int) > 0 ? const Color(0xFFE65100) : Colors.grey.shade400))),
                SizedBox(width: 55, child: Text('${d['total_days']}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)))),
                SizedBox(width: 80, child: Center(child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: pctColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text('$pct%', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: pctColor)),
                ))),
                SizedBox(width: 90, child: Center(child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: ok ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(6)),
                  child: Text(ok ? 'OK' : 'BELOW', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: ok ? const Color(0xFF166534) : const Color(0xFF991B1B), letterSpacing: 0.5)),
                ))),
              ]),
            );
          }).toList()),
        ),
      ],
    ]);
  }
}

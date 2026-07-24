import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/school_admin_provider.dart';
import '../../../../utils/reports_pdf_generator.dart';
import '../../../../utils/csv_download_utils.dart';

class PageReports extends StatefulWidget {
  const PageReports({super.key});
  @override
  State<PageReports> createState() => _PageReportsState();
}

class _PageReportsState extends State<PageReports> {
  String _selectedReport = 'Class Term Summary';
  String? _selectedClassId;
  String? _selectedTermId;
  bool _isCumulative = false;
  List<String> _selectedTermIds = [];
  String _classLevel = '';
  int _topLimit = 10;
  double _promoThreshold = 50;
  String? _selectedStudentId;
  String? _selectedSubjectId;
  String _fromDate = '';
  String _toDate = '';
  String? _selectedFeeTypeId;
  bool _loading = false;
  Map<String, dynamic>? _classSummary;
  List<Map<String, dynamic>> _listData = [];
  String? _error;
  bool _initialized = false;

  static const _reportTypes = [
    'Class Term Summary', 'Subject Term Summary', 'Cumulative Class Summary', 'Cumulative Subject Summary',
    'Class Comparison', 'Top Students', 'Promotion Readiness', 'Student Individual Summary',
    'Attendance Summary', 'Fee Payment Status', 'Fee Collection Summary', 'Teacher Performance',
    'CBT Performance', 'Subject Trend', 'NCE Distribution', 'PACE Completion Rate',
  ];

  List<String> get _filteredReports {
    final isAce = _isAce;
    return _reportTypes.where((r) {
      if (r == 'CBT Performance' && isAce) return false;
      if ((r == 'NCE Distribution' || r == 'PACE Completion Rate') && !isAce) return false;
      return true;
    }).toList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final p = context.read<SchoolAdminProvider>();
      if (p.classes.isNotEmpty && _selectedClassId == null) _selectedClassId = p.classes.first['id']?.toString();
      if (p.termsList.isNotEmpty && _selectedTermId == null) _selectedTermId = p.termsList.first['id']?.toString();
      final pm = p.schoolSettings?['pass_mark'];
      _promoThreshold = pm != null ? num.tryParse(pm.toString())?.toDouble() ?? 50 : 50;
      if (!_filteredReports.contains(_selectedReport) && _filteredReports.isNotEmpty) _selectedReport = _filteredReports.first;
      _initialized = true;
    }
  }

  bool get _isAce => context.read<SchoolAdminProvider>().schoolSettings?['curriculum_mode'] == 'ace';
  String? get _sessionId => context.read<SchoolAdminProvider>().currentSession?['id']?.toString();
  List<Map<String, dynamic>> get _terms => context.read<SchoolAdminProvider>().termsList;
  bool get _needsClass => !['Class Comparison', 'Top Students', 'Promotion Readiness', 'Fee Collection Summary', 'Teacher Performance'].contains(_selectedReport);
  bool get _needsLevel => ['Class Comparison', 'Top Students', 'Promotion Readiness'].contains(_selectedReport);
  bool get _needsStudent => _selectedReport == 'Student Individual Summary';
  bool get _needsSubject => ['Teacher Performance', 'Subject Trend'].contains(_selectedReport);
  bool get _needsDateRange => _selectedReport == 'Attendance Summary';
  bool get _needsFeeType => _selectedReport == 'Fee Payment Status';

  List<Map<String, dynamic>> get _classStudents {
    final p = context.read<SchoolAdminProvider>();
    if (_selectedClassId == null) return [];
    return p.students.where((s) => s['class_id']?.toString() == _selectedClassId).toList();
  }

  bool get _canGenerate {
    if (_sessionId == null || _sessionId!.isEmpty) return false;
    if (_needsClass && (_selectedClassId == null || _selectedClassId!.isEmpty)) return false;
    if (_needsLevel && _classLevel.isEmpty && _selectedReport == 'Class Comparison') return false;
    if (_needsStudent && (_selectedStudentId == null || _selectedStudentId!.isEmpty)) return false;
    if (_needsSubject && (_selectedSubjectId == null || _selectedSubjectId!.isEmpty)) return false;
    if (_isCumulative) return _selectedTermIds.isNotEmpty;
    return _selectedTermId != null && _selectedTermId!.isNotEmpty;
  }

  Future<void> _generate() async {
    if (!_canGenerate) return;
    setState(() { _loading = true; _error = null; _classSummary = null; _listData = []; });
    try {
      final p = context.read<SchoolAdminProvider>();
      final sid = _sessionId!;
      final tids = _isCumulative ? _selectedTermIds : [_selectedTermId!];
      switch (_selectedReport) {
        case 'Class Term Summary': _classSummary = await p.loadClassTermSummary(_selectedClassId!, sid, _selectedTermId!);
        case 'Subject Term Summary': _listData = await p.loadSubjectTermSummaries(_selectedClassId!, sid, _selectedTermId!);
        case 'Cumulative Class Summary': _classSummary = await p.loadClassCumulativeSummary(_selectedClassId!, sid, tids);
        case 'Cumulative Subject Summary': _listData = await p.loadSubjectCumulativeSummaries(_selectedClassId!, sid, tids);
        case 'Class Comparison': _listData = await p.loadClassComparison(sid, tids, _classLevel);
        case 'Top Students': _listData = await p.loadTopStudents(sid, tids, classId: _selectedClassId, classLevel: _classLevel.isNotEmpty ? _classLevel : null, limit: _topLimit);
        case 'Promotion Readiness': _listData = await p.loadPromotionReadiness(sid, tids, classId: _selectedClassId, threshold: _promoThreshold);
        case 'Student Individual Summary': _classSummary = await p.loadStudentIndividualSummary(_selectedStudentId!, sid, tids);
        case 'Attendance Summary': _classSummary = await p.loadAttendanceSummary(_selectedClassId!, sid, _selectedTermId!, fromDate: _fromDate.isNotEmpty ? _fromDate : null, toDate: _toDate.isNotEmpty ? _toDate : null);
        case 'Fee Payment Status': _listData = await p.loadFeePaymentStatus(classId: _selectedClassId, sessionId: sid, termId: _selectedTermId!, feeTypeId: _selectedFeeTypeId);
        case 'Fee Collection Summary': _listData = await p.loadFeeCollectionSummary(sessionId: sid, termId: _selectedTermId!);
        case 'Teacher Performance': _listData = await p.loadTeacherPerformance(sid, tids, subjectId: _selectedSubjectId);
        case 'CBT Performance': _listData = await p.loadCbtPerformance(sid, tids, classId: _selectedClassId, subjectId: _selectedSubjectId);
        case 'Subject Trend': _listData = await p.loadSubjectTrend(_selectedClassId!, _selectedSubjectId!, sid, tids);
        case 'NCE Distribution': _listData = await p.loadNceDistribution(_selectedClassId!, sid, tids);
        case 'PACE Completion Rate': _listData = await p.loadPaceCompletionRate(_selectedClassId!, sid, tids);
      }
    } catch (e) { _error = e.toString(); } finally { setState(() => _loading = false); }
  }

  void _clearResults() => setState(() { _classSummary = null; _listData = []; _error = null; });

  Future<void> _downloadPdf() async {
    final p = context.read<SchoolAdminProvider>();
    final filters = <String, dynamic>{};
    filters['session'] = p.currentSession?['name'] ?? '';
    if (_isCumulative) {
      filters['terms'] = p.termsList.where((t) => _selectedTermIds.contains(t['id']?.toString())).map((t) => t['name']?.toString() ?? '').join(', ');
    } else {
      final t = p.termsList.firstWhere((t) => t['id']?.toString() == _selectedTermId, orElse: () => <String, dynamic>{});
      filters['terms'] = t['name']?.toString() ?? '';
    }
    if (_selectedClassId != null) {
      final c = p.classes.firstWhere((c) => c['id']?.toString() == _selectedClassId, orElse: () => <String, dynamic>{});
      final sec = (c['section'] ?? '').toString();
      filters['class_name'] = sec.isNotEmpty ? '${c['name']} $sec' : (c['name'] ?? '').toString();
    }
    if (_classLevel.isNotEmpty) filters['class_level'] = _classLevel;
    if (_selectedReport == 'Top Students') filters['top_n'] = _topLimit;
    if (_selectedReport == 'Promotion Readiness') filters['threshold'] = _promoThreshold.toStringAsFixed(0);
    if (_selectedStudentId != null) { final s = p.students.firstWhere((s) => s['id']?.toString() == _selectedStudentId, orElse: () => <String, dynamic>{}); filters['student'] = '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim(); }
    if (_selectedSubjectId != null) { final s = p.subjects.firstWhere((s) => s['id']?.toString() == _selectedSubjectId, orElse: () => <String, dynamic>{}); filters['subject'] = s['name']?.toString() ?? ''; }
    final schoolInfo = <String, dynamic>{'name': p.schoolName, 'motto': p.schoolMotto, 'address': p.schoolAddress, 'logo_url': p.schoolLogoUrl, 'phone': p.schoolPhone, 'email': p.schoolEmail};
    await ReportsPdfGenerator.generateAndDownload(reportType: _selectedReport, schoolInfo: schoolInfo, classSummary: _classSummary != null ? {..._classSummary!, 'threshold': _promoThreshold} : null, listData: _listData, filters: filters, isAce: _isAce);
  }

  void _downloadCsv() {
    final isAce = _isAce;
    final safeName = _selectedReport.toLowerCase().replaceAll(' ', '_');
    switch (_selectedReport) {
      case 'Class Term Summary': case 'Cumulative Class Summary':
        if (_classSummary == null) return;
        final d = _classSummary!;
        downloadCsv(['Metric', 'Value'], [
          ['Total Students', '${d['total_students'] ?? 0}'],
          if (isAce) ...[['Avg HACS', '${d['avg_hacs'] ?? 0}'], ['Avg NCE', '${d['avg_nce'] ?? 0}'], ['Avg PACEs', '${d['avg_paces'] ?? 0}'], ['Highest HACS', '${d['highest_hacs'] ?? 0}'], ['Lowest HACS', '${d['lowest_hacs'] ?? 0}']],
          if (!isAce) ...[['Avg Score', '${d['avg_score'] ?? 0}'], ['Highest Score', '${d['highest_score'] ?? 0}'], ['Lowest Score', '${d['lowest_score'] ?? 0}']],
          ['Pass Rate', '${d['pass_rate']}%'], ['Distinctions', '${d['distinction_count'] ?? 0}'], ['At Risk', '${d['at_risk_count'] ?? 0}'],
          if (d['terms_count'] != null) ['Terms', '${d['terms_count']}'],
        ], '$safeName.csv'); return;
      case 'Subject Term Summary': case 'Cumulative Subject Summary':
        final sk = isAce ? 'avg_pt' : 'avg_score';
        downloadCsv(['Subject', 'Code', isAce ? 'Avg PT' : 'Avg Score', 'Pass %', 'Highest', 'Lowest', 'Students'], _listData.map((r) => [r['subject_name'] ?? '', r['subject_code'] ?? '', '${r[sk]}', '${r['pass_rate']}%', '${r[isAce ? 'highest_pt' : 'highest_avg']}', '${r[isAce ? 'lowest_pt' : 'lowest_avg']}', '${r['students_count'] ?? 0}']).toList(), '$safeName.csv'); return;
      case 'Class Comparison':
        final sk = isAce ? 'avg_hacs' : 'avg_score';
        downloadCsv(['Class', 'Students', isAce ? 'Avg HACS' : 'Avg Score', 'Pass %', 'Distinctions', 'At Risk', 'Highest', 'Lowest'], _listData.map((r) => [r['class_name'] ?? '', '${r['total_students'] ?? 0}', '${r[sk]}', '${r['pass_rate']}%', '${r['distinction_count'] ?? 0}', '${r['at_risk_count'] ?? 0}', '${r[isAce ? 'highest_hacs' : 'highest_score']}', '${r[isAce ? 'lowest_hacs' : 'lowest_score']}']).toList(), '$safeName.csv'); return;
      case 'Top Students':
        final sk = isAce ? 'cumulative_hacs' : 'cumulative_score';
        final hdrs = ['#', 'Student', isAce ? 'Cum. HACS' : 'Cum. Score', 'Terms'];
        downloadCsv(hdrs, _listData.asMap().entries.map((e) => [('${e.key + 1}', e.value['student_name'] ?? 'Unknown', '${e.value[sk]}', '${e.value['terms_count'] ?? 0}')] as List).toList(), '$safeName.csv'); return;
      case 'Promotion Readiness':
        final sk = isAce ? 'HACS' : 'Score';
        downloadCsv(['Student', sk, 'Threshold', 'Gap'], _listData.map((r) { final v = (r['cumulative_value'] as num?)?.toDouble() ?? 0.0; return [r['student_name'] ?? 'Unknown', v.toStringAsFixed(1), '${_promoThreshold.toStringAsFixed(0)}%', (_promoThreshold - v).toStringAsFixed(1)]; }).toList(), '$safeName.csv'); return;
      case 'Student Individual Summary':
        if (_classSummary == null) return;
        final d = _classSummary!;
        downloadCsv(['Student', 'Adm No', ''], [[d['student_name'] ?? '', d['admission_no'] ?? '', '']], '$safeName.csv');
        downloadCsv(['Term', isAce ? 'HACS' : 'Total', isAce ? 'NCE' : 'Average', isAce ? 'PACEs' : 'Position', if (!isAce) 'Grade'], (d['terms'] as List).map((t) => [t['term_name'] ?? '', '${t[isAce ? 'hacs_score' : 'total_score']}', '${t[isAce ? 'nce_score' : 'average_score']}', '${t[isAce ? 'paces_completed' : 'position']}', if (!isAce) t['grade'] ?? '']).toList(), '${safeName}_terms.csv'); return;
      case 'Attendance Summary':
        if (_classSummary == null) return;
        final d = _classSummary!;
        downloadCsv(['Student', 'Days Present', 'Days Absent', 'Total Days', 'Rate %'], (d['students'] as List).map((s) => [s['student_name'] ?? '', '${s['days_present']}', '${s['days_absent']}', '${s['total_days']}', '${s['attendance_rate']}%']).toList(), '$safeName.csv'); return;
      case 'Fee Payment Status':
        downloadCsv(['Student', 'Expected', 'Paid', 'Balance', 'Status'], _listData.map((r) => [r['student_name'] ?? '', '${r['total_expected']}', '${r['total_paid']}', '${r['balance']}', '${r['status']}']).toList(), '$safeName.csv'); return;
      case 'Fee Collection Summary':
        downloadCsv(['Fee Type', 'Expected', 'Paid', 'Outstanding', 'Rate %', 'Students'], _listData.map((r) => [r['fee_type_name'] ?? '', '${r['total_expected']}', '${r['total_paid']}', '${r['outstanding']}', '${r['collection_rate']}%', '${r['students_count']}']).toList(), '$safeName.csv'); return;
      case 'Teacher Performance':
        final sk = isAce ? 'avg_pt' : 'avg_score';
        downloadCsv(['Teacher', 'Subjects', 'Classes', isAce ? 'Avg PT' : 'Avg Score', 'Pass %', 'Students'], _listData.map((r) => [r['teacher_name'] ?? '', '${r['subjects']}', '${r['classes_count']}', '${r[sk]}', '${r['pass_rate']}%', '${r['students_count']}']).toList(), '$safeName.csv'); return;
      case 'CBT Performance':
        downloadCsv(['Exam', 'Subject', 'Students', 'Avg Score', 'Pass %', 'Highest', 'Lowest'], _listData.map((r) => [r['exam_title'] ?? '', r['subject_name'] ?? '', '${r['total_students']}', '${r['avg_score']}', '${r['pass_rate']}%', '${r['highest']}', '${r['lowest']}']).toList(), '$safeName.csv'); return;
      case 'Subject Trend':
        final sk = isAce ? 'avg_pt' : 'avg_score';
        downloadCsv(['Term', isAce ? 'Avg PT' : 'Avg Score', 'Pass %', 'Students', 'Trend'], _listData.map((r) => [r['term_name'] ?? '', '${r[sk]}', '${r['pass_rate']}%', '${r['students_count']}', '${r['trend'] ?? ''}']).toList(), '$safeName.csv'); return;
      case 'NCE Distribution':
        downloadCsv(['Band', 'Count', 'Percentage', 'Students'], _listData.map((r) => [r['band'] ?? '', '${r['count']}', '${r['percentage']}%', (r['students'] as List).join('; ')]).toList(), '$safeName.csv'); return;
      case 'PACE Completion Rate':
        downloadCsv(['Subject', 'Code', 'Total PACEs', 'Students', 'Avg/Student', 'Avg PT'], _listData.map((r) => [r['subject_name'] ?? '', r['subject_code'] ?? '', '${r['total_paces']}', '${r['unique_students']}', '${r['avg_paces_per_student']}', '${r['avg_pt']}']).toList(), '$safeName.csv'); return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAce = _isAce;
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Report Type', DropdownButtonFormField<String>(
            value: _filteredReports.contains(_selectedReport) ? _selectedReport : null,
            decoration: _decor('Choose a report'),
            items: _filteredReports.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 14)))).toList(),
            onChanged: (v) { if (v != null) { setState(() => _selectedReport = v); _clearResults(); } },
          )),
          if (_needsClass)
            _section('Class', DropdownButtonFormField<String>(
              value: _selectedClassId,
              decoration: _decor('Select class'),
              items: context.watch<SchoolAdminProvider>().classes.map((c) {
                final sec = (c['section'] ?? '').toString();
                final label = sec.isNotEmpty ? '${c['name']} $sec' : (c['name'] ?? '').toString();
                return DropdownMenuItem(value: c['id']?.toString(), child: Text(label, style: const TextStyle(fontSize: 14)));
              }).toList(),
              onChanged: (v) { setState(() { _selectedClassId = v; _selectedStudentId = null; }); _clearResults(); },
            )),
          if (_needsStudent)
            _section('Student', DropdownButtonFormField<String>(
              value: _selectedStudentId,
              decoration: _decor('Select student'),
              items: _classStudents.map((s) {
                final fn = (s['first_name'] ?? '').toString();
                final ln = (s['last_name'] ?? '').toString();
                return DropdownMenuItem(value: s['id']?.toString(), child: Text('$fn $ln (${s['admission_no'] ?? ''})', style: const TextStyle(fontSize: 14)));
              }).toList(),
              onChanged: (v) => setState(() => _selectedStudentId = v),
            )),
          if (_needsSubject)
            _section('Subject', DropdownButtonFormField<String>(
              value: _selectedSubjectId,
              decoration: _decor('Select subject'),
              items: context.watch<SchoolAdminProvider>().subjects.map((s) => DropdownMenuItem(value: s['id']?.toString(), child: Text('${s['name']} (${s['code'] ?? ''})', style: const TextStyle(fontSize: 14)))).toList(),
              onChanged: (v) => setState(() => _selectedSubjectId = v),
            )),
          if (_needsLevel)
            _section('Class Level', TextFormField(decoration: _decor('e.g. JSS1, SSS2, Grade 3'), onChanged: (v) => setState(() => _classLevel = v.trim()))),
          _section('Term Scope', Row(children: [
            Expanded(child: _scopeChip('Single Term', !_isCumulative, () => setState(() => _isCumulative = false))),
            const SizedBox(width: 8),
            Expanded(child: _scopeChip('Cumulative', _isCumulative, () => setState(() => _isCumulative = true))),
          ])),
          if (!_isCumulative)
            _section('Term', DropdownButtonFormField<String>(
              value: _selectedTermId,
              decoration: _decor('Select term'),
              items: _terms.map((t) => DropdownMenuItem(value: t['id']?.toString(), child: Text(t['name']?.toString() ?? '', style: const TextStyle(fontSize: 14)))).toList(),
              onChanged: (v) => setState(() => _selectedTermId = v),
            )),
          if (_isCumulative)
            _section('Terms', Card(child: Column(children: _terms.map((t) {
              final tid = t['id']?.toString() ?? '';
              return CheckboxListTile(title: Text(t['name']?.toString() ?? '', style: const TextStyle(fontSize: 14)), value: _selectedTermIds.contains(tid), dense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 8), onChanged: (v) => setState(() { if (v == true) _selectedTermIds.add(tid); else _selectedTermIds.remove(tid); }));
            }).toList()))),
          if (_selectedReport == 'Top Students')
            _section('Top N', TextFormField(decoration: _decor('Number of students'), keyboardType: TextInputType.number, initialValue: _topLimit.toString(), onChanged: (v) => setState(() => _topLimit = int.tryParse(v) ?? 10))),
          if (_selectedReport == 'Promotion Readiness')
            _section('Threshold (%)', TextFormField(decoration: _decor(isAce ? 'Default: 80' : 'Default: ${context.read<SchoolAdminProvider>().schoolSettings?['pass_mark'] ?? 50}'), keyboardType: TextInputType.number, initialValue: _promoThreshold.toStringAsFixed(0), onChanged: (v) => setState(() => _promoThreshold = double.tryParse(v) ?? (isAce ? 80 : 50)))),
          if (_needsDateRange)
            Row(children: [
              Expanded(child: _section('From Date', TextFormField(decoration: _decor('YYYY-MM-DD'), onChanged: (v) => setState(() => _fromDate = v.trim())))),
              const SizedBox(width: 8),
              Expanded(child: _section('To Date', TextFormField(decoration: _decor('YYYY-MM-DD'), onChanged: (v) => setState(() => _toDate = v.trim())))),
            ]),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, height: 48, child: ElevatedButton(
            onPressed: _canGenerate && !_loading ? _generate : null,
            child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Generate Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          )),
          const SizedBox(height: 20),
          if (_classSummary != null || _listData.isNotEmpty)
            Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
              Expanded(child: SizedBox(height: 48, child: OutlinedButton.icon(onPressed: _downloadPdf, icon: const Icon(Icons.picture_as_pdf, color: Colors.orange), label: const Text('Download PDF', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.orange)), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orange))))),
              const SizedBox(width: 10),
              Expanded(child: SizedBox(height: 48, child: OutlinedButton.icon(onPressed: _downloadCsv, icon: const Icon(Icons.table_chart, color: Colors.green), label: const Text('Download CSV', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.green)), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.green))))),
            ])),
          if (_error != null) Card(color: Colors.red.shade50, child: Padding(padding: const EdgeInsets.all(12), child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)))),
          if (_classSummary != null) ...[_buildSummaryView(_classSummary!, isAce), const SizedBox(height: 16)],
          if (_listData.isNotEmpty) _buildResultTable(isAce),
          if (!_loading && _classSummary == null && _listData.isEmpty && _error == null)
            Card(child: Padding(padding: const EdgeInsets.all(40), child: Center(child: Text('Configure filters above and generate a report', style: TextStyle(color: Colors.grey.shade500, fontSize: 14))))),
        ],
      ),
    );
  }

  Widget _section(String label, Widget child) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade700)), const SizedBox(height: 4), child]));
  InputDecoration _decor(String hint) => InputDecoration(hintText: hint, hintStyle: const TextStyle(fontSize: 14), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14), border: const OutlineInputBorder(), isDense: true);
  Widget _scopeChip(String label, bool selected, VoidCallback onTap) => OutlinedButton(onPressed: onTap, style: OutlinedButton.styleFrom(backgroundColor: selected ? Colors.blue : Colors.transparent, foregroundColor: selected ? Colors.white : Colors.grey.shade700, side: BorderSide(color: selected ? Colors.blue : Colors.grey.shade400), padding: const EdgeInsets.symmetric(vertical: 12)), child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)));

  // ═══ SUMMARY VIEW (handles cards for class/attendance/student summaries) ═══
  Widget _buildSummaryView(Map<String, dynamic> d, bool isAce) {
    if (d.containsKey('students') && d['students'] is List) {
      // Attendance summary
      final stuList = d['students'] as List;
      return Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Attendance Summary', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(spacing: 12, children: [
            _infoChip('Students', '${d['total_students']}', Colors.blue),
            _infoChip('Avg Rate', '${d['avg_attendance_rate']}%', Colors.green),
            _infoChip('Most Absent', '${d['most_absent_student']}', Colors.red),
            _infoChip('Most Present', '${d['most_present_student']}', Colors.teal),
          ]),
        ])),
        const Divider(),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
          headingRowColor: WidgetStatePropertyAll(Colors.blue.shade50),
          columns: [_dcol('Student'), _dcol('Present'), _dcol('Absent'), _dcol('Total'), _dcol('Rate %')],
          rows: stuList.map((s) => DataRow(cells: [
            DataCell(Text(s['student_name']?.toString() ?? '')),
            DataCell(Text('${s['days_present']}')),
            DataCell(Text('${s['days_absent']}')),
            DataCell(Text('${s['total_days']}')),
            DataCell(Text('${s['attendance_rate']}%', style: TextStyle(color: _numVal(s['attendance_rate']) >= 75 ? Colors.green : Colors.red, fontWeight: FontWeight.w600))),
          ])).toList(),
        )),
      ]));
    }
    if (d.containsKey('subjects') && d['subjects'] is List) {
      // Student individual summary
      return Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(d['student_name']?.toString() ?? 'Student Summary', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        if ((d['admission_no'] ?? '').toString().isNotEmpty) Text('Adm: ${d['admission_no']}', style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 12),
        const Text('Per-Subject Performance', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
          headingRowColor: WidgetStatePropertyAll(Colors.blue.shade50),
          columns: isAce ? [_dcol('Subject'), _dcol('PACEs'), _dcol('Avg PT'), _dcol('Highest'), _dcol('Lowest')] : [_dcol('Subject'), _dcol('Terms'), _dcol('Avg Score'), _dcol('Highest'), _dcol('Lowest')],
          rows: (d['subjects'] as List).map((s) => DataRow(cells: isAce ? [
            DataCell(Text(s['subject_name'] ?? '')), DataCell(Text('${s['total_paces']}')),
            DataCell(_scoreText(s['avg_pt'])), DataCell(_scoreText(s['highest_pt'])), DataCell(_scoreText(s['lowest_pt'])),
          ] : [
            DataCell(Text(s['subject_name'] ?? '')), DataCell(Text('${s['terms_scored']}')),
            DataCell(_scoreText(s['avg_score'])), DataCell(_scoreText(s['highest'])), DataCell(_scoreText(s['lowest'])),
          ])).toList(),
        )),
        if ((d['terms'] as List).isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Term-by-Term', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
            headingRowColor: WidgetStatePropertyAll(Colors.blue.shade50),
            columns: isAce ? [_dcol('Term'), _dcol('HACS'), _dcol('NCE'), _dcol('PACEs')] : [_dcol('Term'), _dcol('Total'), _dcol('Average'), _dcol('Position'), _dcol('Grade')],
            rows: (d['terms'] as List).map((t) => DataRow(cells: isAce ? [
              DataCell(Text(t['term_name'] ?? '')), DataCell(_scoreText(t['hacs_score'])), DataCell(_scoreText(t['nce_score'])), DataCell(Text('${t['paces_completed']}')),
            ] : [
              DataCell(Text(t['term_name'] ?? '')), DataCell(_scoreText(t['total_score'])), DataCell(_scoreText(t['average_score'])), DataCell(Text('${t['position']}')), DataCell(Text(t['grade'] ?? '')),
            ])).toList(),
          )),
        ],
      ])));
    }
    // Class summary cards
    final total = d['total_students'] ?? 0;
    if (total == 0) return const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('No data found', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))));
    final cards = <_MC>[];
    if (isAce) {
      cards.addAll([_MC('Avg HACS', d['avg_hacs'], Colors.blue), _MC('Avg NCE', d['avg_nce'], Colors.orange), _MC('Avg PACEs', d['avg_paces'], Colors.teal), _MC('Pass Rate', '${d['pass_rate']}%', Colors.green), _MC('Distinctions', d['distinction_count'], Colors.purple), _MC('At Risk', d['at_risk_count'], Colors.red), _MC('Highest', d['highest_hacs'], Colors.indigo), _MC('Lowest', d['lowest_hacs'], Colors.deepOrange)]);
    } else {
      cards.addAll([_MC('Avg Score', d['avg_score'], Colors.blue), _MC('Pass Rate', '${d['pass_rate']}%', Colors.green), _MC('Distinctions', d['distinction_count'], Colors.purple), _MC('At Risk', d['at_risk_count'], Colors.red), _MC('Highest', d['highest_score'], Colors.indigo), _MC('Lowest', d['lowest_score'], Colors.deepOrange)]);
    }
    if (d['terms_count'] != null) cards.add(_MC('Terms', d['terms_count'], Colors.grey));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(bottom: 10), child: Text('Total Students: $total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
      Wrap(spacing: 8, runSpacing: 8, children: cards.map((c) => _metricCard(c)).toList()),
    ]);
  }

  Widget _infoChip(String label, String value, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.3))), child: Column(children: [Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)), Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)))]));
  Widget _metricCard(_MC c) => Card(elevation: 0, color: c.color.withOpacity(0.1), child: Container(width: 110, padding: const EdgeInsets.all(10), child: Column(children: [Text('${c.value}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: c.color)), const SizedBox(height: 2), Text(c.label, style: TextStyle(fontSize: 11, color: c.color.withOpacity(0.8)), textAlign: TextAlign.center)])));

  Widget _buildResultTable(bool isAce) {
    switch (_selectedReport) {
      case 'Subject Term Summary': case 'Cumulative Subject Summary': return _subjectTable(isAce);
      case 'Class Comparison': return _comparisonTable(isAce);
      case 'Top Students': return _topStudentsTable(isAce);
      case 'Promotion Readiness': return _promotionTable(isAce);
      case 'Fee Payment Status': return _feeStatusTable();
      case 'Fee Collection Summary': return _feeCollectionTable();
      case 'Teacher Performance': return _teacherTable(isAce);
      case 'CBT Performance': return _cbtTable();
      case 'Subject Trend': return _trendTable(isAce);
      case 'NCE Distribution': return _nceTable();
      case 'PACE Completion Rate': return _paceCompTable();
      default: return const SizedBox.shrink();
    }
  }

  Widget _subjectTable(bool isAce) {
    final sk = isAce ? 'avg_pt' : 'avg_score';
    final hk = isAce ? 'highest_pt' : 'highest_avg';
    final lk = isAce ? 'lowest_pt' : 'lowest_avg';
    return Card(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
      headingRowColor: WidgetStatePropertyAll(Colors.blue.shade50),
      columns: [_dcol('Subject'), _dcol('Code'), _dcol(isAce ? 'Avg PT' : 'Avg Score'), _dcol('Pass %'), _dcol('Highest'), _dcol('Lowest'), _dcol('Students')],
      rows: _listData.map((r) => DataRow(cells: [DataCell(Text(r['subject_name'] ?? '')), DataCell(Text(r['subject_code'] ?? '')), DataCell(_scoreText(r[sk])), DataCell(Text('${r['pass_rate']}%')), DataCell(_scoreText(r[hk])), DataCell(_scoreText(r[lk])), DataCell(Text('${r['students_count'] ?? 0}'))])).toList(),
    )));
  }

  Widget _comparisonTable(bool isAce) {
    final sk = isAce ? 'avg_hacs' : 'avg_score';
    final hk = isAce ? 'highest_hacs' : 'highest_score';
    final lk = isAce ? 'lowest_hacs' : 'lowest_score';
    return Card(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
      headingRowColor: WidgetStatePropertyAll(Colors.blue.shade50),
      columns: [_dcol('Class'), _dcol('Students'), _dcol(isAce ? 'Avg HACS' : 'Avg Score'), _dcol('Pass %'), _dcol('Distinctions'), _dcol('At Risk'), _dcol('Highest'), _dcol('Lowest')],
      rows: _listData.map((r) => DataRow(cells: [DataCell(Text(r['class_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600))), DataCell(Text('${r['total_students'] ?? 0}')), DataCell(_scoreText(r[sk])), DataCell(Text('${r['pass_rate']}%')), DataCell(Text('${r['distinction_count'] ?? 0}')), DataCell(Text('${r['at_risk_count'] ?? 0}')), DataCell(_scoreText(r[hk])), DataCell(_scoreText(r[lk]))])).toList(),
    )));
  }

  Widget _topStudentsTable(bool isAce) {
    final sk = isAce ? 'cumulative_hacs' : 'cumulative_score';
    return Card(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
      headingRowColor: WidgetStatePropertyAll(Colors.blue.shade50),
      columns: [_dcol('#'), _dcol('Student'), _dcol(isAce ? 'Cum. HACS' : 'Cum. Score'), _dcol('Terms'), if (isAce) ...[_dcol('Cum. NCE'), _dcol('Cum. PACEs')]],
      rows: _listData.asMap().entries.map((e) { final r = e.value; final rank = e.key + 1; return DataRow(cells: [DataCell(Text('$rank', style: TextStyle(fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.normal, color: rank <= 3 ? Colors.blue : null))), DataCell(Text(r['student_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w500))), DataCell(_scoreText(r[sk], bold: rank <= 3)), DataCell(Text('${r['terms_count'] ?? 0}')), if (isAce) ...[DataCell(_scoreText(r['cumulative_nce'])), DataCell(_scoreText(r['cumulative_paces']))]]); }).toList(),
    )));
  }

  Widget _promotionTable(bool isAce) {
    return Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.all(12), child: Text('${_listData.length} student(s) below threshold', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red.shade700))),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
        headingRowColor: WidgetStatePropertyAll(Colors.red.shade50),
        columns: [_dcol('Student'), _dcol(isAce ? 'HACS' : 'Score'), _dcol('Threshold'), _dcol('Gap'), if (isAce) _dcol('Cum. NCE')],
        rows: _listData.map((r) { final val = (r['cumulative_value'] as num?)?.toDouble() ?? 0.0; final gap = _promoThreshold - val; return DataRow(cells: [DataCell(Text(r['student_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w500))), DataCell(Text(val.toStringAsFixed(1), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600))), DataCell(Text('${_promoThreshold.toStringAsFixed(0)}%')), DataCell(Text('${gap.toStringAsFixed(1)}', style: TextStyle(color: gap > 20 ? Colors.red : Colors.orange, fontWeight: FontWeight.w600))), if (isAce) DataCell(_scoreText(r['cumulative_nce']))]); }).toList(),
      )),
    ]));
  }

  Widget _feeStatusTable() {
    return Card(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
      headingRowColor: WidgetStatePropertyAll(Colors.blue.shade50),
      columns: [_dcol('Student'), _dcol('Expected'), _dcol('Paid'), _dcol('Balance'), _dcol('Status')],
      rows: _listData.map((r) {
        final st = (r['status'] ?? '').toString();
        Color stColor; if (st == 'Paid') stColor = Colors.green; else if (st == 'Partial') stColor = Colors.orange; else stColor = Colors.red;
        return DataRow(cells: [DataCell(Text(r['student_name'] ?? '')), DataCell(Text('${r['total_expected']}')), DataCell(Text('${r['total_paid']}')), DataCell(Text('${r['balance']}')), DataCell(Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: stColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(st, style: TextStyle(color: stColor, fontWeight: FontWeight.w600, fontSize: 12))))]);
      }).toList(),
    )));
  }

  Widget _feeCollectionTable() {
    return Card(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
      headingRowColor: WidgetStatePropertyAll(Colors.blue.shade50),
      columns: [_dcol('Fee Type'), _dcol('Expected'), _dcol('Collected'), _dcol('Outstanding'), _dcol('Rate %'), _dcol('Students')],
      rows: _listData.map((r) => DataRow(cells: [DataCell(Text(r['fee_type_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500))), DataCell(Text('${r['total_expected']}')), DataCell(Text('${r['total_paid']}')), DataCell(Text('${r['outstanding']}', style: TextStyle(color: _numVal(r['outstanding']) > 0 ? Colors.red : Colors.green))), DataCell(Text('${r['collection_rate']}%')), DataCell(Text('${r['students_count']}'))])).toList(),
    )));
  }

  Widget _teacherTable(bool isAce) {
    final sk = isAce ? 'avg_pt' : 'avg_score';
    return Card(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
      headingRowColor: WidgetStatePropertyAll(Colors.blue.shade50),
      columns: [_dcol('Teacher'), _dcol('Subjects'), _dcol('Classes'), _dcol(isAce ? 'Avg PT' : 'Avg Score'), _dcol('Pass %'), _dcol('Students')],
      rows: _listData.map((r) => DataRow(cells: [DataCell(Text(r['teacher_name'] ?? '')), DataCell(Text('${r['subjects']}', style: const TextStyle(fontSize: 12))), DataCell(Text('${r['classes_count']}')), DataCell(_scoreText(r[sk])), DataCell(Text('${r['pass_rate']}%')), DataCell(Text('${r['students_count']}'))])).toList(),
    )));
  }

  Widget _cbtTable() {
    return Card(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
      headingRowColor: WidgetStatePropertyAll(Colors.blue.shade50),
      columns: [_dcol('Exam'), _dcol('Subject'), _dcol('Students'), _dcol('Avg Score'), _dcol('Pass %'), _dcol('Highest'), _dcol('Lowest')],
      rows: _listData.map((r) => DataRow(cells: [DataCell(Text(r['exam_title'] ?? '')), DataCell(Text(r['subject_name'] ?? '')), DataCell(Text('${r['total_students']}')), DataCell(_scoreText(r['avg_score'])), DataCell(Text('${r['pass_rate']}%')), DataCell(_scoreText(r['highest'])), DataCell(_scoreText(r['lowest']))])).toList(),
    )));
  }

  Widget _trendTable(bool isAce) {
    final sk = isAce ? 'avg_pt' : 'avg_score';
    return Card(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
      headingRowColor: WidgetStatePropertyAll(Colors.blue.shade50),
      columns: [_dcol('Term'), _dcol(isAce ? 'Avg PT' : 'Avg Score'), _dcol('Pass %'), _dcol('Students'), _dcol('Trend')],
      rows: _listData.map((r) {
        final trend = (r['trend'] ?? '').toString();
        Color tc; if (trend.contains('Improving')) tc = Colors.green; else if (trend.contains('Declining')) tc = Colors.red; else tc = Colors.grey;
        return DataRow(cells: [DataCell(Text(r['term_name'] ?? '')), DataCell(_scoreText(r[sk])), DataCell(Text('${r['pass_rate']}%')), DataCell(Text('${r['students_count']}')), DataCell(Text(trend, style: TextStyle(color: tc, fontWeight: FontWeight.w600)))]);
      }).toList(),
    )));
  }

  Widget _nceTable() {
    final maxCount = _listData.map((r) => (r['count'] as num?)?.toInt() ?? 0).fold<int>(0, (a, b) => b > a ? b : a);
    return Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(padding: EdgeInsets.all(12), child: Text('NCE Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
      ..._listData.map((r) {
        final count = (r['count'] as num?)?.toInt() ?? 0;
        final pct = maxCount > 0 ? count / maxCount : 0.0;
        final stuNames = (r['students'] as List?)?.cast<String>() ?? [];
        final barWidth = pct.clamp(0.02, 1.0).toDouble();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              SizedBox(width: 60, child: Text(r['band'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
              Expanded(child: Stack(children: [
                Container(height: 24, decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(4))),
                FractionallySizedBox(widthFactor: barWidth, child: Container(
                  height: 24, decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(4)),
                  alignment: Alignment.center,
                  child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                )),
              ])),
              SizedBox(width: 50, child: Text('${r['percentage']}%', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
            ]),
            if (stuNames.isNotEmpty)
              Padding(padding: const EdgeInsets.only(left: 60, top: 2), child: Text(stuNames.join(', '), style: TextStyle(fontSize: 10, color: Colors.grey.shade600))),
          ]),
        );
      }).toList(),
    ]));
  }

  Widget _paceCompTable() {
    return Card(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
      headingRowColor: WidgetStatePropertyAll(Colors.blue.shade50),
      columns: [_dcol('Subject'), _dcol('Code'), _dcol('Total PACEs'), _dcol('Students'), _dcol('Avg/Student'), _dcol('Avg PT')],
      rows: _listData.map((r) => DataRow(cells: [DataCell(Text(r['subject_name'] ?? '')), DataCell(Text(r['subject_code'] ?? '')), DataCell(Text('${r['total_paces']}')), DataCell(Text('${r['unique_students']}')), DataCell(_scoreText(r['avg_paces_per_student'])), DataCell(_scoreText(r['avg_pt']))])).toList(),
    )));
  }

  DataColumn _dcol(String label) => DataColumn(label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)));
  Text _scoreText(dynamic val, {bool bold = false}) { final s = val is num ? val.toStringAsFixed(1) : (val?.toString() ?? '0.0'); return Text(s, style: TextStyle(fontWeight: bold ? FontWeight.w600 : FontWeight.normal)); }
  double _numVal(dynamic v) { if (v is double) return v; if (v is int) return v.toDouble(); if (v is String) return num.tryParse(v)?.toDouble() ?? 0.0; return 0.0; }
}

class _MC { final String label; final dynamic value; final Color color; _MC(this.label, this.value, this.color); }

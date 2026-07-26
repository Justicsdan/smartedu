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
  bool get _needsSubject => ['Subject Term Summary', 'Cumulative Subject Summary', 'Teacher Performance', 'Subject Trend'].contains(_selectedReport);
  bool get _needsDateRange => _selectedReport == 'Attendance Summary';

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
        case 'Fee Payment Status': _listData = await p.loadFeePaymentStatus(classId: _selectedClassId, sessionId: sid, termId: _selectedTermId!);
        case 'Fee Collection Summary': _listData = await p.loadFeeCollectionSummary(sessionId: sid, termId: _selectedTermId!);
        case 'Teacher Performance': _listData = await p.loadTeacherPerformance(sid, tids, subjectId: _selectedSubjectId);
        case 'CBT Performance': _listData = await p.loadCbtPerformance(sid, tids, classId: _selectedClassId, subjectId: _selectedSubjectId);
        case 'Subject Trend': _listData = await p.loadSubjectTrend(_selectedClassId!, _selectedSubjectId!, sid, tids);
        case 'NCE Distribution': _listData = await p.loadNceDistribution(_selectedClassId!, sid, tids);
        case 'PACE Completion Rate': _listData = await p.loadPaceCompletionRate(_selectedClassId!, sid, tids);
      }
    } catch (e) { _error = e.toString(); } finally { setState(() => _loading = false); }
    // Filter to single subject if selected
    if (_selectedSubjectId != null && _selectedSubjectId!.isNotEmpty) {
      if (_selectedReport == 'Subject Term Summary' || _selectedReport == 'Cumulative Subject Summary') {
        _listData = _listData.where((r) => r['subject_id']?.toString() == _selectedSubjectId).toList();
      }
    }
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
    if (_selectedStudentId != null) {
      final s = p.students.firstWhere((s) => s['id']?.toString() == _selectedStudentId, orElse: () => <String, dynamic>{});
      filters['student'] = '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim();
    }
    if (_selectedSubjectId != null) {
      final s = p.subjects.firstWhere((s) => s['id']?.toString() == _selectedSubjectId, orElse: () => <String, dynamic>{});
      filters['subject'] = s['name']?.toString() ?? '';
    }
    final schoolInfo = <String, dynamic>{'name': p.schoolName, 'motto': p.schoolMotto, 'address': p.schoolAddress, 'logo_url': p.schoolLogoUrl, 'phone': p.schoolPhone, 'email': p.schoolEmail};
    await ReportsPdfGenerator.generateAndDownload(
      reportType: _selectedReport,
      schoolInfo: schoolInfo,
      classSummary: _classSummary != null ? {..._classSummary!, 'threshold': _promoThreshold} : null,
      listData: _listData,
      filters: filters,
      isAce: _isAce,
    );
  }

  void _downloadCsv() {
    final isAce = _isAce;
    final safeName = _selectedReport.toLowerCase().replaceAll(' ', '_');
    switch (_selectedReport) {
      case 'Class Term Summary':
      case 'Cumulative Class Summary':
        if (_classSummary == null) return;
        final d = _classSummary!;
        downloadCsv(['Metric', 'Value'], [
          ['Total Students', '${d['total_students'] ?? 0}'],
          if (isAce) ...[
            ['Avg HACS', '${d['avg_hacs'] ?? 0}'],
            ['Avg NCE', '${d['avg_nce'] ?? 0}'],
            ['Avg PACEs', '${d['avg_paces'] ?? 0}'],
            ['Highest HACS', '${d['highest_hacs'] ?? 0}'],
            ['Lowest HACS', '${d['lowest_hacs'] ?? 0}'],
          ],
          if (!isAce) ...[
            ['Avg Score', '${d['avg_score'] ?? 0}'],
            ['Highest Score', '${d['highest_score'] ?? 0}'],
            ['Lowest Score', '${d['lowest_score'] ?? 0}'],
          ],
          ['Pass Rate', '${d['pass_rate']}%'],
          ['Distinctions', '${d['distinction_count'] ?? 0}'],
          ['At Risk', '${d['at_risk_count'] ?? 0}'],
          if (d['terms_count'] != null) ['Terms', '${d['terms_count']}'],
        ], '$safeName.csv');
        return;
      case 'Subject Term Summary':
      case 'Cumulative Subject Summary':
        final sk = isAce ? 'avg_pt' : 'avg_score';
        downloadCsv(
          ['Subject', 'Code', isAce ? 'Avg PT' : 'Avg Score', 'Pass %', 'Highest', 'Lowest', 'Students'],
          _listData.map((r) => [r['subject_name'] ?? '', r['subject_code'] ?? '', '${r[sk]}', '${r['pass_rate']}%', '${r[isAce ? 'highest_pt' : 'highest_avg']}', '${r[isAce ? 'lowest_pt' : 'lowest_avg']}', '${r['students_count'] ?? 0}']).toList(),
          '$safeName.csv',
        );
        return;
      case 'Class Comparison':
        final sk = isAce ? 'avg_hacs' : 'avg_score';
        downloadCsv(
          ['Class', 'Students', isAce ? 'Avg HACS' : 'Avg Score', 'Pass %', 'Distinctions', 'At Risk', 'Highest', 'Lowest'],
          _listData.map((r) => [r['class_name'] ?? '', '${r['total_students'] ?? 0}', '${r[sk]}', '${r['pass_rate']}%', '${r['distinction_count'] ?? 0}', '${r['at_risk_count'] ?? 0}', '${r[isAce ? 'highest_hacs' : 'highest_score']}', '${r[isAce ? 'lowest_hacs' : 'lowest_score']}']).toList(),
          '$safeName.csv',
        );
        return;
      case 'Top Students':
        final sk = isAce ? 'cumulative_hacs' : 'cumulative_score';
        downloadCsv(
          ['#', 'Student', isAce ? 'Cum. HACS' : 'Cum. Score', 'Terms'],
          _listData.asMap().entries.map((e) => ['${e.key + 1}', e.value['student_name'] ?? 'Unknown', '${e.value[sk]}', '${e.value['terms_count'] ?? 0}']).toList(),
          '$safeName.csv',
        );
        return;
      case 'Promotion Readiness':
        final sk = isAce ? 'HACS' : 'Score';
        downloadCsv(
          ['Student', sk, 'Threshold', 'Gap'],
          _listData.map((r) {
            final v = (r['cumulative_value'] as num?)?.toDouble() ?? 0.0;
            return [r['student_name'] ?? 'Unknown', v.toStringAsFixed(1), '${_promoThreshold.toStringAsFixed(0)}%', (_promoThreshold - v).toStringAsFixed(1)];
          }).toList(),
          '$safeName.csv',
        );
        return;
      case 'Student Individual Summary':
        if (_classSummary == null) return;
        final d = _classSummary!;
        downloadCsv(['Student', 'Adm No', ''], [[d['student_name'] ?? '', d['admission_no'] ?? '', '']], '$safeName.csv');
        downloadCsv(
          ['Term', isAce ? 'HACS' : 'Total', isAce ? 'NCE' : 'Average', isAce ? 'PACEs' : 'Position', if (!isAce) 'Grade'],
          (d['terms'] as List).map((t) => [t['term_name'] ?? '', '${t[isAce ? 'hacs_score' : 'total_score']}', '${t[isAce ? 'nce_score' : 'average_score']}', '${t[isAce ? 'paces_completed' : 'position']}', if (!isAce) t['grade'] ?? '']).toList(),
          '${safeName}_terms.csv',
        );
        return;
      case 'Attendance Summary':
        if (_classSummary == null) return;
        final d = _classSummary!;
        downloadCsv(
          ['Student', 'Days Present', 'Days Absent', 'Total Days', 'Rate %'],
          (d['students'] as List).map((s) => [s['student_name'] ?? '', '${s['days_present']}', '${s['days_absent']}', '${s['total_days']}', '${s['attendance_rate']}%']).toList(),
          '$safeName.csv',
        );
        return;
      case 'Fee Payment Status':
        downloadCsv(
          ['Student', 'Expected', 'Paid', 'Balance', 'Status'],
          _listData.map((r) => [r['student_name'] ?? '', '${r['total_expected']}', '${r['total_paid']}', '${r['balance']}', '${r['status']}']).toList(),
          '$safeName.csv',
        );
        return;
      case 'Fee Collection Summary':
        downloadCsv(
          ['Fee Type', 'Expected', 'Paid', 'Outstanding', 'Rate %', 'Students'],
          _listData.map((r) => [r['fee_type_name'] ?? '', '${r['total_expected']}', '${r['total_paid']}', '${r['outstanding']}', '${r['collection_rate']}%', '${r['students_count']}']).toList(),
          '$safeName.csv',
        );
        return;
      case 'Teacher Performance':
        final sk = isAce ? 'avg_pt' : 'avg_score';
        downloadCsv(
          ['Teacher', 'Subjects', 'Classes', isAce ? 'Avg PT' : 'Avg Score', 'Pass %', 'Students'],
          _listData.map((r) => [r['teacher_name'] ?? '', '${r['subjects']}', '${r['classes_count']}', '${r[sk]}', '${r['pass_rate']}%', '${r['students_count']}']).toList(),
          '$safeName.csv',
        );
        return;
      case 'CBT Performance':
        downloadCsv(
          ['Exam', 'Subject', 'Students', 'Avg Score', 'Pass %', 'Highest', 'Lowest'],
          _listData.map((r) => [r['exam_title'] ?? '', r['subject_name'] ?? '', '${r['total_students']}', '${r['avg_score']}', '${r['pass_rate']}%', '${r['highest']}', '${r['lowest']}']).toList(),
          '$safeName.csv',
        );
        return;
      case 'Subject Trend':
        final sk = isAce ? 'avg_pt' : 'avg_score';
        downloadCsv(
          ['Term', isAce ? 'Avg PT' : 'Avg Score', 'Pass %', 'Students', 'Trend'],
          _listData.map((r) => [r['term_name'] ?? '', '${r[sk]}', '${r['pass_rate']}%', '${r['students_count']}', '${r['trend'] ?? ''}']).toList(),
          '$safeName.csv',
        );
        return;
      case 'NCE Distribution':
        downloadCsv(
          ['Band', 'Count', 'Percentage', 'Students'],
          _listData.map((r) => [r['band'] ?? '', '${r['count']}', '${r['percentage']}%', (r['students'] as List).join('; ')]).toList(),
          '$safeName.csv',
        );
        return;
      case 'PACE Completion Rate':
        downloadCsv(
          ['Subject', 'Code', 'Total PACEs', 'Students', 'Avg/Student', 'Avg PT'],
          _listData.map((r) => [r['subject_name'] ?? '', r['subject_code'] ?? '', '${r['total_paces']}', '${r['unique_students']}', '${r['avg_paces_per_student']}', '${r['avg_pt']}']).toList(),
          '$safeName.csv',
        );
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFF5F6FA),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _headerBar(),
            const SizedBox(height: 16),
            _filtersCard(),
            const SizedBox(height: 16),
            _generateButton(),
            const SizedBox(height: 20),
            if (_classSummary != null || _listData.isNotEmpty) _downloadButtons(),
            if (_classSummary != null || _listData.isNotEmpty) const SizedBox(height: 16),
            if (_error != null) _errorCard(),
            if (_classSummary != null) ...[
              _buildSummaryView(_classSummary!, _isAce),
              const SizedBox(height: 16),
            ],
            if (_listData.isNotEmpty) _buildResultTable(_isAce),
            if (!_loading && _classSummary == null && _listData.isEmpty && _error == null) _emptyState(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _headerBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF3949AB)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.assessment_rounded, size: 22, color: Colors.white),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reports', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                SizedBox(height: 2),
                Text('Generate and download summary reports', style: TextStyle(fontSize: 12, color: Colors.white54)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: Text(_isAce ? 'ACE Mode' : 'Traditional', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _filtersCard() {
    final twoCol = MediaQuery.of(context).size.width > 600;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EBF0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, size: 16, color: Color(0xFF1A237E)),
              SizedBox(width: 8),
              Text('Configure Report', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            ],
          ),
          const SizedBox(height: 16),
          if (twoCol)
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _filterField('Report Type', _reportDropdown()),
                if (_needsClass) _filterField('Class', _classDropdown()),
                if (_needsStudent) _filterField('Student', _studentDropdown()),
                if (_needsSubject) _filterField('Subject', _subjectDropdown()),
                if (_needsLevel) _filterField('Class Level', _levelField()),
                _filterField('Term Scope', _scopeToggle()),
                if (!_isCumulative) _filterField('Term', _termDropdown()),
                if (_isCumulative) _filterField('Terms', _termCheckboxes(), full: true),
                if (_selectedReport == 'Top Students') _filterField('Top N', _topNField()),
                if (_selectedReport == 'Promotion Readiness') _filterField('Threshold %', _thresholdField()),
                if (_needsDateRange) _filterField('Date Range', _dateRangeFields(), full: true),
              ],
            )
          else
            Column(
              children: [
                _filterField('Report Type', _reportDropdown()),
                if (_needsClass) _filterField('Class', _classDropdown()),
                if (_needsStudent) _filterField('Student', _studentDropdown()),
                if (_needsSubject) _filterField('Subject', _subjectDropdown()),
                if (_needsLevel) _filterField('Class Level', _levelField()),
                _filterField('Term Scope', _scopeToggle()),
                if (!_isCumulative) _filterField('Term', _termDropdown()),
                if (_isCumulative) _filterField('Terms', _termCheckboxes(), full: true),
                if (_selectedReport == 'Top Students') _filterField('Top N', _topNField()),
                if (_selectedReport == 'Promotion Readiness') _filterField('Threshold %', _thresholdField()),
                if (_needsDateRange) _filterField('Date Range', _dateRangeFields(), full: true),
              ],
            ),
        ],
      ),
    );
  }

  Widget _filterField(String label, Widget child, {bool full = false}) {
    return SizedBox(
      width: full ? double.infinity : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
          const SizedBox(height: 5),
          child,
        ],
      ),
    );
  }

  Widget _reportDropdown() {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD1D5DB)), borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonFormField<String>(
        value: _filteredReports.contains(_selectedReport) ? _selectedReport : null,
        decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14), hintText: 'Choose report type', hintStyle: TextStyle(fontSize: 13, color: Colors.grey)),
        items: _filteredReports.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: (v) { if (v != null) { setState(() => _selectedReport = v); _clearResults(); } },
      ),
    );
  }

  Widget _classDropdown() {
    final classes = context.watch<SchoolAdminProvider>().classes;
    return Container(
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD1D5DB)), borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonFormField<String>(
        value: _selectedClassId,
        decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14), prefixIcon: Icon(Icons.class_rounded, size: 18, color: Color(0xFF6B7280)), hintText: 'Select class', hintStyle: TextStyle(fontSize: 13, color: Colors.grey), prefixIconConstraints: BoxConstraints(minWidth: 36)),
        items: classes.map((c) {
          final sec = (c['section'] ?? '').toString();
          final label = sec.isNotEmpty ? '${c['name']} $sec' : (c['name'] ?? '').toString();
          return DropdownMenuItem(value: c['id']?.toString(), child: Text(label, style: const TextStyle(fontSize: 13)));
        }).toList(),
        onChanged: (v) { setState(() { _selectedClassId = v; _selectedStudentId = null; }); _clearResults(); },
      ),
    );
  }

  Widget _studentDropdown() {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD1D5DB)), borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonFormField<String>(
        value: _selectedStudentId,
        decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14), prefixIcon: Icon(Icons.person_rounded, size: 18, color: Color(0xFF6B7280)), hintText: 'Select student', hintStyle: TextStyle(fontSize: 13, color: Colors.grey), prefixIconConstraints: BoxConstraints(minWidth: 36)),
        items: _classStudents.map((s) {
          final fn = (s['first_name'] ?? '').toString();
          final ln = (s['last_name'] ?? '').toString();
          return DropdownMenuItem(value: s['id']?.toString(), child: Text('$fn $ln (${s['admission_no'] ?? ''})', style: const TextStyle(fontSize: 13)));
        }).toList(),
        onChanged: (v) => setState(() => _selectedStudentId = v),
      ),
    );
  }

  Widget _subjectDropdown() {
    final subjects = context.watch<SchoolAdminProvider>().subjects;
    return Container(
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD1D5DB)), borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonFormField<String>(
        value: _selectedSubjectId,
        decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14), prefixIcon: Icon(Icons.menu_book_rounded, size: 18, color: Color(0xFF6B7280)), hintText: 'Select subject', hintStyle: TextStyle(fontSize: 13, color: Colors.grey), prefixIconConstraints: BoxConstraints(minWidth: 36)),
        items: subjects.map((s) => DropdownMenuItem(value: s['id']?.toString(), child: Text('${s['name']} (${s['code'] ?? ''})', style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: (v) => setState(() => _selectedSubjectId = v),
      ),
    );
  }

  Widget _levelField() {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD1D5DB)), borderRadius: BorderRadius.circular(10)),
      child: TextFormField(
        decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14), hintText: 'e.g. JSS1, SSS2, Grade 3', hintStyle: TextStyle(fontSize: 13, color: Colors.grey)),
        onChanged: (v) => setState(() => _classLevel = v.trim()),
      ),
    );
  }

  Widget _scopeToggle() {
    return Row(
      children: [
        Expanded(child: _scopePill('Single Term', !_isCumulative, () => setState(() => _isCumulative = false))),
        const SizedBox(width: 8),
        Expanded(child: _scopePill('Cumulative', _isCumulative, () => setState(() => _isCumulative = true))),
      ],
    );
  }

  Widget _scopePill(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1A237E) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? const Color(0xFF1A237E) : const Color(0xFFD1D5DB)),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? Colors.white : const Color(0xFF6B7280))),
      ),
    );
  }

  Widget _termDropdown() {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD1D5DB)), borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonFormField<String>(
        value: _selectedTermId,
        decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14), prefixIcon: Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF6B7280)), hintText: 'Select term', hintStyle: TextStyle(fontSize: 13, color: Colors.grey), prefixIconConstraints: BoxConstraints(minWidth: 36)),
        items: _terms.map((t) => DropdownMenuItem(value: t['id']?.toString(), child: Text(t['name']?.toString() ?? '', style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: (v) => setState(() => _selectedTermId = v),
      ),
    );
  }

  Widget _termCheckboxes() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD1D5DB)), borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: _terms.map((t) {
          final tid = t['id']?.toString() ?? '';
          return CheckboxListTile(
            title: Text(t['name']?.toString() ?? '', style: const TextStyle(fontSize: 13)),
            value: _selectedTermIds.contains(tid),
            dense: true,
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            onChanged: (v) => setState(() { if (v == true) _selectedTermIds.add(tid); else _selectedTermIds.remove(tid); }),
          );
        }).toList(),
      ),
    );
  }

  Widget _topNField() {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD1D5DB)), borderRadius: BorderRadius.circular(10)),
      child: TextFormField(
        keyboardType: TextInputType.number,
        initialValue: _topLimit.toString(),
        decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14), hintText: 'Number of students', hintStyle: TextStyle(fontSize: 13, color: Colors.grey)),
        onChanged: (v) => setState(() => _topLimit = int.tryParse(v) ?? 10),
      ),
    );
  }

  Widget _thresholdField() {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD1D5DB)), borderRadius: BorderRadius.circular(10)),
      child: TextFormField(
        keyboardType: TextInputType.number,
        initialValue: _promoThreshold.toStringAsFixed(0),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          hintText: _isAce ? 'Default: 80' : 'Default: ${context.read<SchoolAdminProvider>().schoolSettings?['pass_mark'] ?? 50}',
          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        onChanged: (v) => setState(() => _promoThreshold = double.tryParse(v) ?? (_isAce ? 80 : 50)),
      ),
    );
  }

  Widget _dateRangeFields() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD1D5DB)), borderRadius: BorderRadius.circular(10)),
            child: TextFormField(
              decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14), hintText: 'From (YYYY-MM-DD)', hintStyle: TextStyle(fontSize: 12, color: Colors.grey)),
              onChanged: (v) => setState(() => _fromDate = v.trim()),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD1D5DB)), borderRadius: BorderRadius.circular(10)),
            child: TextFormField(
              decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14), hintText: 'To (YYYY-MM-DD)', hintStyle: TextStyle(fontSize: 12, color: Colors.grey)),
              onChanged: (v) => setState(() => _toDate = v.trim()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _generateButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _canGenerate && !_loading ? _generate : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _canGenerate ? const Color(0xFF1A237E) : Colors.grey.shade300,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.speed_rounded, size: 20),
                  SizedBox(width: 8),
                  Text('Generate Report', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ],
              ),
      ),
    );
  }

  Widget _downloadButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _downloadPdf,
              icon: const Icon(Icons.picture_as_pdf, size: 18, color: Color(0xFFE65100)),
              label: const Text('Download PDF', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFE65100))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE65100)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _downloadCsv,
              icon: const Icon(Icons.table_chart, size: 18, color: Color(0xFF2E7D32)),
              label: const Text('Download CSV', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF2E7D32)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _errorCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, size: 20, color: Colors.red),
        const SizedBox(width: 10),
        Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13))),
      ]),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE8EBF0))),
      child: const Column(
        children: [
          SizedBox(
            width: 64, height: 64,
            child: Icon(Icons.assessment_outlined, size: 28, color: Color(0xFF1A237E)),
          ),
          SizedBox(height: 16),
          Text('No report generated yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
          SizedBox(height: 6),
          Text('Configure the filters above and tap Generate', style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }

  // ═══ SUMMARY VIEW ═══

  Widget _buildSummaryView(Map<String, dynamic> d, bool isAce) {
    if (d.containsKey('students') && d['students'] is List) {
      final stuList = d['students'] as List;
      return _resultCard(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(children: [
              const Icon(Icons.fact_check_rounded, size: 20, color: Color(0xFF1A237E)),
              const SizedBox(width: 8),
              const Text('Attendance Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _chip('Students', '${d['total_students']}', const Color(0xFF1A237E)),
                _chip('Avg Rate', '${d['avg_attendance_rate']}%', const Color(0xFF2E7D32)),
                _chip('Most Absent', '${d['most_absent_student']}', const Color(0xFFC62828)),
                _chip('Most Present', '${d['most_present_student']}', const Color(0xFF00838F)),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _dataTbl(
            ['Student', 'Present', 'Absent', 'Total', 'Rate %'],
            stuList.map((s) => [s['student_name'] ?? '', '${s['days_present']}', '${s['days_absent']}', '${s['total_days']}', _attCell(s['attendance_rate'])]),
          ),
        ],
      ));
    }

    if (d.containsKey('subjects') && d['subjects'] is List) {
      return _resultCard(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d['student_name']?.toString() ?? 'Student Summary', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                if ((d['admission_no'] ?? '').toString().isNotEmpty) Text('Adm: ${d['admission_no']}', style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: const Text('Per-Subject Performance', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF6B7280))),
          ),
          _dataTbl(
            isAce ? ['Subject', 'PACEs', 'Avg PT', 'Highest', 'Lowest'] : ['Subject', 'Terms', 'Avg Score', 'Highest', 'Lowest'],
            (d['subjects'] as List).map((s) => isAce
                ? [s['subject_name'] ?? '', '${s['total_paces']}', _fmt(s['avg_pt']), _fmt(s['highest_pt']), _fmt(s['lowest_pt'])]
                : [s['subject_name'] ?? '', '${s['terms_scored']}', _fmt(s['avg_score']), _fmt(s['highest']), _fmt(s['lowest'])]),
          ),
          if ((d['terms'] as List).isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: const Text('Term-by-Term', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF6B7280))),
            ),
            _dataTbl(
              isAce ? ['Term', 'HACS', 'NCE', 'PACEs'] : ['Term', 'Total', 'Average', 'Position', 'Grade'],
              (d['terms'] as List).map((t) => isAce
                  ? [t['term_name'] ?? '', _fmt(t['hacs_score']), _fmt(t['nce_score']), '${t['paces_completed']}']
                  : [t['term_name'] ?? '', _fmt(t['total_score']), _fmt(t['average_score']), '${t['position']}', t['grade'] ?? '']),
            ),
          ],
        ],
      ));
    }

    final total = d['total_students'] ?? 0;
    if (total == 0) return _resultCard(const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No data found', style: TextStyle(color: Colors.grey)))));
    final cards = <Map<String, dynamic>>[];
    if (isAce) {
      cards.addAll([
        {'l': 'Avg HACS', 'v': d['avg_hacs'], 'c': const Color(0xFF1A237E)},
        {'l': 'Avg NCE', 'v': d['avg_nce'], 'c': const Color(0xFFE65100)},
        {'l': 'Avg PACEs', 'v': d['avg_paces'], 'c': const Color(0xFF00838F)},
        {'l': 'Pass Rate', 'v': '${d['pass_rate']}%', 'c': const Color(0xFF2E7D32)},
        {'l': 'Distinctions', 'v': d['distinction_count'], 'c': const Color(0xFF7B1FA2)},
        {'l': 'At Risk', 'v': d['at_risk_count'], 'c': const Color(0xFFC62828)},
        {'l': 'Highest', 'v': d['highest_hacs'], 'c': const Color(0xFF283593)},
        {'l': 'Lowest', 'v': d['lowest_hacs'], 'c': const Color(0xFFBF360C)},
      ]);
    } else {
      cards.addAll([
        {'l': 'Avg Score', 'v': d['avg_score'], 'c': const Color(0xFF1A237E)},
        {'l': 'Pass Rate', 'v': '${d['pass_rate']}%', 'c': const Color(0xFF2E7D32)},
        {'l': 'Distinctions', 'v': d['distinction_count'], 'c': const Color(0xFF7B1FA2)},
        {'l': 'At Risk', 'v': d['at_risk_count'], 'c': const Color(0xFFC62828)},
        {'l': 'Highest', 'v': d['highest_score'], 'c': const Color(0xFF283593)},
        {'l': 'Lowest', 'v': d['lowest_score'], 'c': const Color(0xFFBF360C)},
      ]);
    }
    if (d['terms_count'] != null) cards.add({'l': 'Terms', 'v': d['terms_count'], 'c': Colors.grey.shade600});
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(bottom: 12), child: Text('Total Students: $total', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF111827)))),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: cards.map((c) => _metricCard(c['l'] as String, c['v'], c['c'] as Color)).toList(),
        ),
      ],
    );
  }

  Widget _chip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.15))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.7))),
        ],
      ),
    );
  }

  Widget _metricCard(String label, dynamic value, Color color) {
    return Container(
      width: 105,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8EBF0))),
      child: Column(
        children: [
          Container(width: 4, height: 28, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 8),
          Text('$value', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color, height: 1)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _attCell(dynamic val) {
    final rate = _numVal(val);
    return Text('$rate%', style: TextStyle(color: rate >= 75 ? const Color(0xFF2E7D32) : const Color(0xFFC62828), fontWeight: FontWeight.w600, fontSize: 13));
  }

  Widget _resultCard(Widget child) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE8EBF0)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))]),
      child: child,
    );
  }

  Widget _dataTbl(List<String> cols, Iterable<List<dynamic>> rows) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      child: DataTable(
        headingRowColor: const WidgetStatePropertyAll(Color(0xFFF0F4FF)),
        headingTextStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF1A237E)),
        dataRowMinHeight: 44,
        dataRowMaxHeight: 52,
        columns: cols.map((c) => DataColumn(
          label: Text(c),
          numeric: ['Present', 'Absent', 'Total', 'Rate %', 'Students', 'Terms', 'PACEs', 'Avg PT', 'Avg Score', 'Highest', 'Lowest', 'At Risk', 'Distinctions', 'Pass %', 'Collection Rate', 'Outstanding', 'Expected', 'Collected', 'Avg/Student', 'Balance', 'Position', 'Gap'].contains(c),
        )).toList(),
        rows: rows.map((r) => DataRow(cells: r.map((c) => DataCell(Text('$c', style: const TextStyle(fontSize: 13)))).toList())).toList(),
      ),
    );
  }

  // ═══ RESULT TABLE DISPATCH ═══

  Widget _buildResultTable(bool isAce) {
    switch (_selectedReport) {
      case 'Subject Term Summary':
      case 'Cumulative Subject Summary':
        return _subjectTable(isAce);
      case 'Class Comparison':
        return _comparisonTable(isAce);
      case 'Top Students':
        return _topStudentsTable(isAce);
      case 'Promotion Readiness':
        return _promotionTable(isAce);
      case 'Fee Payment Status':
        return _feeStatusTable();
      case 'Fee Collection Summary':
        return _feeCollectionTable();
      case 'Teacher Performance':
        return _teacherTable(isAce);
      case 'CBT Performance':
        return _cbtTable();
      case 'Subject Trend':
        return _trendTable(isAce);
      case 'NCE Distribution':
        return _nceTable();
      case 'PACE Completion Rate':
        return _paceCompTable();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _subjectTable(bool isAce) {
    final sk = isAce ? 'avg_pt' : 'avg_score';
    final hk = isAce ? 'highest_pt' : 'highest_avg';
    final lk = isAce ? 'lowest_pt' : 'lowest_avg';
    return _resultCard(SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      child: DataTable(
        headingRowColor: const WidgetStatePropertyAll(Color(0xFFF0F4FF)),
        headingTextStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF1A237E)),
        dataRowMinHeight: 46,
        columns: [_hcol('Subject'), _hcol('Code'), _hcol(isAce ? 'Avg PT' : 'Avg Score'), _hcol('Pass %'), _hcol('Highest'), _hcol('Lowest'), _hcol('Students')],
        rows: _listData.map((r) => DataRow(cells: [
          DataCell(Text(r['subject_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
          DataCell(Text(r['subject_code'] ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)))),
          DataCell(Text(_fmt(r[sk]), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          DataCell(Text('${r['pass_rate']}%', style: TextStyle(fontSize: 13, color: _numVal(r['pass_rate']) >= 80 ? const Color(0xFF2E7D32) : const Color(0xFF757575)))),
          DataCell(Text(_fmt(r[hk]), style: const TextStyle(fontSize: 13, color: Color(0xFF283593)))),
          DataCell(Text(_fmt(r[lk]), style: const TextStyle(fontSize: 13, color: Color(0xFFBF360C)))),
          DataCell(Text('${r['students_count'] ?? 0}', style: const TextStyle(fontSize: 13))),
        ])).toList(),
      ),
    ));
  }

  Widget _comparisonTable(bool isAce) {
    final sk = isAce ? 'avg_hacs' : 'avg_score';
    final hk = isAce ? 'highest_hacs' : 'highest_score';
    final lk = isAce ? 'lowest_hacs' : 'lowest_score';
    return _resultCard(SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      child: DataTable(
        headingRowColor: const WidgetStatePropertyAll(Color(0xFFF0F4FF)),
        headingTextStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF1A237E)),
        dataRowMinHeight: 46,
        columns: [_hcol('Class'), _hcol('Students'), _hcol(isAce ? 'Avg HACS' : 'Avg Score'), _hcol('Pass %'), _hcol('Dist.'), _hcol('At Risk'), _hcol('Highest'), _hcol('Lowest')],
        rows: _listData.map((r) => DataRow(cells: [
          DataCell(Text(r['class_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          DataCell(Text('${r['total_students'] ?? 0}')),
          DataCell(Text(_fmt(r[sk]), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          DataCell(Text('${r['pass_rate']}%', style: TextStyle(fontSize: 13, color: _numVal(r['pass_rate']) >= 80 ? const Color(0xFF2E7D32) : const Color(0xFF757575)))),
          DataCell(Text('${r['distinction_count'] ?? 0}')),
          DataCell(Text('${r['at_risk_count'] ?? 0}', style: TextStyle(fontSize: 13, color: _numVal(r['at_risk_count']) > 0 ? const Color(0xFFC62828) : Colors.grey))),
          DataCell(Text(_fmt(r[hk]), style: const TextStyle(fontSize: 13, color: Color(0xFF283593)))),
          DataCell(Text(_fmt(r[lk]), style: const TextStyle(fontSize: 13, color: Color(0xFFBF360C)))),
        ])).toList(),
      ),
    ));
  }

  Widget _topStudentsTable(bool isAce) {
    final sk = isAce ? 'cumulative_hacs' : 'cumulative_score';
    return _resultCard(SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      child: DataTable(
        headingRowColor: const WidgetStatePropertyAll(Color(0xFFF0F4FF)),
        headingTextStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF1A237E)),
        dataRowMinHeight: 46,
        columns: [
          _hcol('#'), _hcol('Student'), _hcol(isAce ? 'Cum. HACS' : 'Cum. Score'), _hcol('Terms'),
          if (isAce) ...[_hcol('Cum. NCE'), _hcol('Cum. PACEs')],
        ],
        rows: _listData.asMap().entries.map((e) {
          final r = e.value;
          final rank = e.key + 1;
          return DataRow(cells: [
            DataCell(Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: rank <= 3 ? const Color(0xFF1A237E) : Colors.grey.shade200, borderRadius: BorderRadius.circular(14)),
              alignment: Alignment.center,
              child: Text('$rank', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: rank <= 3 ? Colors.white : Colors.grey.shade600)),
            )),
            DataCell(Text(r['student_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
            DataCell(Text(_fmt(r[sk]), style: TextStyle(fontSize: 13, fontWeight: rank <= 3 ? FontWeight.w700 : FontWeight.normal, color: rank <= 3 ? const Color(0xFF1A237E) : null))),
            DataCell(Text('${r['terms_count'] ?? 0}')),
            if (isAce) ...[
              DataCell(Text(_fmt(r['cumulative_nce']))),
              DataCell(Text(_fmt(r['cumulative_paces']))),
            ],
          ]);
        }).toList(),
      ),
    ));
  }

  Widget _promotionTable(bool isAce) {
    return _resultCard(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(children: [
            const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFC62828)),
            const SizedBox(width: 8),
            Text('${_listData.length} student(s) below threshold', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFC62828))),
          ]),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(12),
          child: DataTable(
            headingRowColor: WidgetStatePropertyAll(Colors.red.shade50),
            headingTextStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFFC62828)),
            dataRowMinHeight: 46,
            columns: [_hcol('Student'), _hcol(isAce ? 'HACS' : 'Score'), _hcol('Threshold'), _hcol('Gap'), if (isAce) _hcol('Cum. NCE')],
            rows: _listData.map((r) {
              final val = (r['cumulative_value'] as num?)?.toDouble() ?? 0.0;
              final gap = _promoThreshold - val;
              return DataRow(cells: [
                DataCell(Text(r['student_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
                DataCell(Text(val.toStringAsFixed(1), style: const TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.w600, fontSize: 13))),
                DataCell(Text('${_promoThreshold.toStringAsFixed(0)}%')),
                DataCell(Text(gap.toStringAsFixed(1), style: TextStyle(color: gap > 20 ? const Color(0xFFC62828) : const Color(0xFFE65100), fontWeight: FontWeight.w600, fontSize: 13))),
                if (isAce) DataCell(Text(_fmt(r['cumulative_nce']))),
              ]);
            }).toList(),
          ),
        ),
      ],
    ));
  }

  Widget _feeStatusTable() {
    return _resultCard(SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      child: DataTable(
        headingRowColor: const WidgetStatePropertyAll(Color(0xFFF0F4FF)),
        headingTextStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF1A237E)),
        dataRowMinHeight: 46,
        columns: [_hcol('Student'), _hcol('Expected'), _hcol('Paid'), _hcol('Balance'), _hcol('Status')],
        rows: _listData.map((r) {
          final st = (r['status'] ?? '').toString();
          final stColor = st == 'Paid' ? const Color(0xFF2E7D32) : st == 'Partial' ? const Color(0xFFE65100) : const Color(0xFFC62828);
          final stBg = st == 'Paid' ? const Color(0xFFE8F5E9) : st == 'Partial' ? const Color(0xFFFFF3E0) : const Color(0xFFFFEBEE);
          return DataRow(cells: [
            DataCell(Text(r['student_name'] ?? '', style: const TextStyle(fontSize: 13))),
            DataCell(Text('${r['total_expected']}')),
            DataCell(Text('${r['total_paid']}')),
            DataCell(Text('${r['balance']}')),
            DataCell(Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: stBg, borderRadius: BorderRadius.circular(6)),
              child: Text(st, style: TextStyle(color: stColor, fontWeight: FontWeight.w600, fontSize: 12)),
            )),
          ]);
        }).toList(),
      ),
    ));
  }

  Widget _feeCollectionTable() {
    return _resultCard(SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      child: DataTable(
        headingRowColor: const WidgetStatePropertyAll(Color(0xFFF0F4FF)),
        headingTextStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF1A237E)),
        dataRowMinHeight: 46,
        columns: [_hcol('Fee Type'), _hcol('Expected'), _hcol('Paid'), _hcol('Outstanding'), _hcol('Rate %'), _hcol('Students')],
        rows: _listData.map((r) {
          final out = _numVal(r['outstanding']);
          return DataRow(cells: [
            DataCell(Text(r['fee_type_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
            DataCell(Text('${r['total_expected']}')),
            DataCell(Text('${r['total_paid']}')),
            DataCell(Text('${r['outstanding']}', style: TextStyle(color: out > 0 ? const Color(0xFFC62828) : const Color(0xFF2E7D32), fontWeight: FontWeight.w600, fontSize: 13))),
            DataCell(Text('${r['collection_rate']}%')),
            DataCell(Text('${r['students_count'] ?? 0}')),
          ]);
        }).toList(),
      ),
    ));
  }

  Widget _teacherTable(bool isAce) {
    final sk = isAce ? 'avg_pt' : 'avg_score';
    return _resultCard(SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      child: DataTable(
        headingRowColor: const WidgetStatePropertyAll(Color(0xFFF0F4FF)),
        headingTextStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF1A237E)),
        dataRowMinHeight: 46,
        columns: [_hcol('Teacher'), _hcol('Subjects'), _hcol('Classes'), _hcol(isAce ? 'Avg PT' : 'Avg Score'), _hcol('Pass %'), _hcol('Students')],
        rows: _listData.map((r) => DataRow(cells: [
          DataCell(Text(r['teacher_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
          DataCell(SizedBox(width: 160, child: Text('${r['subjects']}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)), maxLines: 2, overflow: TextOverflow.ellipsis))),
          DataCell(Text('${r['classes_count']}')),
          DataCell(Text(_fmt(r[sk]), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          DataCell(Text('${r['pass_rate']}%')),
          DataCell(Text('${r['students_count'] ?? 0}')),
        ])).toList(),
      ),
    ));
  }

  Widget _cbtTable() {
    return _resultCard(SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      child: DataTable(
        headingRowColor: const WidgetStatePropertyAll(Color(0xFFF0F4FF)),
        headingTextStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF1A237E)),
        dataRowMinHeight: 46,
        columns: [_hcol('Exam'), _hcol('Subject'), _hcol('Students'), _hcol('Avg Score'), _hcol('Pass %'), _hcol('Highest'), _hcol('Lowest')],
        rows: _listData.map((r) => DataRow(cells: [
          DataCell(Text(r['exam_title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
          DataCell(Text(r['subject_name'] ?? '')),
          DataCell(Text('${r['total_students']}')),
          DataCell(Text(_fmt(r['avg_score']), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          DataCell(Text('${r['pass_rate']}%')),
          DataCell(Text(_fmt(r['highest']), style: const TextStyle(color: Color(0xFF283593)))),
          DataCell(Text(_fmt(r['lowest']), style: const TextStyle(color: Color(0xFFBF360C)))),
        ])).toList(),
      ),
    ));
  }

  Widget _trendTable(bool isAce) {
    final sk = isAce ? 'avg_pt' : 'avg_score';
    return _resultCard(SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      child: DataTable(
        headingRowColor: const WidgetStatePropertyAll(Color(0xFFF0F4FF)),
        headingTextStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF1A237E)),
        dataRowMinHeight: 46,
        columns: [_hcol('Term'), _hcol(isAce ? 'Avg PT' : 'Avg Score'), _hcol('Pass %'), _hcol('Students'), _hcol('Trend')],
        rows: _listData.map((r) {
          final trend = (r['trend'] ?? '').toString();
          final trendColor = trend.startsWith('\u2191') ? const Color(0xFF2E7D32) : trend.startsWith('\u2193') ? const Color(0xFFC62828) : const Color(0xFF9CA3AF);
          return DataRow(cells: [
            DataCell(Text(r['term_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
            DataCell(Text(_fmt(r[sk]), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
            DataCell(Text('${r['pass_rate']}%')),
            DataCell(Text('${r['students_count']}')),
            DataCell(Text(trend, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: trendColor))),
          ]);
        }).toList(),
      ),
    ));
  }

  Widget _nceTable() {
    if (_listData.isEmpty) return const SizedBox.shrink();
    final maxCount = _listData.map((r) => _numVal(r['count'])).reduce((a, b) => a > b ? a : b);
    if (maxCount == 0) return const SizedBox.shrink();
    return _resultCard(Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('NCE Score Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 16),
          ..._listData.map((r) {
            final count = _numVal(r['count']);
            final pct = _numVal(r['percentage']);
            final frac = count / maxCount;
            final students = (r['students'] as List?) ?? [];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(width: 60, child: Text(r['band'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1A237E)))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Stack(
                          children: [
                            Container(height: 28, decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(6))),
                            FractionallySizedBox(
                              widthFactor: frac.clamp(0.02, 1.0),
                              heightFactor: 1.0,
                              child: Container(decoration: BoxDecoration(color: const Color(0xFF1A237E), borderRadius: BorderRadius.circular(6))),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(width: 40, child: Text('$count', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                      SizedBox(width: 50, child: Text('${pct.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
                    ],
                  ),
                  if (students.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 68, top: 2),
                      child: Text(students.join(', '), style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    ));
  }

  Widget _paceCompTable() {
    return _resultCard(SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      child: DataTable(
        headingRowColor: const WidgetStatePropertyAll(Color(0xFFF0F4FF)),
        headingTextStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF1A237E)),
        dataRowMinHeight: 46,
        columns: [_hcol('Subject'), _hcol('Code'), _hcol('Total PACEs'), _hcol('Students'), _hcol('Avg/Student'), _hcol('Avg PT')],
        rows: _listData.map((r) => DataRow(cells: [
          DataCell(Text(r['subject_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
          DataCell(Text(r['subject_code'] ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)))),
          DataCell(Text('${r['total_paces']}')),
          DataCell(Text('${r['unique_students']}')),
          DataCell(Text(_fmt(r['avg_paces_per_student']))),
          DataCell(Text(_fmt(r['avg_pt']), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ])).toList(),
      ),
    ));
  }

  // ═══ HELPERS ═══

  DataColumn _hcol(String label) => DataColumn(
    label: Text(label, style: const TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 12,
      color: Color(0xFF1A237E),
    )),
  );

  String _fmt(dynamic val) {
    if (val == null) return '--';
    final n = num.tryParse(val.toString());
    if (n == null) return '$val';
    if (n == n.truncateToDouble()) return n.toInt().toString();
    return n.toStringAsFixed(1);
  }

  double _numVal(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }
}

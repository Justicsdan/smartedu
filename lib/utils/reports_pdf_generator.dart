import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'pdf_download_utils.dart';

class ReportsPdfGenerator {
  static Future<pw.ImageProvider?> _fetchImage(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) return pw.MemoryImage(res.bodyBytes);
    } catch (e) { debugPrint('Reports PDF image error: $e'); }
    return null;
  }

  static String _fmt(dynamic v) {
    if (v is double) return v.toStringAsFixed(1);
    if (v is int) return v.toString();
    if (v is String) return v;
    return (v ?? '').toString();
  }

  static Future<void> generateAndDownload({
    required String reportType,
    required Map<String, dynamic> schoolInfo,
    Map<String, dynamic>? classSummary,
    List<Map<String, dynamic>> listData = const [],
    required Map<String, dynamic> filters,
    required bool isAce,
  }) async {
    final logo = await _fetchImage(schoolInfo['logo_url']?.toString());
    final pdf = pw.Document(theme: pw.ThemeData.withFont(base: pw.Font.helvetica()));
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(24),
      header: (ctx) => _buildHeader(schoolInfo, logo),
      footer: (ctx) => _buildFooter(dateStr),
      build: (ctx) => [
        _buildTitle(reportType),
        _buildFilters(filters, isAce),
        pw.SizedBox(height: 12),
        ..._buildContent(reportType, classSummary, listData, isAce),
      ],
    ));

    final bytes = await pdf.save();
    final safeName = reportType.toLowerCase().replaceAll(' ', '_');
    downloadPdfBytes(bytes, '${safeName}_report.pdf');
  }

  // ═══ HEADER ═══
  static pw.Widget _buildHeader(Map<String, dynamic> school, pw.ImageProvider? logo) {
    final children = <pw.Widget>[
      if (logo != null)
        pw.Container(width: 50, height: 50, child: pw.Image(logo, fit: pw.BoxFit.contain)),
      if (logo != null) pw.SizedBox(width: 12),
      pw.Expanded(
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(school['name']?.toString() ?? '', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          if ((school['motto'] ?? '').toString().isNotEmpty)
            pw.Text(school['motto'].toString(), style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          if ((school['address'] ?? '').toString().isNotEmpty)
            pw.Text(school['address'].toString(), style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
        ]),
      ),
    ];
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue, width: 2))),
      child: pw.Row(children: children),
    );
  }

  // ═══ TITLE ═══
  static pw.Widget _buildTitle(String reportType) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      color: PdfColors.blue50,
      child: pw.Text(reportType.toUpperCase(), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
    );
  }

  // ═══ FILTERS BAR ═══
  static pw.Widget _buildFilters(Map<String, dynamic> f, bool isAce) {
    final parts = <String>[];
    if (f['session'] != null) parts.add('Session: ${f['session']}');
    if (f['terms'] != null) parts.add('Term(s): ${f['terms']}');
    if (f['class_name'] != null) parts.add('Class: ${f['class_name']}');
    if (f['class_level'] != null) parts.add('Level: ${f['class_level']}');
    if (f['threshold'] != null) parts.add('Threshold: ${f['threshold']}%');
    if (f['top_n'] != null) parts.add('Top ${f['top_n']}');
    if (isAce) parts.add('ACE Mode');
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: PdfColors.grey100,
      child: pw.Text(parts.join('  |  '), style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
    );
  }

  // ═══ CONTENT DISPATCHER ═══
  static List<pw.Widget> _buildContent(String type, Map<String, dynamic>? summary, List<Map<String, dynamic>> data, bool isAce) {
    switch (type) {
      case 'Class Term Summary':
      case 'Cumulative Class Summary':
        return _summaryCards(summary, isAce);
      case 'Subject Term Summary':
      case 'Cumulative Subject Summary':
        return _subjectTable(data, isAce);
      case 'Class Comparison':
        return _comparisonTable(data, isAce);
      case 'Top Students':
        return _topStudentsTable(data, isAce);
      case 'Promotion Readiness':
        return _promotionTable(data, isAce, (summary?['threshold'] as num?)?.toDouble() ?? 50);
      case 'Student Individual Summary':
        return _studentIndividualSummary(summary, isAce);
      case 'Attendance Summary':
        return _attendanceSummaryPdf(summary);
      case 'Fee Payment Status':
        return _feeStatusPdf(data);
      case 'Fee Collection Summary':
        return _feeCollectionPdf(data);
      case 'Teacher Performance':
        return _teacherPdf(data, isAce);
      case 'CBT Performance':
        return _cbtPdf(data);
      case 'Subject Trend':
        return _trendPdf(data, isAce);
      case 'NCE Distribution':
        return _ncePdf(data);
      case 'PACE Completion Rate':
        return _paceCompPdf(data);
      default:
        return [pw.Text('No data')];
    }
  }

  // ═══ SUMMARY CARDS ═══
  static String _ordinal(int n) {
    if (n <= 0) return '\$n';
    final lastTwo = n % 100;
    if (lastTwo >= 11 && lastTwo <= 13) return '\${n}th';
    switch (n % 10) {
      case 1: return '\${n}st';
      case 2: return '\${n}nd';
      case 3: return '\${n}rd';
      default: return '\${n}th';
    }
  }

  static List<pw.Widget> _summaryCards(Map<String, dynamic>? d, bool isAce) {
    if (d == null || (d['total_students'] ?? 0) == 0) {
      return [pw.Center(child: pw.Text('No data found', style: const pw.TextStyle(color: PdfColors.grey)))];
    }
    final rows = <pw.Widget>[];
    final stuList = d['student_list'] as List<dynamic>?;
    if (stuList != null && stuList.isNotEmpty) {
      final isCum = d['terms_count'] != null;
      final hdrs = <String>['#', 'Student Name'];
      if (isAce) hdrs.addAll(['HACS', 'NCE', 'PACEs']);
      else hdrs.addAll(['Total Score', 'Average', 'Position']);
      if (isCum) hdrs.add('Terms');
      final tData = <List<String>>[];
      for (var i = 0; i < stuList.length; i++) {
        final s = stuList[i] as Map<String, dynamic>;
        final row = <String>[(i + 1).toString(), s['student_name']?.toString() ?? 'Unknown'];
        if (isAce) row.addAll([_fmt(s['hacs_score']), _fmt(s['nce_score']), (s['paces_completed'] ?? 0).toString()]);
        else row.addAll([_fmt(s['total_score']), _fmt(s['average_score']), (s['position'] ?? '-').toString()]);
        if (isCum) row.add((s['terms_count'] ?? 0).toString());
        tData.add(row);
      }
      rows.add(pw.SizedBox(height: 12));
      rows.add(pw.Table.fromTextArray(
        headers: hdrs,
        data: tData,
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
        cellStyle: const pw.TextStyle(fontSize: 9),
        cellAlignment: pw.Alignment.center,
        columnWidths: {0: const pw.FixedColumnWidth(25), 1: const pw.FlexColumnWidth(3)},
      ));
    }
    return rows;
  }
    static pw.Widget _buildCard(_PdfCard c) {
    return pw.Container(
      width: 155,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: c.color, width: 1.5),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
        pw.Text(c.value, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: c.color)),
        pw.SizedBox(height: 2),
        pw.Text(c.label, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
      ]),
    );
  }

  // ═══ SUBJECT TABLE ═══
  static List<pw.Widget> _subjectTable(List<Map<String, dynamic>> data, bool isAce) {
    if (data.isEmpty) return [pw.Text('No subject data')];
    if (data.first.containsKey('is_student_format')) {
      if (data.first.containsKey('term_data')) return _subjectCumulativeStudentPdf(data, isAce);
      return _subjectStudentPdf(data, isAce);
    }
    final scoreKey = isAce ? 'avg_pt' : 'avg_score';
    final highKey = isAce ? 'highest_pt' : 'highest_avg';
    final lowKey = isAce ? 'lowest_pt' : 'lowest_avg';
    final scoreLabel = isAce ? 'Avg PT' : 'Avg Score';
    return [
      pw.Table.fromTextArray(
        headers: ['Subject', 'Code', scoreLabel, 'Pass %', 'Highest', 'Lowest', 'Students'],
        data: data.map((r) => [
          r['subject_name'] ?? '',
          r['subject_code'] ?? '',
          _fmt(r[scoreKey]),
          '${r['pass_rate']}%',
          _fmt(r[highKey]),
          _fmt(r[lowKey]),
          _fmt(r['students_count']),
        ]).toList(),
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
        cellAlignments: {
          2: pw.Alignment.center, 3: pw.Alignment.center, 4: pw.Alignment.center, 5: pw.Alignment.center, 6: pw.Alignment.center,
        },
      ),
    ];
  }

  // ═══ COMPARISON TABLE ═══
  static List<pw.Widget> _subjectStudentPdf(List<Map<String, dynamic>> data, bool isAce) {
    final hdrs = <String>['#', 'STUDENTS NAME'];
    if (isAce) {
      hdrs.addAll(['PACES COMPLETED', 'TERM AVERAGE (%)', 'PACE RANGE']);
    } else {
      hdrs.addAll(['TOTAL SCORE', 'GRADE', 'CLASS POSITION']);
    }
    final tData = <List<String>>[];
    for (var i = 0; i < data.length; i++) {
      final s = data[i];
      final row = <String>[(i + 1).toString(), (s['student_name'] ?? 'Unknown').toString().toUpperCase()];
      if (isAce) {
        row.add((s['paces_completed'] ?? 0).toString());
        row.add(_fmt(s['term_average']));
        row.add((s['pace_range'] ?? '--').toString());
      } else {
        row.add(_fmt(s['total_score']));
        row.add((s['grade'] ?? '').toString());
        row.add((s['position'] ?? '--').toString());
      }
      tData.add(row);
    }
    return [
      pw.Table.fromTextArray(
        headers: hdrs,
        data: tData,
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
        cellStyle: const pw.TextStyle(fontSize: 8.5),
        cellAlignment: pw.Alignment.center,
        columnWidths: {0: const pw.FixedColumnWidth(22), 1: const pw.FlexColumnWidth(3)},
      ),
    ];
  }

  static List<pw.Widget> _subjectCumulativeStudentPdf(List<Map<String, dynamic>> data, bool isAce) {
    if (data.isEmpty) return [pw.Text('No data')];
    final termData = data.first['term_data'] as List<dynamic>;
    final termCount = termData.length;
    final hdrs = <String>['#', 'STUDENTS NAME'];
    for (var t = 0; t < termCount; t++) {
      final tn = (termData[t]['term_name'] ?? 'T\${t + 1}').toString();
      if (isAce) { hdrs.addAll(['\$tn AVG PT', '\$tn PACEs']); }
      else { hdrs.addAll(['\$tn TOTAL', '\$tn GRADE', '\$tn POS']); }
    }
    if (isAce) { hdrs.addAll(['TOTAL PACEs', 'CUM. AVG', 'POSITION']); }
    else { hdrs.addAll(['TOTAL', 'AVERAGE', 'POSITION']); }
    final tData = <List<String>>[];
    for (var i = 0; i < data.length; i++) {
      final s = data[i];
      final td = s['term_data'] as List;
      final row = <String>[(i + 1).toString(), (s['student_name'] ?? 'Unknown').toString().toUpperCase()];
      for (var t = 0; t < td.length; t++) {
        final tm = td[t] as Map;
        if (isAce) { row.add(_fmt(tm['avg_pt'])); row.add((tm['paces'] ?? 0).toString()); }
        else { row.add(_fmt(tm['total'])); row.add((tm['grade'] ?? '').toString()); row.add((tm['position'] ?? '--').toString()); }
      }
      if (isAce) { row.add((s['total_paces'] ?? 0).toString()); row.add(_fmt(s['cumulative_avg'])); }
      else { row.add(_fmt(s['cumulative_total'])); row.add(_fmt(s['cumulative_avg'])); }
      row.add((s['position'] ?? '--').toString());
      tData.add(row);
    }
    return [pw.Table.fromTextArray(headers: hdrs, data: tData, headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white), headerDecoration: const pw.BoxDecoration(color: PdfColors.blue), cellStyle: const pw.TextStyle(fontSize: 8), cellAlignment: pw.Alignment.center, columnWidths: {0: const pw.FixedColumnWidth(18), 1: const pw.FlexColumnWidth(3)})];
  }

  static List<pw.Widget> _comparisonTable(List<Map<String, dynamic>> data, bool isAce) {
    if (data.isEmpty) return [pw.Text('No comparison data')];
    final scoreKey = isAce ? 'avg_hacs' : 'avg_score';
    final scoreLabel = isAce ? 'Avg HACS' : 'Avg Score';
    final highKey = isAce ? 'highest_hacs' : 'highest_score';
    final lowKey = isAce ? 'lowest_hacs' : 'lowest_score';
    return [
      pw.Table.fromTextArray(
        headers: ['Class', 'Students', scoreLabel, 'Pass %', 'Distinctions', 'At Risk', 'Highest', 'Lowest'],
        data: data.map((r) => [
          r['class_name'] ?? '',
          _fmt(r['total_students']),
          _fmt(r[scoreKey]),
          '${r['pass_rate']}%',
          _fmt(r['distinction_count']),
          _fmt(r['at_risk_count']),
          _fmt(r[highKey]),
          _fmt(r[lowKey]),
        ]).toList(),
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
        cellAlignments: {
          1: pw.Alignment.center, 2: pw.Alignment.center, 3: pw.Alignment.center,
          4: pw.Alignment.center, 5: pw.Alignment.center, 6: pw.Alignment.center, 7: pw.Alignment.center,
        },
      ),
    ];
  }

  // ═══ TOP STUDENTS TABLE ═══
  static List<pw.Widget> _topStudentsTable(List<Map<String, dynamic>> data, bool isAce) {
    if (data.isEmpty) return [pw.Text('No student data')];
    final scoreKey = isAce ? 'cumulative_hacs' : 'cumulative_score';
    final scoreLabel = isAce ? 'Cum. HACS' : 'Cum. Score';
    final headers = <String>['#', 'Student', scoreLabel, 'Terms'];
    if (isAce) { headers.add('Cum. NCE'); headers.add('Cum. PACEs'); }
    return [
      pw.Table.fromTextArray(
        headers: headers,
        data: data.asMap().entries.map((e) {
          final r = e.value;
          final row = <String>['${e.key + 1}', r['student_name'] ?? 'Unknown', _fmt(r[scoreKey]), _fmt(r['terms_count'])];
          if (isAce) { row.add(_fmt(r['cumulative_nce'])); row.add(_fmt(r['cumulative_paces'])); }
          return row;
        }).toList(),
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
        cellAlignments: {0: pw.Alignment.center, 2: pw.Alignment.center, 3: pw.Alignment.center},
      ),
    ];
  }

  // ═══ PROMOTION TABLE ═══
  static List<pw.Widget> _promotionTable(List<Map<String, dynamic>> data, bool isAce, double threshold) {
    if (data.isEmpty) return [pw.Text('All students meet the threshold')];
    final scoreKey = isAce ? 'cumulative_hacs' : 'cumulative_score';
    final scoreLabel = isAce ? 'HACS' : 'Score';
    final headers = <String>['Student', scoreLabel, 'Threshold', 'Gap'];
    if (isAce) headers.add('Cum. NCE');
    return [
      pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 8),
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: PdfColors.red50,
        child: pw.Text('${data.length} student(s) below threshold of ${threshold.toStringAsFixed(0)}%',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red800, fontSize: 11)),
      ),
      pw.Table.fromTextArray(
        headers: headers,
        data: data.map((r) {
          final val = (r['cumulative_value'] as num?)?.toDouble() ?? 0.0;
          final gap = threshold - val;
          final row = <String>[r['student_name'] ?? 'Unknown', val.toStringAsFixed(1), '${threshold.toStringAsFixed(0)}%', gap.toStringAsFixed(1)];
          if (isAce) row.add(_fmt(r['cumulative_nce']));
          return row;
        }).toList(),
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.red700),
        cellAlignments: {1: pw.Alignment.center, 2: pw.Alignment.center, 3: pw.Alignment.center},
      ),
    ];
  }

  // ═══ FOOTER ═══

  // ═══ PHASE 2 — NEW REPORT BUILDERS ═══

  static List<pw.Widget> _studentIndividualSummary(Map<String, dynamic>? d, bool isAce) {
    if (d == null) return [pw.Text('No data')];
    final w = <pw.Widget>[];
    w.add(pw.Text(d['student_name'] ?? '', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)));
    if ((d['admission_no'] ?? '').toString().isNotEmpty) w.add(pw.Text('Adm: ${d['admission_no']}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)));
    w.add(pw.SizedBox(height: 12));
    final subs = (d['subjects'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (subs.isNotEmpty) {
      w.add(pw.Text('Subject Performance', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)));
      w.add(pw.SizedBox(height: 6));
      if (isAce) {
        w.add(pw.Table.fromTextArray(headers: ['Subject', 'PACEs', 'Avg PT', 'Highest', 'Lowest'], data: subs.map((s) => [s['subject_name'] ?? '', _fmt(s['total_paces']), _fmt(s['avg_pt']), _fmt(s['highest_pt']), _fmt(s['lowest_pt'])]).toList(), headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white), headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700)));
      } else {
        w.add(pw.Table.fromTextArray(headers: ['Subject', 'Terms', 'Avg Score', 'Highest', 'Lowest'], data: subs.map((s) => [s['subject_name'] ?? '', _fmt(s['terms_scored']), _fmt(s['avg_score']), _fmt(s['highest']), _fmt(s['lowest'])]).toList(), headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white), headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700)));
      }
    }
    final terms = (d['terms'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (terms.isNotEmpty) {
      w.add(pw.SizedBox(height: 12));
      w.add(pw.Text('Term-by-Term', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)));
      w.add(pw.SizedBox(height: 6));
      if (isAce) {
        w.add(pw.Table.fromTextArray(headers: ['Term', 'HACS', 'NCE', 'PACEs'], data: terms.map((t) => [t['term_name'] ?? '', _fmt(t['hacs_score']), _fmt(t['nce_score']), _fmt(t['paces_completed'])]).toList(), headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white), headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700)));
      } else {
        w.add(pw.Table.fromTextArray(headers: ['Term', 'Total', 'Average', 'Position', 'Grade'], data: terms.map((t) => [t['term_name'] ?? '', _fmt(t['total_score']), _fmt(t['average_score']), _fmt(t['position']), t['grade'] ?? '']).toList(), headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white), headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700)));
      }
    }
    return w;
  }

  static List<pw.Widget> _attendanceSummaryPdf(Map<String, dynamic>? d) {
    if (d == null) return [pw.Text('No data')];
    final w = <pw.Widget>[];
    w.add(pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceAround, children: [
      pw.Text('Students: ${d['total_students']}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
      pw.Text('Avg Rate: ${d['avg_attendance_rate']}%', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
      pw.Text('Most Absent: ${d['most_absent_student']}', style: pw.TextStyle(fontSize: 11, color: PdfColors.red700)),
    ]));
    w.add(pw.SizedBox(height: 10));
    final stuList = (d['students'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    w.add(pw.Table.fromTextArray(headers: ['Student', 'Present', 'Absent', 'Total', 'Rate %'], data: stuList.map((s) => [s['student_name'] ?? '', _fmt(s['days_present']), _fmt(s['days_absent']), _fmt(s['total_days']), '${s['attendance_rate']}%']).toList(), headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white), headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700)));
    return w;
  }

  static List<pw.Widget> _feeStatusPdf(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return [pw.Text('No data')];
    return [pw.Table.fromTextArray(headers: ['Student', 'Expected', 'Paid', 'Balance', 'Status'], data: data.map((r) => [r['student_name'] ?? '', _fmt(r['total_expected']), _fmt(r['total_paid']), _fmt(r['balance']), r['status'] ?? '']).toList(), headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white), headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700))];
  }

  static List<pw.Widget> _feeCollectionPdf(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return [pw.Text('No data')];
    return [pw.Table.fromTextArray(headers: ['Fee Type', 'Expected', 'Collected', 'Outstanding', 'Rate %', 'Students'], data: data.map((r) => [r['fee_type_name'] ?? '', _fmt(r['total_expected']), _fmt(r['total_paid']), _fmt(r['outstanding']), '${r['collection_rate']}%', _fmt(r['students_count'])]).toList(), headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white), headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700))];
  }

  static List<pw.Widget> _teacherPdf(List<Map<String, dynamic>> data, bool isAce) {
    if (data.isEmpty) return [pw.Text('No data')];
    final sk = isAce ? 'Avg PT' : 'Avg Score';
    return [pw.Table.fromTextArray(headers: ['Teacher', 'Subjects', 'Classes', sk, 'Pass %', 'Students'], data: data.map((r) => [r['teacher_name'] ?? '', '${r['subjects']}', _fmt(r['classes_count']), _fmt(r[isAce ? 'avg_pt' : 'avg_score']), '${r['pass_rate']}%', _fmt(r['students_count'])]).toList(), headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white), headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700))];
  }

  static List<pw.Widget> _cbtPdf(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return [pw.Text('No data')];
    return [pw.Table.fromTextArray(headers: ['Exam', 'Subject', 'Students', 'Avg Score', 'Pass %', 'Highest', 'Lowest'], data: data.map((r) => [r['exam_title'] ?? '', r['subject_name'] ?? '', _fmt(r['total_students']), _fmt(r['avg_score']), '${r['pass_rate']}%', _fmt(r['highest']), _fmt(r['lowest'])]).toList(), headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white), headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700))];
  }

  static List<pw.Widget> _trendPdf(List<Map<String, dynamic>> data, bool isAce) {
    if (data.isEmpty) return [pw.Text('No data')];
    final sk = isAce ? 'Avg PT' : 'Avg Score';
    return [pw.Table.fromTextArray(headers: ['Term', sk, 'Pass %', 'Students', 'Trend'], data: data.map((r) => [r['term_name'] ?? '', _fmt(r[isAce ? 'avg_pt' : 'avg_score']), '${r['pass_rate']}%', _fmt(r['students_count']), r['trend'] ?? '']).toList(), headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white), headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700))];
  }

  static List<pw.Widget> _ncePdf(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return [pw.Text('No data')];
    final w = <pw.Widget>[];
    w.add(pw.Table.fromTextArray(headers: ['Band', 'Count', 'Percentage', 'Students'], data: data.map((r) => [r['band'] ?? '', _fmt(r['count']), '${r['percentage']}%', (r['students'] as List?)?.join(', ') ?? '']).toList(), headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white), headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700)));
    return w;
  }

  static List<pw.Widget> _paceCompPdf(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return [pw.Text('No data')];
    return [pw.Table.fromTextArray(headers: ['Subject', 'Code', 'Total PACEs', 'Students', 'Avg/Student', 'Avg PT'], data: data.map((r) => [r['subject_name'] ?? '', r['subject_code'] ?? '', _fmt(r['total_paces']), _fmt(r['unique_students']), _fmt(r['avg_paces_per_student']), _fmt(r['avg_pt'])]).toList(), headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white), headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700))];
  }

  static pw.Widget _buildFooter(String dateStr) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300))),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text('Generated: $dateStr', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
        pw.Text('Summary Report', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
      ]),
    );
  }
}

class _PdfCard {
  final String label;
  final String value;
  final PdfColor color;
  _PdfCard(this.label, this.value, this.color);
}

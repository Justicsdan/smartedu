import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'pdf_download_utils.dart';

class AcePdfGenerator {
  static Future<pw.ImageProvider?> _fetchImage(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) return pw.MemoryImage(res.bodyBytes);
    } catch (e) { debugPrint('ACE PDF image fetch error: $e'); }
    return null;
  }

  static Future<void> generateAndDownload({
    required Map<String, dynamic> schoolInfo,
    required Map<String, dynamic> student,
    required Map<String, dynamic>? report,
    required List<Map<String, dynamic>> paceScores,
    required List<Map<String, dynamic>> subjects,
    required Map<String, dynamic>? term,
    required Map<String, dynamic>? session,
  }) async {
    final logoImg = await _fetchImage(schoolInfo['logo_url'] as String?);
    final passportImg = await _fetchImage(student['passport_url'] as String?);
    final studentName = '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'.trim();
    final pdf = pw.Document(theme: pw.ThemeData.withFont(base: pw.Font.helvetica()));
    pdf.addPage(pw.MultiPage(
      pageTheme: pw.PageTheme(pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(20), buildForeground: (context) => _watermark(logoImg, schoolInfo['name']?.toString() ?? '')),
      build: (context) => [
        _buildHeader(schoolInfo, logoImg),
        pw.SizedBox(height: 8),
        _buildStudentInfo(studentName, student, term, session, report, passportImg),
        pw.SizedBox(height: 10),
        _buildPaceTable(paceScores, subjects),
        pw.SizedBox(height: 12),
        _buildReadingProgress(report),
        pw.SizedBox(height: 12),
        _buildFooterCard(report),
      ],
    ));
    final bytes = await pdf.save();
    final fileName = '${studentName.replaceAll(' ', '_')}_${term?['name'] ?? 'term'}_ACE_Report.pdf';
    downloadPdfBytes(bytes, fileName);
  }
  static pw.Widget _watermark(pw.ImageProvider? logoImg, String schoolName) {
    if (logoImg == null) return pw.SizedBox();
    return pw.SizedBox(
      width: 595.28,
      height: 841.89,
      child: pw.Center(
        child: pw.Opacity(
          opacity: 0.08,
          child: pw.ClipOval(
            child: pw.Image(logoImg, width: 1100, height: 1100, fit: pw.BoxFit.cover),
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildHeader(Map<String, dynamic> schoolInfo, pw.ImageProvider? logoImg) {
    final ch = <pw.Widget>[
      pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(schoolInfo['name'] ?? '', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
            pw.Text(schoolInfo['motto'] ?? '', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            if (schoolInfo['address'] != null && (schoolInfo['address'] as String).isNotEmpty)
              pw.Text(schoolInfo['address'], style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
          ],
        ),
      ),
      if (logoImg != null)
        pw.Container(width: 85, height: 85, child: pw.Image(logoImg, fit: pw.BoxFit.contain))
      else
        pw.SizedBox(width: 85, height: 85),
    ];
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 6),
      decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue800, width: 2))),
      child: pw.Row(children: ch),
    );
  }

  static pw.Widget _buildStudentInfo(String name, Map<String, dynamic> student, Map<String, dynamic>? term, Map<String, dynamic>? session, Map<String, dynamic>? report, pw.ImageProvider? passportImg) {
    final titleRow = pw.Text('ACE PROGRESS REPORT', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800));
    final nameRow = pw.Row(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
      _il('Name: ', 9), _iv(name, 9), pw.SizedBox(width: 16), _il('Adm No: ', 9), _iv(student['admission_no'] ?? '', 9),
    ]);
    final sessionRow = pw.Row(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
      _il('Session: ', 9), _iv(session?['name'] ?? '-', 9), pw.SizedBox(width: 16), _il('Term: ', 9), _iv(term?['name'] ?? '-', 9),
    ]);

    final infoColumn = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [titleRow, pw.SizedBox(height: 4), nameRow, pw.SizedBox(height: 2), sessionRow],
    );

    final passportBox = pw.Container(
      width: 82,
      height: 104,
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400, width: 1.5)),
      child: passportImg != null
          ? pw.ClipRRect(horizontalRadius: 4, verticalRadius: 4, child: pw.Image(passportImg, fit: pw.BoxFit.cover))
          : pw.Center(child: pw.Text('Photo', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey300))),
    );

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [passportBox, pw.SizedBox(width: 14), pw.Expanded(child: infoColumn)],
      ),
    );
  }

  static pw.Widget _il(String t, [double size = 9]) => pw.Text(t, style: pw.TextStyle(fontSize: size, fontWeight: pw.FontWeight.bold));
  static pw.Widget _iv(String t, [double size = 9]) => pw.Text(t, style: pw.TextStyle(fontSize: size));

  static pw.Widget _hc(String t) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 1, vertical: 4),
      child: pw.Text(t, style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold, color: PdfColors.white), textAlign: pw.TextAlign.center),
    );
  }

  static pw.Widget _dc(String t, {PdfColor? color, pw.TextAlign? align, pw.FontWeight? weight}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 1, vertical: 3),
      child: pw.Text(t, style: pw.TextStyle(fontSize: 7, color: color ?? PdfColors.black, fontWeight: weight), textAlign: align ?? pw.TextAlign.left),
    );
  }

  static pw.Widget _buildPaceTable(List<Map<String, dynamic>> paceScores, List<Map<String, dynamic>> subjects) {
    final bySubject = <String, List<Map<String, dynamic>>>{};
    for (final s in paceScores) {
      final sid = s['subject_id']?.toString() ?? '';
      bySubject.putIfAbsent(sid, () => []).add(s);
    }
    int maxP = 0;
    for (final list in bySubject.values) {
      if (list.length > maxP) maxP = list.length;
    }
    if (maxP == 0) {
      return pw.Center(child: pw.Text('No PACE scores recorded.', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)));
    }

    // A4 with 20pt margins = 555pt usable
    final subjectW = 75.0;
    final totalW = 32.0;
    final remaining = 555.0 - subjectW - totalW;
    final colW = remaining / (maxP * 2);

    final hdr = <pw.Widget>[_hc('Subject')];
    for (int i = 0; i < maxP; i++) {
      hdr.add(_hc('P${i + 1} No.'));
      hdr.add(_hc('PT%'));
    }
    hdr.add(_hc('Total'));

    final rows = <pw.TableRow>[
      pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.blue800), children: hdr),
    ];

    for (final subj in subjects) {
      final sid = subj['id']?.toString() ?? '';
      final scores = bySubject[sid] ?? [];
      if (scores.isEmpty) continue;
      final validPts = scores.where((s) => s['pt_score'] != null).map((s) => (s['pt_score'] as num).toDouble()).toList();
      final total = validPts.isNotEmpty ? validPts.reduce((a, b) => a + b) / validPts.length : 0.0;
      final totalColor = total < 80 ? PdfColors.red800 : PdfColors.green800;
      final rowBg = rows.length.isEven ? PdfColors.white : PdfColor(0.93, 0.96, 1.0);

      final cells = <pw.Widget>[_dc(subj['name'] ?? '', weight: pw.FontWeight.bold)];
      final sorted = List<Map<String, dynamic>>.from(scores)
        ..sort((a, b) => (a['pace_no']?.toString() ?? '').compareTo(b['pace_no']?.toString() ?? ''));
      for (int i = 0; i < maxP; i++) {
        if (i < sorted.length) {
          final pt = sorted[i]['pt_score'];
          final pv = pt != null ? (pt as num).toDouble() : null;
          cells.add(_dc(sorted[i]['pace_no'] ?? '', align: pw.TextAlign.center));
          cells.add(_dc(pv != null ? pv.round().toString() : '--', color: pv != null && pv < 80 ? PdfColors.red700 : PdfColors.black, align: pw.TextAlign.center, weight: pv != null ? pw.FontWeight.bold : null));
        } else {
          cells.add(_dc('', align: pw.TextAlign.center));
          cells.add(_dc('--', align: pw.TextAlign.center, color: PdfColors.grey300));
        }
      }
      cells.add(_dc(total.round().toString(), color: totalColor, align: pw.TextAlign.center, weight: pw.FontWeight.bold));
      rows.add(pw.TableRow(decoration: pw.BoxDecoration(color: rowBg), children: cells));
    }

    final cw = <int, pw.TableColumnWidth>{
      0: pw.FixedColumnWidth(subjectW),
    };
    for (int i = 0; i < maxP; i++) {
      cw[1 + i * 2] = pw.FixedColumnWidth(colW);
      cw[2 + i * 2] = pw.FixedColumnWidth(colW);
    }
    cw[1 + maxP * 2] = pw.FixedColumnWidth(totalW);

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.5),
      columnWidths: cw,
      children: rows,
    );
  }

  static pw.Widget _buildReadingProgress(Map<String, dynamic>? r) {
    if (r == null) return pw.SizedBox();
    final wpm = _fm(r['reading_wpm']);
    final cp = _fm(r['reading_comprehension']);
    final comp = _fm(r['reading_composite']);
    final pc = _fi(r['paces_completed']).toString();
    final pa = _fm(r['paces_avg']);
    final pt = _fm(r['paces_total']);
    final date = DateTime.now().toString().split(' ')[0];
    final dit = _fi(r['day_in_term']).toString();
    final da = _fi(r['days_absent']).toString();
    final sc = r['supervisor_comment'] ?? '';
    const ss = 'Signature: ___________________';
    final pc2 = r['principal_comment'] ?? '';
    const ps = 'Signature: ___________________';
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), borderRadius: pw.BorderRadius.circular(4)),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          decoration: const pw.BoxDecoration(color: PdfColors.blue800),
          child: pw.Center(child: pw.Text('READING PROGRESS', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
        ),
        pw.SizedBox(height: 6),
        _rr('Words per minute (W.P.W):', wpm, 'W.P.W Comprehension:', cp, 'Composite:', comp),
        _rr('NO. of PACEs completed:', pc, 'PACE score AVG:', pa, 'Total (PACES Cass):', pt),
        _rr('Date:', date, 'Days in Term:', dit, 'Days Absent:', da),
        pw.SizedBox(height: 6),
        _cs("Supervisor's Comment:", sc, ss),
        pw.SizedBox(height: 6),
        _cs("Principal's Comment:", pc2, ps),
      ]),
    );
  }

  static pw.Widget _rr(String l1, String v1, String l2, String v2, String l3, String v3) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(children: [
        pw.Expanded(child: pw.RichText(text: pw.TextSpan(children: [
          pw.TextSpan(text: l1, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
          pw.TextSpan(text: ' $v1', style: pw.TextStyle(fontSize: 8)),
        ]))),
        pw.Expanded(child: pw.RichText(text: pw.TextSpan(children: [
          pw.TextSpan(text: l2, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
          pw.TextSpan(text: ' $v2', style: pw.TextStyle(fontSize: 8)),
        ]))),
        pw.Expanded(child: pw.RichText(text: pw.TextSpan(children: [
          pw.TextSpan(text: l3, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
          pw.TextSpan(text: ' $v3', style: pw.TextStyle(fontSize: 8)),
        ]))),
      ]),
    );
  }

  static pw.Widget _cs(String title, String comment, String sig) {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(title, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
      pw.SizedBox(height: 2),
      if (comment.isNotEmpty)
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(4),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(2)),
          child: pw.Text(comment, style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)),
        )
      else
        pw.SizedBox(height: 16),
      pw.SizedBox(height: 4),
      pw.Text(sig, style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
    ]);
  }

  static pw.Widget _buildFooterCard(Map<String, dynamic>? r) {
    if (r == null) return pw.SizedBox();
    final hacs = _fm(r['hacs_score']);
    final nce = _fm(r['nce_score']);
    final total = _fm(r['total_score']);
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.blue800, width: 1.5), borderRadius: pw.BorderRadius.circular(4)),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceAround, children: [
        _footerItem('HACS Score', hacs, PdfColors.blue800),
        _footerItem('NCE Score', nce, PdfColors.orange800),
        _footerItem('Total', total, PdfColors.green800),
      ]),
    );
  }

  static pw.Widget _footerItem(String label, String value, PdfColor color) {
    return pw.Column(children: [
      pw.Text(label, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
      pw.SizedBox(height: 2),
      pw.Text(value, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: color)),
    ]);
  }

  static String _fm(dynamic val) {
    if (val == null) return '';
    if (val is num) return val.toDouble() == val.toDouble().roundToDouble() ? val.toInt().toString() : val.toDouble().toStringAsFixed(1);
    return val.toString();
  }

  static int _fi(dynamic val) {
    if (val == null) return 0;
    return (val is num ? val.toInt() : int.tryParse(val.toString()) ?? 0);
  }
}

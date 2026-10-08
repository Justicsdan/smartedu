import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartedu/core/providers/school_admin_provider.dart';
import 'package:smartedu/core/services/db_proxy.dart';
import 'package:smartedu/utils/grading_utils.dart';
import 'package:smartedu/utils/chart_theme.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import 'package:smartedu/utils/grading_utils.dart';
import 'package:smartedu/utils/pdf_download_utils.dart';

class AdminStudentResultsPage extends StatefulWidget {
  final Map<String, dynamic> student;
  const AdminStudentResultsPage({super.key, required this.student});
  @override
  State<AdminStudentResultsPage> createState() => _AdminStudentResultsPageState();
}

class _AdminStudentResultsPageState extends State<AdminStudentResultsPage> {
  bool _loading = true;
  bool _isDownloading = false;
  List<Map<String, dynamic>> _scores = [];
  Map<String, dynamic>? _summary;
  Map<String, String> _behavioralRatings = {};
  Map<String, dynamic>? _termComment;
  List<Map<String, dynamic>> _assessmentTypes = [];
  Map<String, dynamic>? _positionData;
  String _error = '';
  List<Map<String, dynamic>> _sessionTerms = [];
  Map<String, List<Map<String, dynamic>>> _scoresByTerm = {};
  Map<String, String> _termNames = {};
  List<_ScoreColumn> _dataColumns = [];

  String get _name {
    final first = (widget.student['first_name'] ?? '').toString();
    final last = (widget.student['last_name'] ?? '').toString();
    return '$first $last'.trim();
  }
  String get _admNo => (widget.student['admission_no'] ?? '').toString().trim();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    final p = context.read<SchoolAdminProvider>();
    final sid = widget.student['id']?.toString() ?? '';
    final sessionId = p.currentSession?['id']?.toString() ?? '';
    final termId = p.currentTerm?['id']?.toString() ?? '';
    final classId = widget.student['class_id']?.toString() ?? '';
    if (sid.isEmpty || sessionId.isEmpty || termId.isEmpty) {
      if (mounted) setState(() { _loading = false; _error = 'No session or term selected'; });
      return;
    }
    try {
      await Future.wait([
        _loadScores(sid, sessionId, termId),
        _loadBehavioral(sid, sessionId, termId),
        _loadTermComment(sid, sessionId, termId),
        _loadPosition(sid, sessionId, termId),
        _loadMultiTermData(sid, sessionId),
      ]);
      String tier = 'SSS';
      if (classId.isNotEmpty) {
        final cls = p.classes.firstWhere((c) => c['id']?.toString() == classId, orElse: () => <String, dynamic>{});
        tier = (cls['tier'] ?? 'SSS').toString();
      }
      final grading = p.getEffectiveGradingForTier(tier);
      Map<String, dynamic>? summary;
      if (_scores.isNotEmpty) {
        summary = GradingUtils.computeStudentSummary(studentScores: _scores, gradingSystem: grading);
      }
      final assessments = p.getEffectiveAssessmentForTier(tier);
      if (summary != null && _positionData != null) {
        summary['position'] = _positionData!['position'] ?? 0;
        summary['position_out_of'] = _positionData!['position_out_of'] ?? 0;
      }
      final cols = _buildDataColumns(assessments);
      if (mounted) {
        setState(() {
          _summary = summary;
          _assessmentTypes = assessments;
          _dataColumns = cols;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('AdminStudentResultsPage error: ' + e.toString());
      if (mounted) setState(() { _loading = false; _error = 'Failed: ' + e.toString(); });
    }
  }

  /// Settings ONLY. Always settings labels, always in settings order.
  /// If a settings column has matching data → shows the value.
  /// If a settings column has NO matching data → shows "--".
  /// If a settings column has matching data → shows the value.
  /// If no name match but counts align → positional fallback (1:1 map).
  List<_ScoreColumn> _buildDataColumns(List<Map<String, dynamic>> assessments) {
    if (assessments.isEmpty) return [];

    // Collect all data keys for matching lookup (preserve insertion order)
    final dataByNorm = <String, String>{};
    final dataKeys = <String>[];
    for (final s in _scores) {
      final sj = _parseSj(s['scores_json']);
      for (final k in sj.keys) {
        final n = _norm(k);
        if (!dataByNorm.containsKey(n)) {
          dataByNorm[n] = k;
          dataKeys.add(k);
        }
      }
    }

    final columns = <_ScoreColumn>[];
    for (final a in assessments) {
      final name = (a['name'] ?? '').toString();
      final mx = (a['max_score'] ?? '').toString();
      final norm = _norm(name);
      String matchedKey = '';

      // Exact match on normalized
      if (dataByNorm.containsKey(norm)) {
        matchedKey = dataByNorm[norm]!;
      } else {
        // Proper prefix match: one string starts with the other (min 3 chars)
        for (final entry in dataByNorm.entries) {
          if (entry.key.length >= 3 && norm.length >= 3 &&
              (entry.key.startsWith(norm) || norm.startsWith(entry.key))) {
            matchedKey = entry.value;
            break;
          }
        }
      }

      columns.add(_ScoreColumn(
        key: matchedKey,
        label: name,
        maxScore: mx,
        hasData: matchedKey.isNotEmpty,
      ));
    }

    // Positional fallback: keep name-matched cols, fill unmatched slots from unused data keys
    final matchedCount = columns.where((c) => c.hasData).length;
    final usedKeys = columns.where((c) => c.hasData).map((c) => c.key).toSet();
    final unusedKeys = dataKeys.where((k) => !usedKeys.contains(k)).toList();
    final unmatchedIdx = <int>[];
    for (int i = 0; i < columns.length; i++) { if (!columns[i].hasData) unmatchedIdx.add(i); }
    if (matchedCount < columns.length && unusedKeys.length == unmatchedIdx.length) {
      for (int i = 0; i < unmatchedIdx.length; i++) {
        final idx = unmatchedIdx[i];
        columns[idx] = _ScoreColumn(
          key: unusedKeys[i],
          label: columns[idx].label,
          maxScore: columns[idx].maxScore,
          hasData: true,
        );
      }
    }

    return columns;
  }

  String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  Future<void> _loadScores(String sid, String sessionId, String termId) async {
    final r = await DbProxy.instance
        .from('scores')
        .select('id, subject_id, total, grade, position, position_out_of, scores_json, subjects(name, code)')
        .eq('student_id', sid).eq('session_id', sessionId).eq('term_id', termId).get();
    _scores = List<Map<String, dynamic>>.from(r);
  }

  Future<void> _loadBehavioral(String sid, String sessionId, String termId) async {
    try {
      final r = await DbProxy.instance
          .from('student_behavioural_ratings').select('*')
          .eq('student_id', sid).eq('session_id', sessionId).eq('term_id', termId).maybeSingle();
      if (r != null) {
        for (final k in GradingUtils.behavioralFieldKeys) {
          final v = r[k]; if (v != null) _behavioralRatings[k] = v.toString();
        }
      }
    } catch (_) {}
  }

  Future<void> _loadTermComment(String sid, String sessionId, String termId) async {
    try {
      final r = await DbProxy.instance
          .from('term_comments').select('*')
          .eq('student_id', sid).eq('session_id', sessionId).eq('term_id', termId).maybeSingle();
      if (r != null) _termComment = r;
    } catch (_) {}
  }

  Future<void> _loadPosition(String sid, String sessionId, String termId) async {
    try {
      final r = await DbProxy.instance
          .from('student_term_summaries').select('position, position_out_of')
          .eq('student_id', sid).eq('session_id', sessionId).eq('term_id', termId).maybeSingle();
      if (r != null) _positionData = r;
    } catch (_) {}
  }

  Future<void> _loadMultiTermData(String sid, String sessionId) async {
    try {
      final terms = await DbProxy.instance
          .from('terms').select('id, name').eq('session_id', sessionId).order('name').get();
      _sessionTerms = List<Map<String, dynamic>>.from(terms);
      _termNames = {for (final t in _sessionTerms) t['id'].toString(): (t['name'] ?? '').toString()};
      final allScores = await DbProxy.instance
          .from('scores').select('id, term_id, total, subjects(name, code)')
          .eq('student_id', sid).eq('session_id', sessionId).get();
      final list = List<Map<String, dynamic>>.from(allScores);
      _scoresByTerm = {};
      for (final s in list) {
        final tid = (s['term_id'] ?? '').toString();
        _scoresByTerm.putIfAbsent(tid, () => []).add(s);
      }
    } catch (_) {}
  }



  String _grade(dynamic total) {
    final t = (total as num?)?.toDouble() ?? 0;
    if (t >= 70) return 'A'; if (t >= 60) return 'B';
    if (t >= 50) return 'C'; if (t >= 40) return 'D';
    return 'F';
  }



  Future<void> _downloadResultPdf() async {
    final provider = context.read<SchoolAdminProvider>();
    if (_scores.isEmpty) return;

    setState(() => _isDownloading = true);
    try {
      final classTier = (widget.student['classes']?['tier'] as String?) ?? 'SSS';
      final gradingSystem = GradingUtils.getGradingSystemForTier(classTier, provider.schoolSettings ?? {});
      final assessmentTypes = GradingUtils.getAssessmentTypesForTier(classTier, provider.schoolSettings ?? {});
      final passMark = (provider.schoolSettings?['pass_mark'] as num?)?.toDouble() ?? 40.0;
      
      // Fetch Comments and Behavioral Ratings
      Map<String, dynamic>? termComment;
      Map<String, dynamic>? behavioralRatings;
      try {
        final sessionId = provider.currentSession?['id'] ?? '';
        final termId = provider.currentTerm?['id'] ?? '';
        if (sessionId.isNotEmpty && termId.isNotEmpty) {
          termComment = await DbProxy.instance.from('term_comments').select('teacher_comment, principal_comment').eq('student_id', widget.student['id']).eq('session_id', sessionId).eq('term_id', termId).maybeSingle();
          behavioralRatings = await DbProxy.instance.from('student_behavioural_ratings').select('*').eq('student_id', widget.student['id']).eq('session_id', sessionId).eq('term_id', termId).maybeSingle();
        }
      } catch (_) {}

      final average = _summary?['average_score']?.toDouble() ?? 0.0;
      final overallGradeInfo = GradingUtils.getGradeFromSystem(average, gradingSystem);
      final passed = _scores.where((s) => ((s['total'] ?? 0) as num) >= passMark).length;
      final failed = _scores.length - passed;
      final totalScore = _scores.fold<double>(0, (sum, s) => sum + ((s['total'] ?? 0) as num).toDouble());
      final totalStr = totalScore == totalScore.roundToDouble() ? totalScore.toInt().toString() : totalScore.toStringAsFixed(1);

      // Fetch School Profile and Student Passport
      Map<String, dynamic>? schoolProfile;
      try {
        final res = await DbProxy.instance.from('schools').select('address, motto, official_phone, official_email, logo_url').eq('id', provider.schoolId).maybeSingle();
        if (res != null) schoolProfile = res;
      } catch (_) {}

      final logoUrl = schoolProfile?['logo_url'] ?? '';
      final schoolAddress = schoolProfile?['address'] ?? '';
      final schoolMotto = schoolProfile?['motto'] ?? '';
      final schoolPhone = schoolProfile?['official_phone'] ?? '';
      final schoolEmail = schoolProfile?['official_email'] ?? '';
      final studentPassportUrl = widget.student['passport_url'] ?? '';
      final logoImg = await _fetchImage(logoUrl);
      final passportImg = await _fetchImage(studentPassportUrl);
      
      final pdf = pw.Document(theme: pw.ThemeData.withFont(base: pw.Font.helvetica()));

      final scoreRows = <pw.TableRow>[];
      scoreRows.add(pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.blue800),
        children: [
          _pdfHdr('S/N'), _pdfHdr('Subject'),
          ...assessmentTypes.map((at) => _pdfHdr('${at['name']} (${at['max']})')),
          _pdfHdr('Total'), _pdfHdr('Grade'), _pdfHdr('Remark'),
        ],
      ));
      
      for (int i = 0; i < _scores.length; i++) {
        final score = _scores[i];
        final idx = i + 1;
        final total = ((score['total'] ?? 0) as num).toDouble();
        final isPass = total >= passMark;
        final gradeInfo = GradingUtils.getGradeFromSystem(total, gradingSystem);
        final scoresJson = _parseSj(score['scores_json']);
        final resolvedKeys = _resolveKeys(assessmentTypes, scoresJson);
        final rowColor = idx.isEven ? PdfColors.white : PdfColor(0.95, 0.97, 1.0);
        final txtColor = isPass ? PdfColors.green800 : PdfColors.red800;

        scoreRows.add(pw.TableRow(
          decoration: pw.BoxDecoration(color: rowColor),
          children: [
            _pdfCell('$idx', align: pw.TextAlign.center),
            _pdfCell(((score['subjects'] as Map?)?['name'] ?? '').toString(), weight: pw.FontWeight.bold),
            ...List.generate(assessmentTypes.length, (i) {
              final val = scoresJson[resolvedKeys[i]] ?? 0;
              return _pdfCell(val is int ? '$val' : val.toString(), align: pw.TextAlign.center);
            }),
            _pdfCell(total == total.roundToDouble() ? total.toInt().toString() : total.toStringAsFixed(1), align: pw.TextAlign.center, weight: pw.FontWeight.bold, color: txtColor),
            _pdfCell(gradeInfo['grade'] as String? ?? '', align: pw.TextAlign.center, weight: pw.FontWeight.bold, color: txtColor),
            _pdfCell(gradeInfo['remark'] as String? ?? '', align: pw.TextAlign.center),
          ],
        ));
      }

      final gkRows = <pw.TableRow>[];
      gkRows.add(pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.blue800), children: [_pdfHdr('Grade'), _pdfHdr('Score Range'), _pdfHdr('Remark')]));
      for (int i = 0; i < gradingSystem.length; i++) {
        final g = gradingSystem[i];
        final grade = (g['grade'] ?? '').toString();
        final isFail = !GradingUtils.isPassingGrade(grade, gradingSystem);
        final rowColor = i.isEven ? PdfColors.white : PdfColor(0.95, 0.97, 1.0);
        gkRows.add(pw.TableRow(decoration: pw.BoxDecoration(color: rowColor), children: [
          _pdfCell(grade, align: pw.TextAlign.center, weight: pw.FontWeight.bold, color: isFail ? PdfColors.red800 : PdfColors.black),
          _pdfCell('${g['min']} - ${g['max']}', align: pw.TextAlign.center),
          _pdfCell((g['remark'] ?? '').toString(), color: isFail ? PdfColors.red800 : PdfColors.black),
        ]));
      }

      pdf.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(30), buildForeground: (context) => _watermark(logoImg, provider.schoolName)),
          build: (context) {
            final pageWidgets = <pw.Widget>[];
            
            // 1. SCHOOL HEADER
            pageWidgets.add(pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
              pw.Expanded(child: pw.Column(mainAxisSize: pw.MainAxisSize.min, crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
                pw.Text(provider.schoolName.toUpperCase(), style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                if (schoolAddress.isNotEmpty) pw.Text(schoolAddress, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                if (schoolMotto.isNotEmpty) pw.Text('"$schoolMotto"', style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600)),
                if (schoolPhone.isNotEmpty || schoolEmail.isNotEmpty)
                  pw.Text([if (schoolPhone.isNotEmpty) 'Tel: $schoolPhone', if (schoolEmail.isNotEmpty) 'Email: $schoolEmail'].join('  |  '), style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              ])),
              if (logoImg != null) pw.Container(width: 85, height: 85, child: pw.Image(logoImg, fit: pw.BoxFit.contain)) else pw.SizedBox(width: 85, height: 85),
            ]));
            
            pageWidgets.add(pw.SizedBox(height: 6));
            pageWidgets.add(pw.Container(height: 1.5, color: PdfColors.blue800));
            pageWidgets.add(pw.SizedBox(height: 6));
            pageWidgets.add(pw.Center(child: pw.Text('STUDENT RESULT SHEET', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, letterSpacing: 2, color: PdfColors.blue800))));
            pageWidgets.add(pw.SizedBox(height: 10));

            // 2. PASSPORT + STUDENT INFO
            pageWidgets.add(pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 82, height: 104,
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey600, width: 1)),
                  child: passportImg != null ? pw.Image(passportImg, fit: pw.BoxFit.cover) : pw.Center(child: pw.Text('No Photo', style: pw.TextStyle(fontSize: 7, color: PdfColors.grey400))),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Table(
                    columnWidths: const {0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(5)},
                    border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.8),
                    children: [
                      _pdfInfoRow('Name', "${widget.student['first_name']} ${widget.student['middle_name'] ?? ''} ${widget.student['last_name']}"),
                      _pdfInfoRow('Admission No', widget.student['admission_no'] ?? 'N/A'),
                      _pdfInfoRow('Class', widget.student['classes']?['name'] ?? 'N/A'),
                      _pdfInfoRow('Session', provider.currentSession?['name'] ?? 'N/A'),
                      _pdfInfoRow('Term', provider.currentTerm?['name'] ?? 'N/A'),
                      if (_summary?['position'] != null) _pdfInfoRow('Position', _ordinal(_summary!['position'])),
                    ],
                  ),
                ),
              ],
            ));
            
            pageWidgets.add(pw.SizedBox(height: 10));

            // 3. ACADEMIC SUMMARY
            pageWidgets.add(pw.Table(
              columnWidths: const {0: pw.FlexColumnWidth(2.2), 1: pw.FlexColumnWidth(1.3), 2: pw.FlexColumnWidth(2.2), 3: pw.FlexColumnWidth(1.3)},
              border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.8),
              children: [
                pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.blue800), children: [_pdfHdr('ACADEMIC SUMMARY'), _pdfHdr(''), _pdfHdr(''), _pdfHdr('')]),
                _pdfQuadRow('Subjects Taken', '${_scores.length}', 'Days Present', '${_summary?['days_present'] ?? 0}'),
                _pdfQuadRow('Total Score', totalStr, 'Days Absent', '${_summary?['days_absent'] ?? 0}'),
                _pdfQuadRow('Average', average.toStringAsFixed(1), '', ''),
                _pdfQuadRow('Grade', overallGradeInfo['grade'] as String? ?? '', '', ''),
                _pdfQuadRow('Passed', '$passed', '', '', v1Color: PdfColors.green800),
                _pdfQuadRow('Failed', '$failed', '', '', v1Color: failed > 0 ? PdfColors.red800 : PdfColors.green800),
              ],
            ));

            pageWidgets.add(pw.SizedBox(height: 10));

            // 4. SCORES TABLE
            pageWidgets.add(pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.8),
              columnWidths: {
                0: const pw.FlexColumnWidth(0.7), 1: const pw.FlexColumnWidth(3.2),
                ...Map.fromEntries(assessmentTypes.asMap().entries.map((e) => MapEntry(e.key + 2, const pw.FlexColumnWidth(1.3)))),
                (assessmentTypes.length + 2): const pw.FlexColumnWidth(1.0),
                (assessmentTypes.length + 3): const pw.FlexColumnWidth(0.9),
                (assessmentTypes.length + 4): const pw.FlexColumnWidth(1.9),
              },
              children: scoreRows,
            ));

            pageWidgets.add(pw.SizedBox(height: 10));

            // 5. GRADING KEY
            pageWidgets.add(pw.Table(
              columnWidths: const {0: pw.FlexColumnWidth(1.2), 1: pw.FlexColumnWidth(1.5), 2: pw.FlexColumnWidth(3.5)},
              border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.8),
              children: gkRows,
            ));

            // 6. BEHAVIORAL RATINGS
            if (behavioralRatings != null && behavioralRatings!.isNotEmpty) {
              final behavRows = <pw.TableRow>[];
              behavRows.add(pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.blue800), children: [_pdfHdr('BEHAVIORAL TRAIT'), _pdfHdr('RATING')]));
              final bKeys = ['punctuality', 'relationship_with_others', 'attendance_in_class', 'games_sports', 'attentiveness_in_class', 'handling_tools_lab_workshops', 'carrying_out_assignments', 'participation_in_school_activities', 'neatness', 'honesty', 'self_control'];
              for (int i = 0; i < bKeys.length; i++) {
                final key = bKeys[i];
                final value = (behavioralRatings?[key] ?? '').toString();
                final rowColor = i.isEven ? PdfColors.white : PdfColor(0.95, 0.97, 1.0);
                behavRows.add(pw.TableRow(decoration: pw.BoxDecoration(color: rowColor), children: [
                  _pdfCell(key.replaceAll('_', ' ').split(' ').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ')),
                  _pdfCell(value.isEmpty ? '-' : value, align: pw.TextAlign.center, weight: value.isEmpty ? null : pw.FontWeight.bold, color: value.isEmpty ? PdfColors.grey400 : PdfColors.blue800),
                ]));
              }
              pageWidgets.add(pw.SizedBox(height: 10));
              pageWidgets.add(pw.Table(columnWidths: const {0: pw.FlexColumnWidth(4), 1: pw.FlexColumnWidth(2)}, border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.8), children: behavRows));
            }

            // 7. COMMENTS
            if (termComment != null) {
              final tc = (termComment!['teacher_comment'] ?? '').toString();
              final pc = (termComment!['principal_comment'] ?? '').toString();
              if (tc.isNotEmpty || pc.isNotEmpty) {
                pageWidgets.add(pw.SizedBox(height: 10));
                pageWidgets.add(pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey500, width: 0.8)),
                  child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    if (tc.isNotEmpty) ...[pw.Text("Class Teacher's Comment:", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)), pw.SizedBox(height: 2), pw.Text(tc, style: pw.TextStyle(fontSize: 8)), pw.SizedBox(height: 6)],
                    if (pc.isNotEmpty) ...[pw.Text("Principal's Comment:", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)), pw.SizedBox(height: 2), pw.Text(pc, style: pw.TextStyle(fontSize: 8))],
                  ])
                ));
              }
            }

            pageWidgets.add(pw.SizedBox(height: 28));
            pageWidgets.add(pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Column(children: [pw.Text('Class Teacher', style: pw.TextStyle(fontSize: 9)), pw.SizedBox(height: 30), pw.Container(width: 130, height: 1, color: PdfColors.grey600)]),
              pw.Column(children: [pw.Text('Principal', style: pw.TextStyle(fontSize: 9)), pw.SizedBox(height: 30), pw.Container(width: 130, height: 1, color: PdfColors.grey600)]),
            ]));

            return pageWidgets;
          },
        ),
      );

      final bytes = await pdf.save();
      final studentName = "${widget.student['first_name']}_${widget.student['last_name']}";
      final termName = provider.currentTerm?['name'] ?? 'Term';
      downloadPdfBytes(bytes, '${studentName}_${termName}_Result.pdf');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to generate PDF: $e')));
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  // ─── PDF HELPER METHODS ───
  static pw.Widget _watermark(pw.ImageProvider? logoImg, String schoolName) {
    if (logoImg == null) return pw.Container();
    return pw.SizedBox(
      width: PdfPageFormat.a4.width,
      height: PdfPageFormat.a4.height,
      child: pw.Center(child: pw.Opacity(opacity: 0.08, child: pw.ClipOval(child: pw.Image(logoImg, width: 1100, height: 1100, fit: pw.BoxFit.cover))))
    );
  }

  Future<pw.ImageProvider?> _fetchImage(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) return pw.MemoryImage(res.bodyBytes);
    } catch (_) {}
    return null;
  }

  static Map<String, dynamic> _parseSj(dynamic sj) {
    if (sj == null) return {};
    if (sj is Map<String, dynamic>) return sj;
    if (sj is String) {
      try { return jsonDecode(sj) as Map<String, dynamic>; } catch (_) { return {}; }
    }
    return {};
  }

  static List<String> _resolveKeys(List<dynamic> assessmentTypes, Map<String, dynamic> scoresJson) {
    final keys = <String>[];
    for (final at in assessmentTypes) {
      final id = (at['id'] ?? '').toString();
      final name = (at['name'] ?? '').toString().toLowerCase().replaceAll(' ', '_');
      if (scoresJson.containsKey(id)) keys.add(id);
      else if (scoresJson.containsKey(name)) keys.add(name);
      else keys.add(id);
    }
    return keys;
  }

  static pw.Widget _pdfHdr(String text) {
    return pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(text, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white), textAlign: pw.TextAlign.center));
  }

  static pw.Widget _pdfCell(String text, {pw.TextAlign align = pw.TextAlign.left, pw.FontWeight? weight, PdfColor? color}) {
    return pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(text, style: pw.TextStyle(fontSize: 8, fontWeight: weight, color: color ?? PdfColors.black), textAlign: align));
  }

  static pw.TableRow _pdfInfoRow(String label, String value) {
    return pw.TableRow(children: [
      pw.Container(color: PdfColor(0.91, 0.93, 0.97), padding: const pw.EdgeInsets.all(6), child: pw.Text(label, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900))),
      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
    ]);
  }

  static pw.TableRow _pdfQuadRow(String l1, String v1, String l2, String v2, {PdfColor? v1Color, PdfColor? v2Color}) {
    return pw.TableRow(children: [
      pw.Container(color: PdfColor(0.91, 0.93, 0.97), padding: const pw.EdgeInsets.all(4), child: pw.Text(l1, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800))),
      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(v1, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: v1Color ?? PdfColors.black))),
      pw.Container(color: PdfColor(0.91, 0.93, 0.97), padding: const pw.EdgeInsets.all(4), child: pw.Text(l2, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800))),
      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(v2, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: v2Color ?? PdfColors.black))),
    ]);
  }

  String _ordinal(int number) {
    if (number <= 0) return 'N/A';
    final suffix = ['th', 'st', 'nd', 'rd'];
    final v = number % 100;
    return number.toString() + (suffix[(v - 20) % 10] ?? suffix[v] ?? suffix[0]);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.read<SchoolAdminProvider>();
    final termName = p.currentTerm?['name']?.toString() ?? '';
    final sessionName = p.currentSession?['name']?.toString() ?? '';
    final passMark = (p.schoolSettings?['pass_mark'] as num?)?.toInt() ?? 40;
    final customLabels = p.behavioralLabels;
    final allLabels = GradingUtils.getAllBehavioralLabels(customLabels: customLabels);
    final hasMultiTerm = _sessionTerms.length >= 2;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Student Results', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        centerTitle: true, backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white, iconTheme: const IconThemeData(color: Colors.white), elevation: 0,
        actions: [
          IconButton(icon: _isDownloading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.download), 
            tooltip: 'Download PDF',
            onPressed: _isDownloading ? null : _downloadResultPdf),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? _emptyState(Icons.error_outline, _error)
              : _scores.isEmpty
                  ? _emptyState(Icons.grading_outlined, 'No scores recorded for this term')
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _buildStudentHeader(sessionName, termName),
                        const SizedBox(height: 14),
                        if (_summary != null) ...[_buildSummaryCards(), const SizedBox(height: 14)],
                        _buildScoresTable(passMark),
                        const SizedBox(height: 14),
                        if (_behavioralRatings.isNotEmpty) ...[_buildBehavioralGrid(allLabels), const SizedBox(height: 14)],
                        if (_termComment != null) ...[_buildComments(), const SizedBox(height: 14)],
                        _buildSubjectChart(passMark),
                        const SizedBox(height: 14),
                        if (hasMultiTerm) ...[_buildMultiTermChart(), const SizedBox(height: 14)],
                        if (hasMultiTerm) _buildTermPieChart(),
                        const SizedBox(height: 24),
                      ]),
                    ),
    );
  }

  Widget _emptyState(IconData icon, String msg) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 48, color: Colors.grey.shade400),
      const SizedBox(height: 12),
      Text(msg, style: TextStyle(fontSize: 14, color: Colors.grey.shade600), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
    ]),
  );

  Widget _buildStudentHeader(String sessionName, String termName) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF283593)]), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_name.toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.3)),
        const SizedBox(height: 4),
        Row(children: [
          Icon(Icons.badge_outlined, size: 14, color: Colors.white.withValues(alpha: 0.7)),
          const SizedBox(width: 4),
          Text(_admNo, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
          const SizedBox(width: 16),
          Icon(Icons.calendar_today_outlined, size: 14, color: Colors.white.withValues(alpha: 0.7)),
          const SizedBox(width: 4),
          Text(sessionName + ' \u2014 ' + termName, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
        ]),
      ]),
    );
  }

  Widget _buildSummaryCards() {
    final totalScore = (_summary!['total_score'] ?? 0).toString();
    final avgScore = (_summary!['average_score'] as num?)?.toStringAsFixed(1) ?? '0.0';
    final pos = (_summary!['position'] as num?)?.toInt() ?? 0;
    final posOf = (_summary!['position_out_of'] ?? 0);
    return Row(children: [
      _metricCard('Total Score', totalScore, const Color(0xFF1A237E), Icons.assessment_outlined),
      const SizedBox(width: 10),
      _metricCard('Average', avgScore + '%', const Color(0xFF2E7D32), Icons.trending_up_outlined),
      const SizedBox(width: 10),
      _metricCard('Position', _ordinal(pos) + ' of ' + posOf.toString(), const Color(0xFF7B1FA2), Icons.emoji_events_outlined),
    ]);
  }

  Widget _metricCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
          ])),
        ]),
      ),
    );
  }

  Widget _buildScoresTable(int passMark) {
    if (_dataColumns.isNotEmpty) return _buildDetailedTable(passMark);
    return _buildSimpleTable(passMark);
  }

  Widget _buildSimpleTable(int passMark) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(children: [
        _tableHeader(['SUBJECT', 'SCORE', 'GRADE', 'REMARK'], [3, 1, 1, 1]),
        for (int i = 0; i < _scores.length; i++) _simpleRow(_scores[i], i, passMark),
        Container(height: 1, color: const Color(0xFFE5E7EB)),
      ]),
    );
  }

  Widget _simpleRow(Map<String, dynamic> s, int i, int passMark) {
    final subject = s['subjects'] as Map<String, dynamic>? ?? {};
    final name = (subject['name'] ?? '').toString();
    final total = (s['total'] as num?)?.toInt() ?? 0;
    final grade = (s['grade'] ?? _grade(total)).toString();
    final pass = total >= passMark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: i.isEven ? Colors.white : const Color(0xFFFAFBFC), border: Border(bottom: BorderSide(color: const Color(0xFFF0F0F0)))),
      child: Row(children: [
        Expanded(flex: 3, child: Text(name, style: const TextStyle(fontSize: 12, color: Color(0xFF111827)), overflow: TextOverflow.ellipsis)),
        Expanded(flex: 1, child: Text(total.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF111827)), textAlign: TextAlign.center)),
        Expanded(flex: 1, child: _gradeBadge(grade)),
        Expanded(flex: 1, child: _passBadge(pass)),
      ]),
    );
  }

  Widget _buildDetailedTable(int passMark) {
    final headers = <String>['SUBJECT'];
    final flexes = <int>[3];
    for (final col in _dataColumns) {
      final mx = col.maxScore.isNotEmpty ? ' (' + col.maxScore + ')' : '';
      headers.add(col.label.toUpperCase() + mx);
      flexes.add(1);
    }
    headers.addAll(['TOTAL', 'GRADE', 'REMARK']);
    flexes.addAll([1, 1, 1]);
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(children: [
        _tableHeader(headers, flexes),
        for (int i = 0; i < _scores.length; i++) _detailedRow(_scores[i], i, passMark, flexes),
        Container(height: 1, color: const Color(0xFFE5E7EB)),
      ]),
    );
  }

  Widget _detailedRow(Map<String, dynamic> s, int i, int passMark, List<int> flexes) {
    final subject = s['subjects'] as Map<String, dynamic>? ?? {};
    final name = (subject['name'] ?? '').toString();
    final sj = _parseSj(s['scores_json']);
    final total = (s['total'] as num?)?.toInt() ?? 0;
    final grade = (s['grade'] ?? _grade(total)).toString();
    final pass = total >= passMark;
    final cells = <Widget>[
      Text(name, style: const TextStyle(fontSize: 11, color: Color(0xFF111827)), overflow: TextOverflow.ellipsis),
    ];
    for (final col in _dataColumns) {
      String display;
      if (col.hasData) {
        final val = sj[col.key];
        display = val != null ? val.toString() : '--';
      } else {
        display = '--';
      }
      cells.add(Text(display, style: const TextStyle(fontSize: 11, color: Color(0xFF111827)), textAlign: TextAlign.center));
    }
    cells.add(Text(total.toString(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF111827)), textAlign: TextAlign.center));
    cells.add(_gradeBadge(grade));
    cells.add(_passBadge(pass));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(color: i.isEven ? Colors.white : const Color(0xFFFAFBFC), border: Border(bottom: BorderSide(color: const Color(0xFFF0F0F0)))),
      child: Row(children: [for (int j = 0; j < cells.length; j++) Expanded(flex: flexes[j], child: cells[j])]),
    );
  }

  Widget _tableHeader(List<String> headers, List<int> flexes) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(color: Color(0xFF1A237E), borderRadius: BorderRadius.vertical(top: Radius.circular(10))),
      child: Row(children: [
        for (int i = 0; i < headers.length; i++)
          Expanded(flex: flexes[i], child: Text(headers[i], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5), textAlign: i == 0 ? TextAlign.left : TextAlign.center)),
      ]),
    );
  }

  Widget _gradeBadge(String grade) => Center(child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(4)),
    child: Text(grade, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1A237E)), textAlign: TextAlign.center),
  ));

  Widget _passBadge(bool pass) => Center(child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: pass ? const Color(0xFFE8F5E9) : const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(4)),
    child: Text(pass ? 'Pass' : 'Fail', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: pass ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F)), textAlign: TextAlign.center),
  ));

  Widget _buildBehavioralGrid(List<Map<String, String>> allLabels) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('BEHAVIORAL RATINGS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1A237E), letterSpacing: 0.5)),
        const SizedBox(height: 10),
        Wrap(spacing: 12, runSpacing: 8, children: allLabels.map((item) {
          final key = item['key'] ?? '';
          final label = item['label'] ?? key;
          final value = _behavioralRatings[key] ?? '--';
          return SizedBox(width: 170, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 1),
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
          ]));
        }).toList()),
      ]),
    );
  }

  Widget _buildComments() {
    final tc = _termComment!;
    final items = <_CItem>[];
    final t = (tc['teacher_comment'] ?? '').toString();
    final pr = (tc['principal_comment'] ?? '').toString();
    if (t.isNotEmpty) items.add(_CItem('Teacher Comment', t, Icons.person_outline));
    if (pr.isNotEmpty) items.add(_CItem('Principal Comment', pr, Icons.school_outlined));
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('COMMENTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1A237E), letterSpacing: 0.5)),
        const SizedBox(height: 10),
        for (int i = 0; i < items.length; i++) ...[
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(items[i].icon, size: 16, color: const Color(0xFF6B7280)),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(items[i].label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
              const SizedBox(height: 2),
              Text(items[i].text, style: const TextStyle(fontSize: 12, color: Color(0xFF111827))),
            ])),
          ]),
          if (i < items.length - 1) const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
        ],
      ]),
    );
  }

  Widget _buildSubjectChart(int passMark) {
    final p = context.read<SchoolAdminProvider>();
    final theme = ChartTheme.fromSettings(p.schoolSettings);
    final maxScore = (p.schoolSettings?['subject_max_score'] as num?)?.toInt() ?? 100;
    if (_scores.isEmpty) return const SizedBox.shrink();
    final sorted = List<Map<String, dynamic>>.from(_scores)
      ..sort((a, b) => ((b['total'] as num?)?.toInt() ?? 0).compareTo((a['total'] as num?)?.toInt() ?? 0));
    final display = sorted.take(15).toList();
    const rowH = 32.0, nameW = 100.0, scoreW = 44.0;
    final chartH = display.length * rowH;
    return ChartTheme.card(title: 'Subject Performance', icon: Icons.bar_chart, child: LayoutBuilder(builder: (context, constraints) {
      final barW = (constraints.maxWidth - nameW - scoreW - 8).clamp(0.0, double.infinity);
      return Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(height: chartH, child: Stack(children: [
          for (int i = 0; i <= 5; i++)
            Positioned(left: nameW + (barW * i / 5), top: 0, bottom: 0, child: Container(width: 1.5, color: theme.grid)),
          if (passMark > 0 && passMark < maxScore)
            Positioned(left: nameW + (barW * passMark / maxScore), top: 0, bottom: 0, child: CustomPaint(size: Size(2.5, chartH), painter: _DashedLinePainter(color: theme.fail))),
          for (int i = 0; i < display.length; i++) ..._barRow(display[i], i, nameW, barW, scoreW, maxScore, passMark, rowH, theme),
        ])),
        const SizedBox(height: 4),
        SizedBox(height: 18, child: Row(children: [
          const SizedBox(width: nameW),
          Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            for (int i = 0; i <= 5; i++) SizedBox(width: 28, child: Text((maxScore * i / 5).round().toString(), style: TextStyle(fontSize: 9, color: theme.text), textAlign: TextAlign.center)),
          ])),
        ])),
      ]);
    }));
  }

  List<Widget> _barRow(Map<String, dynamic> s, int i, double nameW, double barW, double scoreW, int maxScore, int passMark, double rowH, ChartTheme theme) {
    final subj = s['subjects'] as Map<String, dynamic>? ?? {};
    final name = (subj['name'] ?? '').toString();
    final total = (s['total'] as num?)?.toDouble() ?? 0;
    final px = (total / maxScore).clamp(0.0, 1.0) * barW;
    final pass = total >= passMark;
    final txt = total % 1 == 0 ? total.toInt().toString() : total.toStringAsFixed(1);
    return [
      if (i.isEven) Positioned(left: 0, right: 0, top: i * rowH, height: rowH, child: Container(color: const Color(0xFFFAFBFC))),
      Positioned(top: i * rowH, left: 0, right: 0, height: rowH, child: Row(children: [
        SizedBox(width: nameW, child: Align(alignment: Alignment.centerRight, child: Padding(padding: const EdgeInsets.only(right: 6), child: Text(name, style: TextStyle(fontSize: 10, color: theme.text), overflow: TextOverflow.ellipsis, maxLines: 1)))),
        SizedBox(width: barW, child: Stack(children: [
          Container(height: 18, margin: const EdgeInsets.symmetric(vertical: 7), decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(3))),
          if (px > 0) Container(height: 18, width: px, margin: const EdgeInsets.symmetric(vertical: 7), decoration: BoxDecoration(color: pass ? theme.primary : theme.fail, borderRadius: BorderRadius.circular(3))),
        ])),
        SizedBox(width: scoreW, child: Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(left: 6), child: Text(txt, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: theme.text))))),
      ])),
    ];
  }

  Widget _buildMultiTermChart() {
    final p = context.read<SchoolAdminProvider>();
    final theme = ChartTheme.fromSettings(p.schoolSettings);
    final termColors = theme.termColors;
    final subjectMap = <String, Map<String, double>>{};
    for (final entry in _scoresByTerm.entries) {
      for (final s in entry.value) {
        final subj = s['subjects'] as Map<String, dynamic>? ?? {};
        final name = (subj['name'] ?? '').toString();
        if (name.isEmpty) continue;
        subjectMap.putIfAbsent(name, () => {});
        subjectMap[name]![entry.key] = (s['total'] as num?)?.toDouble() ?? 0;
      }
    }
    final subjects = subjectMap.keys.toList()..sort();
    if (subjects.isEmpty) return const SizedBox.shrink();
    final display = subjects.take(12).toList();
    final termIds = _sessionTerms.map((t) => t['id'].toString()).toList();
    const barGroupH = 28.0, nameW = 100.0, scoreW = 44.0;
    final chartH = display.length * barGroupH;
    final termLabelList = termIds.map((id) => _termNames[id] ?? 'Term').toList();
    final title = 'REPORT CHART FOR ' + termLabelList.map((t) => t.toUpperCase()).join(', ');
    return ChartTheme.card(title: title, icon: Icons.bar_chart, subtitle: 'End of session comparison', child: LayoutBuilder(builder: (context, constraints) {
      final barAreaW = (constraints.maxWidth - nameW - scoreW - 8).clamp(0.0, double.infinity);
      final barCount = termIds.length;
      final gap = 2.0;
      final singleBarW = barCount > 0 ? ((barAreaW - gap * (barCount - 1)) / barCount).clamp(0.0, 40.0) : 0.0;
      return Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(height: chartH, child: Stack(children: [
          for (int i = 0; i <= 5; i++)
            Positioned(left: nameW + (barAreaW * i / 5), top: 0, bottom: 0, child: Container(width: 1.5, color: theme.grid)),
          for (int i = 0; i < display.length; i++) ...[
            if (i.isEven) Positioned(left: 0, right: 0, top: i * barGroupH, height: barGroupH, child: Container(color: const Color(0xFFFAFBFC))),
            Positioned(top: i * barGroupH, left: 0, right: 0, height: barGroupH, child: Row(children: [
              SizedBox(width: nameW, child: Align(alignment: Alignment.centerRight, child: Padding(padding: const EdgeInsets.only(right: 6), child: Text(display[i], style: TextStyle(fontSize: 10, color: theme.text), overflow: TextOverflow.ellipsis, maxLines: 1)))),
              SizedBox(width: barAreaW, child: Row(children: [
                for (int t = 0; t < termIds.length; t++) ...[
                  if (t > 0) SizedBox(width: gap),
                  Container(width: singleBarW, height: 16, margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(color: (subjectMap[display[i]]?[termIds[t]] ?? 0) > 0 ? termColors[t % termColors.length] : const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(2))),
                ],
              ])),
              SizedBox(width: scoreW, child: Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(left: 6), child: Text(_avgOfTerm(subjectMap[display[i]] ?? {}, termIds).toStringAsFixed(0), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: theme.text))))),
            ])),
          ],
        ])),
        const SizedBox(height: 4),
        SizedBox(height: 18, child: Row(children: [
          const SizedBox(width: nameW),
          Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            for (int i = 0; i <= 5; i++) SizedBox(width: 28, child: Text((i * 20).toString(), style: TextStyle(fontSize: 9, color: theme.text), textAlign: TextAlign.center)),
          ])),
        ])),
        const SizedBox(height: 8),
        Wrap(spacing: 16, runSpacing: 4, children: [
          for (int t = 0; t < termIds.length; t++)
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: termColors[t % termColors.length], borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 4),
              Text(termLabelList[t], style: TextStyle(fontSize: 11, color: theme.text, fontWeight: FontWeight.w500)),
            ]),
        ]),
      ]);
    }));
  }

  double _avgOfTerm(Map<String, double> map, List<String> termIds) {
    double sum = 0; int count = 0;
    for (final tid in termIds) {
      if (map.containsKey(tid) && map[tid]! > 0) { sum += map[tid]!; count++; }
    }
    return count > 0 ? sum / count : 0;
  }

  Widget _buildTermPieChart() {
    final p = context.read<SchoolAdminProvider>();
    final theme = ChartTheme.fromSettings(p.schoolSettings);
    final termColors = theme.termColors;
    final termTotals = <String, double>{};
    for (final entry in _scoresByTerm.entries) {
      double sum = 0;
      for (final s in entry.value) { sum += (s['total'] as num?)?.toDouble() ?? 0; }
      if (sum > 0) termTotals[entry.key] = sum;
    }
    if (termTotals.length < 2) return const SizedBox.shrink();
    final termIds = termTotals.keys.toList();
    final grandTotal = termTotals.values.fold(0.0, (a, b) => a + b);
    final termLabelList = termIds.map((id) => _termNames[id] ?? 'Term').toList();
    return ChartTheme.card(
      title: 'PIE CHART FOR ' + termLabelList.map((t) => t.toUpperCase()).join(', '),
      icon: Icons.pie_chart,
      subtitle: 'End of ' + termLabelList.last + ' Summary Chart',
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: 150, height: 150, child: PieChart(PieChartData(
          sections: [
            for (int i = 0; i < termIds.length; i++)
              PieChartSectionData(
                value: termTotals[termIds[i]],
                color: termColors[i % termColors.length],
                title: grandTotal > 0 ? (termTotals[termIds[i]]! / grandTotal * 100).toStringAsFixed(0) + '%' : '',
                titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                titlePositionPercentageOffset: 0.5,
                borderSide: const BorderSide(width: 3, color: Colors.white),
              ),
          ],
          sectionsSpace: 0, centerSpaceRadius: 0,
        ))),
        const SizedBox(height: 12),
        for (int i = 0; i < termIds.length; i++)
          Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 14, height: 14, decoration: BoxDecoration(color: termColors[i % termColors.length], borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 6),
            Text(termLabelList[i] + ': ' + termTotals[termIds[i]]!.toStringAsFixed(0) + ' (' + (termTotals[termIds[i]]! / grandTotal * 100).toStringAsFixed(0) + '%)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.text)),
          ])),
      ]),
    );
  }
}

class _ScoreColumn {
  final String key;
  final String label;
  final String maxScore;
  final bool hasData;
  _ScoreColumn({required this.key, required this.label, required this.maxScore, this.hasData = true});
}

class _CItem {
  final String label, text;
  final IconData icon;
  _CItem(this.label, this.text, this.icon);
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 2.5..style = PaintingStyle.stroke;
    double y = 0;
    while (y < size.height) { canvas.drawLine(Offset(0, y), Offset(0, y + 6), paint); y += 10; }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

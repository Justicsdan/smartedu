import 'dart:async';
import 'dart:convert';
// ==========================================
// File: lib/features/dashboard/student/pages/student_results_page.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:smartedu/core/providers/student/student_provider.dart';
import 'package:smartedu/utils/grading_utils.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../utils/pdf_download_utils.dart';
import '../widgets/student_performance_trend_chart.dart';
import '../widgets/student_subject_radar_chart.dart';

class StudentResultsPage extends StatefulWidget {
  const StudentResultsPage({super.key});

  @override
  State<StudentResultsPage> createState() => _StudentResultsPageState();
}

class _StudentResultsPageState extends State<StudentResultsPage> {
  bool _isGeneratingPdf = false;
  Map<String, dynamic>? _termComment;
  Map<String, String>? _behavioralRatings;
  bool _commentsLoaded = false;

  static const List<String> _bKeys = [
    'punctuality', 'relationship_with_others', 'attendance_in_class', 'games_sports',
    'attentiveness_in_class', 'handling_tools_lab_workshops', 'carrying_out_assignments',
    'participation_in_school_activities', 'neatness', 'honesty', 'self_control',
  ];



  @override
  void initState() {
    super.initState();
    _loadCommentsAndRatings();
  }

  Future<void> _loadCommentsAndRatings() async {
    try {
      final provider = context.read<StudentProvider>();
      if (provider.currentSessionId == null || provider.currentTermId == null) {
        if (mounted) setState(() => _commentsLoaded = true);
        return;
      }
      final sid = provider.schoolId;
      final stid = provider.studentId;
      final sesid = provider.currentSessionId!;
      final tid = provider.currentTermId!;

      final results = await Future.wait([
        Supabase.instance.client
            .from('term_comments')
            .select()
            .eq('school_id', sid)
            .eq('student_id', stid)
            .eq('session_id', sesid)
            .eq('term_id', tid)
            .maybeSingle(),
        Supabase.instance.client
            .from('student_behavioural_ratings')
            .select()
            .eq('school_id', sid)
            .eq('student_id', stid)
            .eq('session_id', sesid)
            .eq('term_id', tid)
            .maybeSingle(),
      ]);

      final comment = results[0] != null ? Map<String, dynamic>.from(results[0] as Map) : null;
      final rating = results[1] != null ? Map<String, dynamic>.from(results[1] as Map) : null;

      Map<String, String>? ratings;
      if (rating != null) {
        ratings = {};
        for (final key in _bKeys) {
          final val = (rating[key] ?? '').toString().trim();
          if (val.isNotEmpty) ratings[key] = val;
        }
        if (ratings.isEmpty) ratings = null;
      }

      if (mounted) {
        setState(() {
          _termComment = comment;
          _behavioralRatings = ratings;
          _commentsLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading comments/ratings: $e');
      if (mounted) setState(() => _commentsLoaded = true);
    }
  }

  String _ordinal(int? n) {
    if (n == null || n <= 0) return '';
    final remainder = n % 100;
    if (remainder >= 11 && remainder <= 13) return '${n}th';
    switch (n % 10) {
      case 1: return '${n}st';
      case 2: return '${n}nd';
      case 3: return '${n}rd';
      default: return '${n}th';
    }
  }

  Future<pw.ImageProvider?> _fetchImage(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) return pw.MemoryImage(response.bodyBytes);
    } catch (e) {
      debugPrint('PDF IMG error: $e');
    }
    return null;
  }


  PdfColor _hexToPdf(String hex) {
    final h = hex.replaceAll('#', '');
    if (h.length == 6) {
      return PdfColor.fromInt(int.parse('FF$h', radix: 16));
    }
    return PdfColors.black;
  }

  // ═══════════════════════════════════════════
  //  PDF HELPER METHODS — Classic Design
  // ═══════════════════════════════════════════

  static pw.Widget _pdfHdr(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white), textAlign: pw.TextAlign.center),
    );
  }

  static pw.Widget _pdfCell(String text, {pw.TextAlign align = pw.TextAlign.left, pw.FontWeight? weight, PdfColor? color}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 8, fontWeight: weight, color: color ?? PdfColors.black), textAlign: align),
    );
  }

  static pw.TableRow _pdfInfoRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          color: PdfColor(0.91, 0.93, 0.97),
          child: pw.Text(label, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: pw.Text(value, style: pw.TextStyle(fontSize: 8)),
        ),
      ],
    );
  }

  static pw.TableRow _pdfQuadRow(String l1, String v1, String l2, String v2, {PdfColor? v1Color, PdfColor? v2Color}) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
          color: PdfColor(0.91, 0.93, 0.97),
          child: pw.Text(l1, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
          child: pw.Text(v1, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: v1Color ?? PdfColors.black), textAlign: pw.TextAlign.center),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
          color: PdfColor(0.91, 0.93, 0.97),
          child: pw.Text(l2, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
          child: pw.Text(v2, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: v2Color ?? PdfColors.black), textAlign: pw.TextAlign.center),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  //  PDF GENERATION — Classic Layout
  // ═══════════════════════════════════════════
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

  Future<void> _printResult() async {
    final provider = context.read<StudentProvider>();
    final scores = provider.myScoresFlat;
    if (scores.isEmpty) return;

    setState(() => _isGeneratingPdf = true);
    try {
      final gradingSystem = provider.gradingSystem.isNotEmpty
          ? provider.gradingSystem
          : GradingUtils.getDefaultGradingSystem(provider.examTemplate);
      final assessmentTypes = provider.assessmentTypes.isNotEmpty
          ? provider.assessmentTypes
          : GradingUtils.getDefaultAssessmentTypes(provider.examTemplate);
      final passMark = provider.passMark;
      final average = provider.getOverallAverage();
      final overallGradeInfo = GradingUtils.getGradeFromSystem(average, gradingSystem);
      final passed = scores.where((s) => (s['total'] ?? 0) >= passMark).length;
      final failed = scores.length - passed;
      final totalScore = scores.fold<double>(0, (sum, s) => sum + ((s['total'] ?? 0) as num).toDouble());
      final totalStr = totalScore == totalScore.roundToDouble() ? totalScore.toInt().toString() : totalScore.toStringAsFixed(1);

            String _logoUrl = provider.schoolLogoUrl;
      if (_logoUrl.isEmpty) {
        try {
          final _r = await http.get(Uri.parse('https://tcjsmkhmfjigutfhjtem.supabase.co/rest/v1/schools?select=logo_url&id=eq.' + provider.schoolId), headers: {'apikey': 'sb_publishable_zWDvjhEldcV8eutnlRypGA_LGpOUhkg'});
          if (_r.statusCode == 200) { final list = jsonDecode(_r.body) as List; if (list.isNotEmpty) _logoUrl = (list[0]['logo_url'] ?? '').toString(); }
        } catch (_) {}
      }
      final logoImg = await _fetchImage(_logoUrl);

      final passportImg = await _fetchImage(provider.passportUrl);
      final sigImg = await _fetchImage(provider.principalSignatureUrl);
      final stampImg = await _fetchImage(provider.schoolStampUrl);

      final pdf = pw.Document(theme: pw.ThemeData.withFont(base: pw.Font.helvetica()));

      // ─── Build score table rows ───
      final scoreRows = <pw.TableRow>[];
      scoreRows.add(
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue800),
          children: [
            _pdfHdr('S/N'),
            _pdfHdr('Subject'),
            ...assessmentTypes.map((at) => _pdfHdr('${at['name']}\n(${at['max']})')),
            _pdfHdr('Total'),
            _pdfHdr('Grade'),
            _pdfHdr('Remark'),
          ],
        ),
      );
      for (int i = 0; i < scores.length; i++) {
        final score = scores[i];
        final idx = i + 1;
        final total = (score['total'] ?? 0).toDouble();
        final isPass = total >= passMark;
        final gradeInfo = GradingUtils.getGradeFromSystem(total, gradingSystem);
        final scoresJson = score['scores_json'] as Map<String, dynamic>? ?? {};
        final rowColor = idx.isEven ? PdfColors.white : PdfColor(0.95, 0.97, 1.0);
        final txtColor = isPass ? PdfColors.green800 : PdfColors.red800;

        scoreRows.add(
          pw.TableRow(
            decoration: pw.BoxDecoration(color: rowColor),
            children: [
              _pdfCell('$idx', align: pw.TextAlign.center),
              _pdfCell(score['subject_name'] ?? '', weight: pw.FontWeight.bold),
              ...assessmentTypes.map((at) {
                final aid = (at['id'] ?? '').toString().toLowerCase();
                final val = scoresJson[aid] ?? 0;
                return _pdfCell(val is int ? '$val' : val.toString(), align: pw.TextAlign.center);
              }),
              _pdfCell(
                total == total.roundToDouble() ? total.toInt().toString() : total.toStringAsFixed(1),
                align: pw.TextAlign.center, weight: pw.FontWeight.bold, color: txtColor,
              ),
              _pdfCell(
                gradeInfo['grade'] as String? ?? '',
                align: pw.TextAlign.center, weight: pw.FontWeight.bold, color: txtColor,
              ),
              _pdfCell(gradeInfo['remark'] as String? ?? '', align: pw.TextAlign.center),
            ],
          ),
        );
      }

      // ─── Build grading key rows ───
      final gkRows = <pw.TableRow>[];
      gkRows.add(
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue800),
          children: [_pdfHdr('Grade'), _pdfHdr('Score Range'), _pdfHdr('Remark')],
        ),
      );
      for (int i = 0; i < gradingSystem.length; i++) {
        final g = gradingSystem[i];
        final grade = (g['grade'] ?? '').toString();
        final isFail = !GradingUtils.isPassingGrade(grade, gradingSystem);
        final rowColor = i.isEven ? PdfColors.white : PdfColor(0.95, 0.97, 1.0);
        final textColor = isFail ? PdfColors.red800 : PdfColors.black;
        gkRows.add(
          pw.TableRow(
            decoration: pw.BoxDecoration(color: rowColor),
            children: [
              _pdfCell(grade, align: pw.TextAlign.center, weight: pw.FontWeight.bold, color: textColor),
              _pdfCell('${g['min']} - ${g['max']}', align: pw.TextAlign.center),
              _pdfCell((g['remark'] ?? '').toString(), color: textColor),
            ],
          ),
        );
      }

      // ─── Build behavioral rating rows ───
      List<pw.TableRow> behavRows = [];
      if (_behavioralRatings != null && _behavioralRatings!.isNotEmpty) {
        behavRows.add(
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.blue800),
            children: [_pdfHdr('BEHAVIORAL TRAIT'), _pdfHdr('RATING')],
          ),
        );
        for (int i = 0; i < _bKeys.length; i++) {
          final key = _bKeys[i];
          final label = GradingUtils.getBehavioralFieldLabel(key, customLabels: provider.behavioralLabels);
          final value = _behavioralRatings?[key] ?? '';
          final rowColor = i.isEven ? PdfColors.white : PdfColor(0.95, 0.97, 1.0);
          behavRows.add(
            pw.TableRow(
              decoration: pw.BoxDecoration(color: rowColor),
              children: [
                _pdfCell(label),
                _pdfCell(
                  value.isEmpty ? '-' : value,
                  align: pw.TextAlign.center,
                  weight: value.isEmpty ? null : pw.FontWeight.bold,
                  color: value.isEmpty ? PdfColors.grey400 : PdfColors.blue800,
                ),
              ],
            ),
          );
        }
      }

      // ─── Build comment rows ───
      List<pw.TableRow> commentRows = [];
      if (_termComment != null) {
        final tc = (_termComment!['teacher_comment'] ?? '').toString();
        final pc = (_termComment!['principal_comment'] ?? '').toString();
        if (tc.isNotEmpty || pc.isNotEmpty) {
          commentRows.add(
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blue800),
              children: [_pdfHdr('COMMENTS')],
            ),
          );
          if (tc.isNotEmpty) {
            commentRows.add(pw.TableRow(children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text("Class Teacher's Comment:", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                  pw.SizedBox(height: 2),
                  pw.Text(tc, style: pw.TextStyle(fontSize: 8)),
                ]),
              ),
            ]));
          }
          if (pc.isNotEmpty) {
            commentRows.add(pw.TableRow(children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text("Principal's Comment:", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                  pw.SizedBox(height: 2),
                  pw.Text(pc, style: pw.TextStyle(fontSize: 8)),
                ]),
              ),
            ]));
          }
        }
      }

      // ══════════════════════════════════════
      //  ASSEMBLE PAGE
      // ══════════════════════════════════════

      pdf.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(30), buildForeground: (context) => _watermark(logoImg, provider.schoolName)),
          build: (context) {
            final pageWidgets = <pw.Widget>[];

            // ── 1. SCHOOL HEADER ──
            pageWidgets.add(
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      mainAxisSize: pw.MainAxisSize.min,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(provider.schoolName.toUpperCase(), style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                        if (provider.schoolAddress.isNotEmpty)
                          pw.Text(provider.schoolAddress, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        if (provider.schoolMotto.isNotEmpty)
                          pw.Text('"${provider.schoolMotto}"', style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600)),
                        if (provider.schoolPhone.isNotEmpty || provider.schoolEmail.isNotEmpty)
                          pw.Text(
                            [if (provider.schoolPhone.isNotEmpty) 'Tel: ${provider.schoolPhone}', if (provider.schoolEmail.isNotEmpty) 'Email: ${provider.schoolEmail}'].join('  |  '),
                            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                          ),
                      ],
                    ),
                  ),
                  if (logoImg != null)
                    pw.Container(width: 85, height: 85, child: pw.Image(logoImg, fit: pw.BoxFit.contain))
                  else
                    pw.SizedBox(width: 85, height: 85),
                ],
              ),
            );

            pageWidgets.add(pw.SizedBox(height: 6));
            pageWidgets.add(pw.Container(height: 1.5, color: PdfColors.blue800));
            pageWidgets.add(pw.SizedBox(height: 6));

            // ── 2. RESULT TITLE ──
            pageWidgets.add(pw.Center(child: pw.Text('STUDENT RESULT SHEET', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, letterSpacing: 2, color: PdfColors.blue800))));

            pageWidgets.add(pw.SizedBox(height: 4));
            pageWidgets.add(pw.Container(height: 0.5, color: PdfColors.grey400));
            pageWidgets.add(pw.SizedBox(height: 10));

            // ── 3. PASSPORT + STUDENT INFO ──
            pageWidgets.add(
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 82,
                    height: 104,
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey600, width: 1)),
                    child: passportImg != null
                        ? pw.Image(passportImg, fit: pw.BoxFit.cover)
                        : pw.Center(child: pw.Text('No Photo', style: pw.TextStyle(fontSize: 7, color: PdfColors.grey400))),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: pw.Table(
                      columnWidths: const {0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(5)},
                      border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.8),
                      children: [
                        _pdfInfoRow('Name', provider.fullName),
                        _pdfInfoRow('Admission No', provider.admissionNo),
                        _pdfInfoRow('Class', provider.classDisplay),
                        _pdfInfoRow('Session', provider.currentSessionName ?? ''),
                        _pdfInfoRow('Term', provider.currentTermName ?? ''),
                        if (provider.termPosition > 0)
                          _pdfInfoRow('Position', '${_ordinal(provider.termPosition)} out of ${provider.positionOutOf}'),
                      ],
                    ),
                  ),
                ],
              ),
            );

            pageWidgets.add(pw.SizedBox(height: 10));

            // ── 4. ACADEMIC SUMMARY + ATTENDANCE ──
            pageWidgets.add(
              pw.Table(
                columnWidths: const {0: pw.FlexColumnWidth(2.2), 1: pw.FlexColumnWidth(1.3), 2: pw.FlexColumnWidth(2.2), 3: pw.FlexColumnWidth(1.3)},
                border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.8),
                children: [
                  pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.blue800), children: [_pdfHdr('ACADEMIC SUMMARY'), _pdfHdr(''), _pdfHdr('ATTENDANCE'), _pdfHdr('')]),
                  _pdfQuadRow('Subjects Taken', '${scores.length}', 'Days Present', '${provider.daysPresent}', v2Color: PdfColors.blue800),
                  _pdfQuadRow('Total Score', totalStr, 'Days Absent', '${provider.daysAbsent}', v2Color: provider.daysAbsent > 0 ? PdfColors.red800 : PdfColors.green800),
                  _pdfQuadRow('Average', average.toStringAsFixed(1), '', ''),
                  _pdfQuadRow('Grade', overallGradeInfo['grade'] as String? ?? '', '', ''),
                  _pdfQuadRow('Passed', '$passed', '', '', v1Color: PdfColors.green800),
                  _pdfQuadRow('Failed', '$failed', '', '', v1Color: failed > 0 ? PdfColors.red800 : PdfColors.green800),
                ],
              ),
            );

            pageWidgets.add(pw.SizedBox(height: 10));

            // ── 5. SCORES TABLE ──
            pageWidgets.add(
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.8),
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.7),
                  1: const pw.FlexColumnWidth(3.2),
                  ...Map.fromEntries(assessmentTypes.asMap().entries.map((e) => MapEntry(e.key + 2, const pw.FlexColumnWidth(1.3)))),
                  (assessmentTypes.length + 2): const pw.FlexColumnWidth(1.0),
                  (assessmentTypes.length + 3): const pw.FlexColumnWidth(0.9),
                  (assessmentTypes.length + 4): const pw.FlexColumnWidth(1.9),
                },
                children: scoreRows,
              ),
            );

            pageWidgets.add(pw.SizedBox(height: 10));

            // ── 6. GRADING KEY ──
            pageWidgets.add(
              pw.Table(
                columnWidths: const {0: pw.FlexColumnWidth(1.2), 1: pw.FlexColumnWidth(1.5), 2: pw.FlexColumnWidth(3.5)},
                border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.8),
                children: gkRows,
              ),
            );

            // ── 7. BEHAVIORAL RATINGS ──
            if (behavRows.isNotEmpty) {
              pageWidgets.add(pw.SizedBox(height: 10));
              pageWidgets.add(pw.Table(columnWidths: const {0: pw.FlexColumnWidth(4), 1: pw.FlexColumnWidth(2)}, border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.8), children: behavRows));
            }

            // ── 8. COMMENTS ──
            if (commentRows.isNotEmpty) {
              pageWidgets.add(pw.SizedBox(height: 10));
              pageWidgets.add(pw.Table(columnWidths: const {0: pw.FlexColumnWidth(6)}, border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.8), children: commentRows));
            }

            pageWidgets.add(pw.SizedBox(height: 28));

            // ── 9. SIGNATURES ──
            pageWidgets.add(
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(children: [pw.Text('Class Teacher', style: pw.TextStyle(fontSize: 9)), pw.SizedBox(height: 30), pw.Container(width: 130, height: 1, color: PdfColors.grey600)]),
                  if (stampImg != null) pw.Container(width: 80, height: 80, child: pw.Image(stampImg, fit: pw.BoxFit.contain)),
                  pw.Column(children: [
                    pw.Text('Principal', style: pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 30),
                    pw.Container(width: 130, height: 1, color: PdfColors.grey600),
                    if (sigImg != null) ...[pw.SizedBox(height: 2), pw.Container(width: 80, height: 30, child: pw.Image(sigImg, fit: pw.BoxFit.contain))],
                  ]),
                ],
              ),
            );

            pageWidgets.add(pw.SizedBox(height: 12));
            pageWidgets.add(pw.Center(child: pw.Text('Generated on ${DateTime.now().toString().split('.').first}', style: pw.TextStyle(fontSize: 7, color: PdfColors.grey500))));

            return pageWidgets;
          },
        ),
      );

      final bytes = await pdf.save();
      downloadPdfBytes(bytes, '${provider.fullName}_${provider.currentTermName ?? "result"}.pdf');
    } catch (e) {
      debugPrint('PDF generation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to generate PDF: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  // ═══════════════════════════════════════════
  //  FLUTTER UI BUILD
  // ═══════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();
    final scores = provider.scores;
    final gradingSystem = provider.gradingSystem.isNotEmpty
        ? provider.gradingSystem
        : GradingUtils.getDefaultGradingSystem(provider.examTemplate);
    final assessmentTypes = provider.assessmentTypes.isNotEmpty
        ? provider.assessmentTypes
        : GradingUtils.getDefaultAssessmentTypes(provider.examTemplate);
    final passMark = provider.passMark;

    final average = provider.getOverallAverage();
    final passed = scores.where((s) => (s['total'] ?? 0) >= passMark).length;
    final failed = scores.length - passed;
    final totalScore = scores.fold<double>(0, (sum, s) => sum + ((s['total'] ?? 0) as num).toDouble());
    final overallGradeInfo = GradingUtils.getGradeFromSystem(average, gradingSystem);

    // ── Design tokens ──
    const navy = Color(0xFF1A237E);
    const passClr = Color(0xFF2E7D32);
    const failClr = Color(0xFFD32F2F);
    const hdrFs = 12.0; // header font size
    const cellFs = 13.0; // data font size

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title bar ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("My Results", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827), letterSpacing: -0.5)),
              if (scores.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: navy.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: navy.withOpacity(0.2))),
                  child: Text(provider.currentTermName ?? '', style: const TextStyle(fontSize: 13, color: navy, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isGeneratingPdf ? null : _printResult,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: _isGeneratingPdf ? Colors.grey.shade300 : navy, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isGeneratingPdf)
                          const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        else
                          const Icon(Icons.download_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text(_isGeneratingPdf ? 'Preparing...' : 'Print Result', style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (provider.currentSessionName != null) ...[
            const SizedBox(height: 4),
            Text('${provider.currentSessionName} \u2014 ${provider.classDisplay}', style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
          ],
          const SizedBox(height: 20),

          // ── Stat cards ──
          Row(
            children: [
              _StatCard(title: "Subjects", value: "${scores.length}", color: const Color(0xFF1565C0), icon: Icons.menu_book),
              const SizedBox(width: 12),
              _StatCard(title: "Average", value: average.toStringAsFixed(1), color: const Color(0xFF2E7D32), icon: Icons.trending_up),
              const SizedBox(width: 12),
              _StatCard(title: "Grade", value: overallGradeInfo['grade'] as String? ?? '', color: const Color(0xFF00897B), icon: Icons.grade),
              const SizedBox(width: 12),
              _StatCard(title: "Passed", value: "$passed", color: const Color(0xFF2E7D32), icon: Icons.check_circle),
              const SizedBox(width: 12),
              _StatCard(title: "Failed", value: "$failed", color: failed > 0 ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32), icon: Icons.cancel),
            ],
          ),
          if (provider.termPosition > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: navy.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: navy.withOpacity(0.15))),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: navy, size: 22),
                  const SizedBox(width: 12),
                  const Text('Position in Class: ', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                  Text('${_ordinal(provider.termPosition)} out of ${provider.positionOutOf}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: navy)),
                  const Spacer(),
                  Text('Total: $totalScore', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: navy)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),

          // ── Empty state ──
          if (scores.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(60),
                child: Column(children: [
                  Icon(Icons.bar_chart, size: 80, color: Color(0xFFD1D5DB)),
                  SizedBox(height: 16),
                  Text("No results available", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                  SizedBox(height: 8),
                  Text("Results will appear here once your teacher publishes them", style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
                ]),
              ),
            )

          // ── Scores table ──
          else ...[
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
              child: DataTable(
                columnSpacing: 8,
                headingRowColor: WidgetStateProperty.all(navy),
                horizontalMargin: 16,
                headingRowHeight: 56,
                dataRowMinHeight: 48,
                dataRowMaxHeight: 56,
                columns: [
                  // Subject — left-aligned label column
                  const DataColumn(
                    label: SizedBox(height: 56, child: Center(child: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: hdrFs)))),
                    columnWidth: FlexColumnWidth(2.0),
                  ),
                  // Assessment columns — equal width, centered
                  ...assessmentTypes.map((at) => DataColumn(
                    label: SizedBox(height: 56, child: Center(child: Text('${at['name']}\n(${at['max']})', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: hdrFs)))),
                    columnWidth: const FlexColumnWidth(1.3),
                  )),
                  // Total
                  const DataColumn(
                    label: SizedBox(height: 56, child: Center(child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: hdrFs)))),
                    columnWidth: FlexColumnWidth(0.7),
                  ),
                  // Grade
                  const DataColumn(
                    label: SizedBox(height: 56, child: Center(child: Text('Grade', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: hdrFs)))),
                    columnWidth: FlexColumnWidth(0.7),
                  ),
                  // Remark
                  const DataColumn(
                    label: SizedBox(height: 56, child: Center(child: Text('Remark', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: hdrFs)))),
                    columnWidth: FlexColumnWidth(1.2),
                  ),
                ],
                rows: scores.map((score) {
                  final total = (score['total'] ?? 0).toDouble();
                  final isPass = total >= passMark;
                  final gradeInfo = GradingUtils.getGradeFromSystem(total, gradingSystem);
                  final grade = gradeInfo['grade'] as String? ?? '';
                  final remark = gradeInfo['remark'] as String? ?? '';
                  final scoresJson = score['scores_json'] as Map<String, dynamic>? ?? {};
                  final clr = isPass ? passClr : failClr;
                  final totalStr = total == total.roundToDouble() ? total.toInt().toString() : total.toStringAsFixed(1);
                  return DataRow(
                    color: WidgetStateProperty.all(scores.indexOf(score).isEven ? Colors.white : const Color(0xFFFAFBFC)),
                    cells: [
                      // Subject — left-aligned
                      DataCell(Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(score['subject_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF111827), fontSize: cellFs)),
                      )),
                      // Assessment scores — centered
                      ...assessmentTypes.map((at) {
                        final aid = (at['id'] ?? '').toString().toLowerCase();
                        final val = scoresJson[aid] ?? 0;
                        final display = val is int ? '$val' : val.toString();
                        return DataCell(Center(child: Text(display, style: const TextStyle(color: Color(0xFF111827), fontSize: cellFs))));
                      }),
                      // Total — centered, bold
                      DataCell(Center(child: Text(totalStr, style: TextStyle(fontWeight: FontWeight.bold, fontSize: cellFs, color: clr)))),
                      // Grade — centered, bold
                      DataCell(Center(child: Text(grade, style: TextStyle(fontWeight: FontWeight.bold, fontSize: cellFs, color: clr)))),
                      // Remark — centered
                      DataCell(Center(child: Text(remark, style: TextStyle(fontSize: cellFs, color: clr)))),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            const StudentPerformanceTrendChart(),
            const SizedBox(height: 16),
            const StudentSubjectRadarChart(),
            const SizedBox(height: 24),
            if (_behavioralRatings != null && _behavioralRatings!.isNotEmpty) _buildBehavioralSection(),
            const SizedBox(height: 16),
            if (_termComment != null) _buildCommentsSection(_termComment!),
            const SizedBox(height: 16),
            _buildGradingKey(gradingSystem),
          ],
        ],
      ),
    );
  }

  Widget _buildBehavioralSection() {
    final provider = context.read<StudentProvider>();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [Icon(Icons.psychology, color: Color(0xFF1A237E), size: 20), SizedBox(width: 8), Text('Behavioral Ratings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)))]),
          const SizedBox(height: 16),
          ...List.generate((_bKeys.length / 2).ceil(), (rowIdx) {
            final startIdx = rowIdx * 2;
            final endIdx = (startIdx + 2).clamp(0, _bKeys.length);
            final rowItems = List.generate(endIdx - startIdx, (i) {
              final idx = startIdx + i;
              final key = _bKeys[idx];
              final label = GradingUtils.getBehavioralFieldLabel(key, customLabels: provider.behavioralLabels);
              final value = _behavioralRatings?[key] ?? '';
              if (value.isEmpty) return const SizedBox.shrink();
              final color = _getBehavioralColor(value);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == 0 ? 8 : 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.25))),
                    child: Row(
                      children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))), const SizedBox(height: 3), Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color))])),
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      ],
                    ),
                  ),
                ),
              );
            });
            return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: rowItems));
          }),
        ],
      ),
    );
  }


  Color _getBehavioralColor(String rating) {
    switch (rating.toLowerCase()) {
      case 'excellent': return const Color(0xFF2E7D32);
      case 'very good': return const Color(0xFF1565C0);
      case 'good': return const Color(0xFF00897B);
      case 'fair': return const Color(0xFFE65100);
      case 'poor': return const Color(0xFFC62828);
      default: return const Color(0xFF6B7280);
    }
  }

  Widget _buildCommentsSection(Map<String, dynamic> comment) {
    final tc = (comment['teacher_comment'] ?? '').toString();
    final pc = (comment['principal_comment'] ?? '').toString();
    if (tc.isEmpty && pc.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [Icon(Icons.comment, color: Color(0xFF1A237E), size: 20), SizedBox(width: 8), Text('Comments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)))]),
          const SizedBox(height: 16),
          if (tc.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFBFDBFE))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [Icon(Icons.person_outline, size: 16, color: Color(0xFF1565C0)), SizedBox(width: 6), Text('Class Teacher', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1565C0)))]),
                const SizedBox(height: 8),
                Text(tc, style: const TextStyle(fontSize: 14, color: Color(0xFF1B2A4A), height: 1.4)),
              ]),
            ),
          if (tc.isNotEmpty && pc.isNotEmpty) const SizedBox(height: 12),
          if (pc.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFBBF7D0))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [Icon(Icons.school, size: 16, color: Color(0xFF2E7D32)), SizedBox(width: 6), Text('Principal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)))]),
                const SizedBox(height: 8),
                Text(pc, style: const TextStyle(fontSize: 14, color: Color(0xFF1B2A4A), height: 1.4)),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _buildGradingKey(List<Map<String, dynamic>> gradingSystem) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [Icon(Icons.info_outline, color: Color(0xFF1A237E), size: 20), SizedBox(width: 8), Text('Grading Key', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)))]),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: gradingSystem.map((g) {
                final grade = (g['grade'] ?? '').toString();
                final min = g['min'] ?? 0;
                final max = g['max'] ?? 0;
                final remark = (g['remark'] ?? '').toString();
                final isFail = !GradingUtils.isPassingGrade(grade, gradingSystem);
                final bgColor = isFail ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4);
                final borderColor = isFail ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0);
                final textColor = isFail ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32);
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: borderColor)),
                  child: Column(children: [Text(grade, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)), const SizedBox(height: 2), Text('$min-$max', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))), Text(remark, style: TextStyle(fontSize: 10, color: textColor))]),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({required this.title, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.15))),
        child: Column(children: [Icon(icon, color: color, size: 20), const SizedBox(height: 4), Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)), const SizedBox(height: 2), Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)))]),
      ),
    );
  }
}

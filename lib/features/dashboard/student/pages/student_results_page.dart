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
import 'package:printing/printing.dart';

class StudentResultsPage extends StatefulWidget {
  const StudentResultsPage({super.key});

  @override
  State<StudentResultsPage> createState() => _StudentResultsPageState();
}

class _StudentResultsPageState extends State<StudentResultsPage> {
  bool _isGeneratingPdf = false;
  Map<String, dynamic>? _termComment;
  bool _commentsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadTermComments();
  }

  Future<void> _loadTermComments() async {
    try {
      final provider = context.read<StudentProvider>();
      if (provider.currentSessionId == null || provider.currentTermId == null) return;
      final r = await Supabase.instance.client
          .from('term_comments')
          .select()
          .eq('school_id', provider.schoolId)
          .eq('student_id', provider.studentId)
          .eq('session_id', provider.currentSessionId!)
          .eq('term_id', provider.currentTermId!)
          .maybeSingle();
      if (mounted) setState(() {
        _termComment = r != null ? Map<String, dynamic>.from(r) : null;
        _commentsLoaded = true;
      });
    } catch (e) {
      debugPrint('Error loading term comments: $e');
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
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        return pw.MemoryImage(res.bodyBytes);
      }
    } catch (e) {
      debugPrint('Image fetch error: $e');
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
      final passThreshold = GradingUtils.getPassingThreshold(gradingSystem);
      final average = provider.getOverallAverage();
      final overallGradeInfo = GradingUtils.getGradeFromSystem(average, gradingSystem);
      final passed = scores.where((s) => (s['total'] ?? 0) >= passThreshold).length;
      final failed = scores.length - passed;
      final totalScore = scores.fold<double>(0, (sum, s) => sum + ((s['total'] ?? 0) as num).toDouble());

      final logoImg = await _fetchImage(provider.schoolLogoUrl);
      final passportImg = await _fetchImage(provider.passportUrl);
      final sigImg = await _fetchImage(provider.principalSignatureUrl);
      final stampImg = await _fetchImage(provider.schoolStampUrl);

      final headerColor = _hexToPdf(provider.headerBgColor);
      final headerTextColor = _hexToPdf(provider.headerTextColor);

      final pdf = pw.Document(theme: pw.ThemeData.withFont(base: pw.Font.helvetica()));

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 24),
          build: (context) => [
            // SCHOOL HEADER
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 12),
              decoration: pw.BoxDecoration(
                color: headerColor,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logoImg != null)
                    pw.Container(
                      width: 60,
                      height: 60,
                      margin: const pw.EdgeInsets.only(left: 16, right: 12),
                      child: pw.Image(logoImg, fit: pw.BoxFit.contain),
                    ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          provider.schoolName.toUpperCase(),
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: headerTextColor),
                        ),
                        if (provider.schoolAddress.isNotEmpty)
                          pw.Text(
                            provider.schoolAddress,
                            style: pw.TextStyle(fontSize: 8, color: PdfColor(1, 1, 1, 0.8)),
                          ),
                        if (provider.schoolMotto.isNotEmpty)
                          pw.Text(
                            '"${provider.schoolMotto}"',
                            style: pw.TextStyle(fontSize: 7, fontStyle: pw.FontStyle.italic, color: PdfColor(1, 1, 1, 0.7)),
                          ),
                        if (provider.schoolPhone.isNotEmpty || provider.schoolEmail.isNotEmpty)
                          pw.Text(
                            [if (provider.schoolPhone.isNotEmpty) 'Tel: ${provider.schoolPhone}', if (provider.schoolEmail.isNotEmpty) 'Email: ${provider.schoolEmail}'].join('  |  '),
                            style: pw.TextStyle(fontSize: 7, color: PdfColor(1, 1, 1, 0.7)),
                          ),
                      ],
                    ),
                  ),
                  if (logoImg != null) pw.SizedBox(width: 72),
                ],
              ),
            ),

            pw.SizedBox(height: 12),

            // RESULT TITLE
            pw.Center(
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.blue800, width: 1.5),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'STUDENT RESULT SHEET',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, letterSpacing: 2, color: PdfColors.blue800),
                ),
              ),
            ),

            pw.SizedBox(height: 10),

            // STUDENT INFO
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (passportImg != null)
                    pw.Container(
                      width: 56,
                      height: 56,
                      margin: const pw.EdgeInsets.only(right: 12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Image(passportImg, fit: pw.BoxFit.cover),
                    ),
                  pw.Expanded(
                    child: pw.Wrap(
                      spacing: 4,
                      runSpacing: 3,
                      children: [
                        _pdfInfoItem('Name:', provider.fullName),
                        _pdfInfoItem('Adm No:', provider.admissionNo),
                        _pdfInfoItem('Class:', provider.classDisplay),
                        _pdfInfoItem('Session:', provider.currentSessionName ?? ''),
                        _pdfInfoItem('Term:', provider.currentTermName ?? ''),
                        if (provider.termPosition > 0)
                          _pdfInfoItem('Position:', '${_ordinal(provider.termPosition)} out of ${provider.positionOutOf}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 10),

            // SCORES TABLE
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.2),
                1: const pw.FlexColumnWidth(3.5),
                ...Map.fromEntries(
                  assessmentTypes.asMap().entries.map((e) => MapEntry(e.key + 2, const pw.FlexColumnWidth(1.4))),
                ),
                (assessmentTypes.length + 2): const pw.FlexColumnWidth(1.2),
                (assessmentTypes.length + 3): const pw.FlexColumnWidth(1.2),
                (assessmentTypes.length + 4): const pw.FlexColumnWidth(2.0),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue800),
                  children: [
                    _pdfHeaderCell('S/N'),
                    _pdfHeaderCell('Subject'),
                    ...assessmentTypes.map((at) => _pdfHeaderCell('${at['name']}\n(${at['max']})')),
                    _pdfHeaderCell('Total'),
                    _pdfHeaderCell('Grade'),
                    _pdfHeaderCell('Remark'),
                  ],
                ),
                ...scores.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final score = entry.value;
                  final total = (score['total'] ?? 0).toDouble();
                  final isPass = total >= passThreshold;
                  final gradeInfo = GradingUtils.getGradeFromSystem(total, gradingSystem);
                  final scoresJson = score['scores_json'] as Map<String, dynamic>? ?? {};
                  final bgColor = idx.isEven ? PdfColors.white : PdfColor(0.95, 0.97, 1.0);

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: bgColor),
                    children: [
                      _pdfDataCell('$idx', align: pw.TextAlign.center),
                      _pdfDataCell(score['subject_name'] ?? '', weight: pw.FontWeight.bold),
                      ...assessmentTypes.map((at) {
                        final aid = (at['id'] ?? '').toString().toLowerCase();
                        final val = scoresJson[aid] ?? 0;
                        return _pdfDataCell(val is int ? '$val' : val.toString(), align: pw.TextAlign.center);
                      }),
                      _pdfDataCell(total == total.roundToDouble() ? total.toInt().toString() : total.toStringAsFixed(1),
                          align: pw.TextAlign.center, weight: pw.FontWeight.bold, color: isPass ? PdfColors.green800 : PdfColors.red800),
                      _pdfDataCell(gradeInfo['grade'] as String? ?? '',
                          align: pw.TextAlign.center, weight: pw.FontWeight.bold, color: isPass ? PdfColors.green800 : PdfColors.red800),
                      _pdfDataCell(gradeInfo['remark'] as String? ?? '', align: pw.TextAlign.center),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 10),

            // SUMMARY
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _pdfSummaryItem('Subjects', '${scores.length}', PdfColors.blue800),
                  _pdfSummaryItem('Total', totalScore == totalScore.roundToDouble() ? totalScore.toInt().toString() : totalScore.toStringAsFixed(1), PdfColors.blue800),
                  _pdfSummaryItem('Average', average.toStringAsFixed(1), PdfColors.blue800),
                  _pdfSummaryItem('Grade', overallGradeInfo['grade'] as String? ?? '', PdfColors.blue800),
                  _pdfSummaryItem('Passed', '$passed', PdfColors.green800),
                  _pdfSummaryItem('Failed', '$failed', failed > 0 ? PdfColors.red800 : PdfColors.green800),
                ],
              ),
            ),

            // ATTENDANCE
            if (provider.daysPresent > 0 || provider.daysAbsent > 0) ...[
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), borderRadius: pw.BorderRadius.circular(4)),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _pdfSummaryItem('Days Present', '${provider.daysPresent}', PdfColors.blue800),
                    _pdfSummaryItem('Days Absent', '${provider.daysAbsent}', provider.daysAbsent > 0 ? PdfColors.red800 : PdfColors.green800),
                  ],
                ),
              ),
            ],

            // GRADING KEY
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), borderRadius: pw.BorderRadius.circular(4)),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Grading Key', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                  pw.SizedBox(height: 4),
                  pw.Wrap(
                    spacing: 10,
                    runSpacing: 3,
                    children: gradingSystem.map((g) {
                      final grade = (g['grade'] ?? '').toString();
                      final isFail = !GradingUtils.isPassingGrade(grade, gradingSystem);
                      return pw.Text(
                        '$grade (${g['min']}-${g['max']}): ${g['remark'] ?? ''}   ',
                        style: pw.TextStyle(fontSize: 7.5, color: isFail ? PdfColors.red700 : PdfColors.black),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // COMMENTS
            if (_termComment != null) ...[
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), borderRadius: pw.BorderRadius.circular(4)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Comments', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                    pw.SizedBox(height: 6),
                    if ((_termComment!['teacher_comment'] ?? '').toString().isNotEmpty) ...[
                      pw.Text("Class Teacher's Comment:", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text((_termComment!['teacher_comment'] ?? '').toString(), style: const pw.TextStyle(fontSize: 8)),
                      pw.SizedBox(height: 6),
                    ],
                    if ((_termComment!['principal_comment'] ?? '').toString().isNotEmpty) ...[
                      pw.Text("Principal's Comment:", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text((_termComment!['principal_comment'] ?? '').toString(), style: const pw.TextStyle(fontSize: 8)),
                      pw.SizedBox(height: 6),
                    ],
                  ],
                ),
              ),

              // BEHAVIORAL
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), borderRadius: pw.BorderRadius.circular(4)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Behavioral Ratings', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                    pw.SizedBox(height: 6),
                    pw.Wrap(
                      spacing: 20,
                      runSpacing: 4,
                      children: [
                        _behavioralItem('Conduct', _termComment!['conduct']),
                        _behavioralItem('Attitude', _termComment!['attitude']),
                        _behavioralItem('Interest', _termComment!['interest']),
                        _behavioralItem('Attendance', _termComment!['attendance_remark']),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            pw.SizedBox(height: 30),

            // SIGNATURES
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  children: [
                    pw.Text('Class Teacher', style: const pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 30),
                    pw.Container(width: 130, height: 1, color: PdfColors.grey600),
                  ],
                ),
                if (stampImg != null)
                  pw.Container(width: 80, height: 80, child: pw.Image(stampImg, fit: pw.BoxFit.contain)),
                pw.Column(
                  children: [
                    pw.Text('Principal', style: const pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 30),
                    pw.Container(width: 130, height: 1, color: PdfColors.grey600),
                    if (sigImg != null) ...[
                      pw.SizedBox(height: 2),
                      pw.Container(width: 80, height: 30, child: pw.Image(sigImg, fit: pw.BoxFit.contain)),
                    ],
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 12),
            pw.Center(
              child: pw.Text(
                'Generated on ${DateTime.now().toString().split('.').first}',
                style: pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
              ),
            ),
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: '${provider.fullName}_${provider.currentTermName ?? "result"}.pdf',
      );
    } catch (e) {
      debugPrint('PDF generation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  // PDF HELPERS

  static pw.Widget _pdfInfoItem(String label, String value) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        pw.SizedBox(width: 4),
        pw.Text(value, style: const pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(width: 16),
      ],
    );
  }

  static pw.Widget _pdfHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 5),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white), textAlign: pw.TextAlign.center),
    );
  }

  static pw.Widget _pdfDataCell(String text, {pw.TextAlign align = pw.TextAlign.left, pw.FontWeight? weight, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 8, fontWeight: weight, color: color), textAlign: align),
    );
  }

  static pw.Widget _pdfSummaryItem(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: color)),
        pw.SizedBox(height: 1),
        pw.Text(label, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
      ],
    );
  }

  static pw.Widget _behavioralItem(String label, dynamic value) {
    final v = (value ?? '').toString();
    if (v.isEmpty) return pw.SizedBox.shrink();
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text('$label: ', style: const pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        pw.Text(v, style: const pw.TextStyle(fontSize: 8)),
      ],
    );
  }

  // UI BUILD

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
    final passThreshold = GradingUtils.getPassingThreshold(gradingSystem);

    final average = provider.getOverallAverage();
    final passed = scores.where((s) => (s['total'] ?? 0) >= passThreshold).length;
    final failed = scores.length - passed;
    final totalScore = scores.fold<double>(0, (sum, s) => sum + ((s['total'] ?? 0) as num).toDouble());
    final overallGradeInfo = GradingUtils.getGradeFromSystem(average, gradingSystem);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("My Results", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827), letterSpacing: -0.5)),
              if (scores.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A237E).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1A237E).withOpacity(0.2)),
                  ),
                  child: Text(provider.currentTermName ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF1A237E), fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isGeneratingPdf ? null : _printResult,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isGeneratingPdf ? Colors.grey.shade300 : const Color(0xFF1A237E),
                      borderRadius: BorderRadius.circular(8),
                    ),
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
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E).withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1A237E).withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: Color(0xFF1A237E), size: 22),
                  const SizedBox(width: 12),
                  const Text('Position in Class: ', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                  Text('${_ordinal(provider.termPosition)} out of ${provider.positionOutOf}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                  const Spacer(),
                  Text('Total: $totalScore', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A237E))),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          if (scores.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(60),
                child: Column(
                  children: [
                    Icon(Icons.bar_chart, size: 80, color: Color(0xFFD1D5DB)),
                    SizedBox(height: 16),
                    Text("No results available", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                    SizedBox(height: 8),
                    Text("Results will appear here once your teacher publishes them", style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
                  ],
                ),
              ),
            )
          else ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 12,
                  headingRowColor: WidgetStateProperty.all(const Color(0xFF1A237E)),
                  horizontalMargin: 12,
                  headingRowHeight: 48,
                  dataRowMinHeight: 44,
                  dataRowMaxHeight: 52,
                  columns: [
                    const DataColumn(label: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                    ...assessmentTypes.map((at) => DataColumn(
                      label: Text('${at['name']}\n(${at['max']})', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11), textAlign: TextAlign.center),
                      numeric: true,
                    )),
                    const DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), numeric: true),
                    const DataColumn(label: Text('Grade', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                    const DataColumn(label: Text('Remark', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                  ],
                  rows: scores.map((score) {
                    final total = (score['total'] ?? 0).toDouble();
                    final isPass = total >= passThreshold;
                    final gradeInfo = GradingUtils.getGradeFromSystem(total, gradingSystem);
                    final grade = gradeInfo['grade'] as String? ?? '';
                    final remark = gradeInfo['remark'] as String? ?? '';
                    final scoresJson = score['scores_json'] as Map<String, dynamic>? ?? {};

                    return DataRow(
                      color: WidgetStateProperty.all(scores.indexOf(score).isEven ? Colors.white : const Color(0xFFFAFBFC)),
                      cells: [
                        DataCell(Text(score['subject_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF111827)))),
                        ...assessmentTypes.map((at) {
                          final aid = (at['id'] ?? '').toString().toLowerCase();
                          final val = scoresJson[aid] ?? 0;
                          final display = val is int ? '$val' : val.toString();
                          return DataCell(Text(display, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF111827))));
                        }),
                        DataCell(Text(
                          total == total.roundToDouble() ? total.toInt().toString() : total.toStringAsFixed(1),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isPass ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F)),
                          textAlign: TextAlign.center,
                        )),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPass ? const Color(0xFFE8F5E9) : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(grade, style: TextStyle(fontWeight: FontWeight.bold, color: isPass ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F), fontSize: 13), textAlign: TextAlign.center),
                          ),
                        ),
                        DataCell(Text(remark, style: TextStyle(fontSize: 12, color: isPass ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F)))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 24),

            if (_termComment != null) _buildBehavioralSection(_termComment!),
            const SizedBox(height: 16),
            if (_termComment != null) _buildCommentsSection(_termComment!),
            const SizedBox(height: 16),
            _buildGradingKey(gradingSystem),
          ],
        ],
      ),
    );
  }

  Widget _buildBehavioralSection(Map<String, dynamic> comment) {
    final fields = [
      {'key': 'conduct', 'label': 'Conduct', 'icon': Icons.star_outline},
      {'key': 'attitude', 'label': 'Attitude', 'icon': Icons.emoji_emotions_outlined},
      {'key': 'interest', 'label': 'Interest', 'icon': Icons.lightbulb_outline},
      {'key': 'attendance_remark', 'label': 'Attendance', 'icon': Icons.schedule},
    ];
    final hasAny = fields.any((f) => (comment[f['key']] ?? '').toString().isNotEmpty);
    if (!hasAny) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology, color: Color(0xFF1A237E), size: 20),
              SizedBox(width: 8),
              Text('Behavioral Ratings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: fields.map((f) {
              final value = (comment[f['key']] ?? '').toString();
              if (value.isEmpty) return const SizedBox.shrink();
              final color = _getBehavioralColor(value);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.25))),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(f['icon'] as IconData, size: 18, color: color),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(f['label'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
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
          const Row(
            children: [
              Icon(Icons.comment, color: Color(0xFF1A237E), size: 20),
              SizedBox(width: 8),
              Text('Comments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            ],
          ),
          const SizedBox(height: 16),
          if (tc.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFBFDBFE))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [Icon(Icons.person_outline, size: 16, color: Color(0xFF1565C0)), SizedBox(width: 6), Text('Class Teacher', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1565C0)))]),
                  const SizedBox(height: 8),
                  Text(tc, style: const TextStyle(fontSize: 14, color: Color(0xFF1B2A4A), height: 1.4)),
                ],
              ),
            ),
          if (tc.isNotEmpty && pc.isNotEmpty) const SizedBox(height: 12),
          if (pc.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFBBF7D0))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [Icon(Icons.school, size: 16, color: Color(0xFF2E7D32)), SizedBox(width: 6), Text('Principal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)))]),
                  const SizedBox(height: 8),
                  Text(pc, style: const TextStyle(fontSize: 14, color: Color(0xFF1B2A4A), height: 1.4)),
                ],
              ),
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
          const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF1A237E), size: 20),
              SizedBox(width: 8),
              Text('Grading Key', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            ],
          ),
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
                  child: Column(
                    children: [
                      Text(grade, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(height: 2),
                      Text('$min-$max', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                      Text(remark, style: TextStyle(fontSize: 10, color: textColor)),
                    ],
                  ),
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
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          ],
        ),
      ),
    );
  }
}

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
      if (mounted) setState(() => _termComment = r != null ? Map<String, dynamic>.from(r) : null);
    } catch (e) {
      debugPrint('Error loading term comments: $e');
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

  Future<pw.ImageProvider?> _fetchLogo(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        return pw.MemoryImage(res.bodyBytes);
      }
    } catch (e) {
      debugPrint('Logo fetch error: $e');
    }
    return null;
  }

  Future<void> _printResult() async {
    final provider = context.read<StudentProvider>();
    if (provider.scores.isEmpty) return;

    setState(() => _isGeneratingPdf = true);
    try {
      final pdf = pw.Document(theme: pw.ThemeData.withFont(base: pw.Font.helvetica()));

      final gradingSystem = provider.gradingSystem.isNotEmpty
          ? provider.gradingSystem
          : GradingUtils.getDefaultGradingSystem(provider.examTemplate);
      final assessmentTypes = provider.assessmentTypes.isNotEmpty
          ? provider.assessmentTypes
          : GradingUtils.getDefaultAssessmentTypes(provider.examTemplate);
      final passThreshold = GradingUtils.getPassingThreshold(gradingSystem);
      final average = provider.getOverallAverage();
      final overallGradeInfo = GradingUtils.getGradeFromSystem(average, gradingSystem);
      final scores = provider.scores;
      final passed = scores.where((s) => (s['total'] ?? 0) >= passThreshold).length;
      final failed = scores.length - passed;
      final totalScore = scores.fold<double>(0, (sum, s) => sum + ((s['total'] ?? 0) as num).toDouble());

      final logoImg = await _fetchLogo(provider.schoolLogoUrl);

      final assessHeaders = assessmentTypes.map((at) => '${at['name']} (${at['max']})').toList();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          build: (context) => [
            // ── SCHOOL HEADER WITH LOGO ──
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (logoImg != null)
                  pw.Container(
                    height: 64,
                    width: 64,
                    child: pw.Image(logoImg, fit: pw.BoxFit.contain),
                  ),
                if (logoImg != null) pw.SizedBox(height: 8),
                pw.Text(
                  provider.schoolName.toUpperCase(),
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
                ),
                if (provider.schoolAddress.isNotEmpty)
                  pw.Text(
                    provider.schoolAddress,
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                if (provider.schoolMotto.isNotEmpty)
                  pw.Text(
                    '"${provider.schoolMotto}"',
                    style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColors.grey500),
                  ),
                if (provider.schoolPhone.isNotEmpty)
                  pw.Text(
                    'Tel: ${provider.schoolPhone}${provider.schoolEmail.isNotEmpty ? '  |  ${provider.schoolEmail}' : ''}',
                    style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
                  ),
              ],
            ),

            pw.SizedBox(height: 6),
            pw.Divider(color: PdfColors.blue200, thickness: 1.5),
            pw.SizedBox(height: 10),

            // ── RESULT TITLE ──
            pw.Center(
              child: pw.Text(
                'STUDENT RESULT SHEET',
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, letterSpacing: 2, color: PdfColors.blue800),
              ),
            ),
            pw.SizedBox(height: 8),

            // ── STUDENT INFO ──
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _infoRow('Name:', provider.fullName),
                  _infoRow('Admission No:', provider.admissionNo),
                  _infoRow('Class:', provider.classDisplay),
                  _infoRow('Session:', provider.currentSessionName ?? ''),
                  _infoRow('Term:', provider.currentTermName ?? ''),
                  if (provider.termPosition > 0)
                    _infoRow('Position:', '${_ordinal(provider.termPosition)} out of ${provider.positionOutOf}'),
                ],
              ),
            ),

            pw.SizedBox(height: 12),

            // ── SCORES TABLE ──
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                pw.TableRow(
                  children: [
                    _headerCell('S/N'),
                    _headerCell('Subject'),
                    ...assessHeaders.map((h) => _headerCell(h)),
                    _headerCell('Total'),
                    _headerCell('Grade'),
                    _headerCell('Remark'),
                  ],
                ),
                ...scores.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final score = entry.value;
                  final total = (score['total'] ?? 0).toDouble();
                  final isPass = total >= passThreshold;
                  final gradeInfo = GradingUtils.getGradeFromSystem(total, gradingSystem);
                  final scoresJson = score['scores_json'] as Map<String, dynamic>? ?? {};

                  return pw.TableRow(
                    children: [
                      _dataCell('$idx', align: pw.TextAlign.center),
                      _dataCell(score['subject_name'] ?? ''),
                      ...assessmentTypes.map((at) {
                        final aid = (at['id'] ?? '').toString().toLowerCase();
                        final val = scoresJson[aid] ?? 0;
                        final displayVal = val is int ? '$val' : (val is double ? val.toInt().toString() : val.toString());
                        return _dataCell(displayVal, align: pw.TextAlign.center);
                      }),
                      _dataCell(total == total.roundToDouble() ? total.toInt().toString() : total.toStringAsFixed(1), align: pw.TextAlign.center, bold: true, color: isPass ? PdfColors.green800 : PdfColors.red800),
                      _dataCell(gradeInfo['grade'] as String? ?? '', align: pw.TextAlign.center, bold: true, color: isPass ? PdfColors.green800 : PdfColors.red800),
                      _dataCell(gradeInfo['remark'] as String? ?? '', align: pw.TextAlign.center),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 12),

            // ── SUMMARY BOX ──
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _summaryItem('Subjects Taken', '${scores.length}'),
                  _summaryItem('Total Score', totalScore == totalScore.roundToDouble() ? totalScore.toInt().toString() : totalScore.toStringAsFixed(1)),
                  _summaryItem('Average', average.toStringAsFixed(1)),
                  _summaryItem('Grade', overallGradeInfo['grade'] as String? ?? ''),
                  _summaryItem('Passed', '$passed', color: PdfColors.green800),
                  _summaryItem('Failed', '$failed', color: failed > 0 ? PdfColors.red800 : PdfColors.green800),
                ],
              ),
            ),

            if (provider.daysPresent > 0 || provider.daysAbsent > 0) ...[
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(4)),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _summaryItem('Days Present', '${provider.daysPresent}'),
                    _summaryItem('Days Absent', '${provider.daysAbsent}'),
                  ],
                ),
              ),
            ],

            pw.SizedBox(height: 12),

            // ── GRADING KEY ──
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Grading Key', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: gradingSystem.map((g) {
                      final grade = (g['grade'] ?? '').toString();
                      final isFail = !GradingUtils.isPassingGrade(grade, gradingSystem);
                      return pw.Text(
                        '$grade (${g['min']}-${g['max']}) ${g['remark'] ?? ''}  ',
                        style: pw.TextStyle(fontSize: 8, color: isFail ? PdfColors.red700 : PdfColors.black),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // ── TEACHER COMMENT ──
            if (_termComment != null) ...[
              pw.SizedBox(height: 12),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(4)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Class Teacher\'s Comment:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text((_termComment!['teacher_comment'] ?? '').toString(), style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(4)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Principal\'s Comment:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text((_termComment!['principal_comment'] ?? '').toString(), style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ),
            ],

            // ── CONDUCT/ATTITUDE ──
            if (_termComment != null) ...[
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(4)),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    if ((_termComment!['conduct'] ?? '').toString().isNotEmpty)
                      pw.Column(children: [
                        pw.Text('Conduct', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 2),
                        pw.Text((_termComment!['conduct'] ?? '').toString(), style: const pw.TextStyle(fontSize: 8)),
                      ]),
                    if ((_termComment!['attitude'] ?? '').toString().isNotEmpty)
                      pw.Column(children: [
                        pw.Text('Attitude', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 2),
                        pw.Text((_termComment!['attitude'] ?? '').toString(), style: const pw.TextStyle(fontSize: 8)),
                      ]),
                    if ((_termComment!['interest'] ?? '').toString().isNotEmpty)
                      pw.Column(children: [
                        pw.Text('Interest', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 2),
                        pw.Text((_termComment!['interest'] ?? '').toString(), style: const pw.TextStyle(fontSize: 8)),
                      ]),
                    if ((_termComment!['attendance_remark'] ?? '').toString().isNotEmpty)
                      pw.Column(children: [
                        pw.Text('Attendance', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 2),
                        pw.Text((_termComment!['attendance_remark'] ?? '').toString(), style: const pw.TextStyle(fontSize: 8)),
                      ]),
                  ],
                ),
              ),
            ],

            pw.SizedBox(height: 24),

            // ── SIGNATURE LINES ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  children: [
                    pw.Text('Class Teacher', style: const pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 30),
                    pw.Container(width: 120, height: 1, color: PdfColors.grey600),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text('Principal', style: const pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 30),
                    pw.Container(width: 120, height: 1, color: PdfColors.grey600),
                  ],
                ),
              ],
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

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          pw.SizedBox(width: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _headerCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
    );
  }

  static pw.Widget _dataCell(String text, {pw.TextAlign align = pw.TextAlign.left, bool bold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 8, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _summaryItem(String label, String value, {PdfColor? color}) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: color)),
        pw.SizedBox(height: 2),
        pw.Text(label, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
      ],
    );
  }

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

    final blue700 = const Color(0xFF42A5F5);
    final green700 = const Color(0xFF81C784);
    final red700 = const Color(0xFFE57373);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("My Results", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
              if (scores.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.3)),
                  ),
                  child: Text(
                    provider.currentTermName ?? '',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF2E7D32), fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isGeneratingPdf ? null : _printResult,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isGeneratingPdf ? Colors.grey.shade300 : const Color(0xFF2E7D64),
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
                        Text(
                          _isGeneratingPdf ? 'Preparing...' : 'Print Result',
                          style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (provider.currentSessionName != null) ...[
            const SizedBox(height: 4),
            Text(
              '${provider.currentSessionName} — ${provider.classDisplay}',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
          const SizedBox(height: 20),

          Row(
            children: [
              _SummaryCard(title: "Subjects", value: "${scores.length}", color: Colors.blue, icon: Icons.menu_book),
              const SizedBox(width: 12),
              _SummaryCard(title: "Average", value: average.toStringAsFixed(1), color: Colors.green, icon: Icons.bar_chart),
              const SizedBox(width: 12),
              _SummaryCard(title: "Grade", value: overallGradeInfo['grade'] as String? ?? '', color: Colors.teal, icon: Icons.grade),
              const SizedBox(width: 12),
              _SummaryCard(title: "Passed", value: "$passed", color: Colors.teal, icon: Icons.check_circle),
              const SizedBox(width: 12),
              _SummaryCard(title: "Failed", value: "$failed", color: Colors.red, icon: Icons.cancel),
            ],
          ),

          if (provider.termPosition > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: Color(0xFF2E7D32), size: 22),
                  const SizedBox(width: 12),
                  const Text('Position in Class: ', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  Text(
                    '${_ordinal(provider.termPosition)} out of ${provider.positionOutOf}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                  ),
                  const Spacer(),
                  Text('Total: $totalScore', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32))),
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
                    Icon(Icons.bar_chart, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text("No results available", style: TextStyle(fontSize: 16, color: Colors.grey)),
                    SizedBox(height: 8),
                    Text("Results will appear here once your teacher publishes them", style: TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
            )
          else ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 12,
                  headingRowColor: WidgetStateProperty.all(const Color(0xFF2E7D32).withOpacity(0.08)),
                  columns: [
                    const DataColumn(label: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold))),
                    ...assessmentTypes.map((at) => DataColumn(
                      label: Text('${at['name']}\n(${at['max']})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center),
                      numeric: true,
                    )),
                    const DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                    const DataColumn(label: Text('Grade', style: TextStyle(fontWeight: FontWeight.bold))),
                    const DataColumn(label: Text('Remark', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: scores.map((score) {
                    final total = (score['total'] ?? 0).toDouble();
                    final isPass = total >= passThreshold;
                    final gradeInfo = GradingUtils.getGradeFromSystem(total, gradingSystem);
                    final grade = gradeInfo['grade'] as String? ?? '';
                    final remark = gradeInfo['remark'] as String? ?? '';
                    final scoresJson = score['scores_json'] as Map<String, dynamic>? ?? {};

                    final displayVal = assessmentTypes.map((at) {
                      final aid = (at['id'] ?? '').toString().toLowerCase();
                      final val = scoresJson[aid] ?? 0;
                      return val is int ? '$val' : (val is double ? val.toInt().toString() : val.toString());
                    }).toList();

                    return DataRow(
                      cells: [
                        DataCell(Text(score['subject_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500))),
                        ...displayVal.map((val) => DataCell(Text(val))),
                        DataCell(
                          Text(
                            total == total.roundToDouble() ? total.toInt().toString() : total.toStringAsFixed(1),
                            style: TextStyle(fontWeight: FontWeight.bold, color: isPass ? Colors.green : Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPass ? Colors.green.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: isPass ? Colors.green.shade200 : Colors.red.shade200),
                            ),
                            child: Text(grade, style: TextStyle(fontWeight: FontWeight.bold, color: isPass ? Colors.green : Colors.red, fontSize: 13), textAlign: TextAlign.center),
                          ),
                        ),
                        DataCell(Text(remark, style: TextStyle(fontSize: 12, color: isPass ? Colors.green.shade700 : Colors.red.shade700))),
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
    final behavioralFields = [
      {'key': 'conduct', 'label': 'Conduct', 'icon': Icons.star_outline},
      {'key': 'attitude', 'label': 'Attitude', 'icon': Icons.emoji_emotions_outlined},
      {'key': 'interest', 'label': 'Interest in Studies', 'icon': Icons.lightbulb_outline},
      {'key': 'attendance_remark', 'label': 'Attendance Remark', 'icon': Icons.schedule},
    ];

    final hasAnyRating = behavioralFields.any((f) => (comment[f['key']] ?? '').toString().isNotEmpty);
    if (!hasAnyRating) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology, color: Color(0xFF2E7D32), size: 20),
              SizedBox(width: 8),
              Text('Behavioral Ratings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32))),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: behavioralFields.map((f) {
              final value = (comment[f['key']] ?? '').toString();
              if (value.isEmpty) return const SizedBox.shrink();
              final color = _getBehavioralColor(value);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.3))),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(f['icon'] as IconData, size: 18, color: color),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(f['label'] as String, style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
      default: return Colors.grey;
    }
  }

  Widget _buildCommentsSection(Map<String, dynamic> comment) {
    final teacherComment = (comment['teacher_comment'] ?? '').toString();
    final principalComment = (comment['principal_comment'] ?? '').toString();
    if (teacherComment.isEmpty && principalComment.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.comment, color: Color(0xFF2E7D32), size: 20),
              SizedBox(width: 8),
              Text('Comments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32))),
            ],
          ),
          const SizedBox(height: 16),
          if (teacherComment.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF90CAF9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.person_outline, size: 16, color: Color(0xFF1565C0)),
                      SizedBox(width: 6),
                      Text('Class Teacher', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1565C0))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(teacherComment, style: const TextStyle(fontSize: 14, color: Color(0xFF1B2A4A), height: 1.4)),
                ],
              ),
            ),
            if (principalComment.isNotEmpty) const SizedBox(height: 12),
          ],
          if (principalComment.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.school, size: 16, color: Color(0xFF2E7D32)),
                      SizedBox(width: 6),
                      Text('Principal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(principalComment, style: const TextStyle(fontSize: 14, color: Color(0xFF1B2A4A), height: 1.4)),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF2E7D32), size: 20),
              SizedBox(width: 8),
              Text('Grading Key', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32))),
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
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isFail ? Colors.red.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isFail ? Colors.red.shade200 : Colors.green.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(grade, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isFail ? Colors.red : Colors.green)),
                      const SizedBox(height: 2),
                      Text('$min-$max', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      Text(remark, style: TextStyle(fontSize: 10, color: isFail ? Colors.red.shade700 : Colors.green.shade700)),
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

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({required this.title, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

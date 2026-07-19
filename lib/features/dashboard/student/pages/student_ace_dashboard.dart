import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/student/student_provider.dart';
import '../../../../core/services/db_proxy.dart';
import '../../../../utils/ace_pdf_generator.dart';

class StudentAceDashboard extends StatefulWidget {
  const StudentAceDashboard({super.key});

  @override
  State<StudentAceDashboard> createState() => _StudentAceDashboardState();
}

class _StudentAceDashboardState extends State<StudentAceDashboard> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _subjects = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = context.read<StudentProvider>();
    final sid = provider.currentSessionId ?? '';
    final tid = provider.currentTermId ?? '';
    if (sid.isEmpty || tid.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    await Future.wait([
      provider.loadMyAcePaceScores(sid, tid),
      provider.loadMyAceReport(sid, tid),
    ]);
    final classId = provider.classId;
    if (classId.isNotEmpty) {
      try {
        final result = await DbProxy.instance
            .from('class_subjects')
            .select('subject_id, subjects(id, name, code)')
            .eq('class_id', classId)
            .get();
        if (mounted) {
          setState(() {
            _subjects = result.map((r) {
              final sub = r['subjects'] as Map<String, dynamic>? ?? {};
              return {
                'id': (r['subject_id'] ?? '').toString(),
                'name': (sub['name'] ?? '').toString(),
                'code': (sub['code'] ?? '').toString(),
              };
            }).toList();
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('Error loading subjects: $e');
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();
    final report = provider.myAceReport;
    final scoresBySubject = provider.getMyPaceScoresBySubject();

    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: Center(
          child: CircularProgressIndicator(color: const Color(0xFF1A237E)),
        ),
      );
    }

    if (report == null) {
      final hasScores = provider.myPaceScores.isNotEmpty;
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: AppBar(
          title: const Text('ACE Report', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
          backgroundColor: const Color(0xFF1A237E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(hasScores ? Icons.hourglass_empty_outlined : Icons.description_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(hasScores ? 'Report is being prepared' : 'No report available', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
              const SizedBox(height: 8),
              Text(hasScores ? 'Please check back later' : 'Contact your school administrator', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('ACE Report', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Material(
              color: const Color(0xFFE65100),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _downloadPdf(provider),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.picture_as_pdf, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text('Download PDF', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(provider, report),
            const SizedBox(height: 12),
            _buildReadingProgress(report),
            const SizedBox(height: 12),
            _buildScoresTable(scoresBySubject),
            const SizedBox(height: 12),
            _buildFooterCard(report),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(StudentProvider p, Map<String, dynamic> r) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1A237E), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SCHOOL PROGRESS REPORT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1)),
          const SizedBox(height: 12),
          _infoRow('Student', p.studentName, Colors.white70),
          _infoRow('Session', p.currentSessionName, Colors.white70),
          _infoRow('Term', p.currentTermName, Colors.white70),
          if (r['day_in_term'] != null) _infoRow('Day in Term', '${r['day_in_term']}', Colors.white70),
          if (r['published_at'] != null) _infoRow('Date', (r['published_at'] as String).split('T').first, Colors.white70),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, Color vc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 13, color: vc, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildReadingProgress(Map<String, dynamic> r) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8EAED))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: const BoxDecoration(color: Color(0xFF1A237E), borderRadius: BorderRadius.all(Radius.circular(6))),
            child: const Text('READING PROGRESS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5)),
          ),
          const SizedBox(height: 12),
          Row(children: [_rpField('W.P.W', r['reading_wpm']), const SizedBox(width: 12), _rpField('W.P.W Comprehension %', r['reading_comprehension']), const SizedBox(width: 12), _rpField('Composite', r['reading_composite'])]),
          const SizedBox(height: 10),
          Row(children: [_rpReadOnly('NO. of PACEs completed', r['paces_completed']?.toString() ?? '0'), const SizedBox(width: 12), _rpReadOnly('PACE score AVG', _fmtNum(r['paces_avg'])), const SizedBox(width: 12), _rpReadOnly('Total (PACES Cass)', _fmtNum(r['paces_total']))]),
          const SizedBox(height: 10),
          Row(children: [_rpField('Date', r['published_at'] != null ? (r['published_at'] as String).split('T').first : null), const SizedBox(width: 12), _rpField('Days in Term', r['day_in_term']), const SizedBox(width: 12), _rpField('Days Absent', r['days_absent'])]),
          const SizedBox(height: 12),
          _rpCommentSection('Supervisor\'s Comment', r['supervisor_comment']),
          const SizedBox(height: 10),
          _rpCommentSection('Principal\'s Comment', r['principal_comment']),
        ],
      ),
    );
  }

  Widget _rpField(String label, dynamic value) {
    final display = value != null ? value.toString() : '--';
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFF7F8FA), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFE8EAED))),
            child: Text(display, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
          ),
        ],
      ),
    );
  }

  Widget _rpReadOnly(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A237E))),
        ],
      ),
    );
  }

  Widget _rpCommentSection(String label, dynamic value) {
    final comment = (value as String?) ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        if (comment.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF7F8FA), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFE8EAED))),
            child: Text(comment, style: const TextStyle(fontSize: 12, color: Color(0xFF555555), fontStyle: FontStyle.italic)),
          )
        else
          const Text('--', style: TextStyle(fontSize: 12, color: Color(0xFFD0D0D0))),
        const SizedBox(height: 6),
        const Align(alignment: Alignment.centerLeft, child: SizedBox(width: 200, child: Divider(color: Color(0xFFAAAAAA), thickness: 0.5))),
        const SizedBox(height: 4),
        const Text('Signature', style: TextStyle(fontSize: 9, color: Color(0xFFAAAAAA))),
      ],
    );
  }

  Widget _buildScoresTable(Map<String, List<Map<String, dynamic>>> scoresBySubject) {
    int maxPaces = 0;
    for (final entries in scoresBySubject.values) {
      if (entries.length > maxPaces) maxPaces = entries.length;
    }
    if (scoresBySubject.isEmpty || maxPaces == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8EAED))),
        child: const Center(child: Text('No PACE scores recorded yet', style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)))),
      );
    }

    final sortedEntries = scoresBySubject.entries.toList()
      ..sort((a, b) {
        final an = (a.value.firstOrNull?['subject_name'] ?? '').toString().toLowerCase();
        final bn = (b.value.firstOrNull?['subject_name'] ?? '').toString().toLowerCase();
        if (an.contains('math')) return -1;
        if (bn.contains('math')) return 1;
        if (an.contains('english')) return -1;
        if (bn.contains('english')) return 1;
        return an.compareTo(bn);
      });

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8EAED))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final colCount = maxPaces * 2 + 2;
            final minW = colCount * 56.0;
            final tableW = minW > constraints.maxWidth ? minW : constraints.maxWidth;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableW,
                child: DataTable(
                  horizontalMargin: 8,
                  columnSpacing: 0,
                  headingRowHeight: 40,
                  dataRowHeight: 36,
                  headingRowColor: WidgetStateProperty.all(const Color(0xFF1A237E)),
                  headingTextStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                  dataTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF111827)),
                  columns: [
                    const DataColumn(label: Text('Subject')),
                    for (int i = 0; i < maxPaces; i++) ...[
                      DataColumn(label: SizedBox(width: 52, child: const Center(child: Text('PACE No.', textAlign: TextAlign.center, style: TextStyle(fontSize: 10))))),
                      DataColumn(label: SizedBox(width: 36, child: const Center(child: Text('PT', textAlign: TextAlign.center, style: TextStyle(fontSize: 10))))),
                    ],
                    const DataColumn(label: SizedBox(width: 52, child: Center(child: Text('Total', textAlign: TextAlign.center, style: TextStyle(fontSize: 10))))),
                  ],
                  rows: sortedEntries.map((entry) {
                    final subjectId = entry.key;
                    final paces = entry.value;
                    final subject = _subjects.where((s) => s['id']?.toString() == subjectId).firstOrNull;
                    final subjectName = (subject?['name'] ?? 'Unknown').toString();
                    final ptScores = paces.map((p) {
                      final v = p['pt_score'];
                      if (v is num) return v;
                      if (v is String) return num.tryParse(v);
                      return null;
                    }).whereType<num>();
                    final total = ptScores.isNotEmpty ? ptScores.reduce((a, b) => a + b) : 0.0;
                    final totalColor = total >= 80 ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F);
                    final cells = <DataCell>[
                      DataCell(Text(subjectName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11))),
                    ];
                    for (int i = 0; i < maxPaces; i++) {
                      cells.add(DataCell(SizedBox(width: 52, child: Center(child: Text(i < paces.length ? (paces[i]['pace_no'] ?? '--').toString() : '--', style: const TextStyle(fontSize: 11, color: Color(0xFF666666)))))));
                      final ptRaw = i < paces.length ? paces[i]['pt_score'] : null;
                      final ptVal = ptRaw is num ? ptRaw : (ptRaw is String ? num.tryParse(ptRaw) : null);
                      cells.add(DataCell(SizedBox(width: 36, child: Center(child: Text(ptVal != null ? _fmtNum(ptVal) : '--', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ptVal != null && ptVal < 80 ? const Color(0xFFD32F2F) : const Color(0xFF111827)))))));
                    }
                    cells.add(DataCell(SizedBox(width: 52, child: Center(child: Text(_fmtNum(total), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: totalColor))))));
                    return DataRow(cells: cells);
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFooterCard(Map<String, dynamic> r) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8EAED))),
      child: Row(
        children: [
          _footerItem('HACS Score', _fmtNum(r['hacs_score']), const Color(0xFF1A237E)),
          const SizedBox(width: 12),
          _footerItem('NCE Score', _fmtNum(r['nce_score']), const Color(0xFFE65100)),
          const SizedBox(width: 12),
          _footerItem('Total', _fmtNum(r['total_score']), const Color(0xFF2E7D32)),
        ],
      ),
    );
  }

  Widget _footerItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2))),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.7), fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadPdf(StudentProvider provider) async {
    try {
      await AcePdfGenerator.generateAndDownload(
        schoolInfo: provider.schoolInfoMap,
        student: {'first_name': provider.firstName, 'last_name': provider.lastName, 'passport_url': provider.passportUrl, 'admission_no': provider.admissionNo},
        report: provider.myAceReport,
        paceScores: provider.myPaceScores,
        subjects: _subjects,
        term: provider.currentTerm,
        session: provider.currentSession,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error downloading PDF: $e'), backgroundColor: const Color(0xFFD32F2F)));
      }
    }
  }

  String _fmtNum(dynamic value) {
    if (value == null) return '--';
    if (value is num) {
      if (value == value.truncateToDouble()) return value.toInt().toString();
      return value.toStringAsFixed(1);
    }
    return value.toString();
  }
}

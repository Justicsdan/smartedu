import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/school_admin_provider.dart';
import '../../../../utils/ace_pdf_generator.dart';

class PageAceReports extends StatefulWidget {
  const PageAceReports({super.key});
  @override
  State<PageAceReports> createState() => _PageAceReportsState();
}

class _PageAceReportsState extends State<PageAceReports> {
  List<Map<String, dynamic>> _classes = [];
  String? _selectedClassId;
  List<Map<String, dynamic>> _students = [];
  Map<String, Map<String, dynamic>> _reports = {};
  Map<String, int> _paceCounts = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    final p = context.read<SchoolAdminProvider>();
    if (mounted) setState(() => _classes = List.from(p.classes));
  }

  Future<void> _loadData() async {
    if (_selectedClassId == null) return;
    setState(() => _loading = true);
    final p = context.read<SchoolAdminProvider>();
    final sid = p.currentSession?['id']?.toString() ?? '';
    final tid = p.currentTerm?['id']?.toString() ?? '';
    final sts = p.students.where((s) => s['class_id']?.toString() == _selectedClassId).toList();
    _reports = {};
    _paceCounts = {};
    for (final s in sts) {
      final id = s['id'].toString();
      final r = await p.getAceReport(id, sid, tid);
      if (r != null) _reports[id] = r;
      await p.loadAcePaceScoresForStudent(id, sid, tid);
      _paceCounts[id] = p.acePaceScores.length;
    }
    if (mounted) setState(() { _students = sts; _loading = false; });
  }

  String _sName(Map<String, dynamic> s) =>
      '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim();

  void _openSheet(Map<String, dynamic> student) {
    final id = student['id'].toString();
    final p = context.read<SchoolAdminProvider>();
    final sid = p.currentSession?['id']?.toString() ?? '';
    final tid = p.currentTerm?['id']?.toString() ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ReportSheet(
        student: student,
        existingReport: _reports[id],
        paceCount: _paceCounts[id] ?? 0,
        sessionId: sid,
        termId: tid,
        onPublish: () async {
          await p.publishAceReport(id, sid, tid);
          _loadData();
          Navigator.pop(ctx);
        },
        onSave: ({
          teacherComment,
          readingProgress,
          readingWpm,
          readingComposite,
          readingComprehension,
          daysAbsent,
          supervisorComment,
          principalComment,
          dayInTerm,
        }) async {
          await p.generateAceReport(
            studentId: id,
            classId: _selectedClassId!,
            sessionId: sid,
            termId: tid,
            teacherComment: teacherComment,
            readingProgress: readingProgress,
            readingWpm: readingWpm,
            readingComposite: readingComposite,
            readingComprehension: readingComprehension,
            daysAbsent: daysAbsent,
            supervisorComment: supervisorComment,
            principalComment: principalComment,
            dayInTerm: dayInTerm,
          );
          _loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SchoolAdminProvider>();
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: DropdownButtonFormField<String>(
              value: _classes.any((c) => c['id'].toString() == _selectedClassId) ? _selectedClassId : null,
              decoration: const InputDecoration(
                labelText: 'Select Class',
                prefixIcon: Icon(Icons.class_rounded),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: _classes.map((c) {
                final label = '${c['name'] ?? ''}${(c['section'] ?? '').toString().isNotEmpty ? ' ${c['section']}' : ''}';
                return DropdownMenuItem(value: c['id'].toString(), child: Text(label));
              }).toList(),
              onChanged: (v) {
                setState(() => _selectedClassId = v);
                _loadData();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Session: ${p.currentSession?['name'] ?? '-'} | Term: ${p.currentTerm?['name'] ?? '-'}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _selectedClassId == null
                    ? const Center(child: Text('Select a class to begin', style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))))
                    : _students.isEmpty
                        ? const Center(child: Text('No students in this class', style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _students.length,
                            itemBuilder: (_, i) {
                              final s = _students[i];
                              final id = s['id'].toString();
                              final pc = _paceCounts[id] ?? 0;
                              final r = _reports[id];
                              final pub = r?['is_published'] == true;
                              final hacs = r?['hacs_score'];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  leading: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: const Color(0xFFF0F4FF),
                                    child: Text(
                                      _sName(s).isEmpty ? '?' : _sName(s)[0].toUpperCase(),
                                      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A237E)),
                                    ),
                                  ),
                                  title: Text(_sName(s), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  subtitle: Text('$pc PACE${pc != 1 ? 's' : ''} recorded'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (pub)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(12)),
                                          child: const Text('Published', style: TextStyle(fontSize: 11, color: Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
                                        )
                                      else if (hacs != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(12)),
                                          child: Text('HACS: ${(hacs as num).toStringAsFixed(1)}', style: const TextStyle(fontSize: 11, color: Color(0xFFE65100), fontWeight: FontWeight.w600)),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                                          child: const Text('Draft', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                                        ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
                                    ],
                                  ),
                                  onTap: () => _openSheet(s),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _ReportSheet extends StatefulWidget {
  final Map<String, dynamic> student;
  final Map<String, dynamic>? existingReport;
  final int paceCount;
  final String sessionId;
  final String termId;
  final VoidCallback onPublish;
  final Future<void> Function({
    String? teacherComment,
    String? readingProgress,
    double? readingWpm,
    double? readingComposite,
    double? readingComprehension,
    int? daysAbsent,
    String? supervisorComment,
    String? principalComment,
    int? dayInTerm,
  }) onSave;

  const _ReportSheet({
    required this.student,
    this.existingReport,
    required this.paceCount,
    required this.sessionId,
    required this.termId,
    required this.onPublish,
    required this.onSave,
  });

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  late final TextEditingController _dayCtrl;
  late final TextEditingController _absentCtrl;
  late final TextEditingController _wpmCtrl;
  late final TextEditingController _compPrehCtrl;
  late final TextEditingController _compositeCtrl;
  late final TextEditingController _dateCtrl;
  late final TextEditingController _superCtrl;
  late final TextEditingController _princCtrl;
  bool _saving = false;

  Map<String, dynamic>? get _r => widget.existingReport;
  bool get _pub => _r?['is_published'] == true;
  String get _name => '${widget.student['first_name'] ?? ''} ${widget.student['last_name'] ?? ''}'.trim();

  @override
  void initState() {
    super.initState();
    _dayCtrl = TextEditingController(text: _r?['day_in_term']?.toString() ?? '');
    _absentCtrl = TextEditingController(text: _r?['days_absent']?.toString() ?? '0');
    _wpmCtrl = TextEditingController(text: _r?['reading_wpm']?.toString() ?? '');
    _compPrehCtrl = TextEditingController(text: _r?['reading_comprehension']?.toString() ?? '');
    _compositeCtrl = TextEditingController(text: _r?['reading_composite']?.toString() ?? '');
    _dateCtrl = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
    _superCtrl = TextEditingController(text: _r?['supervisor_comment'] ?? '');
    _princCtrl = TextEditingController(text: _r?['principal_comment'] ?? '');
  }

  @override
  void dispose() {
    _dayCtrl.dispose();
    _absentCtrl.dispose();
    _wpmCtrl.dispose();
    _compPrehCtrl.dispose();
    _compositeCtrl.dispose();
    _dateCtrl.dispose();
    _superCtrl.dispose();
    _princCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.onSave(
      readingWpm: double.tryParse(_wpmCtrl.text),
      readingComprehension: double.tryParse(_compPrehCtrl.text),
      readingComposite: double.tryParse(_compositeCtrl.text),
      daysAbsent: int.tryParse(_absentCtrl.text) ?? 0,
      supervisorComment: _superCtrl.text.trim().isEmpty ? null : _superCtrl.text.trim(),
      principalComment: _princCtrl.text.trim().isEmpty ? null : _princCtrl.text.trim(),
      dayInTerm: int.tryParse(_dayCtrl.text) ?? 0,
    );
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _saveAndPublish() async {
    await _save();
    if (_r != null) widget.onPublish();
  }

  String _pAvg() {
    if (_r != null && _r!['paces_avg'] != null) return (_r!['paces_avg'] as num).toStringAsFixed(1);
    return '0.0';
  }

  String _pTotal() {
    if (_r != null && _r!['paces_total'] != null) return (_r!['paces_total'] as num).toStringAsFixed(1);
    return '0.0';
  }

  @override
  Widget build(BuildContext context) {
    final hacs = _r?['hacs_score'];
    final nce = _r?['nce_score'];
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                    Text('${widget.paceCount} PACEs recorded', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
              if (_pub)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(20)),
                  child: const Text('Published', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32))),
                ),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(height: 24),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hacs != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFD0D7FF))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _sCol('HACS', (hacs as num).toStringAsFixed(1), const Color(0xFF1A237E)),
                          Container(width: 1, height: 40, color: const Color(0xFFD0D7FF)),
                          _sCol('NCE', (nce as num).toStringAsFixed(1), const Color(0xFFE65100)),
                          Container(width: 1, height: 40, color: const Color(0xFFD0D7FF)),
                          _sCol('Total', (hacs as num).toStringAsFixed(1), const Color(0xFF2E7D32)),
                        ],
                      ),
                    ),
                  _hdr('READING PROGRESS'),
                  Row(
                    children: [
                      Expanded(child: _fld(_wpmCtrl, 'Words per minute (W.P.W)', 'e.g. 85', num: true)),
                      const SizedBox(width: 8),
                      Expanded(child: _fld(_compPrehCtrl, 'W.P.W Comprehension', 'e.g. 78', num: true)),
                      const SizedBox(width: 8),
                      Expanded(child: _fld(_compositeCtrl, 'Composite', 'e.g. 72', num: true)),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 8),
                    child: Text(
                      'NO. of PACEs completed: ${widget.paceCount}   |   PACE score AVG: ${_pAvg()}   |   Total (PACES Cass): ${_pTotal()}',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF374151), fontWeight: FontWeight.w500),
                    ),
                  ),
                  _fld(_dateCtrl, 'Date', 'e.g. 26/3/2026'),
                  Row(
                    children: [
                      Expanded(child: _fld(_dayCtrl, 'Days in Term', 'e.g. 55', num: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _fld(_absentCtrl, 'Days Absent', 'e.g. 2', num: true)),
                    ],
                  ),
                  _fld(_superCtrl, "Supervisor's Comment", 'Supervisor remark...'),
                  const SizedBox(height: 8),
                  _sigLine(),
                  const SizedBox(height: 12),
                  _fld(_princCtrl, "Principal's Comment", 'Principal remark...'),
                  const SizedBox(height: 8),
                  _sigLine(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving || _pub ? null : _save,
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF1A237E)), padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_pub ? 'Published' : 'Save Draft', style: const TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _pub ? null : _saveAndPublish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Save & Publish', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_r != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _downloadPdf,
                icon: const Icon(Icons.picture_as_pdf, color: Color(0xFFE65100)),
                label: const Text('Download PDF', style: TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFE65100)), padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _downloadPdf() async {
    final p = context.read<SchoolAdminProvider>();
    final sid = widget.student['id'].toString();
    await p.loadAcePaceScoresForStudent(sid, widget.sessionId, widget.termId);
    await AcePdfGenerator.generateAndDownload(
      schoolInfo: {
        'name': p.schoolName,
        'logo_url': p.schoolLogoUrl,
        'motto': p.schoolMotto,
        'address': p.schoolAddress,
      },
      student: widget.student,
      report: _r,
      paceScores: List<Map<String, dynamic>>.from(p.acePaceScores),
      subjects: p.subjects,
      term: p.currentTerm,
      session: p.currentSession,
    );
  }

  Widget _hdr(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF9CA3AF), letterSpacing: 1)),
    );
  }

  Widget _sCol(String label, String val, Color c) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: c)),
      ],
    );
  }

  Widget _fld(TextEditingController c, String l, String h, {bool num = false, int mx = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: l,
          hintText: h,
          hintStyle: const TextStyle(fontSize: 12),
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        maxLines: mx,
        keyboardType: num ? const TextInputType.numberWithOptions(decimal: true) : null,
        readOnly: _pub,
      ),
    );
  }

  Widget _sigLine() {
    return Container(
      margin: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: const Color(0xFF9CA3AF).withOpacity(0.5), width: 1))),
      child: const Text('Signature: _______________', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
    );
  }
}

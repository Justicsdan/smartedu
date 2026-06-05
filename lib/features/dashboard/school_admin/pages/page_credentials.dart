import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../utils/pdf_download_utils.dart';
import '../../../../core/providers/school_admin_provider.dart';

class PageCredentials extends StatefulWidget {
  const PageCredentials({super.key});
  @override
  State<PageCredentials> createState() => _PageCredentialsState();
}

class _PageCredentialsState extends State<PageCredentials>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String? _teacherClassId;
  String? _studentClassId;
  bool _generating = false;
  bool _printing = false;
  final Set<String> _loadingIds = {};
  String? _viewingId;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool ok = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ok ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
        shape: const StadiumBorder(),
        margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
      ),
    );
  }

  void _copy(String username, String secret, bool isTeacher) {
    final label = isTeacher ? 'Password' : 'PIN';
    final text = 'Username: $username\n$label: $secret';
    Clipboard.setData(ClipboardData(text: text));
    _snack('Credentials copied');
  }

  String _name(Map<String, dynamic> m) {
    final f = (m['first_name'] ?? '').toString().trim();
    final l = (m['last_name'] ?? '').toString().trim();
    if (f.isNotEmpty && l.isNotEmpty) return '$f $l';
    return f.isNotEmpty ? f : l;
  }

  String _secret(Map<String, dynamic> it, bool isTeacher) {
    if (isTeacher) {
      return (it['password'] ?? '').toString();
    }
    return (it['pin'] ?? '').toString();
  }

  bool _needsRegen(String secret, bool isTeacher) {
    if (secret.startsWith('\$2')) return true;
    if (isTeacher && RegExp(r'^\d{4}$').hasMatch(secret)) return true;
    return false;
  }

  String _generateStrongPassword() {
    final r = Random();
    final digits = List.generate(6, (_) => r.nextInt(10)).join();
    return 'Tchr@$digits!';
  }

  String _generatePin() {
    return '${Random().nextInt(9000) + 1000}';
  }

  Future<void> _regenerateOne(SchoolAdminProvider p, Map<String, dynamic> it,
      bool isTeacher) async {
    final id = it['id'].toString();
    setState(() => _loadingIds.add(id));
    try {
      final secret = isTeacher ? _generateStrongPassword() : _generatePin();
      final updates = <String, String>{};
      if (isTeacher) {
        updates['password'] = secret;
      } else {
        updates['pin'] = secret;
      }
      if ((it['username'] ?? '').toString().isEmpty) {
        final fn = (it['first_name'] ?? '')
            .toString()
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z]'), '');
        final ln = (it['last_name'] ?? '')
            .toString()
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z]'), '');
        final adm = (it['admission_no'] ?? '')
            .toString()
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]'), '');
        final base = isTeacher
            ? '$fn${ln.isNotEmpty ? '_$ln' : ''}'
            : (adm.isNotEmpty ? adm : '$fn$ln');
        updates['username'] = '$base${Random().nextInt(9000) + 1000}';
      }
      await Supabase.instance.client
          .from(isTeacher ? 'teachers' : 'students')
          .update(updates)
          .eq('id', it['id']);
      await p.reloadData();
      if (mounted) _snack('New ${isTeacher ? 'password' : 'PIN'} generated');
    } catch (e) {
      if (mounted) _snack('Error: $e', ok: false);
    } finally {
      if (mounted) {
        setState(() => _loadingIds.remove(id));
        setState(() => _viewingId = null);
      }
    }
  }

  Future<void> _generate(
      SchoolAdminProvider p, bool isTeacher, List<dynamic> items) async {
    final missing = items
        .where((e) => (e['username'] ?? '').toString().isEmpty)
        .toList();
    if (missing.isEmpty) {
      _snack('All already have credentials');
      return;
    }
    setState(() => _generating = true);
    try {
      for (final it in missing) {
        final fn = (it['first_name'] ?? '')
            .toString()
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z]'), '');
        final ln = (it['last_name'] ?? '')
            .toString()
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z]'), '');
        final adm = (it['admission_no'] ?? '')
            .toString()
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]'), '');
        final base = isTeacher
            ? '$fn${ln.isNotEmpty ? '_$ln' : ''}'
            : (adm.isNotEmpty ? adm : '$fn$ln');
        final uname = '$base${Random().nextInt(9000) + 1000}';
        final secret = isTeacher ? _generateStrongPassword() : _generatePin();
        final updates = {'username': uname};
        if (isTeacher) {
          updates['password'] = secret;
        } else {
          updates['pin'] = secret;
        }
        await Supabase.instance.client
            .from(isTeacher ? 'teachers' : 'students')
            .update(updates)
            .eq('id', it['id']);
      }
      await p.reloadData();
      if (mounted) {
        _snack(
            'Generated for ${missing.length} ${isTeacher ? 'teacher(s)' : 'student(s)'}');
      }
    } catch (e) {
      if (mounted) _snack('Error: $e', ok: false);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<pw.MemoryImage?> _fetchLogo(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      final resp = await Supabase.instance.client
          .storage
          .from('school-logos')
          .download(url);
      return pw.MemoryImage(resp);
    } catch (_) {
      return null;
    }
  }

  pw.Widget _credCard(
      String schoolName,
      String name,
      String username,
      String secret,
      String secretLabel,
      String? extra,
      pw.MemoryImage? logo) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColor.fromInt(0xFFD0D5DD), width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF1A237E),
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(6),
                topRight: pw.Radius.circular(6),
              ),
            ),
            child: pw.Row(
              children: [
                if (logo != null)
                  pw.Container(
                    width: 22,
                    height: 22,
                    margin: const pw.EdgeInsets.only(right: 6),
                    child: pw.Image(logo, fit: pw.BoxFit.contain),
                  ),
                pw.Expanded(
                  child: pw.Text(
                    schoolName.toUpperCase(),
                    style: const pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                if (logo != null) pw.SizedBox(width: 22),
              ],
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  name,
                  style: const pw.TextStyle(
                    fontSize: 10.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF111827),
                  ),
                ),
                if (extra != null)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 1),
                    child: pw.Text(
                      extra,
                      style: const pw.TextStyle(
                        fontSize: 6.5,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ),
                pw.SizedBox(height: 6),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFF8F9FC),
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(
                        color: PdfColor.fromInt(0xFFE8EAED), width: 0.5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _credRow('USERNAME', username),
                      pw.SizedBox(height: 5),
                      _credRow(secretLabel.toUpperCase(), secret),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Text(
              '-- Keep confidential --',
              style: pw.TextStyle(
                fontSize: 5,
                color: PdfColors.grey400,
                fontStyle: pw.FontStyle.italic,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _credRow(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 5.5,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(0xFF9CA3AF),
            letterSpacing: 0.8,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: const pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(0xFF111827),
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Future<void> _printOne(
      SchoolAdminProvider p, Map<String, dynamic> it, bool isTeacher) async {
    final id = it['id'].toString();
    setState(() => _loadingIds.add(id));
    try {
      final nm = _name(it);
      final un = (it['username'] ?? '').toString();
      final sec = _secret(it, isTeacher);
      final sl = isTeacher ? 'Password' : 'PIN';
      String? ex;
      if (isTeacher) {
        final s = (it['staff_id'] ?? '').toString();
        if (s.isNotEmpty) ex = 'Staff ID: $s';
      } else {
        final s = (it['admission_no'] ?? '').toString();
        if (s.isNotEmpty) ex = 'Adm No: $s';
      }
      final sn = p.schoolName;
      final logo = await _fetchLogo(p.schoolLogoUrl);
      final pdf = pw.Document(theme: pw.ThemeData.withFont());
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (_) => pw.Center(
            child: pw.SizedBox(
              width: 260,
              child: _credCard(sn, nm, un, sec, sl, ex, logo),
            ),
          ),
        ),
      );
      downloadPdfBytes(
          await pdf.save(), '${nm.replaceAll(' ', '_')}_creds.pdf');
    } catch (e) {
      if (mounted) _snack('Print error: $e', ok: false);
    } finally {
      if (mounted) setState(() => _loadingIds.remove(id));
    }
  }

  Future<void> _printAll(
      SchoolAdminProvider p, bool isTeacher, List<dynamic> items) async {
    final have = items
        .where((e) =>
            (e['username'] ?? '').toString().isNotEmpty &&
            !_needsRegen(_secret(e, isTeacher), isTeacher))
        .toList();
    if (have.isEmpty) {
      _snack('No credentials to print. Generate first.', ok: false);
      return;
    }
    setState(() => _printing = true);
    try {
      final sn = p.schoolName;
      final sl = isTeacher ? 'Password' : 'PIN';
      final logo = await _fetchLogo(p.schoolLogoUrl);
      final pdf = pw.Document(theme: pw.ThemeData.withFont());
      const cols = 2;
      const rows = 3;
      const perPage = cols * rows;
      final pageW = PdfPageFormat.a4.width - 48;
      final pageH = PdfPageFormat.a4.height - 48;
      final cardW = (pageW - 12) / cols;
      final cardH = (pageH - 16) / rows;

      for (var i = 0; i < have.length; i += perPage) {
        final pageItems = have.skip(i).take(perPage).toList();
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(24),
            build: (_) => pw.Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                for (final it in pageItems)
                  pw.SizedBox(
                    width: cardW,
                    height: cardH,
                    child: _credCard(
                      sn,
                      _name(it),
                      (it['username'] ?? '').toString(),
                      _secret(it, isTeacher),
                      sl,
                      isTeacher
                          ? (it['staff_id'] ?? '').toString().isNotEmpty
                              ? 'Staff ID: ${it['staff_id']}'
                              : null
                          : (it['admission_no'] ?? '').toString().isNotEmpty
                              ? 'Adm No: ${it['admission_no']}'
                              : null,
                      logo,
                    ),
                  ),
              ],
            ),
          ),
        );
      }
      downloadPdfBytes(await pdf.save(),
          '${isTeacher ? 'Teachers' : 'Students'}_Creds.pdf');
      if (mounted) _snack('Printed ${have.length} credential(s)');
    } catch (e) {
      if (mounted) _snack('Print error: $e', ok: false);
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  List<dynamic> _filterTeachers(SchoolAdminProvider p) {
    if (_teacherClassId == null) return p.teachers;
    return p.teachers
        .where((t) => p.assignments.any((a) =>
            a['teacher_id']?.toString() == t['id']?.toString() &&
            a['class_id']?.toString() == _teacherClassId))
        .toList();
  }

  List<dynamic> _filterStudents(SchoolAdminProvider p) {
    if (_studentClassId == null) return p.students;
    return p.students
        .where((s) => s['class_id']?.toString() == _studentClassId)
        .toList();
  }

  Widget _iconBtn(IconData icon, Color color, bool loading,
      VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4FF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: loading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(icon, size: 15, color: color),
      ),
    );
  }

  Widget _inlineCreds(Map<String, dynamic> it, bool isTeacher) {
    final un = (it['username'] ?? '').toString();
    final sec = _secret(it, isTeacher);
    final sl = isTeacher ? 'Password' : 'PIN';
    final bad = _needsRegen(sec, isTeacher);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
        border: Border.all(color: const Color(0xFFD0D5DD)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: un),
                  readOnly: true,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF111827)),
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(
                        color: Colors.grey.shade600, fontSize: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFAFBFC),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: TextEditingController(
                      text: bad
                          ? (sec.startsWith('\$2')
                              ? '[bcrypt hash]'
                              : '[weak password]')
                          : sec),
                  readOnly: true,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: bad ? Colors.red.shade400 : const Color(0xFF111827),
                    letterSpacing: bad ? 0 : 1.2,
                  ),
                  decoration: InputDecoration(
                    labelText: sl,
                    labelStyle: TextStyle(
                        color: Colors.grey.shade600, fontSize: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor:
                        bad ? const Color(0xFFFFFBFB) : const Color(0xFFFAFBFC),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (!bad)
                GestureDetector(
                  onTap: () => _copy(un, sec, isTeacher),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy_rounded,
                            size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Copy',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: () => _regenerateOne(
                      context.read<SchoolAdminProvider>(), it, isTeacher),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh_rounded,
                            size: 14, color: Color(0xFFE65100)),
                        SizedBox(width: 4),
                        Text(
                          'Regenerate',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE65100),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: bad
                    ? null
                    : () => _printOne(
                        context.read<SchoolAdminProvider>(), it, isTeacher),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color:
                        bad ? Colors.grey.shade300 : const Color(0xFF1A237E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.print_rounded,
                          size: 14,
                          color: bad ? Colors.grey.shade500 : Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        'Print',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: bad ? Colors.grey.shade500 : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (bad) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 14, color: Colors.orange.shade700),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    sec.startsWith('\$2')
                        ? 'This ${isTeacher ? 'teacher' : 'student'} has a hashed password. Click "Regenerate" to set a new plain-text credential.'
                        : 'This password is too weak (4-digit). Click "Regenerate" to set a strong password.',
                    style: TextStyle(
                        fontSize: 11, color: Colors.orange.shade700),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildList(
      List<dynamic> items, SchoolAdminProvider p, bool isTeacher) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isTeacher
                    ? Icons.person_off_rounded
                    : Icons.school_rounded,
                size: 28,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No ${isTeacher ? 'teachers' : 'students'} found',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500),
            ),
            const SizedBox(height: 4),
            Text(
              'Adjust the filter or add ${isTeacher ? 'teachers' : 'students'} first',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final it = items[i];
        final id = it['id'].toString();
        final nm = _name(it);
        final un = (it['username'] ?? '').toString();
        final sec = _secret(it, isTeacher);
        final has = un.isNotEmpty;
        final bad = _needsRegen(sec, isTeacher);
        final ld = _loadingIds.contains(id);
        final isOpen = _viewingId == id;
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color:
                      i.isEven ? const Color(0xFFFAFBFC) : Colors.white,
                  borderRadius: isOpen
                      ? const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10))
                      : BorderRadius.circular(10),
                  border: Border.all(
                      color: isOpen
                          ? const Color(0xFFD0D5DD)
                          : const Color(0xFFE8EAED)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFF0F4FF),
                      child: Text(
                        nm.isNotEmpty ? nm[0].toUpperCase() : '?',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A237E)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nm,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (has)
                            Text(
                              isOpen
                                  ? (bad
                                      ? 'Weak password -- see below'
                                      : 'Credentials shown below')
                                  : (bad
                                      ? '$un | [weak password]'
                                      : '$un | ${isTeacher ? 'Pwd' : 'PIN'}: $sec'),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: bad
                                      ? Colors.orange.shade600
                                      : (isOpen
                                          ? const Color(0xFF1A237E)
                                          : Colors.grey.shade500),
                                  fontStyle:
                                      isOpen ? FontStyle.italic : null),
                            )
                          else
                            Text(
                              'No credentials',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade400,
                                  fontStyle: FontStyle.italic),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (has && !bad)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Ready',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2E7D32)),
                        ),
                      )
                    else if (has && bad)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          sec.startsWith('\$2') ? 'Hashed' : 'Weak',
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFE65100)),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Pending',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFE65100)),
                        ),
                      ),
                    const SizedBox(width: 8),
                    if (has && !bad)
                      _iconBtn(
                          Icons.print_rounded,
                          const Color(0xFF1A237E),
                          ld,
                          ld
                              ? null
                              : () => _printOne(p, it, isTeacher))
                    else
                      const SizedBox(width: 27),
                    const SizedBox(width: 6),
                    _iconBtn(
                      isOpen
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      isOpen
                          ? const Color(0xFFE65100)
                          : (has
                              ? const Color(0xFF1A237E)
                              : Colors.grey.shade400),
                      false,
                      has
                          ? () => setState(
                              () => _viewingId = isOpen ? null : id)
                          : null,
                    ),
                  ],
                ),
              ),
              if (isOpen) _inlineCreds(it, isTeacher),
            ],
          ),
        );
      },
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, bool loading,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2))
            else
              Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabContent(SchoolAdminProvider p, bool isTeacher) {
    final items = isTeacher ? _filterTeachers(p) : _filterStudents(p);
    final sel = isTeacher ? _teacherClassId : _studentClassId;
    final miss =
        items.where((e) => (e['username'] ?? '').toString().isEmpty).length;
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8EAED)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String?>(
                    value: sel,
                    hint: const Text(
                      'All Classes',
                      style:
                          TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                    ),
                    isDense: true,
                    underline: const SizedBox(),
                    borderRadius: BorderRadius.circular(8),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(
                          'All Classes',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      for (final c in p.classes)
                        DropdownMenuItem(
                          value: c['id'].toString(),
                          child: Text(
                            c['name'].toString(),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(() {
                      if (isTeacher) {
                        _teacherClassId = v;
                      } else {
                        _studentClassId = v;
                      }
                    }),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (miss > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$miss pending',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE65100)),
                  ),
                ),
              const SizedBox(width: 10),
              _actionBtn(
                Icons.auto_awesome_rounded,
                'Generate',
                const Color(0xFF2E7D32),
                _generating,
                () => _generate(p, isTeacher, items),
              ),
              const SizedBox(width: 8),
              _actionBtn(
                Icons.print_rounded,
                'Print All',
                const Color(0xFF1A237E),
                _printing,
                () => _printAll(p, isTeacher, items),
              ),
            ],
          ),
        ),
        Expanded(child: _buildList(items, p, isTeacher)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F8FA),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8EAED)),
            ),
            child: TabBar(
              controller: _tabCtrl,
              labelColor: const Color(0xFF1A237E),
              unselectedLabelColor: Colors.grey.shade500,
              indicatorColor: const Color(0xFF1A237E),
              indicatorSize: TabBarIndicatorSize.label,
              indicatorWeight: 2.5,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              unselectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tabs: const [
                Tab(text: 'Teachers'),
                Tab(text: 'Students'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Consumer<SchoolAdminProvider>(
              builder: (_, p, __) => TabBarView(
                controller: _tabCtrl,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _tabContent(p, true),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _tabContent(p, false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

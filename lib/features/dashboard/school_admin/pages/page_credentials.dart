// ==========================================
// File: lib/features/dashboard/school_admin/pages/page_credentials.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../../../core/providers/school_admin_provider.dart';

class PageCredentials extends StatefulWidget {
  const PageCredentials({super.key});

  @override
  State<PageCredentials> createState() => _PageCredentialsState();
}

class _PageCredentialsState extends State<PageCredentials>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _loadingIds = {};
  bool _isPrintingAll = false;
  bool _isGeneratingAll = false;
  String? _selectedTeacherClassId;
  String? _selectedStudentClassId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _snack(String message, {bool success = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor:
            success ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.only(
            bottom: 24, left: 16, right: 16),
      ),
    );
  }

  String _getSchoolName(SchoolAdminProvider p) {
    final getterName = p.schoolName;
    final mapName =
        p.schoolInfoMap['name']?.toString() ?? '';
    if (getterName.isNotEmpty) return getterName;
    if (mapName.isNotEmpty) return mapName;
    return 'School';
  }

  String? _getLogoUrl(SchoolAdminProvider p) {
    return p.schoolLogoUrl.isNotEmpty ? p.schoolLogoUrl : null;
  }

  String _getSchoolAddress(SchoolAdminProvider p) {
    return p.fullAddress.isNotEmpty ? p.fullAddress : '';
  }

  String _getSchoolMotto(SchoolAdminProvider p) {
    return p.schoolMotto.isNotEmpty ? p.schoolMotto : '';
  }

  String _displayName(Map<String, dynamic> m) {
    final f = (m['first_name'] ?? '').toString().trim();
    final l = (m['last_name'] ?? '').toString().trim();
    if (f.isNotEmpty && l.isNotEmpty) return '$f $l';
    if (f.isNotEmpty) return f;
    if (l.isNotEmpty) return l;
    return '';
  }

  void _copy(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied!'),
        backgroundColor: Color(0xFF2E7D32),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8))),
      ),
    );
  }

  Future<void> _generateAll(SchoolAdminProvider p, bool isTeacher,
      List<dynamic> users) async {
    setState(() => _isGeneratingAll = true);
    int generated = 0;
    int skipped = 0;

    for (final u in users) {
      final id =
          (u as Map<String, dynamic>)['id']?.toString() ?? '';
      final hasCreds =
          (u['username'] ?? '').toString().isNotEmpty;
      if (hasCreds) {
        skipped++;
        continue;
      }
      try {
        final result = isTeacher
            ? await p.generateTeacherCredentialInDb(id)
            : await p.generateStudentCredentialInDb(id);
        if (result != null) generated++;
      } catch (e) {
        debugPrint('Generate error for $id: $e');
      }
    }

    if (mounted) {
      setState(() => _isGeneratingAll = false);
      String msg =
          '$generated credential${generated != 1 ? 's' : ''} generated';
      if (skipped > 0) {
        msg += ', $skipped already had credentials';
      }
      _snack(msg, success: generated > 0);
    }
  }

  Future<void> _printSlip(SchoolAdminProvider p, String name,
      String username, String secret, String secretLabel,
      {String? extraInfo}) async {
    try {
      final pdf = pw.Document(
          theme: pw.ThemeData.withFont(
              base: pw.Font.helvetica()));
      final schoolName = _getSchoolName(p);
      final schoolAddress = _getSchoolAddress(p);
      final schoolMotto = _getSchoolMotto(p);

      pw.ImageProvider? logoImg;
      final logoUrl = _getLogoUrl(p);
      if (logoUrl != null) {
        try {
          final res = await http.get(Uri.parse(logoUrl));
          if (res.statusCode == 200 &&
              res.bodyBytes.isNotEmpty) {
            logoImg = pw.MemoryImage(res.bodyBytes);
          }
        } catch (e) {
          debugPrint('Logo fetch error: $e');
        }
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => pw.Center(
            child: pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(24),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                    color: PdfColors.blue800, width: 1.5),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  if (logoImg != null)
                    pw.Container(
                        height: 70,
                        width: 70,
                        child: pw.Image(logoImg,
                            fit: pw.BoxFit.contain)),
                  if (logoImg != null) pw.SizedBox(height: 10),
                  pw.Text(schoolName.toUpperCase(),
                      style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800)),
                  if (schoolAddress.isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(schoolAddress,
                        style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey600)),
                  ],
                  if (schoolMotto.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text('"$schoolMotto"',
                        style: pw.TextStyle(
                            fontSize: 9,
                            fontStyle: pw.FontStyle.italic,
                            color: PdfColors.grey600)),
                  ],
                  pw.SizedBox(height: 4),
                  pw.Divider(color: PdfColors.blue200),
                  pw.SizedBox(height: 16),
                  pw.Text('$secretLabel Slip',
                      style: pw.TextStyle(
                          fontSize: 13, color: PdfColors.grey700)),
                  pw.SizedBox(height: 20),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment:
                          pw.CrossAxisAlignment.start,
                      children: [
                        _pdfRow('Name', name),
                        pw.SizedBox(height: 10),
                        _pdfRow('Username', username),
                        pw.SizedBox(height: 10),
                        _pdfRow(secretLabel, secret),
                        if (extraInfo != null &&
                            extraInfo.isNotEmpty) ...[
                          pw.SizedBox(height: 10),
                          _pdfRow('Class', extraInfo),
                        ],
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                      'Keep this information safe. Do not share your $secretLabel.',
                      style: pw.TextStyle(
                          fontSize: 9, color: PdfColors.grey500),
                      textAlign: pw.TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      );

      await Printing.layoutPdf(
          onLayout: (format) async => pdf.save(),
          name: '${name}_credentials.pdf');
    } catch (e) {
      debugPrint('Print slip error: $e');
      if (mounted) {
        _snack('Print error: $e', success: false);
      }
    }
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('$label: ',
            style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, fontSize: 12)),
        pw.Expanded(
            child: pw.Text(value,
                style: pw.TextStyle(fontSize: 12))),
      ],
    );
  }

  Future<void> _printAll(SchoolAdminProvider p, bool isTeacher,
      List<dynamic> filteredUsers) async {
    setState(() => _isPrintingAll = true);

    try {
      final pdf = pw.Document(
          theme: pw.ThemeData.withFont(
              base: pw.Font.helvetica()));
      final schoolName = _getSchoolName(p);
      final schoolAddress = _getSchoolAddress(p);
      final schoolMotto = _getSchoolMotto(p);

      pw.ImageProvider? logoImg;
      final logoUrl = _getLogoUrl(p);
      if (logoUrl != null) {
        try {
          final res = await http.get(Uri.parse(logoUrl));
          if (res.statusCode == 200 &&
              res.bodyBytes.isNotEmpty) {
            logoImg = pw.MemoryImage(res.bodyBytes);
          }
        } catch (_) {}
      }

      final withCreds = filteredUsers.where((u) {
        final hasUsername =
            (u['username'] ?? '').toString().isNotEmpty;
        final hasSecret = isTeacher
            ? (u['password'] ?? '').toString().isNotEmpty
            : (u['pin'] ?? '').toString().isNotEmpty;
        return hasUsername && hasSecret;
      }).toList();

      if (withCreds.isEmpty) {
        if (mounted) {
          _snack(
              'No credentials to print. Generate first.',
              success: false);
        }
        setState(() => _isPrintingAll = false);
        return;
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => withCreds.map((u) {
            final displayName = _displayName(
                u as Map<String, dynamic>);
            final username =
                (u['username'] ?? '').toString();
            final secret = isTeacher
                ? (u['password'] ?? '').toString()
                : (u['pin'] ?? '').toString();
            final secretLabel =
                isTeacher ? 'Password' : 'PIN';

            String? extraInfo;
            if (!isTeacher) {
              final admNo =
                  (u['admission_no'] ?? '').toString().trim();
              final className =
                  (u['class_name'] ?? '').toString().trim();
              if (className.isNotEmpty) extraInfo = className;
              if (admNo.isNotEmpty && extraInfo != null) {
                extraInfo = '$extraInfo (Adm: $admNo)';
              } else if (admNo.isNotEmpty) {
                extraInfo = 'Adm: $admNo';
              }
            } else {
              final staffId =
                  (u['staff_id'] ?? '').toString().trim();
              if (staffId.isNotEmpty) {
                extraInfo = 'Staff ID: $staffId';
              }
            }

            return pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(14),
              margin:
                  const pw.EdgeInsets.only(bottom: 14),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                    color: PdfColors.blue800),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment:
                    pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    crossAxisAlignment:
                        pw.CrossAxisAlignment.start,
                    children: [
                      if (logoImg != null)
                        pw.Container(
                            height: 36,
                            width: 36,
                            margin:
                                const pw.EdgeInsets.only(right: 10),
                            child: pw.Image(logoImg,
                                fit: pw.BoxFit.contain)),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment:
                              pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                                schoolName.toUpperCase(),
                                style: pw.TextStyle(
                                    fontSize: 13,
                                    fontWeight:
                                        pw.FontWeight.bold,
                                    color:
                                        PdfColors.blue800)),
                            if (schoolAddress.isNotEmpty)
                              pw.Text(schoolAddress,
                                  style: pw.TextStyle(
                                      fontSize: 8,
                                      color: PdfColors
                                          .grey600)),
                            if (schoolMotto.isNotEmpty)
                              pw.Text('"$schoolMotto"',
                                  style: pw.TextStyle(
                                      fontSize: 7,
                                      fontStyle:
                                          pw.FontStyle.italic,
                                      color: PdfColors
                                          .grey600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Divider(color: PdfColors.blue200),
                  pw.SizedBox(height: 10),
                  pw.Text(displayName,
                      style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold)),
                  if (extraInfo != null) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(extraInfo,
                        style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey600)),
                  ],
                  pw.SizedBox(height: 10),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius:
                          pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      crossAxisAlignment:
                          pw.CrossAxisAlignment.start,
                      children: [
                        _pdfRow('Username', username),
                        pw.SizedBox(height: 6),
                        _pdfRow(secretLabel, secret),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );

      await Printing.layoutPdf(
          onLayout: (format) async => pdf.save(),
          name:
              '${isTeacher ? 'Teachers' : 'Students'}_Credentials.pdf');
    } catch (e) {
      debugPrint('Bulk print error: $e');
      if (mounted) {
        _snack('Print error: $e', success: false);
      }
    } finally {
      if (mounted) setState(() => _isPrintingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F8FA),
      child: Column(
        children: [
          // Tab bar
          Container(
            margin: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8EAED)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF1A237E),
              unselectedLabelColor: Colors.grey.shade500,
              indicatorColor: const Color(0xFF1A237E),
              indicatorSize: TabBarIndicatorSize.label,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14),
              unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 14),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_outline, size: 18),
                      SizedBox(width: 6),
                      Text('Teachers'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.school_rounded, size: 18),
                      SizedBox(width: 6),
                      Text('Students'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Content
          Expanded(
            child: Consumer<SchoolAdminProvider>(
              builder: (context, provider, child) {
                if (_isPrintingAll || _isGeneratingAll) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const CircularProgressIndicator(
                              strokeWidth: 3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isGeneratingAll
                              ? 'Generating credentials...'
                              : 'Preparing print...',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTeacherTab(provider),
                    _buildStudentTab(provider),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar({
    required SchoolAdminProvider provider,
    required String? selectedClassId,
    required ValueChanged<String?> onChanged,
    required int withoutCreds,
    required VoidCallback onGenerate,
    required VoidCallback onPrint,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Row(
        children: [
          // Filter dropdown
          Expanded(
            child: Container(
              height: 40,
              padding:
                  const EdgeInsets.only(left: 12, right: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFBFC),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: const Color(0xFFE8EAED)),
              ),
              alignment: Alignment.centerLeft,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedClassId,
                  hint: Text('Filter by Class',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500,
                      )),
                  icon: const Icon(Icons.arrow_drop_down,
                      color: Color(0xFF6B7280), size: 20),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(
                        value: null,
                        child: Text('All',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827)))),
                    ...provider.classes.map((c) {
                      final name =
                          (c['name'] ?? '').toString();
                      final sec =
                          (c['section'] ?? '').toString();
                      final display =
                          sec.isNotEmpty ? '$name — $sec' : name;
                      return DropdownMenuItem(
                        value: c['id']?.toString(),
                        child: Text(display,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827)),
                            overflow: TextOverflow.ellipsis),
                      );
                    }),
                  ],
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Generate All button
          _actionPill(
            icon: withoutCreds > 0
                ? Icons.key_rounded
                : Icons.check_circle_rounded,
            label: withoutCreds > 0
                ? 'Generate All ($withoutCreds)'
                : 'All Generated',
            color: withoutCreds > 0
                ? const Color(0xFF1A237E)
                : const Color(0xFF2E7D32),
            onTap: withoutCreds > 0 ? onGenerate : null,
          ),
          const SizedBox(width: 8),
          // Print All button
          _actionPill(
            icon: Icons.print_rounded,
            label: 'Print All',
            color: Colors.grey.shade600,
            onTap: onPrint,
          ),
        ],
      ),
    );
  }

  Widget _actionPill({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    final disabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: disabled ? color.withOpacity(0.1) : null,
          border: Border.all(
            color: disabled
                ? color.withOpacity(0.2)
                : color.withOpacity(0.4),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: disabled
                    ? color.withOpacity(0.4)
                    : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: disabled
                    ? color.withOpacity(0.4)
                    : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherTab(SchoolAdminProvider provider) {
    final teachers = provider.teachers;

    List<dynamic> filteredTeachers;
    if (_selectedTeacherClassId == null) {
      filteredTeachers = teachers;
    } else {
      try {
        final classId = _selectedTeacherClassId!;
        filteredTeachers = teachers.where((t) {
          try {
            final assignments = provider.assignments ?? [];
            return assignments.any((a) =>
                a['teacher_id']?.toString() ==
                    t['id']?.toString() &&
                a['class_id']?.toString() == classId);
          } catch (_) {
            return false;
          }
        }).toList();
      } catch (_) {
        filteredTeachers = teachers;
      }
    }

    final withoutCreds = filteredTeachers
        .where((t) =>
            (t['username'] ?? '').toString().isEmpty)
        .length;

    return Column(
      children: [
        _buildFilterBar(
          provider: provider,
          selectedClassId: _selectedTeacherClassId,
          onChanged: (v) => setState(
              () => _selectedTeacherClassId = v),
          withoutCreds: withoutCreds,
          onGenerate: () => _generateAll(
              provider, true, filteredTeachers),
          onPrint: () => _printAll(
              provider, true, filteredTeachers),
        ),
        Expanded(
          child: _buildPersonList(
            items: filteredTeachers,
            provider: provider,
            isTeacher: true,
          ),
        ),
      ],
    );
  }

  Widget _buildStudentTab(SchoolAdminProvider provider) {
    final allStudents = provider.students;

    final filteredStudents = _selectedStudentClassId == null
        ? allStudents
        : allStudents
            .where((s) =>
                s['class_id']?.toString() ==
                _selectedStudentClassId)
            .toList();

    final withoutCreds = filteredStudents
        .where((s) =>
            (s['username'] ?? '').toString().isEmpty)
        .length;

    return Column(
      children: [
        _buildFilterBar(
          provider: provider,
          selectedClassId: _selectedStudentClassId,
          onChanged: (v) => setState(
              () => _selectedStudentClassId = v),
          withoutCreds: withoutCreds,
          onGenerate: () => _generateAll(
              provider, false, filteredStudents),
          onPrint: () => _printAll(
              provider, false, filteredStudents),
        ),
        Expanded(
          child: _buildPersonList(
            items: filteredStudents,
            provider: provider,
            isTeacher: false,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonList({
    required List<dynamic> items,
    required SchoolAdminProvider provider,
    required bool isTeacher,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                isTeacher
                    ? Icons.person_outline
                    : Icons.school_outlined,
                size: 36,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No ${isTeacher ? 'teachers' : 'students'} found',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final m = items[index];
        final id = m['id']?.toString() ?? '';
        final displayName =
            _displayName(m as Map<String, dynamic>);
        final hasCreds =
            (m['username'] ?? '').toString().isNotEmpty;
        final bgColor = index % 2 == 0
            ? Colors.white
            : const Color(0xFFFAFBFC);

        // Sub-info
        String subInfo = '';
        if (isTeacher) {
          final staffId =
              (m['staff_id'] ?? '').toString().trim();
          if (staffId.isNotEmpty) subInfo = staffId;
        } else {
          final admNo =
              (m['admission_no'] ?? '').toString().trim();
          try {
            final cls =
                m['classes'] as Map<String, dynamic>?;
            if (cls != null) {
              final cn = cls['name']?.toString() ?? '';
              final cs =
                  cls['section']?.toString() ?? '';
              final classDisplay =
                  cs.isNotEmpty ? '$cn $cs' : cn;
              subInfo = classDisplay;
              if (admNo.isNotEmpty) {
                subInfo =
                    '$subInfo  •  Adm: $admNo';
              }
            } else if (admNo.isNotEmpty) {
              subInfo = 'Adm: $admNo';
            }
          } catch (_) {
            if (admNo.isNotEmpty) subInfo = 'Adm: $admNo';
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE8EAED)),
          ),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 18,
                backgroundColor: hasCreds
                    ? const Color(0xFF1A237E)
                    : Colors.grey.shade300,
                child: Text(
                  displayName.isNotEmpty
                      ? displayName
                          .substring(0, 1)
                          .toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: hasCreds
                        ? Colors.white
                        : Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Name + sub
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subInfo.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subInfo,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status badge
              _buildCredBadge(hasCreds),
              const SizedBox(width: 8),
              // Action
              _loadingIds.contains(id)
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2))
                  : hasCreds
                      ? InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () => _handleView(
                              provider, id, isTeacher),
                          child: Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A237E)
                                  .withOpacity(0.1),
                              border: Border.all(
                                color: const Color(0xFF1A237E)
                                    .withOpacity(0.3),
                              ),
                              borderRadius:
                                  BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'View',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A237E),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(
                          width: 36,
                          child: Text('—',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 12))),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCredBadge(bool hasCreds) {
    if (hasCreds) {
      return Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded,
                size: 12, color: Color(0xFF2E7D32)),
            SizedBox(width: 4),
            Text('Ready',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2E7D32),
                )),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('Pending',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
          )),
    );
  }

  Future<void> _handleView(SchoolAdminProvider provider,
      String id, bool isTeacher) async {
    setState(() => _loadingIds.add(id));

    try {
      final users =
          isTeacher ? provider.teachers : provider.students;
      Map<String, dynamic>? user;
      try {
        user = users
            .cast<Map<String, dynamic>?>()
            .firstWhere(
                (u) => u?['id']?.toString() == id,
                orElse: () => null);
      } catch (_) {}

      if (user == null) {
        _snack('User not found', success: false);
        return;
      }

      final displayName = _displayName(user);
      final username =
          (user['username'] ?? '').toString();
      final secret = isTeacher
          ? (user['password'] ?? '').toString()
          : (user['pin'] ?? '').toString();
      final secretLabel = isTeacher ? 'Password' : 'PIN';

      String? extraInfo;
      if (!isTeacher) {
        final admNo =
            (user['admission_no'] ?? '').toString().trim();
        final className =
            (user['class_name'] ?? '').toString().trim();
        if (className.isNotEmpty) extraInfo = className;
        if (admNo.isNotEmpty && extraInfo != null) {
          extraInfo = '$extraInfo (Adm: $admNo)';
        } else if (admNo.isNotEmpty) {
          extraInfo = 'Adm: $admNo';
        }
      } else {
        final staffId =
            (user['staff_id'] ?? '').toString().trim();
        if (staffId.isNotEmpty) {
          extraInfo = 'Staff ID: $staffId';
        }
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4FF),
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isTeacher
                              ? Icons.person_rounded
                              : Icons.school_rounded,
                          size: 22,
                          color: const Color(0xFF1A237E),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          isTeacher
                              ? 'Teacher Credentials'
                              : 'Student Credentials',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Name
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  if (extraInfo != null) ...[
                    const SizedBox(height: 4),
                    Text(extraInfo,
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600)),
                  ],
                  const SizedBox(height: 16),
                  // Username field
                  TextField(
                    controller: TextEditingController(
                        text: username),
                    decoration: InputDecoration(
                      labelText: 'Username',
                      labelStyle: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: Colors.grey.shade300),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: Colors.grey.shade200),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFFAFBFC),
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.copy_rounded,
                            size: 16, color: Color(0xFF1A237E)),
                        onPressed: () =>
                            _copy(ctx, username),
                        tooltip: 'Copy',
                      ),
                    ),
                    readOnly: true,
                    style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF111827)),
                  ),
                  const SizedBox(height: 12),
                  // Secret field
                  TextField(
                    controller:
                        TextEditingController(text: secret),
                    decoration: InputDecoration(
                      labelText: secretLabel,
                      labelStyle: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: Colors.grey.shade300),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: Colors.grey.shade200),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFFAFBFC),
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.copy_rounded,
                            size: 16, color: Color(0xFF1A237E)),
                        onPressed: () => _copy(ctx, secret),
                        tooltip: 'Copy',
                      ),
                    ),
                    readOnly: true,
                    style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF111827)),
                  ),
                  const SizedBox(height: 20),
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                        10)),
                            padding:
                                const EdgeInsets.symmetric(
                                    vertical: 12),
                          ),
                          child: const Text('Close',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _printSlip(
                              provider,
                              displayName,
                              username,
                              secret,
                              secretLabel,
                              extraInfo: extraInfo,
                            );
                          },
                          icon: const Icon(Icons.print_rounded,
                              size: 18),
                          label: const Text('Print Slip',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF1A237E),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                        10)),
                            padding:
                                const EdgeInsets.symmetric(
                                    vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('View credential error: $e');
      _snack('Error: $e', success: false);
    } finally {
      if (mounted) setState(() => _loadingIds.remove(id));
    }
  }
}

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

  String _getSchoolName(SchoolAdminProvider p) {
    final getterName = p.schoolName;
    final mapName = p.schoolInfoMap['name']?.toString() ?? '';
    debugPrint('CRED: getter="$getterName" mapName="$mapName" instance=${identityHashCode(p)} type=${p.runtimeType} schoolId="${p.schoolId}"');
    if (getterName.isNotEmpty) return getterName;
    if (mapName.isNotEmpty) {
      debugPrint('CRED: GETTER SHADOWED — using mapName "$mapName"');
      return mapName;
    }
    debugPrint('CRED: BOTH EMPTY, falling back to SCHOOL');
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied!'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
    );
  }

  Future<void> _generateAll(SchoolAdminProvider p, bool isTeacher, List<dynamic> users) async {
    setState(() => _isGeneratingAll = true);
    int generated = 0;
    int skipped = 0;

    for (final u in users) {
      final id = (u as Map<String, dynamic>)['id']?.toString() ?? '';
      final hasCreds = (u['username'] ?? '').toString().isNotEmpty;
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
      String msg = '$generated credential${generated != 1 ? 's' : ''} generated';
      if (skipped > 0) msg += ', $skipped already had credentials';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: generated > 0 ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 3),
      ));
    }
  }

  Future<void> _printSlip(SchoolAdminProvider p, String name, String username, String secret, String secretLabel, {String? extraInfo}) async {
    try {
      final pdf = pw.Document(theme: pw.ThemeData.withFont(base: pw.Font.helvetica()));
      final schoolName = _getSchoolName(p);
      final schoolAddress = _getSchoolAddress(p);
      final schoolMotto = _getSchoolMotto(p);

      pw.ImageProvider? logoImg;
      final logoUrl = _getLogoUrl(p);
      if (logoUrl != null) {
        try {
          final res = await http.get(Uri.parse(logoUrl));
          if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
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
                border: pw.Border.all(color: PdfColors.blue800, width: 1.5),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  if (logoImg != null)
                    pw.Container(height: 70, width: 70, child: pw.Image(logoImg, fit: pw.BoxFit.contain)),
                  if (logoImg != null) pw.SizedBox(height: 10),
                  pw.Text(schoolName.toUpperCase(), style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                  if (schoolAddress.isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(schoolAddress, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                  ],
                  if (schoolMotto.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text('"$schoolMotto"', style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600)),
                  ],
                  pw.SizedBox(height: 4),
                  pw.Divider(color: PdfColors.blue200),
                  pw.SizedBox(height: 16),
                  pw.Text('$secretLabel Slip', style: pw.TextStyle(fontSize: 13, color: PdfColors.grey700)),
                  pw.SizedBox(height: 20),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(8)),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _pdfRow('Name', name),
                        pw.SizedBox(height: 10),
                        _pdfRow('Username', username),
                        pw.SizedBox(height: 10),
                        _pdfRow(secretLabel, secret),
                        if (extraInfo != null && extraInfo.isNotEmpty) ...[
                          pw.SizedBox(height: 10),
                          _pdfRow('Class', extraInfo),
                        ],
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text('Keep this information safe. Do not share your $secretLabel.', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500), textAlign: pw.TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      );

      await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: '${name}_credentials.pdf');
    } catch (e) {
      debugPrint('Print slip error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Print error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('$label: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
        pw.Expanded(child: pw.Text(value, style: pw.TextStyle(fontSize: 12))),
      ],
    );
  }

  Future<void> _printAll(SchoolAdminProvider p, bool isTeacher, List<dynamic> filteredUsers) async {
    setState(() => _isPrintingAll = true);

    try {
      final pdf = pw.Document(theme: pw.ThemeData.withFont(base: pw.Font.helvetica()));
      final schoolName = _getSchoolName(p);
      final schoolAddress = _getSchoolAddress(p);
      final schoolMotto = _getSchoolMotto(p);

      pw.ImageProvider? logoImg;
      final logoUrl = _getLogoUrl(p);
      if (logoUrl != null) {
        try {
          final res = await http.get(Uri.parse(logoUrl));
          if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
            logoImg = pw.MemoryImage(res.bodyBytes);
          }
        } catch (_) {}
      }

      final withCreds = filteredUsers.where((u) {
        final hasUsername = (u['username'] ?? '').toString().isNotEmpty;
        final hasSecret = isTeacher ? (u['password'] ?? '').toString().isNotEmpty : (u['pin'] ?? '').toString().isNotEmpty;
        return hasUsername && hasSecret;
      }).toList();

      if (withCreds.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No credentials to print. Generate credentials first.'),
            backgroundColor: Colors.orange,
          ));
        }
        setState(() => _isPrintingAll = false);
        return;
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => withCreds.map((u) {
            final displayName = _displayName(u as Map<String, dynamic>);
            final username = (u['username'] ?? '').toString();
            final secret = isTeacher ? (u['password'] ?? '').toString() : (u['pin'] ?? '').toString();
            final secretLabel = isTeacher ? 'Password' : 'PIN';

            String? extraInfo;
            if (!isTeacher) {
              final admNo = (u['admission_no'] ?? '').toString().trim();
              final className = (u['class_name'] ?? '').toString().trim();
              if (className.isNotEmpty) extraInfo = className;
              if (admNo.isNotEmpty && extraInfo != null) {
                extraInfo = '$extraInfo (Adm: $admNo)';
              } else if (admNo.isNotEmpty) {
                extraInfo = 'Adm: $admNo';
              }
            } else {
              final staffId = (u['staff_id'] ?? '').toString().trim();
              if (staffId.isNotEmpty) extraInfo = 'Staff ID: $staffId';
            }

            return pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(14),
              margin: const pw.EdgeInsets.only(bottom: 14),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.blue800), borderRadius: pw.BorderRadius.circular(8)),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (logoImg != null)
                        pw.Container(height: 36, width: 36, margin: const pw.EdgeInsets.only(right: 10), child: pw.Image(logoImg, fit: pw.BoxFit.contain)),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(schoolName.toUpperCase(), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                            if (schoolAddress.isNotEmpty) pw.Text(schoolAddress, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                            if (schoolMotto.isNotEmpty) pw.Text('"$schoolMotto"', style: pw.TextStyle(fontSize: 7, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Divider(color: PdfColors.blue200),
                  pw.SizedBox(height: 10),
                  pw.Text(displayName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  if (extraInfo != null) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(extraInfo, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                  ],
                  pw.SizedBox(height: 10),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(6)),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
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

      await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: '${isTeacher ? 'Teachers' : 'Students'}_Credentials.pdf');
    } catch (e) {
      debugPrint('Bulk print error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Print error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isPrintingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1E3C72),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1E3C72),
          tabs: const [
            Tab(text: 'Teachers', icon: Icon(Icons.person_outline, size: 18)),
            Tab(text: 'Students', icon: Icon(Icons.school, size: 18)),
          ],
        ),
        Expanded(
          child: Consumer<SchoolAdminProvider>(
            builder: (context, provider, child) {
              if (_isPrintingAll || _isGeneratingAll) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Generating...'),
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
            return assignments.any((a) => a['teacher_id']?.toString() == t['id']?.toString() && a['class_id']?.toString() == classId);
          } catch (_) {
            return false;
          }
        }).toList();
      } catch (_) {
        filteredTeachers = teachers;
      }
    }

    final withoutCreds = filteredTeachers.where((t) => (t['username'] ?? '').toString().isEmpty).length;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedTeacherClassId,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Class',
                    labelStyle: TextStyle(fontSize: 12),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    isDense: true,
                    prefixIcon: Icon(Icons.filter_list, size: 18),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Teachers', style: TextStyle(fontSize: 13))),
                    ...provider.classes.map((c) {
                      final name = (c['name'] ?? '').toString();
                      final section = (c['section'] ?? '').toString();
                      final display = section.isNotEmpty ? '$name - $section' : name;
                      return DropdownMenuItem(value: c['id']?.toString(), child: Text(display, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis));
                    }),
                  ],
                  onChanged: (v) => setState(() => _selectedTeacherClassId = v),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 36,
                child: ElevatedButton.icon(
                  icon: withoutCreds > 0 ? const Icon(Icons.key, size: 16) : const Icon(Icons.check_circle, size: 16),
                  label: Text(withoutCreds > 0 ? 'Generate All ($withoutCreds)' : 'All Generated', style: const TextStyle(fontSize: 12)),
                  onPressed: withoutCreds > 0 ? () => _generateAll(provider, true, filteredTeachers) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: withoutCreds > 0 ? const Color(0xFF1E3C72) : Colors.green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.green.shade100,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 36,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.print, size: 16),
                  label: const Text('Print All', style: TextStyle(fontSize: 12)),
                  onPressed: filteredTeachers.isNotEmpty ? () => _printAll(provider, true, filteredTeachers) : null,
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _buildTeacherList(filteredTeachers, provider)),
      ],
    );
  }

  Widget _buildTeacherList(List<dynamic> teachers, SchoolAdminProvider provider) {
    if (teachers.isEmpty) {
      return const Center(child: Text('No teachers found.', style: TextStyle(color: Colors.grey, fontSize: 13)));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: teachers.length,
      itemBuilder: (context, index) {
        final t = teachers[index];
        final id = t['id']?.toString() ?? '';
        final displayName = _displayName(t as Map<String, dynamic>);
        final staffId = (t['staff_id'] ?? '').toString();
        final hasCreds = (t['username'] ?? '').toString().isNotEmpty;

        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: hasCreds ? const Color(0xFF1E3C72) : Colors.grey.shade400,
                child: Text(displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 13)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (staffId.isNotEmpty) ...[
                          Text(staffId, style: const TextStyle(fontSize: 11, color: Color(0xFF555555))),
                          const SizedBox(width: 8),
                        ],
                        if (hasCreds)
                          const Icon(Icons.check_circle, size: 12, color: Colors.green)
                        else
                          const Icon(Icons.radio_button_unchecked, size: 12, color: Colors.grey),
                        const SizedBox(width: 3),
                        Text(hasCreds ? 'Credentials ready' : 'No credentials', style: TextStyle(fontSize: 10, color: hasCreds ? Colors.green : Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _loadingIds.contains(id)
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : hasCreds
                      ? SizedBox(
                          height: 30,
                          child: ElevatedButton(
                            onPressed: () => _handleView(provider, id, true),
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10), backgroundColor: const Color(0xFF1E3C72)),
                            child: const Text('View', style: TextStyle(fontSize: 11)),
                          ))
                      : const SizedBox(width: 40, child: Text('—', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 11))),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStudentTab(SchoolAdminProvider provider) {
    final allStudents = provider.students;

    final filteredStudents = _selectedStudentClassId == null
        ? allStudents
        : allStudents.where((s) => s['class_id']?.toString() == _selectedStudentClassId).toList();

    final withoutCreds = filteredStudents.where((s) => (s['username'] ?? '').toString().isEmpty).length;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStudentClassId,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Class',
                    labelStyle: TextStyle(fontSize: 12),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    isDense: true,
                    prefixIcon: Icon(Icons.filter_list, size: 18),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Students', style: TextStyle(fontSize: 13))),
                    ...provider.classes.map((c) {
                      final name = (c['name'] ?? '').toString();
                      final section = (c['section'] ?? '').toString();
                      final display = section.isNotEmpty ? '$name - $section' : name;
                      return DropdownMenuItem(value: c['id']?.toString(), child: Text(display, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis));
                    }),
                  ],
                  onChanged: (v) => setState(() => _selectedStudentClassId = v),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 36,
                child: ElevatedButton.icon(
                  icon: withoutCreds > 0 ? const Icon(Icons.key, size: 16) : const Icon(Icons.check_circle, size: 16),
                  label: Text(withoutCreds > 0 ? 'Generate All ($withoutCreds)' : 'All Generated', style: const TextStyle(fontSize: 12)),
                  onPressed: withoutCreds > 0 ? () => _generateAll(provider, false, filteredStudents) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: withoutCreds > 0 ? const Color(0xFF1E3C72) : Colors.green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.green.shade100,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 36,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.print, size: 16),
                  label: const Text('Print All', style: TextStyle(fontSize: 12)),
                  onPressed: filteredStudents.isNotEmpty ? () => _printAll(provider, false, filteredStudents) : null,
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _buildStudentList(filteredStudents, provider)),
      ],
    );
  }

  Widget _buildStudentList(List<dynamic> students, SchoolAdminProvider provider) {
    if (students.isEmpty) {
      return const Center(child: Text('No students found.', style: TextStyle(color: Colors.grey, fontSize: 13)));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final s = students[index];
        final id = s['id']?.toString() ?? '';
        final displayName = _displayName(s as Map<String, dynamic>);
        final admNo = (s['admission_no'] ?? '').toString();
        final hasCreds = (s['username'] ?? '').toString().isNotEmpty;

        String classDisplay = '';
        try {
          final cls = s['classes'] as Map<String, dynamic>?;
          if (cls != null) {
            final cn = cls['name']?.toString() ?? '';
            final cs = cls['section']?.toString() ?? '';
            classDisplay = cs.isNotEmpty ? '$cn $cs' : cn;
          }
        } catch (_) {}

        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: hasCreds ? const Color(0xFF1E3C72) : Colors.grey.shade400,
                child: Text(displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 13)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (admNo.isNotEmpty) ...[
                          Text(admNo, style: const TextStyle(fontSize: 11, color: Color(0xFF555555))),
                          const SizedBox(width: 8),
                        ],
                        if (classDisplay.isNotEmpty) ...[
                          Text(classDisplay, style: const TextStyle(fontSize: 11, color: Color(0xFF1E3C72))),
                          const SizedBox(width: 8),
                        ],
                        if (hasCreds)
                          const Icon(Icons.check_circle, size: 12, color: Colors.green)
                        else
                          const Icon(Icons.radio_button_unchecked, size: 12, color: Colors.grey),
                        const SizedBox(width: 3),
                        Text(hasCreds ? 'Credentials ready' : 'No credentials', style: TextStyle(fontSize: 10, color: hasCreds ? Colors.green : Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _loadingIds.contains(id)
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : hasCreds
                      ? SizedBox(
                          height: 30,
                          child: ElevatedButton(
                            onPressed: () => _handleView(provider, id, false),
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10), backgroundColor: const Color(0xFF1E3C72)),
                            child: const Text('View', style: TextStyle(fontSize: 11)),
                          ))
                      : const SizedBox(width: 40, child: Text('—', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 11))),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleView(SchoolAdminProvider provider, String id, bool isTeacher) async {
    setState(() => _loadingIds.add(id));

    try {
      final users = isTeacher ? provider.teachers : provider.students;
      Map<String, dynamic>? user;
      try {
        user = users.cast<Map<String, dynamic>?>().firstWhere((u) => u?['id']?.toString() == id, orElse: () => null);
      } catch (_) {}

      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not found'), backgroundColor: Colors.red));
        }
        return;
      }

      final displayName = _displayName(user);
      final username = (user['username'] ?? '').toString();
      final secret = isTeacher ? (user['password'] ?? '').toString() : (user['pin'] ?? '').toString();
      final secretLabel = isTeacher ? 'Password' : 'PIN';

      String? extraInfo;
      if (!isTeacher) {
        final admNo = (user['admission_no'] ?? '').toString().trim();
        final className = (user['class_name'] ?? '').toString().trim();
        if (className.isNotEmpty) extraInfo = className;
        if (admNo.isNotEmpty && extraInfo != null) {
          extraInfo = '$extraInfo (Adm: $admNo)';
        } else if (admNo.isNotEmpty) {
          extraInfo = 'Adm: $admNo';
        }
      } else {
        final staffId = (user['staff_id'] ?? '').toString().trim();
        if (staffId.isNotEmpty) extraInfo = 'Staff ID: $staffId';
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(isTeacher ? 'Teacher Credentials' : 'Student Credentials', style: const TextStyle(fontSize: 16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: $displayName', style: const TextStyle(fontWeight: FontWeight.w600)),
                if (extraInfo != null) ...[
                  const SizedBox(height: 4),
                  Text(extraInfo, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: TextEditingController(text: username),
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: const TextStyle(fontSize: 12),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    isDense: true,
                    suffixIcon: IconButton(icon: const Icon(Icons.copy, size: 16), onPressed: () => _copy(ctx, username), tooltip: 'Copy'),
                  ),
                  readOnly: true,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: TextEditingController(text: secret),
                  decoration: InputDecoration(
                    labelText: secretLabel,
                    labelStyle: const TextStyle(fontSize: 12),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    isDense: true,
                    suffixIcon: IconButton(icon: const Icon(Icons.copy, size: 16), onPressed: () => _copy(ctx, secret), tooltip: 'Copy'),
                  ),
                  readOnly: true,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
              ElevatedButton.icon(
                icon: const Icon(Icons.print, size: 18),
                label: const Text('Print Slip'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3C72), foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.pop(ctx);
                  _printSlip(provider, displayName, username, secret, secretLabel, extraInfo: extraInfo);
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('View credential error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loadingIds.remove(id));
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartedu/core/providers/student/student_provider.dart';
import '../../school_admin/widgets/change_password_section.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  Map<String, dynamic>? _extra;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchExtra();
  }

  Future<void> _fetchExtra() async {
    try {
      final p = context.read<StudentProvider>();
      if (p.studentId.isEmpty) { setState(() => _loading = false); return; }
      final res = await Supabase.instance.client
          .from('students')
          .select('school_level, sport_team, club_society, admission_session, admission_mode, home_address, parent_occupation')
          .eq('id', p.studentId)
          .maybeSingle();
      if (mounted && res != null) setState(() => _extra = res);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<StudentProvider>();

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)));
    }

    final e = _extra ?? {};
    final schoolLevel = (e['school_level'] as String?) ?? '';
    final sportTeam = (e['sport_team'] as String?) ?? '';
    final club = (e['club_society'] as String?) ?? '';
    final admSession = (e['admission_session'] as String?) ?? '';
    final admMode = (e['admission_mode'] as String?) ?? '';
    final homeAddr = (e['home_address'] as String?) ?? '';
    final parentOcc = (e['parent_occupation'] as String?) ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _header(p),
          const SizedBox(height: 14),
          _card(
            icon: Icons.person_outline_rounded,
            iconBg: const Color(0xFFF0F4FF),
            iconColor: const Color(0xFF1A237E),
            title: 'Personal Information',
            rows: [
              _row('Gender', _cap(p.gender)),
              _row('Date of Birth', _fmtDate(p.dateOfBirth)),
              _row('School Level', schoolLevel),
              _row('Sport Team', sportTeam),
              _row('Club / Society', club),
            ],
          ),
          const SizedBox(height: 14),
          _card(
            icon: Icons.family_restroom_rounded,
            iconBg: const Color(0xFFFFF3E0),
            iconColor: const Color(0xFFE65100),
            title: 'Parent / Guardian',
            rows: [
              _row('Name', p.parentName),
              _row('Phone', p.parentPhone),
              _row('Email', p.parentEmail),
              _row('Occupation', parentOcc),
              _row('Home Address', homeAddr),
            ],
          ),
          const SizedBox(height: 14),
          _card(
            icon: Icons.school_rounded,
            iconBg: const Color(0xFFF3E5F5),
            iconColor: const Color(0xFF7B1FA2),
            title: 'Academic',
            rows: [
              _row('Admission No', p.admissionNo),
              _row('Admission Session', admSession),
              _row('Admission Mode', admMode),
              _row('Class', p.classDisplay),
            ],
          ),
          const SizedBox(height: 14),
          ChangePasswordSection(
            title: 'Change PIN',
            subtitle: 'Update your login PIN',
            currentLabel: 'Current PIN',
            newLabel: 'New PIN',
            confirmLabel: 'Confirm New PIN',
            buttonLabel: 'Change PIN',
            onSubmit: (current, newPin) async {
              final res = await Supabase.instance.client.rpc('change_student_pin', params: {'student_id_param': p.studentId, 'old_pin': current, 'new_pin': newPin});
              return res as bool? ?? false;
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade400,
                side: BorderSide(color: Colors.red.shade400),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _header(StudentProvider p) {
    final passport = p.passportUrl;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Column(
        children: [
          if (p.schoolLogoUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white,
                backgroundImage: NetworkImage(p.schoolLogoUrl),
                onBackgroundImageError: (_, __) {},
              ),
            ),
          CircleAvatar(
            radius: 42,
            backgroundColor: const Color(0xFFF0F4FF),
            backgroundImage: passport.isNotEmpty ? NetworkImage(passport) : null,
            onBackgroundImageError: passport.isNotEmpty ? (_, __) {} : null,
            child: passport.isEmpty ? const Icon(Icons.person, size: 42, color: Color(0xFF1A237E)) : null,
          ),
          const SizedBox(height: 12),
          Text(p.fullName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _pill(p.admissionNo, const Color(0xFFF0F4FF), const Color(0xFF1A237E)),
              if (p.className.isNotEmpty) _pill(p.classDisplay, const Color(0xFFF0FFF4), const Color(0xFF2E7D32)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  Widget _card({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required List<Widget> rows,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 30, height: 30, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: iconColor)),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          ]),
          const SizedBox(height: 14),
          ...rows,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)))),
          Expanded(child: Text(value.isEmpty ? '-' : value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF111827)))),
        ],
      ),
    );
  }

  String _cap(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';

  String _fmtDate(String d) {
    if (d.isEmpty) return '-';
    try {
      final dt = DateTime.parse(d);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return d;
    }
  }
}

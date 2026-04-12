// ==========================================
// File: lib/features/dashboard/student/pages/student_profile_page.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartedu/core/providers/student/student_provider.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  Map<String, dynamic>? _student;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStudent();
  }

  Future<void> _loadStudent() async {
    try {
      final provider = context.read<StudentProvider>();
      final r = await Supabase.instance.client
          .from('students')
          .select()
          .eq('school_id', provider.schoolId)
          .eq('id', provider.studentId)
          .single();
      if (mounted) setState(() { _student = Map<String, dynamic>.from(r); _loading = false; });
    } catch (e) {
      debugPrint('Profile load error: $e');
      if (mounted) setState(() { _error = 'Failed to load profile'; _loading = false; });
    }
  }

  String _name() {
    if (_student == null) return '';
    final first = (_student!['first_name'] ?? '').toString();
    final middle = (_student!['middle_name'] ?? '').toString();
    final last = (_student!['last_name'] ?? '').toString();
    return '$first${middle.isNotEmpty ? ' $middle' : ''}${last.isNotEmpty ? ' $last' : ''}'.trim();
  }

  String _initials() {
    final n = _name();
    if (n.isEmpty) return 'S';
    final parts = n.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return n[0].toUpperCase();
  }

  String _passportUrl() {
    if (_student == null) return '';
    return (_student!['passport_url'] ?? '').toString();
  }

  Widget _fieldCard(String label, String value, {IconData? icon}) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF1A237E)),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color iconBg, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)));
    }
    if (_error != null) {
      return Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _loadStudent, child: const Text('Retry')),
        ],
      ));
    }
    if (_student == null) return const SizedBox.shrink();

    final passport = _passportUrl();
    final name = _name();
    final admissionNo = (_student!['admission_no'] ?? '').toString();
    final gender = (_student!['gender'] ?? '').toString();
    final dob = (_student!['date_of_birth'] ?? '').toString();
    final schoolLevel = (_student!['school_level'] ?? '').toString();
    final admissionSession = (_student!['admission_session'] ?? '').toString();
    final admissionMode = (_student!['admission_mode'] ?? '').toString();
    final sportTeam = (_student!['sport_team'] ?? '').toString();
    final clubSociety = (_student!['club_society'] ?? '').toString();
    final parentName = (_student!['parent_name'] ?? '').toString();
    final parentPhone = (_student!['parent_phone'] ?? '').toString();
    final parentEmail = (_student!['parent_email'] ?? '').toString();
    final parentOccupation = (_student!['parent_occupation'] ?? '').toString();
    final homeAddress = (_student!['home_address'] ?? '').toString();
    final gradStatus = (_student!['graduation_status'] ?? '').toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('My Profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827), letterSpacing: -0.5)),
          const SizedBox(height: 4),
          const Text('Personal and academic information', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8EAED)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: passport.isNotEmpty
                      ? Image.network(
                          passport,
                          width: 88,
                          height: 88,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _avatarPlaceholder(),
                        )
                      : _avatarPlaceholder(),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (name.isNotEmpty)
                        Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                      if (name.isEmpty) const Text('Student', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                      const SizedBox(height: 4),
                      if (admissionNo.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('ADM: $admissionNo', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A237E))),
                        ),
                      const SizedBox(height: 8),
                      Consumer<StudentProvider>(
                        builder: (_, provider, __) {
                          return Text(
                            provider.classDisplay,
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          _sectionHeader('Personal Information', Icons.person_outline, const Color(0xFFF0F4FF), const Color(0xFF1A237E)),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _fieldCard('Gender', gender, icon: Icons.wc_outlined),
              _fieldCard('Date of Birth', dob, icon: Icons.cake_outlined),
              _fieldCard('School Level', schoolLevel, icon: Icons.school_outlined),
              _fieldCard('Graduation Status', gradStatus, icon: Icons.verified_outlined),
            ],
          ),

          const SizedBox(height: 28),

          _sectionHeader('Admission Details', Icons.how_to_reg_outlined, const Color(0xFFFFF3E0), const Color(0xFFE65100)),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _fieldCard('Admission No', admissionNo, icon: Icons.tag_outlined),
              _fieldCard('Admission Session', admissionSession, icon: Icons.calendar_today_outlined),
              _fieldCard('Admission Mode', admissionMode, icon: Icons.login_outlined),
            ],
          ),

          const SizedBox(height: 28),

          _sectionHeader('Extracurricular', Icons.sports_soccer_outlined, const Color(0xFFF0FFF4), const Color(0xFF2E7D32)),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _fieldCard('Sport Team', sportTeam, icon: Icons.sports_basketball_outlined),
              _fieldCard('Club / Society', clubSociety, icon: Icons.groups_outlined),
            ],
          ),

          const SizedBox(height: 28),

          _sectionHeader('Parent / Guardian', Icons.family_restroom_outlined, const Color(0xFFF3E5F5), const Color(0xFF7B1FA2)),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _fieldCard('Parent Name', parentName, icon: Icons.person_outline),
              _fieldCard('Phone', parentPhone, icon: Icons.phone_outlined),
              _fieldCard('Email', parentEmail, icon: Icons.email_outlined),
              _fieldCard('Occupation', parentOccupation, icon: Icons.work_outline),
            ],
          ),

          const SizedBox(height: 28),

          if (homeAddress.isNotEmpty) ...[
            _sectionHeader('Contact', Icons.location_on_outlined, const Color(0xFFFFF8E1), const Color(0xFFF57F17)),
            _fieldCard('Home Address', homeAddress, icon: Icons.home_outlined),
            const SizedBox(height: 28),
          ],
        ],
      ),
    );
  }

  Widget _avatarPlaceholder() {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          _initials(),
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF1A237E)),
        ),
      ),
    );
  }
}

// ==========================================
// File: lib/features/dashboard/student/pages/student_profile_page.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../../../../core/providers/student/student_provider.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  Map<String, dynamic>? _student;
  String _className = 'Not assigned';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final provider = context.read<StudentProvider>();
      final studentId = provider.studentId;
      if (studentId == null) {
        if (mounted) {
          setState(() {
            _error = 'Student ID not found.';
            _isLoading = false;
          });
        }
        return;
      }

      final data = await Supabase.instance.client
          .from('students')
          .select('*, classes(name, section)')
          .eq('id', studentId)
          .single();

      if (mounted) {
        setState(() {
          _student = Map<String, dynamic>.from(data);
          final classes = data['classes'];
          if (classes != null && classes is Map<String, dynamic>) {
            final name = classes['name'] as String? ?? '';
            final section = classes['section'] as String? ?? '';
            _className = section.isNotEmpty ? '$name ($section)' : name;
          } else {
            _className = 'Not assigned';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load profile. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  String? _formatDate(dynamic dateStr) {
    if (dateStr == null) return null;
    try {
      final date = DateTime.parse(dateStr.toString());
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${date.day} ${months[date.month - 1]}, ${date.year}';
    } catch (_) {
      return dateStr.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A237E)),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Color(0xFFD32F2F)),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _loadProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A237E),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopBar(),
                        const SizedBox(height: 24),
                        _buildHeaderCard(),
                        const SizedBox(height: 16),
                        _buildSectionCard(
                          icon: Icons.person_outline_rounded,
                          iconBg: const Color(0xFFF0F4FF),
                          iconColor: const Color(0xFF1A237E),
                          title: 'Personal Information',
                          children: [
                            _infoPair('Gender', _student?['gender']),
                            _infoPair('Date of Birth', _formatDate(_student?['date_of_birth'])),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSectionCard(
                          icon: Icons.school_outlined,
                          iconBg: const Color(0xFFF0FFF4),
                          iconColor: const Color(0xFF2E7D32),
                          title: 'Academic Information',
                          children: [
                            _infoPair('Class', _className),
                            _infoPair('Admission No', _student?['admission_no']),
                            _infoPair('School Level', _student?['school_level']),
                            _infoPair('Admission Session', _student?['admission_session']),
                            _infoPair('Admission Mode', _student?['admission_mode']),
                            _infoPair('Class Admission Year', _student?['class_admission_year']?.toString()),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSectionCard(
                          icon: Icons.family_restroom_outlined,
                          iconBg: const Color(0xFFFFF8E1),
                          iconColor: const Color(0xFFF57F17),
                          title: 'Parent / Guardian Information',
                          children: [
                            _infoPair('Parent Name', _student?['parent_name']),
                            _infoPair('Phone', _student?['parent_phone']),
                            _infoPair('Email', _student?['parent_email']),
                            _infoPair('Occupation', _student?['parent_occupation']),
                            _infoPair('Home Address', _student?['home_address']),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSectionCard(
                          icon: Icons.sports_soccer_outlined,
                          iconBg: const Color(0xFFF3E5F5),
                          iconColor: const Color(0xFF7B1FA2),
                          title: 'Activities',
                          children: [
                            _infoPair('Sport Team', _student?['sport_team']),
                            _infoPair('Club / Society', _student?['club_society']),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE8EAED)),
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF64748B)),
          ),
        ),
        const SizedBox(width: 16),
        const Text(
          'My Profile',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCard() {
    final firstName = _student?['first_name'] as String? ?? '';
    final lastName = _student?['last_name'] as String? ?? '';
    final middleName = _student?['middle_name'] as String? ?? '';
    final admissionNo = _student?['admission_no'] as String? ?? '';
    final passportUrl = _student?['passport_url'] as String?;

    String fullName = '$firstName $lastName';
    if (middleName.isNotEmpty) {
      fullName = '$firstName $middleName $lastName';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: passportUrl != null && passportUrl.isNotEmpty
                  ? Image.network(
                      passportUrl,
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _photoPlaceholder(),
                    )
                  : _photoPlaceholder(),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    admissionNo,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.class_outlined, size: 16, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _className,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoPlaceholder() {
    return const Center(
      child: Icon(Icons.person_rounded, size: 40, color: Color(0xFF1A237E)),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 500) {
                final rows = <Widget>[];
                for (int i = 0; i < children.length; i += 2) {
                  rows.add(
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(child: children[i]),
                          if (i + 1 < children.length) ...[
                            const SizedBox(width: 24),
                            Expanded(child: children[i + 1]),
                          ],
                        ],
                      ),
                    ),
                  );
                }
                return Column(children: rows);
              } else {
                return Column(
                  children: children
                      .map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: c,
                          ))
                      .toList(),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _infoPair(String label, dynamic value) {
    final displayValue = (value == null || value.toString().trim().isEmpty)
        ? '—'
        : value.toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF9CA3AF),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          displayValue,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF111827),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

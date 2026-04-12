// ==========================================
// File: lib/features/dashboard/student/pages/student_announcements_page.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartedu/core/providers/student/student_provider.dart';

class StudentAnnouncementsPage extends StatefulWidget {
  const StudentAnnouncementsPage({super.key});

  @override
  State<StudentAnnouncementsPage> createState() => _StudentAnnouncementsPageState();
}

class _StudentAnnouncementsPageState extends State<StudentAnnouncementsPage> {
  List<Map<String, dynamic>> _announcements = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    try {
      final provider = context.read<StudentProvider>();

      // Get student's class_id
      final student = await Supabase.instance.client
          .from('students')
          .select('class_id')
          .eq('id', provider.studentId)
          .single();
      final classId = student['class_id']?.toString() ?? '';

      // Fetch published, non-expired announcements for this school
      final r = await Supabase.instance.client
          .from('announcements')
          .select()
          .eq('school_id', provider.schoolId)
          .eq('is_published', true)
          .or('expires_at.is.null,expires_at.gt.${DateTime.now().toUtc().toIso8601String()}')
          .order('is_pinned', ascending: false)
          .order('published_at', ascending: false);

      final all = List<Map<String, dynamic>>.from(r);

      // Filter: school-wide (class_id null) OR class-specific matching student's class
      // Also filter target_audience: 'all', 'students', or 'student' + class match
      final filtered = all.where((a) {
        final aClassId = a['class_id']?.toString() ?? '';
        final audience = (a['target_audience'] ?? '').toString().toLowerCase();

        // Class filter: must be school-wide or match student's class
        final classMatch = aClassId.isEmpty || aClassId == classId;
        if (!classMatch) return false;

        // Audience filter
        if (audience == 'all' || audience == 'students' || audience == 'student') return true;
        if (audience == 'teachers' || audience == 'teacher') return false;
        // If empty, treat as all
        return true;
      }).toList();

      // Load author names for display
      final authorIds = filtered
          .map((a) => a['author_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final authorMap = <String, String>{};
      if (authorIds.isNotEmpty) {
        // Try teachers
        final teachers = await Supabase.instance.client
            .from('teachers')
            .select('id, first_name, last_name')
            .eq('school_id', provider.schoolId)
            .inFilter('id', authorIds);
        for (final t in teachers) {
          final id = t['id']?.toString() ?? '';
          if (id.isNotEmpty) {
            authorMap[id] = '${t['first_name'] ?? ''} ${t['last_name'] ?? ''}'.trim();
          }
        }
      }

      if (mounted) {
        setState(() {
          _announcements = filtered.map((a) {
            final copy = Map<String, dynamic>.from(a);
            final aid = a['author_id']?.toString() ?? '';
            copy['_authorName'] = authorMap[aid] ?? (a['author_type'] ?? 'Admin');
            return copy;
          }).toList();
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Load announcements error: $e');
      if (mounted) setState(() { _error = 'Failed to load announcements'; _loading = false; });
    }
  }

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return '';
    final dt = DateTime.tryParse(dateVal.toString());
    if (dt == null) return '';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _timeAgo(dynamic dateVal) {
    if (dateVal == null) return '';
    final dt = DateTime.tryParse(dateVal.toString());
    if (dt == null) return '';
    final diff = DateTime.now().toUtc().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return _formatDate(dateVal);
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
          ElevatedButton(onPressed: _loadAnnouncements, child: const Text('Retry')),
        ],
      ));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Announcements', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827), letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text('${_announcements.length} announcement${_announcements.length != 1 ? 's' : ''}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 20),
          if (_announcements.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(60),
                child: Column(
                  children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.campaign_outlined, size: 32, color: Color(0xFF1A237E)),
                    ),
                    const SizedBox(height: 16),
                    const Text('No announcements', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                    const SizedBox(height: 4),
                    const Text('Announcements from your school will appear here', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            ..._announcements.map((a) {
              final isPinned = a['is_pinned'] == true;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isPinned ? const Color(0xFF1A237E) : const Color(0xFFE8EAED)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: isPinned ? const Color(0xFFF0F4FF) : const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isPinned ? Icons.push_pin : Icons.campaign,
                            size: 20,
                            color: isPinned ? const Color(0xFF1A237E) : const Color(0xFFF57F17),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a['title'] ?? 'Untitled', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                              const SizedBox(height: 2),
                              Text(
                                'By ${a['_authorName'] ?? ''}',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Text(_timeAgo(a['published_at']), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    if (a['content'] != null && (a['content'] as String).isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(a['content'], style: const TextStyle(fontSize: 14, color: Color(0xFF555555), height: 1.5)),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

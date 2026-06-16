// ==========================================
// File: lib/features/dashboard/school_admin/pages/page_announcements.dart
// ==========================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartedu/core/services/db_proxy.dart';
import 'package:smartedu/core/providers/school_admin_provider.dart';

class PageAnnouncements extends StatefulWidget {
  const PageAnnouncements({super.key});

  @override
  State<PageAnnouncements> createState() => _PageAnnouncementsState();
}

class _PageAnnouncementsState extends State<PageAnnouncements> {
  List<Map<String, dynamic>> _announcements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    try {
      final provider = context.read<SchoolAdminProvider>();
      final r = await DbProxy.instance
          .from('announcements')
          .select()
          .order('is_pinned', ascending: false)
          .order('created_at', ascending: false)
          .get();
      if (mounted) setState(() { _announcements = List<Map<String, dynamic>>.from(r); _loading = false; });
    } catch (e) {
      debugPrint('Load announcements error: $e');
      if (mounted) setState(() => _loading = false);
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

  void _showCreateSheet() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String targetAudience = 'all';
    String? selectedClassId;
    bool isPinned = false;
    bool publishNow = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          final provider = context.read<SchoolAdminProvider>();
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.campaign_outlined, size: 18, color: Color(0xFF1A237E)),
                    ),
                    const SizedBox(width: 12),
                    const Text('New Announcement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    prefixIcon: Icon(Icons.title_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: contentCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Content *',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: targetAudience,
                  decoration: const InputDecoration(
                    labelText: 'Target Audience',
                    prefixIcon: Icon(Icons.group_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Everyone')),
                    DropdownMenuItem(value: 'students', child: Text('Students Only')),
                    DropdownMenuItem(value: 'teachers', child: Text('Teachers Only')),
                  ],
                  onChanged: (v) => setSt(() { targetAudience = v ?? 'all'; selectedClassId = null; }),
                ),
                if (targetAudience == 'students' && provider.classes.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: selectedClassId,
                    decoration: const InputDecoration(
                      labelText: 'Specific Class (optional)',
                      prefixIcon: Icon(Icons.class_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Students')),
                      ...provider.classes.map((c) {
                        final name = c['name'] ?? '';
                        final section = c['section'] ?? '';
                        return DropdownMenuItem(value: c['id']?.toString(), child: Text(section.isNotEmpty ? '$name $section' : name));
                      }),
                    ],
                    onChanged: (v) => setSt(() => selectedClassId = v),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setSt(() => isPinned = !isPinned),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: isPinned ? const Color(0xFF1A237E) : const Color(0xFFE8EAED)),
                            borderRadius: BorderRadius.circular(8),
                            color: isPinned ? const Color(0xFFF0F4FF) : Colors.white,
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.push_pin, size: 16, color: isPinned ? const Color(0xFF1A237E) : Colors.grey),
                              const SizedBox(width: 8),
                              Text('Pin to top', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isPinned ? const Color(0xFF1A237E) : Colors.grey.shade600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setSt(() => publishNow = !publishNow),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: publishNow ? const Color(0xFF2E7D32) : const Color(0xFFE8EAED)),
                            borderRadius: BorderRadius.circular(8),
                            color: publishNow ? const Color(0xFFE8F5E9) : Colors.white,
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.publish, size: 16, color: publishNow ? const Color(0xFF2E7D32) : Colors.grey),
                              const SizedBox(width: 8),
                              Text('Publish now', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: publishNow ? const Color(0xFF2E7D32) : Colors.grey.shade600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titleCtrl.text.trim().isEmpty || contentCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Fill title and content'), backgroundColor: Color(0xFFD32F2F)),
                        );
                        return;
                      }
                      try {
                        final provider = context.read<SchoolAdminProvider>();
                        final insertRow = <String, dynamic>{
                          'school_id': provider.schoolId,
                          'author_type': 'admin',
                          'title': titleCtrl.text.trim(),
                          'content': contentCtrl.text.trim(),
                          'target_audience': targetAudience,
                          'class_id': selectedClassId,
                          'is_pinned': isPinned,
                          'is_published': publishNow,
                          'published_at': publishNow ? DateTime.now().toUtc().toIso8601String() : null,
                        };
                        await DbProxy.instance.from('announcements').insert(insertRow);
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Announcement created'), backgroundColor: Color(0xFF2E7D32)),
                          );
                          _loadAnnouncements();
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Failed: $e'), backgroundColor: Color(0xFFD32F2F)),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Create Announcement', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirm(Map<String, dynamic> a) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red, size: 24),
            SizedBox(width: 10),
            Text('Delete Announcement'),
          ],
        ),
        content: Text('Delete "${a['title'] ?? 'this announcement'}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final provider = context.read<SchoolAdminProvider>();
                await DbProxy.instance.from('announcements').eq('id', a['id']).delete();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Deleted'), backgroundColor: Color(0xFFD32F2F)),
                );
                _loadAnnouncements();
              } catch (e) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed: $e'), backgroundColor: Color(0xFFD32F2F)),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _togglePublish(Map<String, dynamic> a) async {
    try {
      final provider = context.read<SchoolAdminProvider>();
      final newVal = !(a['is_published'] == true);
      await DbProxy.instance.from('announcements').eq('id', a['id']).update({
        'is_published': newVal,
        'published_at': newVal ? DateTime.now().toUtc().toIso8601String() : null,
      });
      _loadAnnouncements();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Color(0xFFD32F2F)),
      );
    }
  }

  Future<void> _togglePin(Map<String, dynamic> a) async {
    try {
      final provider = context.read<SchoolAdminProvider>();
      final newVal = !(a['is_pinned'] == true);
      await DbProxy.instance.from('announcements').eq('id', a['id']).update({'is_pinned': newVal});
      _loadAnnouncements();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Color(0xFFD32F2F)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)));
    }

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Text('Announcements', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827), letterSpacing: -0.5)),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 4, 24, 0),
              child: Text('Broadcast messages to your school community', style: TextStyle(fontSize: 13, color: Colors.grey)),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _announcements.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64, height: 64,
                            decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(16)),
                            child: const Icon(Icons.campaign_outlined, size: 32, color: Color(0xFF1A237E)),
                          ),
                          const SizedBox(height: 16),
                          const Text('No announcements yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                          const SizedBox(height: 4),
                          const Text('Create one to keep everyone informed', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                      itemCount: _announcements.length,
                      itemBuilder: (context, index) {
                        final a = _announcements[index];
                        final isPublished = a['is_published'] == true;
                        final isPinned = a['is_pinned'] == true;
                        final audience = (a['target_audience'] ?? 'all').toString();
                        final expiresAt = a['expires_at'];
                        final isExpired = expiresAt != null && DateTime.tryParse(expiresAt.toString()) != null && DateTime.tryParse(expiresAt.toString())!.isBefore(DateTime.now());

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isPinned ? const Color(0xFF1A237E) : (isExpired ? Colors.grey.shade300 : const Color(0xFFE8EAED)),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44, height: 44,
                                    decoration: BoxDecoration(
                                      color: isPinned ? const Color(0xFFF0F4FF) : (isPublished ? const Color(0xFFFFF8E1) : const Color(0xFFF5F5F5)),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      isPinned ? Icons.push_pin : Icons.campaign,
                                      size: 20,
                                      color: isPinned ? const Color(0xFF1A237E) : (isPublished ? const Color(0xFFF57F17) : Colors.grey),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(a['title'] ?? 'Untitled', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                              decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(4)),
                                              child: Text(audience == 'all' ? 'Everyone' : audience, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF1A237E))),
                                            ),
                                            if (isExpired) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                                                child: Text('Expired', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.red.shade700)),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(_timeAgo(a['created_at']), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                              if (a['content'] != null && (a['content'] as String).isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(a['content'], style: const TextStyle(fontSize: 13, color: Color(0xFF555555), height: 1.4)),
                              ],
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  if (a['published_at'] != null) ...[
                                    Icon(Icons.schedule, size: 12, color: Colors.grey.shade400),
                                    const SizedBox(width: 4),
                                    Text('Published: ${_formatDate(a['published_at'])}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                    const SizedBox(width: 16),
                                  ],
                                  if (a['expires_at'] != null) ...[
                                    Icon(Icons.event_busy, size: 12, color: Colors.grey.shade400),
                                    const SizedBox(width: 4),
                                    Text('Expires: ${_formatDate(a['expires_at'])}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                    const SizedBox(width: 16),
                                  ],
                                  const Spacer(),
                                  IconButton(
                                    icon: Icon(Icons.push_pin, size: 18, color: isPinned ? const Color(0xFF1A237E) : Colors.grey.shade400),
                                    tooltip: isPinned ? 'Unpin' : 'Pin',
                                    onPressed: () => _togglePin(a),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  ),
                                  IconButton(
                                    icon: Icon(isPublished ? Icons.unpublished_outlined : Icons.publish_outlined, size: 18, color: isPublished ? Colors.orange : const Color(0xFF2E7D32)),
                                    tooltip: isPublished ? 'Unpublish' : 'Publish',
                                    onPressed: () => _togglePublish(a),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
                                    tooltip: 'Delete',
                                    onPressed: () => _showDeleteConfirm(a),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        Positioned(
          bottom: 24,
          right: 24,
          child: GestureDetector(
            onTap: _showCreateSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: const Color(0xFF1A237E).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('New Announcement', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:smartedu/core/services/db_proxy.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PageComplaints extends StatefulWidget {
  const PageComplaints({super.key});
  @override
  State<PageComplaints> createState() => _PageComplaintsState();
}

class _PageComplaintsState extends State<PageComplaints> {
  List<Map<String, dynamic>> _complaints = [];
  bool _loading = true;
  String? _statusFilter;
  String? _categoryFilter;
  String _searchQuery = '';

  final List<String> _allStatuses = ['open', 'in_progress', 'resolved', 'dismissed'];
  final List<String> _allCategories = ['Bullying', 'Facility Damage', 'Academic Issue', 'Staff Conduct', 'Health & Safety', 'Others'];

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    try {
      final schoolId = Supabase.instance.client.auth.currentUser?.id;
      // We need school_id from context — but this page doesn't have provider access
      // Fetch all and filter, or accept schoolId as param
      final r = await DbProxy.instance.from('complaints').select('*, students(first_name, last_name, admission_no, class_id), classes(name)').order('created_at', ascending: false).get();
      if (mounted) setState(() { _complaints = List<Map<String, dynamic>>.from(r); _loading = false; });
    } catch (e) {
      debugPrint('Load complaints error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _complaints;
    if (_statusFilter != null) {
      list = list.where((c) => (c['status'] ?? '') == _statusFilter).toList();
    }
    if (_categoryFilter != null) {
      list = list.where((c) => (c['category'] ?? '') == _categoryFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((c) {
        final student = c['students'] as Map<String, dynamic>? ?? {};
        final name = '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'.toLowerCase();
        final subject = (c['subject'] ?? '').toString().toLowerCase();
        return name.contains(q) || subject.contains(q);
      }).toList();
    }
    return list;
  }

  int _countByStatus(String status) {
    return _complaints.where((c) => (c['status'] ?? '') == status).length;
  }

  String _studentName(Map<String, dynamic> c) {
    final s = c['students'] as Map<String, dynamic>? ?? {};
    final first = s['first_name'] ?? '';
    final last = s['last_name'] ?? '';
    return '$first $last'.trim();
  }

  String _studentClass(Map<String, dynamic> c) {
    final cls = c['classes'] as Map<String, dynamic>? ?? {};
    return cls['name']?.toString() ?? '';
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
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'open': return const Color(0xFFF57F17);
      case 'in_progress': return const Color(0xFF1565C0);
      case 'resolved': return const Color(0xFF2E7D32);
      case 'dismissed': return Colors.grey;
      default: return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'open': return 'Open';
      case 'in_progress': return 'In Progress';
      case 'resolved': return 'Resolved';
      case 'dismissed': return 'Dismissed';
      default: return status;
    }
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    try {
      await DbProxy.instance.from('complaints').eq('id', id).update({'status': newStatus});
      _loadComplaints();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $_statusLabel(newStatus)'), backgroundColor: const Color(0xFF2E7D32), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: const Color(0xFFD32F2F), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        );
      }
    }
  }

  void _showResponseDialog(Map<String, dynamic> complaint) {
    final ctrl = TextEditingController(text: (complaint['resolution_note'] ?? '').toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.reply_outlined, color: Color(0xFF1A237E))),
            const SizedBox(width: 12),
            const Text('Respond to Complaint', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(complaint['subject'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF111827))),
            const SizedBox(height: 4),
            Text('By: ${_studentName(complaint)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: complaint['status'] ?? 'open',
              decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
              items: _allStatuses.map((s) => DropdownMenuItem(value: s, child: Text(_statusLabel(s)))).toList(),
              onChanged: null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: ctrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Resolution Note', alignLabelWithHint: true, border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final note = ctrl.text.trim();
              final status = complaint['status'] ?? 'open';
              try {
                final updates = <String, dynamic>{'resolution_note': note, 'status': status};
                if (status == 'resolved' || status == 'dismissed') {
                  updates['resolved_by'] = Supabase.instance.client.auth.currentUser?.id;
                }
                await DbProxy.instance.from('complaints').eq('id', complaint['id']).update(updates);
                _loadComplaints();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: const Text('Response saved'), backgroundColor: const Color(0xFF2E7D32), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e'), backgroundColor: const Color(0xFFD32F2F), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white),
            child: const Text('Save Response'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Complaints', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827), letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text('View and respond to student complaints', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          const SizedBox(height: 20),
          _buildStatusTabs(),
          const SizedBox(height: 16),
          _buildFilters(),
          const SizedBox(height: 16),
          _buildComplaintList(),
        ],
      ),
    );
  }

  Widget _buildStatusTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _StatusPill(label: 'All', count: _complaints.length, selected: _statusFilter == null, color: const Color(0xFF1A237E), onTap: () => setState(() => _statusFilter = null)),
          const SizedBox(width: 8),
          ..._allStatuses.map((s) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _StatusPill(label: _statusLabel(s), count: _countByStatus(s), selected: _statusFilter == s, color: _statusColor(s), onTap: () => setState(() => _statusFilter = _statusFilter == s ? null : s)),
          )),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE8EAED)), borderRadius: BorderRadius.circular(8)),
            child: TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey), hintText: 'Search by name or subject...', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              style: const TextStyle(fontSize: 13),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE8EAED)), borderRadius: BorderRadius.circular(8)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _categoryFilter,
              hint: Text('Category', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
              isDense: true,
              items: [const DropdownMenuItem(value: null, child: Text('All Categories')), ..._allCategories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))],
              onChanged: (v) => setState(() => _categoryFilter = v),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComplaintList() {
    final list = _filtered;
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            children: [
              Container(width: 64, height: 64, decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.inbox_outlined, size: 32, color: Color(0xFF1A237E))),
              const SizedBox(height: 16),
              Text(_complaints.isEmpty ? 'No complaints submitted yet' : 'No complaints match your filters', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
            ],
          ),
        ),
      );
    }
    return Column(children: list.map((c) => _buildComplaintCard(c)).toList());
  }

  Widget _buildComplaintCard(Map<String, dynamic> c) {
    final status = (c['status'] ?? 'open').toString();
    final category = (c['category'] ?? '').toString();
    final priority = (c['priority'] ?? 'normal').toString();
    final resolution = (c['resolution_note'] ?? '').toString();
    final isOpen = status == 'open';
    final isInProgress = status == 'in_progress';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOpen ? const Color(0xFFFFFFF8) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isOpen ? const Color(0xFFF57F17).withOpacity(0.3) : const Color(0xFFE8EAED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(c['subject'] ?? 'Untitled', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)))),
              const SizedBox(width: 8),
              if (priority == 'high') Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(4)),
                child: const Text('HIGH', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFD32F2F), letterSpacing: 0.5)),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(_statusLabel(status), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor(status))),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.person_outline, size: 14, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text(_studentName(c), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
              if (_studentClass(c).isNotEmpty) ...[
                Text('  ·  ', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                Text(_studentClass(c), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(4)),
                child: Text(category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
              ),
              const SizedBox(width: 8),
              Text(_timeAgo(c['created_at']), style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          if (c['description'] != null && (c['description'] as String).isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(c['description'], style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4)),
          ],
          if (resolution.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.rate_review_outlined, size: 16, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(resolution, style: const TextStyle(fontSize: 12, color: Color(0xFF2E7D32), height: 1.4))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (isOpen) ...[
                _actionBtn('Start Progress', Icons.play_arrow_outlined, const Color(0xFF1565C0), () => _updateStatus(c['id'], 'in_progress')),
                const SizedBox(width: 8),
              ],
              if (isInProgress) ...[
                _actionBtn('Resolve', Icons.check_circle_outline, const Color(0xFF2E7D32), () => _updateStatus(c['id'], 'resolved')),
                const SizedBox(width: 8),
                _actionBtn('Dismiss', Icons.cancel_outlined, Colors.grey, () => _updateStatus(c['id'], 'dismissed')),
                const SizedBox(width: 8),
              ],
              if (status == 'dismissed') ...[
                _actionBtn('Reopen', Icons.refresh_outlined, const Color(0xFFF57F17), () => _updateStatus(c['id'], 'open')),
                const SizedBox(width: 8),
              ],
              _actionBtn('Respond', Icons.reply_outlined, const Color(0xFF1A237E), () => _showResponseDialog(c)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(border: Border.all(color: color.withOpacity(0.3)), borderRadius: BorderRadius.circular(6)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _StatusPill({required this.label, required this.count, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : const Color(0xFFE8EAED)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : Colors.grey.shade600)),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: selected ? Colors.white24 : const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(10)),
                child: Text('$count', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: selected ? Colors.white : Colors.grey.shade600)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

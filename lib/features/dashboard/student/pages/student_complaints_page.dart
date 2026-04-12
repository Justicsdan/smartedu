import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartedu/core/providers/student/student_provider.dart';

class StudentComplaintsPage extends StatefulWidget {
  const StudentComplaintsPage({super.key});
  @override
  State<StudentComplaintsPage> createState() => _StudentComplaintsPageState();
}

class _StudentComplaintsPageState extends State<StudentComplaintsPage> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _selectedCategory;
  bool _submitting = false;
  List<Map<String, dynamic>> _complaints = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadComplaints(); }

  @override
  void dispose() { _titleCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  Future<void> _loadComplaints() async {
    try {
      final provider = context.read<StudentProvider>();
      final r = await Supabase.instance.client.from('complaints').select()
          .eq('school_id', provider.schoolId).eq('student_id', provider.studentId)
          .order('created_at', ascending: false);
      if (mounted) setState(() { _complaints = List<Map<String, dynamic>>.from(r); _loading = false; });
    } catch (e) {
      debugPrint('Load complaints error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty || _descCtrl.text.trim().isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all required fields'), backgroundColor: Color(0xFFD32F2F)));
      return;
    }
    setState(() => _submitting = true);
    try {
      final provider = context.read<StudentProvider>();
      await Supabase.instance.client.from('complaints').insert({
        'school_id': provider.schoolId, 'student_id': provider.studentId,
        'subject': _titleCtrl.text.trim(), 'category': _selectedCategory,
        'description': _descCtrl.text.trim(), 'status': 'open', 'priority': 'normal',
      });
      _titleCtrl.clear(); _descCtrl.clear();
      setState(() => _selectedCategory = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complaint submitted'), backgroundColor: Color(0xFF2E7D32)));
      _loadComplaints();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Color(0xFFD32F2F)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
    switch (status.toLowerCase()) {
      case 'open': return const Color(0xFFF57F17);
      case 'in_progress': return const Color(0xFF1565C0);
      case 'resolved': return const Color(0xFF2E7D32);
      default: return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'open': return 'Open';
      case 'in_progress': return 'In Progress';
      case 'resolved': return 'Resolved';
      case 'closed': return 'Closed';
      default: return status;
    }
  }

  Widget _buildComplaintCard(Map<String, dynamic> c) {
    final status = (c['status'] ?? 'open').toString();
    final category = (c['category'] ?? '').toString();
    final resolution = (c['resolution_note'] ?? '').toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8EAED))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(c['subject'] ?? 'Untitled', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(_statusLabel(status), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor(status))),
          ),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(4)),
            child: Text(category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
          ),
          const SizedBox(width: 8),
          Text(_timeAgo(c['created_at']), style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ]),
        if (c['description'] != null && (c['description'] as String).isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(c['description'], style: const TextStyle(fontSize: 13, color: Color(0xFF555555), height: 1.4)),
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
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Report an Issue', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827), letterSpacing: -0.5)),
          const SizedBox(height: 4),
          const Text('Submit a complaint and track its resolution', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8EAED))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.report_problem_outlined, size: 18, color: Color(0xFFF57F17))),
                  const SizedBox(width: 10),
                  const Text('New Complaint', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                ]),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category *', prefixIcon: Icon(Icons.category_outlined), border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'Bullying', child: Text('Bullying')),
                    DropdownMenuItem(value: 'Facility Damage', child: Text('Facility Damage')),
                    DropdownMenuItem(value: 'Academic Issue', child: Text('Academic Issue')),
                    DropdownMenuItem(value: 'Staff Conduct', child: Text('Staff Conduct')),
                    DropdownMenuItem(value: 'Health & Safety', child: Text('Health & Safety')),
                    DropdownMenuItem(value: 'Others', child: Text('Others')),
                  ],
                  onChanged: (v) => setState(() => _selectedCategory = v),
                ),
                const SizedBox(height: 14),
                TextFormField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Subject / Title *', prefixIcon: Icon(Icons.subject_outlined), border: OutlineInputBorder())),
                const SizedBox(height: 14),
                TextFormField(controller: _descCtrl, maxLines: 4, decoration: const InputDecoration(labelText: 'Describe the issue *', alignLabelWithHint: true, border: OutlineInputBorder())),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: _submitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Submit Complaint', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Row(children: [
            Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.history, size: 16, color: Color(0xFF1A237E))),
            const SizedBox(width: 10),
            const Text('My Complaints', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          ]),
          const SizedBox(height: 14),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Color(0xFF1A237E))))
          else if (_complaints.isEmpty)
            Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(
              children: [
                Container(width: 56, height: 56, decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.check_circle_outline, size: 28, color: Color(0xFF1A237E))),
                const SizedBox(height: 12),
                const Text('No complaints submitted', style: TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            )))
          else
            ..._complaints.map((c) => _buildComplaintCard(c)),
        ],
      ),
    );
  }
}

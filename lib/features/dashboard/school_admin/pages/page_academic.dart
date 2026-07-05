import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/school_admin_provider.dart';
import '../../../../core/services/db_proxy.dart';

class PageAcademic extends StatefulWidget {
  final List<Map<String, dynamic>> classes;
  final List<Map<String, dynamic>> academicYears;
  final Function(List<Map<String, dynamic>>) onYearsUpdated;

  const PageAcademic({
    super.key,
    required this.classes,
    required this.academicYears,
    required this.onYearsUpdated,
  });

  @override
  State<PageAcademic> createState() => _PageAcademicState();
}

class _PageAcademicState extends State<PageAcademic>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _sessions = [];
  List<Map<String, dynamic>> _terms = [];
  bool _loading = false;
  String? _dialogError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _sessions = List<Map<String, dynamic>>.from(widget.academicYears);
    _loadTerms();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTerms() async {
    final provider = context.read<SchoolAdminProvider>();
    try {
      final result = await DbProxy.instance
          .from('terms')
          .eq('school_id', provider.schoolId)
          .order('created_at', ascending: false)
          .get();
      setState(() => _terms = List<Map<String, dynamic>>.from(result));
    } catch (_) {}
  }

  Future<void> _loadSessions() async {
    final provider = context.read<SchoolAdminProvider>();
    try {
      final result = await DbProxy.instance
          .from('academic_sessions')
          .eq('school_id', provider.schoolId)
          .order('created_at', ascending: false)
          .get();
      setState(() {
        _sessions = List<Map<String, dynamic>>.from(result);
        widget.onYearsUpdated(_sessions);
      });
    } catch (_) {}
  }

  Future<void> _updateActiveSession(String sessionId) async {
    setState(() => _loading = true);
    try {
      await DbProxy.instance
          .from('academic_sessions')
          .neq('id', sessionId)
          .eq('school_id', context.read<SchoolAdminProvider>().schoolId)
          .update({'is_current': false});
      await DbProxy.instance
          .from('academic_sessions')
          .eq('id', sessionId)
          .update({'is_current': true});
      await _loadSessions();
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _updateActiveTerm(String termId) async {
    setState(() => _loading = true);
    try {
      final term = _terms.firstWhere(
        (t) => t['id'].toString() == termId,
        orElse: () => <String, dynamic>{},
      );
      final sessionId = term['session_id']?.toString() ?? '';
      await DbProxy.instance
          .from('terms')
          .neq('id', termId)
          .eq('school_id', context.read<SchoolAdminProvider>().schoolId)
          .eq('session_id', sessionId)
          .update({'is_current': false});
      await DbProxy.instance
          .from('terms')
          .eq('id', termId)
          .update({'is_current': true});
      await _loadTerms();
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _showAddDialog(String type) async {
    final controller = TextEditingController();
    String? selectedSessionId;

    setState(() => _dialogError = null);

    final String hintText;
    if (type == 'Session') {
      hintText = 'e.g. 2024/2025';
    } else {
      hintText = 'e.g. First Term';
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlg) {
            return AlertDialog(
              title: Text('Add $type'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (type == 'Term')
                    DropdownButtonFormField<String>(
                      value: selectedSessionId,
                      hint: const Text('Select Session'),
                      items: _sessions
                          .map((s) => DropdownMenuItem(
                                value: s['id'].toString(),
                                child: Text(s['name'] ?? ''),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setDlg(() => selectedSessionId = v),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: '$type Name',
                      hintText: hintText,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  if (_dialogError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              size: 18, color: Color(0xFFDC2626)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _dialogError!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFDC2626),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _loading
                      ? null
                      : () async {
                          final name = controller.text.trim();
                          if (name.isEmpty) {
                            setDlg(() =>
                                _dialogError = 'Please enter a name');
                            return;
                          }
                          if (type == 'Term' && selectedSessionId == null) {
                            setDlg(() =>
                                _dialogError = 'Please select a session');
                            return;
                          }
                          setDlg(() => _dialogError = null);
                          try {
                            final schoolId = context
                                .read<SchoolAdminProvider>()
                                .schoolId;
                            if (type == 'Session') {
                              await DbProxy.instance
                                  .from('academic_sessions')
                                  .insert({
                                'school_id': schoolId,
                                'name': name,
                                'is_current': _sessions.isEmpty,
                              });
                              await _loadSessions();
                            } else {
                              await DbProxy.instance
                                  .from('terms')
                                  .insert({
                                'school_id': schoolId,
                                'session_id': selectedSessionId,
                                'name': name,
                                'is_current': false,
                              });
                              await _loadTerms();
                            }
                            if (mounted) Navigator.pop(ctx);
                          } catch (e) {
                            setDlg(() => _dialogError = e.toString());
                          }
                        },
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Sessions & Terms'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sessions'),
            Tab(text: 'Terms'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSessionsTab(),
          _buildTermsTab(),
        ],
      ),
    );
  }

  Widget _buildSessionsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_sessions.isEmpty)
                const Text(
                  'No sessions yet',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                )
              else
                Text(
                  '${_sessions.length} session${_sessions.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ElevatedButton.icon(
                onPressed: () => _showAddDialog('Session'),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Add Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_sessions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 60),
                child: Text(
                  'Add a session first',
                  style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                ),
              ),
            )
          else
            Expanded(
              child: ListView(
                children: _sessions.map((s) {
                  final sid = s['id'].toString();
                  final isActive = s['is_current'] == true;
                  final termCount = _terms
                      .where((t) => t['session_id']?.toString() == sid)
                      .length;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s['name'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  '$termCount term${termCount != 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Active',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            )
                          else
                            InkWell(
                              onTap: () => _updateActiveSession(sid),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Set Active',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTermsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_terms.isEmpty)
                const Text(
                  'No terms yet',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                )
              else
                Text(
                  '${_terms.length} term${_terms.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              if (_sessions.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () => _showAddDialog('Term'),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Add Term'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_sessions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 60),
                child: Text(
                  'Add a session first',
                  style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                ),
              ),
            )
          else if (_terms.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 60),
                child: Text(
                  'No terms yet',
                  style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                ),
              ),
            )
          else
            Expanded(
              child: ListView(
                children: _terms.map((t) {
                  final tid = t['id'].toString();
                  final isActive = t['is_current'] == true;
                  final sessionId = t['session_id']?.toString() ?? '';
                  final sessionName = _sessions.firstWhere(
                    (s) => s['id'].toString() == sessionId,
                    orElse: () => {'name': '-'},
                  );
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t['name'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  sessionName['name']?.toString() ?? '-',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Active',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            )
                          else
                            InkWell(
                              onTap: () => _updateActiveTerm(tid),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Set Active',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

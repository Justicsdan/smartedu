import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartedu/core/providers/student/student_provider.dart';

class StudentAttendancePage extends StatefulWidget {
  const StudentAttendancePage({super.key});
  @override
  State<StudentAttendancePage> createState() => _StudentAttendancePageState();
}

class _StudentAttendancePageState extends State<StudentAttendancePage> {
  Map<String, int> _summary = {};
  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> _monthly = [];
  bool _loading = true;
  int _consecutiveAbsences = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = context.read<StudentProvider>();
    final results = await Future.wait<dynamic>([
      provider.getMyAttendanceSummary(),
      provider.getMyAttendanceHistory(),
      provider.getMonthlyBreakdown(),
      provider.getConsecutiveAbsences(),
    ]);
    if (mounted) {
      setState(() {
        _summary = results[0] as Map<String, int>;
        _history = results[1] as List<Map<String, dynamic>>;
        _monthly = results[2] as List<Map<String, dynamic>>;
        _consecutiveAbsences = results[3] as int;
        _loading = false;
      });
    }
  }

  double _getPercentage() {
    final total = _summary['total_days'] ?? 0;
    if (total == 0) return 0.0;
    final attended = (_summary['present'] ?? 0) + (_summary['late'] ?? 0);
    return (attended / total) * 100;
  }

  Color _percentageColor(double pct) {
    if (pct >= 75) return const Color(0xFF2E7D32);
    if (pct >= 50) return const Color(0xFFF57F17);
    return const Color(0xFFD32F2F);
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present': return const Color(0xFF2E7D32);
      case 'absent': return const Color(0xFFD32F2F);
      case 'late': return const Color(0xFFF57F17);
      case 'excused': return const Color(0xFF1565C0);
      default: return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'present': return Icons.check_circle;
      case 'absent': return Icons.cancel;
      case 'late': return Icons.schedule;
      case 'excused': return Icons.info;
      default: return Icons.help_outline;
    }
  }

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return '';
    final dt = DateTime.tryParse(dateVal.toString());
    if (dt == null) return '';
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _statusLabel(String status) {
    final s = status.toLowerCase();
    if (s == 'present') return 'Present';
    if (s == 'absent') return 'Absent';
    if (s == 'late') return 'Late';
    if (s == 'excused') return 'Excused';
    return status;
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
          const Text('Attendance', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827), letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text('Your attendance record for the current term', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          const SizedBox(height: 24),
          _buildPercentageCard(),
          const SizedBox(height: 16),
          _buildSummaryCards(),
          const SizedBox(height: 28),
          _buildConsecutiveAbsenceWarning(),
          const SizedBox(height: 24),
          _buildMonthlyBreakdown(),
          const SizedBox(height: 28),
          _buildDailyLog(),
        ],
      ),
    );
  }

  Widget _buildPercentageCard() {
    final pct = _getPercentage();
    final total = _summary['total_days'] ?? 0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8EAED))),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _percentageColor(pct).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    value: total == 0 ? 0 : pct / 100,
                    strokeWidth: 6,
                    backgroundColor: const Color(0xFFE8EAED),
                    valueColor: AlwaysStoppedAnimation<Color>(_percentageColor(pct)),
                  ),
                ),
                Text(
                  total == 0 ? '—' : '${pct.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _percentageColor(pct)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  total == 0 ? 'No attendance recorded' : 'Attendance Rate',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
                const SizedBox(height: 4),
                if (total > 0)
                  Text(
                    '${(_summary['present'] ?? 0) + (_summary['late'] ?? 0)} of $total days attended',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final cards = [
      _StatCard(label: 'Present', value: _summary['present'] ?? 0, color: const Color(0xFF2E7D32), bgColor: const Color(0xFFE8F5E9), icon: Icons.check_circle_outline),
      _StatCard(label: 'Absent', value: _summary['absent'] ?? 0, color: const Color(0xFFD32F2F), bgColor: const Color(0xFFFFEBEE), icon: Icons.cancel_outlined),
      _StatCard(label: 'Late', value: _summary['late'] ?? 0, color: const Color(0xFFF57F17), bgColor: const Color(0xFFFFF8E1), icon: Icons.schedule_outlined),
      _StatCard(label: 'Excused', value: _summary['excused'] ?? 0, color: const Color(0xFF1565C0), bgColor: const Color(0xFFE3F2FD), icon: Icons.info_outline),
    ];
    return Row(
      children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: c))).toList(),
    );
  }

  Widget _buildConsecutiveAbsenceWarning() {
    if (_consecutiveAbsences < 2) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.shade200)),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You have been absent for $_consecutiveAbsences consecutive day${_consecutiveAbsences > 1 ? 's' : ''}. Please contact your school.',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.red.shade900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyBreakdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.calendar_month, size: 16, color: Color(0xFF1A237E))),
            const SizedBox(width: 10),
            const Text('Monthly Breakdown', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          ],
        ),
        const SizedBox(height: 14),
        if (_monthly.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Container(width: 56, height: 56, decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.calendar_today_outlined, size: 28, color: Color(0xFF1A237E))),
                  const SizedBox(height: 12),
                  Text('No monthly data', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                ],
              ),
            ),
          )
        else
          ..._monthly.map((m) {
            final total = m['total'] as int? ?? 0;
            final present = (m['present'] as int? ?? 0) + (m['late'] as int? ?? 0);
            final pct = total == 0 ? 0.0 : (present / total) * 100;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE8EAED))),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(m['month_name'] ?? m['month'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0 : pct / 100,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE8EAED),
                        valueColor: AlwaysStoppedAnimation<Color>(_percentageColor(pct)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 52,
                    child: Text('${pct.toStringAsFixed(0)}%', textAlign: TextAlign.right, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _percentageColor(pct))),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 60,
                    child: Text('$present/$total', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildDailyLog() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFFF3E5F5), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.list_alt, size: 16, color: Color(0xFF7B1FA2))),
            const SizedBox(width: 10),
            const Text('Daily Log', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFF3E5F5), borderRadius: BorderRadius.circular(10)),
              child: Text('${_history.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF7B1FA2))),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_history.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Container(width: 56, height: 56, decoration: BoxDecoration(color: const Color(0xFFF3E5F5), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.event_available, size: 28, color: Color(0xFF7B1FA2))),
                  const SizedBox(height: 12),
                  Text('No attendance records', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                ],
              ),
            ),
          )
        else
          ..._history.asMap().entries.map((entry) {
            final idx = entry.key;
            final c = entry.value;
            final status = (c['status'] ?? '').toString();
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: idx % 2 == 0 ? const Color(0xFFFAFBFC) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE8EAED)),
              ),
              child: Row(
                children: [
                  Icon(_statusIcon(status), size: 18, color: _statusColor(status)),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 140,
                    child: Text(_formatDate(c['date']), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF111827))),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(_statusLabel(status), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor(status))),
                  ),
                  const Spacer(),
                  if (c['remark'] != null && (c['remark'] as String).isNotEmpty)
                    SizedBox(
                      width: 180,
                      child: Text(c['remark'], style: TextStyle(fontSize: 12, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis),
                    ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final Color bgColor;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.color, required this.bgColor, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8EAED))),
      child: Column(
        children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 18, color: color)),
          const SizedBox(height: 8),
          Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

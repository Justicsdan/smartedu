import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartedu/core/providers/student/student_provider.dart';

class StudentFeesPage extends StatefulWidget {
  const StudentFeesPage({super.key});
  @override
  State<StudentFeesPage> createState() => _StudentFeesPageState();
}

class _StudentFeesPageState extends State<StudentFeesPage> {
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _balances = [];
  List<Map<String, dynamic>> _payments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = context.read<StudentProvider>();
    final results = await Future.wait<dynamic>([
      provider.getPaymentSummary(),
      provider.getFeeBalance(),
      provider.getFeesForCurrentTerm(),
    ]);
    if (mounted) {
      setState(() {
        _summary = results[0] as Map<String, dynamic>;
        _balances = results[1] as List<Map<String, dynamic>>;
        _payments = results[2] as List<Map<String, dynamic>>;
        _loading = false;
      });
    }
  }

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return '';
    final dt = DateTime.tryParse(dateVal.toString());
    if (dt == null) return '';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _methodLabel(String? method) {
    if (method == null) return '—';
    final m = method.toLowerCase();
    if (m == 'cash') return 'Cash';
    if (m == 'bank_transfer' || m == 'transfer') return 'Bank Transfer';
    if (m == 'card') return 'Card';
    if (m == 'pos') return 'POS';
    if (m == 'cheque') return 'Cheque';
    if (m == 'online') return 'Online';
    return method;
  }

  String _currency() => _summary['currency']?.toString() ?? '';

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
          const Text('Fees', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827), letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text('Your fee status for the current term', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          const SizedBox(height: 24),
          _buildSummaryCards(),
          const SizedBox(height: 28),
          _buildFeeBalances(),
          const SizedBox(height: 28),
          _buildPaymentHistory(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final paid = (_summary['total_paid'] as num?)?.toDouble() ?? 0;
    final owed = (_summary['total_owed'] as num?)?.toDouble() ?? 0;
    final paidCount = (_summary['paid_count'] as int?) ?? 0;
    final unpaidCount = (_summary['unpaid_count'] as int?) ?? 0;
    final c = _currency();

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Total Paid',
            value: '$c${paid.toStringAsFixed(0)}',
            subtitle: '$paidCount fee${paidCount != 1 ? 's' : ''} cleared',
            color: const Color(0xFF2E7D32),
            bgColor: const Color(0xFFE8F5E9),
            icon: Icons.check_circle_outline,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: 'Outstanding',
            value: owed > 0 ? '$c${owed.toStringAsFixed(0)}' : '${c}0',
            subtitle: unpaidCount > 0 ? '$unpaidCount fee${unpaidCount != 1 ? 's' : ''} pending' : 'All clear',
            color: owed > 0 ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
            bgColor: owed > 0 ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
            icon: owed > 0 ? Icons.error_outline : Icons.verified_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildFeeBalances() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.receipt_long, size: 16, color: Color(0xFF1A237E))),
            const SizedBox(width: 10),
            const Text('Fee Breakdown', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(10)),
              child: Text('${_balances.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1A237E))),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_balances.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Container(width: 56, height: 56, decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.receipt_long_outlined, size: 28, color: Color(0xFF1A237E))),
                  const SizedBox(height: 12),
                  Text('No fees configured', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                ],
              ),
            ),
          )
        else
          ..._balances.asMap().entries.map((entry) {
            final idx = entry.key;
            final b = entry.value;
            final isPaid = b['is_paid'] == true;
            final balance = (b['balance'] as num?)?.toDouble() ?? 0;
            final totalOwed = (b['total_owed'] as num?)?.toDouble() ?? 0;
            final totalPaid = (b['total_paid'] as num?)?.toDouble() ?? 0;
            final c = (b['currency'] as String?) ?? '';
            final pct = totalOwed > 0 ? (totalPaid / totalOwed * 100).clamp(0, 100) : 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: idx % 2 == 0 ? const Color(0xFFFAFBFC) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE8EAED)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(b['fee_name'] ?? 'Fee', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isPaid ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(isPaid ? Icons.check_circle : Icons.schedule, size: 12, color: isPaid ? const Color(0xFF2E7D32) : const Color(0xFFF57F17)),
                            const SizedBox(width: 4),
                            Text(isPaid ? 'Paid' : 'Pending', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isPaid ? const Color(0xFF2E7D32) : const Color(0xFFF57F17))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE8EAED),
                      valueColor: AlwaysStoppedAnimation<Color>(isPaid ? const Color(0xFF2E7D32) : const Color(0xFFF57F17)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Paid: ${c}${totalPaid.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      Text('Total: ${c}${totalOwed.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                      if (!isPaid)
                        Text('Balance: ${c}${balance.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFD32F2F))),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildPaymentHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFFF3E5F5), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.history, size: 16, color: Color(0xFF7B1FA2))),
            const SizedBox(width: 10),
            const Text('Payment History', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFF3E5F5), borderRadius: BorderRadius.circular(10)),
              child: Text('${_payments.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF7B1FA2))),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_payments.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Container(width: 56, height: 56, decoration: BoxDecoration(color: const Color(0xFFF3E5F5), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.payment_outlined, size: 28, color: Color(0xFF7B1FA2))),
                  const SizedBox(height: 12),
                  Text('No payments recorded', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                ],
              ),
            ),
          )
        else
          ..._payments.asMap().entries.map((entry) {
            final idx = entry.key;
            final p = entry.value;
            final ft = p['fee_types'] as Map<String, dynamic>? ?? {};
            final term = p['terms'] as Map<String, dynamic>? ?? {};
            final c = _currency();
            final amount = (p['amount_paid'] as num?)?.toDouble() ?? 0;

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
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: const Color(0xFFF3E5F5).withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.receipt, size: 18, color: Color(0xFF7B1FA2)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ft['name'] ?? 'Fee', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(_formatDate(p['payment_date']), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            if (term['name'] != null) ...[
                              Text('  ·  ', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                              Text(term['name'], style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            ],
                            Text('  ·  ${_methodLabel(p['payment_method'])}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text('${c}${amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final Color bgColor;
  final IconData icon;
  const _SummaryCard({required this.label, required this.value, required this.subtitle, required this.color, required this.bgColor, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8EAED))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 18, color: color)),
              const SizedBox(width: 10),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

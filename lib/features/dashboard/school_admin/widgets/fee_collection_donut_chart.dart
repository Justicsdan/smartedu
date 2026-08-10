import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smartedu/utils/chart_theme.dart';
import 'package:smartedu/widgets/empty_chart_placeholder.dart';

class FeeCollectionDonutChart extends StatelessWidget {
  final double collected;
  final double outstanding;
  final String currency;

  const FeeCollectionDonutChart({
    super.key,
    required this.collected,
    required this.outstanding,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final total = collected + outstanding;
    if (total <= 0) {
      return ChartTheme.card(
        title: 'Collection Overview',
        icon: Icons.account_balance_wallet,
        child: const EmptyChartPlaceholder(message: 'No fee data available'),
      );
    }

    final collectedPct = (collected / total * 100).clamp(0.0, 100.0);
    final outstandingPct = (outstanding / total * 100).clamp(0.0, 100.0);

    return ChartTheme.card(
      title: 'Collection Overview',
      icon: Icons.account_balance_wallet,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          SizedBox(
            width: 180,
            height: 180,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: collected,
                    color: const Color(0xFF2E7D32),
                    title: collectedPct >= 5 ? '${collectedPct.toStringAsFixed(0)}%' : '',
                    titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    titlePositionPercentageOffset: 0.5,
                    borderSide: const BorderSide(width: 3, color: Colors.white),
                  ),
                  if (outstanding > 0)
                    PieChartSectionData(
                      value: outstanding,
                      color: const Color(0xFFE65100),
                      title: outstandingPct >= 5 ? '${outstandingPct.toStringAsFixed(0)}%' : '',
                      titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      titlePositionPercentageOffset: 0.5,
                      borderSide: const BorderSide(width: 3, color: Colors.white),
                    ),
                ],
                sectionsSpace: 0,
                centerSpaceRadius: 55,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendItem(const Color(0xFF2E7D32), 'Collected', collected, currency),
                const SizedBox(width: 24),
                if (outstanding > 0)
                  _legendItem(const Color(0xFFE65100), 'Outstanding', outstanding, currency),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label, double amount, String currency) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: $currency${amount.toStringAsFixed(0)}',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
        ),
      ],
    );
  }
}

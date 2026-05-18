import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:productivity/core/theme/app_theme.dart';
import 'package:productivity/data/models/transaction_model.dart';
import 'package:intl/intl.dart';
import 'package:productivity/presentation/widgets/glass_container.dart';

class DashboardLineChart extends StatelessWidget {
  final List<TransactionModel> transactions;
  final DateTime month;

  const DashboardLineChart(
      {super.key, required this.transactions, required this.month});

  @override
  Widget build(BuildContext context) {
    // Group transactions by day
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final Map<int, double> dailyIncome = {};
    final Map<int, double> dailyExpense = {};

    for (int i = 1; i <= daysInMonth; i++) {
      final dayTxs = transactions.where((t) => t.date.day == i);
      double inc = 0, exp = 0;
      for (final tx in dayTxs) {
        if (tx.isIncome) {
          inc += tx.amount;
        } else {
          exp += tx.amount;
        }
      }
      dailyIncome[i] = inc;
      dailyExpense[i] = exp;
    }

    final incomeSpots = dailyIncome.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
    final expenseSpots = dailyExpense.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    if (incomeSpots.isEmpty) incomeSpots.add(const FlSpot(1, 0));
    if (expenseSpots.isEmpty) expenseSpots.add(const FlSpot(1, 0));

    const minX = 1.0;
    final maxX = daysInMonth.toDouble();

    final allY = [
      ...incomeSpots.map((s) => s.y),
      ...expenseSpots.map((s) => s.y)
    ];
    double minY = allY.reduce((a, b) => a < b ? a : b);
    double maxY = allY.reduce((a, b) => a > b ? a : b);

    if (minY == maxY) {
      minY = 0;
      maxY += 10000;
    }

    final incomeColor = AppColors.blueAccent;
    const expenseColor = Color(0xFFFBBF24); // Premium yellow

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Grafik Arus Kas',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bgCard.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.borderAccent.withValues(alpha: 0.5)),
                ),
                child: Text(
                  DateFormat('MMMM yyyy', 'id_ID').format(month),
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _LegendDot(color: incomeColor, label: 'Uang Masuk'),
              const SizedBox(width: 16),
              const _LegendDot(color: expenseColor, label: 'Uang Keluar'),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval:
                      (maxY - minY) / 4 == 0 ? 1 : (maxY - minY) / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.border.withValues(alpha: 0.5),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == minY || value == maxY) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          NumberFormat.compact().format(value),
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: minX,
                maxX: maxX,
                minY: minY,
                maxY: maxY + (maxY - minY) * 0.1, // Add some top padding
                lineBarsData: [
                  LineChartBarData(
                    spots: incomeSpots,
                    isCurved: true,
                    color: incomeColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          incomeColor.withValues(alpha: 0.3),
                          incomeColor.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  LineChartBarData(
                    spots: expenseSpots,
                    isCurved: true,
                    color: expenseColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          expenseColor.withValues(alpha: 0.3),
                          expenseColor.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ],
    );
  }
}

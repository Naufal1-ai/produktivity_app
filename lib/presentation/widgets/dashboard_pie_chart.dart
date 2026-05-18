import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:productivity/core/theme/app_theme.dart';
import 'package:productivity/data/models/transaction_model.dart';
import 'package:productivity/presentation/widgets/glass_container.dart';

class DashboardPieChart extends StatelessWidget {
  final List<TransactionModel> transactions;

  const DashboardPieChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final expenses = transactions.where((t) => !t.isIncome).toList();
    final Map<String, double> categoryTotals = {};
    double totalExpense = 0;

    for (final tx in expenses) {
      categoryTotals[tx.category] =
          (categoryTotals[tx.category] ?? 0) + tx.amount;
      totalExpense += tx.amount;
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topCategories = sortedCategories.take(4).toList();

    final colors = [
      AppColors.purple,
      AppColors.primaryWeb,
      AppColors.income,
      const Color(0xFFF59E0B), // Orange
    ];

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pengeluaran Terbesar',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          if (totalExpense == 0)
            const Expanded(
              child: Center(
                child: Text('Belum ada data',
                    style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: List.generate(topCategories.length, (i) {
                              final cat = topCategories[i];
                              final percentage =
                                  (cat.value / totalExpense) * 100;
                              return PieChartSectionData(
                                color: colors[i % colors.length],
                                value: cat.value,
                                title: '',
                                radius: 16,
                              );
                            }),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${((topCategories.isNotEmpty ? topCategories.first.value / totalExpense : 0) * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              topCategories.isNotEmpty ? 'Utama' : '',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(topCategories.length, (i) {
                        final cat = topCategories[i];
                        final percentage = (cat.value / totalExpense) * 100;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: colors[i % colors.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  cat.key,
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${percentage.toStringAsFixed(0)}%',
                                style: TextStyle(
                                    color: AppColors.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

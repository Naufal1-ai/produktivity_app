import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:productivity/core/theme/app_theme.dart';
import 'package:productivity/core/utils/currency_utils.dart';
import 'package:productivity/data/models/transaction_model.dart';
import 'package:productivity/data/repositories/transaction_repository.dart';
import 'package:productivity/presentation/widgets/common_widgets.dart';
import 'package:productivity/presentation/widgets/glass_container.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  final _repo = TransactionRepository();
  DateTime _selectedMonth = DateTime.now();
  int _touchedIndex = -1;
  late TabController _tabController;

  static const _pieColors = [
    Color(0xFFF87171),
    Color(0xFFFBBF24),
    Color(0xFF60A5FA),
    Color(0xFFA78BFA),
    Color(0xFF34D399),
    Color(0xFFF472B6),
    Color(0xFFFD7E14),
    Color(0xFF94A3B8),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<DateTime> get _last6Months => List.generate(
        6,
        (i) => DateTime(DateTime.now().year, DateTime.now().month - (5 - i)),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header bulan
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STATISTIK',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(letterSpacing: 1.4),
              ),
              GestureDetector(
                onTap: _pickMonth,
                child: GlassContainer(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  borderRadius: 16,
                  color:
                      AppColors.isDark ? null : Colors.white.withValues(alpha: 0.75),
                  border:
                      Border.all(color: AppColors.blueAccent.withValues(alpha: 0.15)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_month_outlined,
                          size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        DateUtils2.formatMonth(_selectedMonth),
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ✅ Sub-tab Pengeluaran / Tren — label putih
        GlassContainer(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          borderRadius: 18,
          color: AppColors.isDark ? null : Colors.white.withValues(alpha: 0.72),
          border: Border.all(color: AppColors.blueAccent.withValues(alpha: 0.12)),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: AppColors.blueMid,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.blueBorder),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.isDark
                ? Colors.white.withValues(alpha: 0.6)
                : AppColors.textSecondary,
            labelStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Pengeluaran'),
              Tab(text: 'Tren 6 Bulan'),
            ],
          ),
        ),
        const SizedBox(height: 4),

        Expanded(
          child: StreamBuilder<List<TransactionModel>>(
            stream: _repo.watchByMonth(_selectedMonth),
            builder: (context, snapshot) {
              final txList = snapshot.data ?? [];
              return TabBarView(
                controller: _tabController,
                children: [
                  _buildPieTab(txList),
                  _buildBarTab(),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPieTab(List<TransactionModel> txList) {
    final expenses = txList.where((t) => !t.isIncome).toList();
    final total = expenses.fold(0.0, (s, t) => s + t.amount);

    if (expenses.isEmpty) {
      return Center(
        child: Text('Belum ada pengeluaran\nbulan ini 🎉',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.textMuted, fontSize: 14, height: 1.6)),
      );
    }

    final Map<String, double> catMap = {};
    for (final t in expenses) {
      catMap[t.category] = (catMap[t.category] ?? 0) + t.amount;
    }
    final sorted = catMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        children: [
          GlassContainer(
            padding: const EdgeInsets.all(16),
            borderRadius: 24,
            color: AppColors.isDark ? null : Colors.white.withValues(alpha: 0.72),
            border: Border.all(color: AppColors.blueAccent.withValues(alpha: 0.12)),
            child: Column(
              children: [
                SizedBox(
                  height: 220,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 52,
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                response?.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex =
                                response!.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      sections: List.generate(sorted.length, (i) {
                        final entry = sorted[i];
                        final isTouched = i == _touchedIndex;
                        final pct =
                            total > 0 ? (entry.value / total * 100) : 0.0;
                        return PieChartSectionData(
                          color: _pieColors[i % _pieColors.length],
                          value: entry.value,
                          title: isTouched
                              ? '${pct.toStringAsFixed(1)}%'
                              : pct >= 8
                                  ? '${pct.toStringAsFixed(0)}%'
                                  : '',
                          radius: isTouched ? 72 : 62,
                          titleStyle: TextStyle(
                            fontSize: isTouched ? 14 : 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                if (_touchedIndex >= 0 && _touchedIndex < sorted.length) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      '${sorted[_touchedIndex].key}\n${CurrencyUtils.format(sorted[_touchedIndex].value)}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(sorted.length, (i) {
            final entry = sorted[i];
            final pct = total > 0 ? (entry.value / total * 100) : 0.0;
            return GlassContainer(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              borderRadius: 18,
              color: AppColors.isDark ? null : Colors.white.withValues(alpha: 0.72),
              border: Border.all(color: AppColors.blueAccent.withValues(alpha: 0.12)),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _pieColors[i % _pieColors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(entry.key,
                        style: TextStyle(
                            color: AppColors.textPrimary, fontSize: 13)),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(CurrencyUtils.formatCompact(entry.value),
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                      Text('${pct.toStringAsFixed(1)}%',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBarTab() {
    return StreamBuilder<List<TransactionModel>>(
      stream: _repo.watchAll(),
      builder: (context, snapshot) {
        final allTx = snapshot.data ?? [];
        if (allTx.isEmpty) {
          return Center(
            child: Text('Belum cukup data\nuntuk tren 📈',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textMuted, fontSize: 14, height: 1.6)),
          );
        }

        final months = _last6Months;
        final incomePerMonth = <double>[];
        final expensePerMonth = <double>[];

        for (final m in months) {
          final inM = allTx
              .where((t) => t.date.year == m.year && t.date.month == m.month);
          incomePerMonth.add(
              inM.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount));
          expensePerMonth.add(
              inM.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount));
        }

        final allVals = [...incomePerMonth, ...expensePerMonth];
        final maxVal = allVals.isEmpty
            ? 1000000.0
            : allVals.reduce((a, b) => a > b ? a : b);
        final yMax = maxVal == 0 ? 1000000.0 : maxVal * 1.25;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            children: [
              GlassContainer(
                padding: const EdgeInsets.all(16),
                borderRadius: 24,
                color: AppColors.isDark ? null : Colors.white.withValues(alpha: 0.72),
                border:
                    Border.all(color: AppColors.blueAccent.withValues(alpha: 0.12)),
                child: Row(
                  children: [
                    _MiniCard(
                      label: 'Rata-rata Pemasukan',
                      value: CurrencyUtils.formatCompact(
                          incomePerMonth.fold(0.0, (a, b) => a + b) / 6),
                      color: AppColors.income,
                    ),
                    const SizedBox(width: 10),
                    _MiniCard(
                      label: 'Rata-rata Pengeluaran',
                      value: CurrencyUtils.formatCompact(
                          expensePerMonth.fold(0.0, (a, b) => a + b) / 6),
                      color: AppColors.expense,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GlassContainer(
                padding: const EdgeInsets.fromLTRB(8, 20, 12, 12),
                borderRadius: 18,
                color: AppColors.isDark ? null : Colors.white.withValues(alpha: 0.72),
                border:
                    Border.all(color: AppColors.blueAccent.withValues(alpha: 0.12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 16),
                      child: Text('Pemasukan vs Pengeluaran',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                    ),
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: yMax,
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (_) => AppColors.bgCardAlt,
                              getTooltipItem:
                                  (group, groupIndex, rod, rodIndex) {
                                final isIncome = rodIndex == 0;
                                return BarTooltipItem(
                                  '${isIncome ? '📈' : '📉'} ${CurrencyUtils.formatCompact(rod.toY)}',
                                  TextStyle(
                                    color: isIncome
                                        ? AppColors.income
                                        : AppColors.expense,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 48,
                                getTitlesWidget: (value, meta) {
                                  if (value == 0) return const Text('');
                                  return Text(
                                    CurrencyUtils.formatCompact(value)
                                        .replaceAll('Rp ', ''),
                                    style: TextStyle(
                                        color: AppColors.textDim, fontSize: 9),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx < 0 || idx >= months.length) {
                                    return const Text('');
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      DateFormat('MMM', 'id_ID')
                                          .format(months[idx]),
                                      style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 10),
                                    ),
                                  );
                                },
                              ),
                            ),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: FlGridData(
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (_) => FlLine(
                              color: AppColors.border,
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(months.length, (i) {
                            return BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: incomePerMonth[i],
                                  color:
                                      AppColors.income.withValues(alpha: 0.8),
                                  width: 10,
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4)),
                                ),
                                BarChartRodData(
                                  toY: expensePerMonth[i],
                                  color:
                                      AppColors.expense.withValues(alpha: 0.8),
                                  width: 10,
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4)),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LegendDot(color: AppColors.income, label: 'Pemasukan'),
                        SizedBox(width: 20),
                        _LegendDot(
                            color: AppColors.expense, label: 'Pengeluaran'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassContainer(
                padding: const EdgeInsets.all(16),
                borderRadius: 18,
                color: AppColors.isDark ? null : Colors.white.withValues(alpha: 0.72),
                border:
                    Border.all(color: AppColors.blueAccent.withValues(alpha: 0.12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ringkasan per Bulan',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 12),
                    ...List.generate(months.length, (i) {
                      final net = incomePerMonth[i] - expensePerMonth[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              child: Text(
                                DateFormat('MMM', 'id_ID').format(months[i]),
                                style: TextStyle(
                                    color: AppColors.textMuted, fontSize: 12),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                CurrencyUtils.formatCompact(incomePerMonth[i]),
                                style: const TextStyle(
                                    color: AppColors.income, fontSize: 12),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                CurrencyUtils.formatCompact(expensePerMonth[i]),
                                style: const TextStyle(
                                    color: AppColors.expense, fontSize: 12),
                              ),
                            ),
                            Text(
                              (net >= 0 ? '+' : '') +
                                  CurrencyUtils.formatCompact(net),
                              style: TextStyle(
                                color: net >= 0
                                    ? AppColors.income
                                    : AppColors.expense,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final months = List.generate(12, (i) => DateTime(now.year, now.month - i));
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCardAlt,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: AppColors.borderAccent,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          const SectionLabel('Pilih Bulan'),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...months.map(
                    (m) => ListTile(
                      title: Text(DateUtils2.formatMonth(m),
                          style: TextStyle(color: AppColors.textPrimary)),
                      trailing: _selectedMonth.year == m.year &&
                              _selectedMonth.month == m.month
                          ? Icon(Icons.check, color: AppColors.blueAccent)
                          : null,
                      onTap: () {
                        setState(() => _selectedMonth = m);
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
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
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:productivity/core/theme/app_theme.dart';
import 'package:productivity/core/utils/currency_utils.dart';
import 'package:productivity/data/models/transaction_model.dart';
import 'package:productivity/presentation/widgets/glass_container.dart';

class DashboardSummaryCards extends StatelessWidget {
  final double balance;
  final double totalIncome;
  final double totalExpense;
  final List<TransactionModel> transactions;
  final bool isDesktop;

  const DashboardSummaryCards({
    super.key,
    required this.balance,
    required this.totalIncome,
    required this.totalExpense,
    required this.transactions,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return Row(
        children: [
          Expanded(
            child: _buildCard(
              'Total Saldo',
              balance,
              AppColors.primaryWeb,
              Icons.account_balance_wallet,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildCard(
              'Pemasukan',
              totalIncome,
              AppColors.income,
              Icons.arrow_upward,
              onTap: () => _showMonthlyDetailSheet(context, true),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildCard(
              'Pengeluaran',
              totalExpense,
              AppColors.expense,
              Icons.arrow_downward,
              onTap: () => _showMonthlyDetailSheet(context, false),
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          _buildCard(
            'Total Saldo',
            balance,
            AppColors.primaryWeb,
            Icons.account_balance_wallet,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildCard(
                  'Pemasukan',
                  totalIncome,
                  AppColors.income,
                  Icons.arrow_upward,
                  onTap: () => _showMonthlyDetailSheet(context, true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCard(
                  'Pengeluaran',
                  totalExpense,
                  AppColors.expense,
                  Icons.arrow_downward,
                  onTap: () => _showMonthlyDetailSheet(context, false),
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildCard(
    String title,
    double amount,
    Color accentColor,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        splashColor: accentColor.withValues(alpha: 0.1),
        highlightColor: accentColor.withValues(alpha: 0.05),
        child: GlassContainer(
          showRetroWindowBar: true,
          retroWindowBarColor: accentColor,
          padding: const EdgeInsets.all(20),
          borderRadius: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary.withValues(alpha: 0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accentColor, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                CurrencyUtils.format(amount),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMonthlyDetailSheet(BuildContext context, bool isIncome) {
    // ── Filter transactions (O(N) time complexity) ──
    final filteredTxs = transactions.where((t) => t.isIncome == isIncome).toList();

    // ── Group by year and month ──
    final Map<String, List<TransactionModel>> grouped = {};
    for (final tx in filteredTxs) {
      final key = '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    // ── Sort descending (newest first) ──
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _MonthlyDetailSheet(
          title: isIncome ? 'Detail Pemasukan Bulanan' : 'Detail Pengeluaran Bulanan',
          isIncome: isIncome,
          sortedKeys: sortedKeys,
          groupedData: grouped,
        );
      },
    );
  }
}

// ── Monthly Detail Sheet Widget ──────────────────────────────────────────────

class _MonthlyDetailSheet extends StatefulWidget {
  final String title;
  final bool isIncome;
  final List<String> sortedKeys;
  final Map<String, List<TransactionModel>> groupedData;

  const _MonthlyDetailSheet({
    required this.title,
    required this.isIncome,
    required this.sortedKeys,
    required this.groupedData,
  });

  @override
  State<_MonthlyDetailSheet> createState() => _MonthlyDetailSheetState();
}

class _MonthlyDetailSheetState extends State<_MonthlyDetailSheet> {
  final Set<String> _expandedKeys = {};

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard.withValues(alpha: 0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: AppColors.borderAccent, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Top drag indicator
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),

              // Header title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (widget.isIncome ? AppColors.greenSuccess : AppColors.expense).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        color: widget.isIncome ? AppColors.greenSuccess : AppColors.expense,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Tap kartu bulan untuk melihat daftar transaksi',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),

              // Month lists
              Expanded(
                child: widget.sortedKeys.isEmpty
                    ? Center(
                        child: Text(
                          'Belum ada data transaksi ${widget.isIncome ? 'pemasukan' : 'pengeluaran'}.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                        itemCount: widget.sortedKeys.length,
                        itemBuilder: (context, index) {
                          final key = widget.sortedKeys[index];
                          final txList = widget.groupedData[key] ?? [];
                          final totalAmount = txList.fold<double>(0.0, (s, t) => s + t.amount);

                          // Parse Year and Month
                          final parts = key.split('-');
                          final year = parts[0];
                          final monthInt = int.parse(parts[1]);
                          final dateObj = DateTime(int.parse(year), monthInt);
                          final monthName = DateFormat('MMMM yyyy', 'id_ID').format(dateObj);

                          final isExpanded = _expandedKeys.contains(key);

                          return AnimatedSize(
                            duration: const Duration(milliseconds: 250),
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.bgCardAlt.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isExpanded
                                        ? (widget.isIncome ? AppColors.greenSuccess : AppColors.expense).withValues(alpha: 0.3)
                                        : AppColors.borderAccent,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    // Header Card
                                    InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () {
                                        setState(() {
                                          if (isExpanded) {
                                            _expandedKeys.remove(key);
                                          } else {
                                            _expandedKeys.add(key);
                                          }
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    monthName,
                                                    style: TextStyle(
                                                      color: AppColors.textPrimary,
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '${txList.length} transaksi',
                                                    style: TextStyle(
                                                      color: AppColors.textMuted,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              CurrencyUtils.format(totalAmount),
                                              style: TextStyle(
                                                color: widget.isIncome ? AppColors.greenSuccess : AppColors.expense,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Icon(
                                              isExpanded
                                                  ? Icons.keyboard_arrow_up_rounded
                                                  : Icons.keyboard_arrow_down_rounded,
                                              color: AppColors.textMuted,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Transaction list details under month
                                    if (isExpanded) ...[
                                      const Divider(height: 1),
                                      ListView.separated(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        padding: const EdgeInsets.all(16),
                                        itemCount: txList.length,
                                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                                        itemBuilder: (context, txIndex) {
                                          final tx = txList[txIndex];
                                          final dateStr = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(tx.date);

                                          return Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: AppColors.bgCard.withValues(alpha: 0.7),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: AppColors.borderAccent.withValues(alpha: 0.5)),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        tx.category,
                                                        style: TextStyle(
                                                          color: AppColors.textPrimary,
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      if (tx.note.isNotEmpty) ...[
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          tx.note,
                                                          style: TextStyle(
                                                            color: AppColors.textSecondary,
                                                            fontSize: 11,
                                                          ),
                                                        ),
                                                      ],
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        dateStr,
                                                        style: TextStyle(
                                                          color: AppColors.textMuted,
                                                          fontSize: 9,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Text(
                                                  CurrencyUtils.format(tx.amount),
                                                  style: TextStyle(
                                                    color: AppColors.textPrimary,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

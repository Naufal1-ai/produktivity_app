import 'package:flutter/material.dart';
import 'package:productivity/core/theme/app_theme.dart';
import 'package:productivity/core/utils/currency_utils.dart';
import 'package:productivity/presentation/widgets/glass_container.dart';

class DashboardSummaryCards extends StatelessWidget {
  final double balance;
  final double totalIncome;
  final double totalExpense;
  final bool isDesktop;

  const DashboardSummaryCards({
    super.key,
    required this.balance,
    required this.totalIncome,
    required this.totalExpense,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return Row(
        children: [
          Expanded(
              child: _buildCard('Total Saldo', balance, AppColors.primaryWeb,
                  Icons.account_balance_wallet)),
          const SizedBox(width: 16),
          Expanded(
              child: _buildCard('Pemasukan', totalIncome, AppColors.income,
                  Icons.arrow_upward)),
          const SizedBox(width: 16),
          Expanded(
              child: _buildCard('Pengeluaran', totalExpense, AppColors.expense,
                  Icons.arrow_downward)),
        ],
      );
    } else {
      return Column(
        children: [
          _buildCard('Total Saldo', balance, AppColors.primaryWeb,
              Icons.account_balance_wallet),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _buildCard('Pemasukan', totalIncome, AppColors.income,
                      Icons.arrow_upward)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildCard('Pengeluaran', totalExpense,
                      AppColors.expense, Icons.arrow_downward)),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildCard(
      String title, double amount, Color accentColor, IconData icon) {
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
                title,
                style: TextStyle(
                    color: AppColors.textPrimary.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
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
    );
  }
}

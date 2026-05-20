import 'package:flutter/material.dart';
import 'package:productivity/core/theme/app_theme.dart';
import 'package:productivity/presentation/screens/budget/budget_screen.dart';
import 'package:productivity/presentation/screens/search/search_screen.dart';
import 'package:productivity/presentation/screens/statistics/statistics_screen.dart';
import 'package:productivity/presentation/widgets/grid_background.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor:
            AppColors.isDark ? const Color(0xFF0F1117) : AppColors.bg,
        // ✅ GridBackground membungkus seluruh body termasuk semua tab
        body: SizedBox.expand(
          child: GridBackground(
            child: SafeArea(
              bottom: false,
              child: Column(
              children: [
                // ✅ Header dengan desain lebih baik
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.blueAccent.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_outlined,
                          color: AppColors.blueAccent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Keuangan',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // ✅ TabBar dengan desain lebih baik
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: AppColors.blueAccent.withValues(alpha: 0.12)),
                    ),
                    child: TabBar(
                      indicator: BoxDecoration(
                        color: AppColors.blueMid,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.blueBorder),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : AppColors.textSecondary,
                      labelStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                      unselectedLabelStyle:
                          const TextStyle(fontWeight: FontWeight.w400),
                      dividerColor: const Color.fromARGB(0, 255, 255, 255),
                      padding: const EdgeInsets.all(4),
                      tabs: const [
                        Tab(text: 'Analisis'),
                        Tab(text: 'Anggaran'),
                        Tab(text: 'Cari'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ✅ TabBarView mengisi sisa ruang
                const Expanded(
                  child: TabBarView(
                    children: [
                      StatisticsScreen(),
                      BudgetScreen(),
                      SearchScreen(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}

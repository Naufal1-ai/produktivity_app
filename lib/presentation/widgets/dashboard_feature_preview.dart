import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:productivity/core/theme/app_theme.dart';
import 'package:productivity/providers/kanban_board_provider.dart';
import 'package:productivity/providers/pomodoro_provider.dart';
import 'package:productivity/providers/habit_tracker_provider.dart';

class DashboardFeaturePreviewWidget extends StatelessWidget {
  const DashboardFeaturePreviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Fitur Produktivitas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _FeatureCard(
                title: 'Kanban Board',
                icon: Icons.dashboard_customize,
                child: Consumer<KanbanBoardProvider>(
                  builder: (context, provider, _) {
                    final total = provider.getTotalCards();
                    final completed = provider.getCompletedCards();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$completed/$total',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.greenSuccess,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Kartu Selesai',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              _FeatureCard(
                title: 'Pomodoro Timer',
                icon: Icons.schedule,
                child: Consumer<PomodoroProvider>(
                  builder: (context, provider, _) {
                    final today = provider.getTodaysSessions();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          today.toString(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.blueAccent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Sesi Hari Ini',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              _FeatureCard(
                title: 'Habit Tracker',
                icon: Icons.favorite,
                child: Consumer<HabitTrackerProvider>(
                  builder: (context, provider, _) {
                    final stats = provider.stats;
                    if (stats == null) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${stats.activeHabits}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Kebiasaan Aktif',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              const _FeatureCard(
                title: 'Analytics',
                icon: Icons.analytics,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ringkasan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Lihat insight di overview',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _FeatureCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.isDark ? Colors.grey[800]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.blueAccent, size: 24),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

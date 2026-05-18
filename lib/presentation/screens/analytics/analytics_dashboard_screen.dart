import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:productivity/core/theme/app_theme.dart';
import 'package:productivity/providers/kanban_board_provider.dart';
import 'package:productivity/providers/pomodoro_provider.dart';
import 'package:productivity/providers/habit_tracker_provider.dart';
import 'package:productivity/presentation/widgets/grid_background.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KanbanBoardProvider>().initialize();
      context.read<PomodoroProvider>().initialize();
      context.read<HabitTrackerProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.isDark ? const Color(0xFF0F1117) : AppColors.bg,
      body: GridBackground(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dashboard Analitik',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ringkasan aktivitas Anda hari ini',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 24),
                // Kanban Board Summary
                _buildSectionTitle('Kanban Board'),
                const SizedBox(height: 12),
                Consumer<KanbanBoardProvider>(
                  builder: (context, provider, _) {
                    final total = provider.getTotalCards();
                    final completed = provider.getCompletedCards();
                    final progress = total > 0 ? completed / total : 0.0;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.isDark
                              ? Colors.grey[800]!
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Progress Keseluruhan',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${(progress * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.greenSuccess,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: AppColors.isDark
                                  ? const Color(0xFF1C1C1C)
                                  : Colors.grey[300],
                              valueColor: const AlwaysStoppedAnimation(
                                AppColors.greenSuccess,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _StatItem(
                                label: 'Total Kartu',
                                value: total.toString(),
                              ),
                              _StatItem(
                                label: 'Selesai',
                                value: completed.toString(),
                              ),
                              _StatItem(
                                label: 'Sisa',
                                value: (total - completed).toString(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Pomodoro Summary
                _buildSectionTitle('Pomodoro Focus Sessions'),
                const SizedBox(height: 12),
                Consumer<PomodoroProvider>(
                  builder: (context, provider, _) {
                    final todaySessions = provider.getTodaysSessions();
                    final totalFocus = provider.getTotalFocusMinutesToday();
                    final totalStats = provider.stats;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.isDark
                              ? Colors.grey[800]!
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _StatItem(
                                label: 'Sesi Hari Ini',
                                value: todaySessions.toString(),
                                icon: Icons.schedule,
                              ),
                              _StatItem(
                                label: 'Total Fokus',
                                value: '$totalFocus menit',
                                icon: Icons.timer,
                              ),
                              _StatItem(
                                label: 'Total Sesi',
                                value:
                                    (totalStats?.totalSessions ?? 0).toString(),
                                icon: Icons.assessment,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (totalStats != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Statistik Keseluruhan',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _MiniStat(
                                      label: 'Total Pomodoro',
                                      value:
                                          totalStats.totalPomodoros.toString(),
                                    ),
                                    _MiniStat(
                                      label: 'Total Waktu',
                                      value:
                                          '${totalStats.totalFocusTime.inHours}h',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Habit Tracker Summary
                _buildSectionTitle('Habit Tracker'),
                const SizedBox(height: 12),
                Consumer<HabitTrackerProvider>(
                  builder: (context, provider, _) {
                    final stats = provider.stats;

                    if (stats == null) {
                      return const SizedBox.shrink();
                    }

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.isDark
                              ? Colors.grey[800]!
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _StatItem(
                                label: 'Total Kebiasaan',
                                value: stats.totalHabits.toString(),
                                icon: Icons.favorite,
                              ),
                              _StatItem(
                                label: 'Aktif',
                                value: stats.activeHabits.toString(),
                                icon: Icons.check_circle,
                              ),
                              _StatItem(
                                label: 'Streak',
                                value: '${stats.streak} hari',
                                icon: Icons.local_fire_department,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Completion Rate',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${stats.completionRate.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.blueAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: stats.completionRate / 100,
                              minHeight: 6,
                              backgroundColor: AppColors.isDark
                                  ? const Color(0xFF1C1C1C)
                                  : Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation(
                                AppColors.blueAccent,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.isDark
                                  ? const Color(0xFF1C1C1C)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Informasi Hari Ini',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Kebiasaan Selesai:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    Text(
                                      '${stats.completedToday}/${stats.activeHabits}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                // Quick Tips
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.isDark
                          ? Colors.grey[800]!
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb,
                            color: Colors.yellow[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Tips Produktivitas',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const _TipItem(
                        text:
                            'Fokus pada satu kanban card sekaligus untuk hasil maksimal',
                      ),
                      const SizedBox(height: 8),
                      const _TipItem(
                        text:
                            'Gunakan Pomodoro Timer untuk sesi fokus 25 menit yang efektif',
                      ),
                      const SizedBox(height: 8),
                      const _TipItem(
                        text:
                            'Catat kebiasaan harian untuk membangun momentum kesuksesan',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const _StatItem({
    required this.label,
    required this.value,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (icon != null)
          Icon(
            icon,
            size: 24,
            color: AppColors.blueAccent,
          )
        else
          const SizedBox(height: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.isDark ? const Color(0xFF1C1C1C) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final String text;

  const _TipItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Icon(
            Icons.check_circle_outline,
            size: 16,
            color: AppColors.greenSuccess,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}

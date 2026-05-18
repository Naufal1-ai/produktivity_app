import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:productivity/core/theme/app_theme.dart';
import 'package:productivity/providers/pomodoro_provider.dart';
import 'package:productivity/presentation/widgets/grid_background.dart';

class PomodoroTimerScreen extends StatefulWidget {
  const PomodoroTimerScreen({super.key});

  @override
  State<PomodoroTimerScreen> createState() => _PomodoroTimerScreenState();
}

class _PomodoroTimerScreenState extends State<PomodoroTimerScreen> {
  final _taskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PomodoroProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  void _startTimer(PomodoroProvider provider) {
    if (provider.currentTask.isEmpty) {
      _taskController.clear();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: const Text('Masukkan Nama Tugas'),
          content: TextField(
            controller: _taskController,
            decoration: InputDecoration(
              hintText: 'Nama tugas',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor:
                  AppColors.isDark ? const Color(0xFF1C1C1C) : Colors.grey[100],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_taskController.text.isNotEmpty) {
                  provider.startTimer(_taskController.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('Mulai'),
            ),
          ],
        ),
      );
      return;
    }

    provider.startTimer(provider.currentTask);
  }

  void _pauseTimer(PomodoroProvider provider) => provider.pauseTimer();
  void _resetTimer(PomodoroProvider provider) => provider.resetTimer();

  @override
  Widget build(BuildContext context) {
    return Consumer<PomodoroProvider>(
      builder: (context, provider, _) {
        // Menggunakan GridBackground langsung sebagai root tanpa Scaffold bersarang
        return GridBackground(
          child: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 16, 4, 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.blueAccent.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.timer_outlined,
                            color: AppColors.blueAccent,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Pomodoro Timer',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Timer card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.blueAccent.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: (provider.isWorkSession
                                    ? AppColors.greenSuccess
                                    : AppColors.blueAccent)
                                .withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            provider.isWorkSession ? 'Sesi Kerja' : 'Istirahat',
                            style: TextStyle(
                              fontSize: 14,
                              color: provider.isWorkSession
                                  ? AppColors.greenSuccess
                                  : AppColors.blueAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          provider.formatTime(provider.remainingSeconds),
                          style: TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (provider.currentTask.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Tugas: ${provider.currentTask}',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tombol kontrol
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: provider.isRunning
                            ? () => _pauseTimer(provider)
                            : () => _startTimer(provider),
                        icon: Icon(provider.isRunning
                            ? Icons.pause
                            : Icons.play_arrow),
                        label: Text(provider.isRunning ? 'Pause' : 'Mulai'),
                        style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () => _resetTimer(provider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset'),
                        style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Statistik
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.blueAccent.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Statistik Hari Ini',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'Sesi Selesai',
                                value: provider.getTodaysSessions().toString(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                title: 'Total Fokus',
                                value:
                                    '${provider.getTotalFocusMinutesToday()} menit',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sesi terbaru
                  if (provider.sessions.where((s) => s.isCompleted).isEmpty)
                    Center(
                      child: Text(
                        'Belum ada sesi pomodoro',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  else ...[
                    Text(
                      'Sesi Terbaru',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.sessions
                          .where((s) => s.isCompleted)
                          .take(5)
                          .length,
                      itemBuilder: (context, index) {
                        final completedSessions = provider.sessions
                            .where((s) => s.isCompleted)
                            .take(5)
                            .toList();
                        final session = completedSessions[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  AppColors.blueAccent.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      session.taskTitle,
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('HH:mm - dd MMM', 'id_ID')
                                          .format(session.createdAt),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${session.completedPomodoros} pom',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.blueAccent,
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
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:productivity/core/theme/app_theme.dart';
import 'package:productivity/providers/pomodoro_provider.dart';
import 'package:productivity/presentation/widgets/grid_background.dart';
import 'package:productivity/presentation/widgets/glass_container.dart';

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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Nama Tugas',
              style: TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: _taskController,
            autofocus: true,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Contoh: Belajar Flutter',
              hintStyle: TextStyle(color: AppColors.textMuted),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  Text('Batal', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                if (_taskController.text.isNotEmpty) {
                  provider.startTimer(_taskController.text);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blueAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const Text('Mulai'),
            ),
          ],
        ),
      );
      return;
    }
    provider.startTimer(provider.currentTask);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PomodoroProvider>(
      builder: (context, provider, _) {
        final totalSeconds = provider.isWorkSession
            ? provider.workDuration * 60
            : provider.breakDuration * 60;
        final progress = totalSeconds > 0
            ? provider.remainingSeconds / totalSeconds
            : 0.0;
        final accent =
            provider.isWorkSession ? AppColors.greenSuccess : AppColors.blueAccent;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SizedBox.expand(
            child: GridBackground(
              child: SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 16, 0, 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.blueAccent.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.timer_outlined,
                              color: AppColors.blueAccent, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pomodoro Timer',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Fokus & tingkatkan produktivitas',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Timer Card ───────────────────────────────────────
                  GlassContainer(
                    borderRadius: 28,
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        // Session badge
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 7),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(20),
                            border:
                                Border.all(color: accent.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            provider.isWorkSession ? '🎯 Sesi Kerja' : '☕ Istirahat',
                            style: TextStyle(
                              fontSize: 13,
                              color: accent,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Circular progress + timer
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Background ring
                              SizedBox(
                                width: 200,
                                height: 200,
                                child: CustomPaint(
                                  painter: _RingPainter(
                                    progress: 1.0,
                                    color: AppColors.borderAccent,
                                    strokeWidth: 10,
                                  ),
                                ),
                              ),
                              // Foreground ring
                              SizedBox(
                                width: 200,
                                height: 200,
                                child: CustomPaint(
                                  painter: _RingPainter(
                                    progress: progress,
                                    color: accent,
                                    strokeWidth: 10,
                                  ),
                                ),
                              ),
                              // Time text
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    provider.formatTime(
                                        provider.remainingSeconds),
                                    style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  if (provider.currentTask.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      child: Text(
                                        provider.currentTask,
                                        style: TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 11),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Reset
                            _ControlButton(
                              icon: Icons.refresh_rounded,
                              onTap: () => provider.resetTimer(),
                              color: AppColors.textMuted,
                              size: 44,
                            ),
                            const SizedBox(width: 20),
                            // Play/Pause (big)
                            _ControlButton(
                              icon: provider.isRunning
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              onTap: () => provider.isRunning
                                  ? provider.pauseTimer()
                                  : _startTimer(provider),
                              color: accent,
                              size: 64,
                              filled: true,
                            ),
                            const SizedBox(width: 20),
                            // Skip
                            _ControlButton(
                              icon: Icons.skip_next_rounded,
                              onTap: () => provider.skipSession(),
                              color: AppColors.textMuted,
                              size: 44,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Stats Row ────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: GlassContainer(
                          borderRadius: 18,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                               const Icon(Icons.check_circle_outline_rounded,
                                  color: AppColors.greenSuccess, size: 20),
                              const SizedBox(height: 8),
                              Text(
                                '${provider.getTodaysSessions()}',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text('Sesi selesai',
                                  style: TextStyle(
                                      color: AppColors.textMuted, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassContainer(
                          borderRadius: 18,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.bolt_rounded,
                                  color: AppColors.blueAccent, size: 20),
                              const SizedBox(height: 8),
                              Text(
                                '${provider.getTotalFocusMinutesToday()}',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text('Menit fokus',
                                  style: TextStyle(
                                      color: AppColors.textMuted, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Session History ──────────────────────────────────
                  if (provider.sessions.where((s) => s.isCompleted).isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Sesi Terbaru',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    ...provider.sessions
                        .where((s) => s.isCompleted)
                        .take(5)
                        .map((session) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: GlassContainer(
                                borderRadius: 16,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.greenSuccess
                                            .withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check_rounded,
                                          color: AppColors.greenSuccess,
                                          size: 14),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            session.taskTitle,
                                            style: TextStyle(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            DateFormat('HH:mm • dd MMM', 'id_ID')
                                                .format(session.createdAt),
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textMuted),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.blueAccent
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${session.completedPomodoros} 🍅',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.blueAccent,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )),
                  ],
                ],
              ),
            ),
          ),
        ),
        ),
      );
      },
    );
  }
}

// ── Circular ring painter ─────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ── Control button ────────────────────────────────────────────────────────────

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final double size;
  final bool filled;

  const _ControlButton({
    required this.icon,
    required this.onTap,
    required this.color,
    required this.size,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: filled
              ? color
              : AppColors.borderAccent.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: Icon(
          icon,
          color: filled ? Colors.white : color,
          size: size * 0.5,
        ),
      ),
    );
  }
}

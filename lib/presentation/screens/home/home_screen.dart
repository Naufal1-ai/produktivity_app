import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:productivity/core/theme/app_theme.dart';
import 'package:productivity/core/utils/currency_utils.dart';
import 'package:productivity/data/models/transaction_model.dart';
import 'package:productivity/data/repositories/transaction_repository.dart';
import 'package:productivity/data/models/lending_model.dart';
import 'package:productivity/data/repositories/lending_repository.dart';
import 'package:productivity/presentation/screens/lending/lending_screen.dart';
import 'package:productivity/presentation/widgets/common_widgets.dart';
import 'package:productivity/presentation/widgets/transaction_form_sheet.dart';
import 'package:productivity/presentation/widgets/grid_background.dart';
import 'package:productivity/presentation/widgets/glass_container.dart';
import 'package:productivity/presentation/widgets/dashboard_summary_cards.dart';
import 'package:productivity/presentation/widgets/dashboard_line_chart.dart';
import 'package:productivity/presentation/widgets/dashboard_pie_chart.dart';
import 'package:productivity/providers/kanban_board_provider.dart';
import 'package:productivity/providers/pomodoro_provider.dart';
import 'package:productivity/providers/habit_tracker_provider.dart';
import 'package:productivity/presentation/screens/kanban/kanban_board_screen.dart';
import 'package:productivity/presentation/screens/pomodoro/pomodoro_timer_screen.dart';
import 'package:productivity/presentation/screens/habit_tracker/habit_tracker_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;
  final VoidCallback onOpenDrawer;

  const HomeScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
    required this.onOpenDrawer,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = TransactionRepository();
  final _lendingRepo = LendingRepository();
  final _auth = FirebaseAuth.instance;
  DateTime _selectedMonth = DateTime.now();

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Selamat Pagi';
    if (h < 17) return 'Selamat Siang';
    return 'Selamat Malam';
  }

  String get _userEmail =>
      _auth.currentUser?.email?.split('@').first ?? 'Pengguna';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KanbanBoardProvider>().initialize();
      context.read<PomodoroProvider>().initialize();
      context.read<HabitTrackerProvider>().initialize();
    });
  }

  void _openForm([TransactionModel? tx]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionFormSheet(existing: tx),
    );
  }

  void openAddForm() => _openForm();

  Future<void> _delete(String id) async {
    await _repo.delete(id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Transaksi dihapus'),
        backgroundColor: AppColors.bgCard,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
            label: 'OK', textColor: AppColors.blueAccent, onPressed: () {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.isDark ? const Color(0xFF0F1117) : AppColors.bg,
      body: GridBackground(
        child: SafeArea(
          bottom: false,
          child: StreamBuilder<List<TransactionModel>>(
            stream: _repo.watchByMonth(_selectedMonth),
            builder: (context, snapshot) {
              final txList = snapshot.data ?? [];
              final totalIncome = txList
                  .where((t) => t.isIncome)
                  .fold(0.0, (s, t) => s + t.amount);
              final totalExpense = txList
                  .where((t) => !t.isIncome)
                  .fold(0.0, (s, t) => s + t.amount);
              final balance = totalIncome - totalExpense;

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 1024;

                  return CustomScrollView(
                    slivers: [
                      // ── Header ──────────────────────────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (!isDesktop)
                                IconButton(
                                  icon: const Icon(Icons.menu),
                                  color: AppColors.textPrimary,
                                  onPressed: widget.onOpenDrawer,
                                  padding: const EdgeInsets.only(right: 12),
                                  constraints: const BoxConstraints(),
                                ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dashboard Overview',
                                      style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$_greeting, $_userEmail.',
                                      style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    const _DashboardClock(),
                                  ],
                                ),
                              ),
                              if (!isDesktop)
                                Consumer<PomodoroProvider>(
                                  builder: (context, provider, _) => Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (provider.isRunning) ...[
                                        _buildPomodoroChip(provider),
                                        const SizedBox(width: 8),
                                      ],
                                      IconButton(
                                        icon: Icon(
                                          widget.isDarkMode
                                              ? Icons.wb_sunny_outlined
                                              : Icons.nights_stay_outlined,
                                          size: 20,
                                        ),
                                        color: AppColors.textMuted,
                                        onPressed: widget.onToggleTheme,
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Consumer<PomodoroProvider>(
                                  builder: (context, provider, _) => Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (provider.isRunning) ...[
                                        _buildPomodoroChip(provider),
                                        const SizedBox(width: 8),
                                      ],
                                      ElevatedButton.icon(
                                        onPressed: () => _openForm(),
                                        icon: const Icon(Icons.add, size: 18),
                                        label: const Text('Tambah Transaksi'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.blueMid,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // ── Dashboard Content ──────────────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DashboardSummaryCards(
                                balance: balance,
                                totalIncome: totalIncome,
                                totalExpense: totalExpense,
                                isDesktop: isDesktop,
                              ),
                              const SizedBox(height: 24),

                              // ── Kanban, Pomodoro, Habit ──────────────────
                              if (isDesktop) ...[
                                IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                          child: _buildKanbanOverview(context)),
                                      const SizedBox(width: 16),
                                      Expanded(
                                          child:
                                              _buildPomodoroOverview(context)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                          child: _buildHabitOverview(context)),
                                      const SizedBox(width: 16),
                                      Expanded(
                                          child:
                                              _buildLendingOverview(context)),
                                    ],
                                  ),
                                ),
                              ] else
                                Column(
                                  children: [
                                    _buildKanbanOverview(context),
                                    const SizedBox(height: 16),
                                    _buildPomodoroOverview(context),
                                    const SizedBox(height: 16),
                                    _buildHabitOverview(context),
                                    const SizedBox(height: 16),
                                    _buildLendingOverview(context),
                                  ],
                                ),

                              const SizedBox(height: 24),

                              // ── Charts ───────────────────────────────────
                              if (isDesktop)
                                SizedBox(
                                  height: 320,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: DashboardLineChart(
                                            transactions: txList,
                                            month: _selectedMonth),
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        flex: 1,
                                        child: DashboardPieChart(
                                            transactions: txList),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Column(
                                  children: [
                                    SizedBox(
                                      height: 300,
                                      child: DashboardLineChart(
                                          transactions: txList,
                                          month: _selectedMonth),
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      height: 240,
                                      child: DashboardPieChart(
                                          transactions: txList),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),

                      // ── Action & Title for Transactions ────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Riwayat Transaksi',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: _pickMonth,
                                icon: Icon(Icons.calendar_month_outlined,
                                    size: 14, color: AppColors.textSecondary),
                                label: Text(
                                  DateUtils2.formatMonth(_selectedMonth),
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  side:
                                      BorderSide(color: AppColors.borderAccent),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),

                      // ── Transaction list ───────────────────────────────────
                      if (txList.isEmpty) ...[
                        SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('💸',
                                      style: TextStyle(fontSize: 48)),
                                  const SizedBox(height: 12),
                                  Text('Belum ada transaksi bulan ini',
                                      style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 14)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 140)),
                      ] else ...[
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 140),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) => TransactionTile(
                                tx: txList[i],
                                onEdit: () => _openForm(txList[i]),
                                onDelete: () => _delete(txList[i].id),
                              ),
                              childCount: txList.length,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildKanbanOverview(BuildContext context) {
    final kanbanProvider = context.watch<KanbanBoardProvider>();
    final totalCards = kanbanProvider.getTotalCards();
    final completedCards = kanbanProvider.getCompletedCards();
    final progress = kanbanProvider.getProgressPercentage();

    return GlassContainer(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const KanbanBoardScreen()),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Kanban',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text('Lihat detail',
                    style: TextStyle(
                        color: AppColors.blueAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),
            Text('Ringkasan tugas saat ini',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$totalCards total kartu',
                          style: TextStyle(
                              color: AppColors.textPrimary, fontSize: 14)),
                      const SizedBox(height: 6),
                      Text('$completedCards selesai',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress / 100,
                        backgroundColor: AppColors.borderAccent,
                        color: AppColors.greenSuccess,
                        strokeWidth: 6,
                      ),
                      Text('${progress.toStringAsFixed(0)}%',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPomodoroOverview(BuildContext context) {
    final pomodoroProvider = context.watch<PomodoroProvider>();
    final remaining =
        pomodoroProvider.formatTime(pomodoroProvider.remainingSeconds);
    final currentTask = pomodoroProvider.currentTask.isNotEmpty
        ? pomodoroProvider.currentTask
        : 'Belum ada tugas aktif';
    final statusLabel = pomodoroProvider.isRunning
        ? 'Berjalan (${pomodoroProvider.isWorkSession ? 'Fokus' : 'Istirahat'})'
        : 'Tidak berjalan';

    return GlassContainer(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PomodoroTimerScreen()),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Pomodoro',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Chip(
                  label: Text(statusLabel,
                      style: TextStyle(
                          color: AppColors.textPrimary, fontSize: 12)),
                  backgroundColor: pomodoroProvider.isRunning
                      ? AppColors.greenSuccess.withValues(alpha: 0.16)
                      : AppColors.borderAccent,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Sisa waktu',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 10),
            Text(remaining,
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 34,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(currentTask,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitOverview(BuildContext context) {
    final habitProvider = context.watch<HabitTrackerProvider>();
    final totalHabits = habitProvider.habits.length;
    final completedToday = habitProvider.getCompletedHabitsToday();
    final streak = habitProvider.getStreak();

    return GlassContainer(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const HabitTrackerScreen()),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Habit Tracker',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text('Lihat detail',
                    style: TextStyle(
                        color: AppColors.blueAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),
            Text('Status kebiasaan hari ini',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$completedToday selesai hari ini',
                          style: TextStyle(
                              color: AppColors.textPrimary, fontSize: 14)),
                      const SizedBox(height: 6),
                      Text('$totalHabits kebiasaan aktif',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.blueAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Streak $streak hari',
                      style:
                          TextStyle(color: AppColors.blueAccent, fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLendingOverview(BuildContext context) {
    return StreamBuilder<List<LendingModel>>(
      stream: _lendingRepo.watchAll(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        final activeCount = items.where((i) => !i.isReturned).length;
        final overdueCount = items
            .where((i) =>
                !i.isReturned && i.targetReturnDate.isBefore(DateTime.now()))
            .length;

        return GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LendingScreen()),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Peminjaman',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    Text('Lihat detail',
                        style: TextStyle(
                            color: AppColors.blueAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Status barang dipinjam',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$activeCount barang aktif',
                              style: TextStyle(
                                  color: AppColors.textPrimary, fontSize: 14)),
                          const SizedBox(height: 6),
                          Text(
                              overdueCount > 0
                                  ? '$overdueCount terlambat!'
                                  : 'Semua aman',
                              style: TextStyle(
                                  color: overdueCount > 0
                                      ? AppColors.expense
                                      : AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: overdueCount > 0
                                      ? FontWeight.bold
                                      : FontWeight.normal)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: (overdueCount > 0
                                ? AppColors.expense
                                : AppColors.blueAccent)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        overdueCount > 0
                            ? Icons.warning_amber_rounded
                            : Icons.inventory_2_outlined,
                        color: overdueCount > 0
                            ? AppColors.expense
                            : AppColors.blueAccent,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPomodoroChip(PomodoroProvider provider) {
    return Chip(
      label: Text(
        provider.isWorkSession
            ? 'Pomodoro aktif • ${provider.formatTime(provider.remainingSeconds)}'
            : 'Istirahat • ${provider.formatTime(provider.remainingSeconds)}',
        style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
      ),
      backgroundColor: AppColors.greenSuccess.withValues(alpha: 0.16),
      side: BorderSide(color: AppColors.greenSuccess.withValues(alpha: 0.24)),
    );
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final months = List.generate(
      12,
      (i) => DateTime(now.year, now.month - i),
    );
    final modalContext = context;
    await showModalBottomSheet(
      context: modalContext,
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
              borderRadius: BorderRadius.circular(2),
            ),
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

class _DashboardClock extends StatefulWidget {
  const _DashboardClock();

  @override
  State<_DashboardClock> createState() => _DashboardClockState();
}

class _DashboardClockState extends State<_DashboardClock> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _scheduleNextMinuteTick();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _scheduleNextMinuteTick() {
    final nextMinute = DateTime(
      _now.year,
      _now.month,
      _now.day,
      _now.hour,
      _now.minute + 1,
    );
    final delay = nextMinute.difference(DateTime.now());

    _timer = Timer(delay.isNegative ? const Duration(minutes: 1) : delay, () {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
      _scheduleNextMinuteTick();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      DateFormat('EEEE, d MMM · HH:mm', 'id_ID').format(_now),
      style: TextStyle(color: AppColors.textMuted, fontSize: 11),
    );
  }
}

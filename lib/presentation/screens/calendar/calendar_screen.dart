import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:productivity/core/theme/app_theme.dart';
import 'package:productivity/data/models/kanban_board_model.dart';
import 'package:productivity/data/models/habit_model.dart';
import 'package:productivity/data/models/lending_model.dart';
import 'package:productivity/data/repositories/kanban_board_repository.dart';
import 'package:productivity/data/repositories/habit_repository.dart';
import 'package:productivity/data/repositories/lending_repository.dart';
import 'package:productivity/presentation/widgets/grid_background.dart';
import 'package:productivity/presentation/widgets/glass_container.dart';

enum CalendarFilter { all, kanban, habit, lending }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _kanbanRepo = KanbanBoardRepository();
  final _habitRepo = HabitRepository();
  final _lendingRepo = LendingRepository();

  StreamSubscription? _kanbanSub;
  StreamSubscription? _habitSub;
  StreamSubscription? _lendingSub;

  List<KanbanCard> _cards = [];
  List<Habit> _habits = [];
  List<LendingModel> _lendings = [];

  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  CalendarFilter _activeFilter = CalendarFilter.all;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _subscribeAll();
  }

  void _subscribeAll() {
    _kanbanSub = _kanbanRepo.watchAllCardsGlobal().listen((cards) {
      if (mounted) {
        setState(() {
          _cards = cards;
          _isLoading = false;
        });
      }
    }, onError: (err) {
      debugPrint("Gagal memuat kartu kanban untuk kalender: $err");
    });

    _habitSub = _habitRepo.watchAll().listen((habits) {
      if (mounted) {
        setState(() {
          _habits = habits;
          _isLoading = false;
        });
      }
    }, onError: (err) {
      debugPrint("Gagal memuat habits untuk kalender: $err");
    });

    _lendingSub = _lendingRepo.watchAll().listen((lendings) {
      if (mounted) {
        setState(() {
          _lendings = lendings;
          _isLoading = false;
        });
      }
    }, onError: (err) {
      debugPrint("Gagal memuat data peminjaman untuk kalender: $err");
    });
  }

  @override
  void dispose() {
    _kanbanSub?.cancel();
    _habitSub?.cancel();
    _lendingSub?.cancel();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _doesHabitRecurOn(Habit habit, DateTime day) {
    if (!habit.isActive) return false;
    final start = DateTime(habit.startDate.year, habit.startDate.month, habit.startDate.day);
    final target = DateTime(day.year, day.month, day.day);

    if (target.isBefore(start)) return false;

    if (habit.frequency == 'Daily') {
      return true;
    } else if (habit.frequency == 'Weekly') {
      return target.weekday == start.weekday;
    } else if (habit.frequency == 'Monthly') {
      return target.day == start.day;
    }
    return false;
  }

  // Generate event data for a given day
  List<_CalendarEvent> _getEventsForDay(DateTime day) {
    final List<_CalendarEvent> events = [];

    // 1. Kanban Card deadlines
    if (_activeFilter == CalendarFilter.all || _activeFilter == CalendarFilter.kanban) {
      for (final card in _cards) {
        if (card.dueDate != null && _isSameDay(card.dueDate!, day)) {
          events.add(_CalendarEvent(
            id: 'kanban_${card.id}',
            title: card.title,
            subtitle: 'Kanban Card • Kolom: ${card.column}',
            date: card.dueDate!,
            type: CalendarFilter.kanban,
            isCompleted: card.column == 'Done',
            description: card.description,
            tag: card.priority ?? 'Medium',
          ));
        }
      }
    }

    // 2. Habit schedules
    if (_activeFilter == CalendarFilter.all || _activeFilter == CalendarFilter.habit) {
      for (final habit in _habits) {
        if (_doesHabitRecurOn(habit, day)) {
          events.add(_CalendarEvent(
            id: 'habit_${habit.id}',
            title: habit.name,
            subtitle: 'Jadwal Kebiasaan • Frekuensi: ${habit.frequency}',
            date: day,
            type: CalendarFilter.habit,
            isCompleted: false, // Default scheduled
            description: habit.description,
            tag: habit.category,
          ));
        }
      }
    }

    // 3. Lending Reminder target return deadlines
    if (_activeFilter == CalendarFilter.all || _activeFilter == CalendarFilter.lending) {
      for (final lending in _lendings) {
        if (_isSameDay(lending.targetReturnDate, day)) {
          events.add(_CalendarEvent(
            id: 'lending_${lending.id}',
            title: 'Kembalikan: ${lending.itemName}',
            subtitle: 'Peminjam: ${lending.borrowerName}',
            date: lending.targetReturnDate,
            type: CalendarFilter.lending,
            isCompleted: lending.isReturned,
            description: lending.note,
            tag: lending.category,
          ));
        }
      }
    }

    // Sort: Kanban first, then Lending, then Habit
    events.sort((a, b) => a.type.index.compareTo(b.type.index));
    return events;
  }

  List<DateTime> _generateMonthDays(DateTime monthDate) {
    final firstDayOfMonth = DateTime(monthDate.year, monthDate.month, 1);
    final lastDayOfMonth = DateTime(monthDate.year, monthDate.month + 1, 0);

    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday

    final List<DateTime> days = [];

    // Pad days from the previous month
    final prevMonthLastDay = DateTime(monthDate.year, monthDate.month, 0);
    final padCount = firstWeekday - 1;
    for (int i = padCount - 1; i >= 0; i--) {
      days.add(DateTime(prevMonthLastDay.year, prevMonthLastDay.month, prevMonthLastDay.day - i));
    }

    // Add current month days
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(monthDate.year, monthDate.month, i));
    }

    // Pad days from the next month to make a complete 42-cell grid
    final remaining = 42 - days.length;
    for (int i = 1; i <= remaining; i++) {
      days.add(DateTime(monthDate.year, monthDate.month + 1, i));
    }

    return days;
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  void _prevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final days = _generateMonthDays(_focusedMonth);
    final selectedDayEvents = _getEventsForDay(_selectedDate);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GridBackground(
        child: SafeArea(
          bottom: false,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // ── Header ───────────────────────────────────────────────
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
                              Icons.calendar_month_rounded,
                              color: AppColors.blueAccent,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kalender Tersinkron',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Deadline Kanban, Habit, & Peminjaman',
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

                    // ── Filter Chips ─────────────────────────────────────────
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      child: Row(
                        children: [
                          _buildFilterChip('Semua', CalendarFilter.all, Icons.dashboard_outlined, AppColors.blueAccent),
                          const SizedBox(width: 8),
                          _buildFilterChip('Kanban', CalendarFilter.kanban, Icons.assignment_outlined, AppColors.expense),
                          const SizedBox(width: 8),
                          _buildFilterChip('Habit', CalendarFilter.habit, Icons.psychology_outlined, AppColors.greenSuccess),
                          const SizedBox(width: 8),
                          _buildFilterChip('Peminjaman', CalendarFilter.lending, Icons.inventory_2_outlined, Colors.orange),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Month Selector & Calendar Grid ────────────────────────
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                        children: [
                          GlassContainer(
                            borderRadius: 24,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                // Month Selector Header
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.chevron_left, color: AppColors.textPrimary),
                                      onPressed: _prevMonth,
                                    ),
                                    Text(
                                      DateFormat('MMMM yyyy', 'id_ID').format(_focusedMonth),
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.chevron_right, color: AppColors.textPrimary),
                                      onPressed: _nextMonth,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Day of the Week Header
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']
                                      .map((label) => Expanded(
                                            child: Center(
                                              child: Text(
                                                label,
                                                style: TextStyle(
                                                  color: AppColors.textMuted,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ),
                                const SizedBox(height: 12),

                                // Days Grid
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: 42,
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 7,
                                    mainAxisSpacing: 8,
                                    crossAxisSpacing: 8,
                                  ),
                                  itemBuilder: (context, idx) {
                                    final day = days[idx];
                                    final isCurrentMonth = day.month == _focusedMonth.month;
                                    final isSelected = _isSameDay(day, _selectedDate);
                                    final isToday = _isSameDay(day, DateTime.now());
                                    final dayEvents = _getEventsForDay(day);

                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedDate = day;
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.blueAccent
                                              : isToday
                                                  ? AppColors.blueAccent.withValues(alpha: 0.15)
                                                  : Colors.transparent,
                                          borderRadius: BorderRadius.circular(16),
                                          border: isToday && !isSelected
                                              ? Border.all(color: AppColors.blueAccent.withValues(alpha: 0.4), width: 1.5)
                                              : null,
                                        ),
                                        alignment: Alignment.center,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '${day.day}',
                                              style: TextStyle(
                                                color: isSelected
                                                    ? Colors.white
                                                    : isCurrentMonth
                                                        ? AppColors.textPrimary
                                                        : AppColors.textMuted,
                                                fontSize: 14,
                                                fontWeight: (isSelected || isToday)
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            // Event Dots indicators
                                            if (dayEvents.isNotEmpty)
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: _buildDots(dayEvents, isSelected),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // ── Selected Day Events List ───────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDate),
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${selectedDayEvents.length} Kegiatan',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (selectedDayEvents.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.event_busy_rounded, size: 48, color: AppColors.textMuted),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tidak ada kegiatan atau deadline.',
                                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: selectedDayEvents.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, idx) {
                                final event = selectedDayEvents[idx];
                                return _buildEventCard(event);
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, CalendarFilter filter, IconData icon, Color color) {
    final selected = _activeFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeFilter = filter;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.transparent : AppColors.borderAccent.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDots(List<_CalendarEvent> events, bool isSelected) {
    final List<Widget> dots = [];
    final List<CalendarFilter> addedTypes = [];

    for (final event in events) {
      if (!addedTypes.contains(event.type)) {
        addedTypes.add(event.type);
        Color dotColor;
        switch (event.type) {
          case CalendarFilter.kanban:
            dotColor = isSelected ? Colors.white : AppColors.expense;
            break;
          case CalendarFilter.habit:
            dotColor = isSelected ? Colors.white : AppColors.greenSuccess;
            break;
          case CalendarFilter.lending:
            dotColor = isSelected ? Colors.white : Colors.orange;
            break;
          default:
            dotColor = Colors.white;
        }

        dots.add(
          Container(
            width: 4.5,
            height: 4.5,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
        );
      }
      if (dots.length >= 3) break; // Maximum 3 dots
    }

    return dots;
  }

  Widget _buildEventCard(_CalendarEvent event) {
    Color typeColor;
    IconData icon;
    String typeLabel;

    switch (event.type) {
      case CalendarFilter.kanban:
        typeColor = AppColors.expense;
        icon = Icons.assignment_outlined;
        typeLabel = 'KANBAN CARD';
        break;
      case CalendarFilter.habit:
        typeColor = AppColors.greenSuccess;
        icon = Icons.psychology_outlined;
        typeLabel = 'HABIT';
        break;
      case CalendarFilter.lending:
        typeColor = Colors.orange;
        icon = Icons.inventory_2_outlined;
        typeLabel = 'PENGEMBALIAN';
        break;
      default:
        typeColor = AppColors.blueAccent;
        icon = Icons.event_note_outlined;
        typeLabel = 'KEGIATAN';
    }

    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: typeColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(
                          color: typeColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (event.tag != null)
                      Text(
                        event.tag!,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  event.title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    decoration: event.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (event.description != null && event.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    event.description!,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarEvent {
  final String id;
  final String title;
  final String subtitle;
  final DateTime date;
  final CalendarFilter type;
  final bool isCompleted;
  final String? description;
  final String? tag;

  _CalendarEvent({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.type,
    required this.isCompleted,
    this.description,
    this.tag,
  });
}

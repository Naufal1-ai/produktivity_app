import 'package:flutter/material.dart';
import 'package:productivity/core/theme/app_theme.dart';
import 'package:productivity/data/repositories/task_repository.dart';
import 'package:productivity/data/models/task_model.dart';
import 'package:productivity/presentation/widgets/task_form_sheet.dart';
import 'package:productivity/presentation/widgets/grid_background.dart';
import 'package:productivity/core/utils/currency_utils.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _repo = TaskRepository();
  String _taskFilter = 'all';

  void _openTaskForm([TaskModel? task]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskFormSheet(existing: task),
    );
  }

  Future<void> _toggleCompletion(TaskModel task) async {
    final updated = task.copyWith(completed: !task.completed);
    await _repo.update(updated);
  }

  Future<void> _deleteTask(String id) async {
    await _repo.delete(id);
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isThisWeek(DateTime date) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    return !date.isBefore(DateTime(monday.year, monday.month, monday.day)) &&
        !date.isAfter(
            DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59));
  }

  int _priorityValue(String priority) {
    switch (priority) {
      case 'High':
        return 3;
      case 'Low':
        return 1;
      default:
        return 2;
    }
  }

  List<TaskModel> _applyTaskFilter(List<TaskModel> tasks) {
    if (_taskFilter == 'today') {
      return tasks.where((task) => _isToday(task.dueDate)).toList();
    }
    if (_taskFilter == 'week') {
      return tasks.where((task) => _isThisWeek(task.dueDate)).toList();
    }
    return tasks;
  }

  List<TaskModel> _sortTasks(List<TaskModel> tasks) {
    final sortedTasks = [...tasks];
    sortedTasks.sort((a, b) {
      if (a.completed != b.completed) {
        return a.completed ? 1 : -1;
      }
      final priorityCompare =
          _priorityValue(b.priority).compareTo(_priorityValue(a.priority));
      if (priorityCompare != 0) return priorityCompare;
      return a.dueDate.compareTo(b.dueDate);
    });
    return sortedTasks;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.isDark ? const Color(0xFF0F1117) : AppColors.bg,
      body: GridBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ✅ Header — sama persis dengan FinanceScreen
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
                        Icons.check_circle_outline,
                        color: AppColors.blueAccent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Task & Jadwal',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // ✅ Tombol tambah di kanan header
                    GestureDetector(
                      onTap: () => _openTaskForm(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.blueAccent.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add,
                          color: AppColors.blueAccent,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ✅ Filter chips — sama style dengan TabBar di FinanceScreen
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
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      _buildFilterTab('Semua', 'all'),
                      _buildFilterTab('Hari Ini', 'today'),
                      _buildFilterTab('Minggu Ini', 'week'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ✅ Body stream
              Expanded(
                child: StreamBuilder<List<TaskModel>>(
                  stream: _repo.watchAll(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Terjadi kesalahan saat memuat task: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppColors.expense, fontSize: 14),
                          ),
                        ),
                      );
                    }

                    final tasks = snapshot.data ?? [];
                    final filteredTasks = _sortTasks(_applyTaskFilter(tasks));
                    final completedCount =
                        tasks.where((task) => task.completed).length;
                    final overdueCount =
                        tasks.where((task) => task.isOverdue).length;

                    return Column(
                      children: [
                        // ✅ Stats row
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          child: Row(
                            children: [
                              Text(
                                'Total: ${tasks.length}',
                                style: TextStyle(
                                    color: AppColors.textMuted, fontSize: 12),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                'Selesai: $completedCount',
                                style: const TextStyle(
                                    color: AppColors.income, fontSize: 12),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                'Terlambat: $overdueCount',
                                style: const TextStyle(
                                    color: AppColors.expense, fontSize: 12),
                              ),
                            ],
                          ),
                        ),

                        Expanded(
                          child: filteredTasks.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 32),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.checklist_rtl,
                                            size: 64,
                                            color: AppColors.textMuted),
                                        const SizedBox(height: 18),
                                        Text(
                                          'Belum ada task. Tambahkan kegiatan harian atau jadwal penting Anda.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 16),
                                        ),
                                        const SizedBox(height: 20),
                                        ElevatedButton(
                                          onPressed: () => _openTaskForm(),
                                          child: const Text('Tambah Task'),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 4, 16, 120),
                                  itemCount: filteredTasks.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final task = filteredTasks[index];
                                    return _TaskCard(
                                      task: task,
                                      onToggleComplete: () =>
                                          _toggleCompletion(task),
                                      onEdit: () => _openTaskForm(task),
                                      onDelete: () => _deleteTask(task.id),
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: FloatingActionButton(
          onPressed: () => _openTaskForm(),
          backgroundColor: AppColors.blueAccent,
          child:
              const Icon(Icons.add, color: Color.fromARGB(255, 255, 255, 255)),
        ),
      ),
    );
  }

  /// ✅ Filter tab dengan peningkatan kontras warna teks (Putih)
  Widget _buildFilterTab(String label, String value) {
    final selected = _taskFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _taskFilter = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.blueAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : (AppColors.isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : AppColors.textSecondary),
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onToggleComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.task,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = task.completed
        ? AppColors.income
        : task.isOverdue
            ? AppColors.expense
            : AppColors.blueAccent;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withAlpha((0.18 * 255).round())),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                  value: task.completed, onChanged: (_) => onToggleComplete()),
              Expanded(
                child: Text(
                  task.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        decoration:
                            task.completed ? TextDecoration.lineThrough : null,
                      ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') return onEdit();
                  if (value == 'delete') return onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.bgCardAlt,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(task.category,
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: task.priority == 'High'
                      ? AppColors.expense.withAlpha((0.16 * 255).round())
                      : task.priority == 'Low'
                          ? AppColors.textSecondary
                              .withAlpha((0.16 * 255).round())
                          : AppColors.income.withAlpha((0.16 * 255).round()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  task.priority,
                  style: TextStyle(
                    color: task.priority == 'High'
                        ? AppColors.expense
                        : task.priority == 'Low'
                            ? AppColors.textSecondary
                            : AppColors.income,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                DateUtils2.formatDisplay(task.dueDate),
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              task.description,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}

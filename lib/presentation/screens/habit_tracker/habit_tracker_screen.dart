import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:productivity/core/theme/app_theme.dart';
import 'package:productivity/data/models/habit_model.dart';
import 'package:productivity/providers/habit_tracker_provider.dart';
import 'package:productivity/presentation/widgets/grid_background.dart';

class HabitTrackerScreen extends StatefulWidget {
  const HabitTrackerScreen({super.key});

  @override
  State<HabitTrackerScreen> createState() => _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends State<HabitTrackerScreen> {
  final String _selectedCategory = 'All';
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedFrequency = 'Daily';
  String _selectedHabitCategory = 'Health';
  int _goal = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HabitTrackerProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _openAddHabitDialog() {
    _nameController.clear();
    _descriptionController.clear();
    _selectedFrequency = 'Daily';
    _selectedHabitCategory = 'Health';
    _goal = 1;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Tambah Kebiasaan Baru'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Nama kebiasaan',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: AppColors.isDark
                      ? const Color(0xFF1C1C1C)
                      : Colors.grey[100],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Deskripsi',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: AppColors.isDark
                      ? const Color(0xFF1C1C1C)
                      : Colors.grey[100],
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedHabitCategory,
                items: kHabitCategories
                    .map(
                        (cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedHabitCategory = val);
                },
                decoration: InputDecoration(
                  hintText: 'Kategori',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: AppColors.isDark
                      ? const Color(0xFF1C1C1C)
                      : Colors.grey[100],
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedFrequency,
                items: kHabitFrequencies
                    .map((freq) =>
                        DropdownMenuItem(value: freq, child: Text(freq)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedFrequency = val);
                },
                decoration: InputDecoration(
                  hintText: 'Frekuensi',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: AppColors.isDark
                      ? const Color(0xFF1C1C1C)
                      : Colors.grey[100],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Goal (per minggu/bulan)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: AppColors.isDark
                      ? const Color(0xFF1C1C1C)
                      : Colors.grey[100],
                ),
                onChanged: (val) {
                  if (val.isNotEmpty) setState(() => _goal = int.parse(val));
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: _submitHabit,
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  void _submitHabit() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama kebiasaan tidak boleh kosong')),
      );
      return;
    }

    final habit = Habit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      description: _descriptionController.text,
      category: _selectedHabitCategory,
      frequency: _selectedFrequency,
      goal: _goal,
      startDate: DateTime.now(),
      isActive: true,
      createdAt: DateTime.now(),
    );

    context.read<HabitTrackerProvider>().addHabit(habit);
    Navigator.pop(context);
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
              // ✅ Header konsisten
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
                        Icons.psychology_outlined,
                        color: AppColors.blueAccent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Habit Tracker',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // ✅ Stat cards row
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Consumer<HabitTrackerProvider>(
                  builder: (context, provider, _) {
                    final stats = provider.stats;
                    if (stats == null) return const SizedBox.shrink();

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.white.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.blueAccent.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatCard(
                            icon: Icons.favorite,
                            label: 'Aktif',
                            value: stats.activeHabits.toString(),
                            color: AppColors.greenSuccess,
                          ),
                          _divider(),
                          _StatCard(
                            icon: Icons.local_fire_department,
                            label: 'Streak',
                            value: '${stats.streak} hari',
                            color: Colors.orange,
                          ),
                          _divider(),
                          _StatCard(
                            icon: Icons.check_circle,
                            label: 'Hari Ini',
                            value: stats.completedToday.toString(),
                            color: AppColors.blueAccent,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ✅ List habit
              Expanded(
                child: Consumer<HabitTrackerProvider>(
                  builder: (context, provider, _) {
                    final habits = _selectedCategory == 'All'
                        ? provider.habits
                        : provider.getHabitsByCategory(_selectedCategory);

                    if (habits.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.psychology,
                                size: 64, color: AppColors.textMuted),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada kebiasaan',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                      itemCount: habits.length,
                      itemBuilder: (context, index) =>
                          _buildHabitCard(context, habits[index], provider),
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
          onPressed: _openAddHabitDialog,
          backgroundColor: AppColors.blueAccent,
          child:
              const Icon(Icons.add, color: Color.fromARGB(255, 255, 255, 255)),
        ),
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 36,
        color: AppColors.blueAccent.withValues(alpha: 0.12),
      );

  Widget _buildHabitCard(
    BuildContext context,
    Habit habit,
    HabitTrackerProvider provider,
  ) {
    final isCompletedToday = provider.isHabitCompletedToday(habit.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.blueAccent.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(habit.category)
                                .withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            habit.category,
                            style: TextStyle(
                              fontSize: 12,
                              color: _getCategoryColor(habit.category),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          habit.frequency,
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _deleteHabit(habit.id),
                child: Icon(Icons.close, color: AppColors.textMuted),
              ),
            ],
          ),
          if (habit.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              habit.description,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Goal: ${habit.goal}x',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              if (isCompletedToday)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.greenSuccess.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle,
                          size: 14, color: AppColors.greenSuccess),
                      SizedBox(width: 4),
                      Text(
                        'Selesai hari ini',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.greenSuccess,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: () => provider.logHabitCompletion(habit.id),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Log'),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Health':
        return AppColors.greenSuccess;
      case 'Productivity':
        return AppColors.blueAccent;
      case 'Learning':
        return Colors.purple;
      case 'Social':
        return Colors.pink;
      case 'Finance':
        return Colors.orange;
      default:
        return AppColors.textMuted;
    }
  }

  void _deleteHabit(String habitId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kebiasaan?'),
        content: const Text('Apakah Anda yakin ingin menghapus kebiasaan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<HabitTrackerProvider>().deleteHabit(habitId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

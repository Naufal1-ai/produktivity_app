import 'package:flutter/material.dart';
import 'package:productivity/core/theme/app_theme.dart';
import 'package:productivity/data/models/lending_model.dart';
import 'package:productivity/data/repositories/lending_repository.dart';
import 'package:productivity/presentation/widgets/glass_container.dart';
import 'package:productivity/presentation/widgets/lending_form_sheet.dart';
import 'package:productivity/presentation/widgets/grid_background.dart';

class LendingScreen extends StatefulWidget {
  const LendingScreen({super.key});

  @override
  State<LendingScreen> createState() => _LendingScreenState();
}

class _LendingScreenState extends State<LendingScreen> {
  final _repo = LendingRepository();
  late final Stream<List<LendingModel>> _lendingStream;

  @override
  void initState() {
    super.initState();
    _lendingStream = _repo.watchAll();
  }

  void _openForm([LendingModel? item]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LendingFormSheet(existing: item),
    );
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
                        Icons.inventory_2_outlined,
                        color: AppColors.blueAccent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Barang Dipinjam',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _openForm(),
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

              // ✅ List konten
              Expanded(
                child: StreamBuilder<List<LendingModel>>(
                  stream: _lendingStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('⚠️', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text(
                              'Terjadi kesalahan saat memuat data',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 15),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              style: const TextStyle(
                                  color: AppColors.expense, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    final items = snapshot.data ?? [];

                    if (items.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('📦', style: TextStyle(fontSize: 64)),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada barang yang dipinjam',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isOverdue = !item.isReturned &&
                            item.targetReturnDate.isBefore(DateTime.now());

                        return GlassContainer(
                          borderRadius: 16,
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Checkbox(
                                value: item.isReturned,
                                activeColor: AppColors.greenSuccess,
                                onChanged: (val) {
                                  _repo.toggleStatus(item.id, item.isReturned);
                                },
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.itemName,
                                      style: TextStyle(
                                        color: item.isReturned
                                            ? AppColors.textMuted
                                            : AppColors.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        decoration: item.isReturned
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Dipinjam oleh: ${item.borrowerName} • ${item.category}',
                                      style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: isOverdue
                                              ? AppColors.expense
                                              : AppColors.textMuted,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Tenggat: ${item.targetReturnDate.day}/${item.targetReturnDate.month}/${item.targetReturnDate.year}',
                                          style: TextStyle(
                                            color: isOverdue
                                                ? AppColors.expense
                                                : AppColors.textMuted,
                                            fontSize: 12,
                                            fontWeight: isOverdue
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton(
                                icon: Icon(Icons.more_vert,
                                    color: AppColors.textMuted),
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                      value: 'edit', child: Text('Edit')),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Hapus',
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                                onSelected: (val) {
                                  if (val == 'edit') {
                                    _openForm(item);
                                  } else if (val == 'delete') {
                                    _showDeleteConfirmation(item);
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
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
          backgroundColor: AppColors.blueAccent,
          onPressed: () => _openForm(),
          child:
              const Icon(Icons.add, color: Color.fromARGB(255, 255, 255, 255)),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(LendingModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            AppColors.isDark ? const Color(0xFF1A1D27) : Colors.white,
        title: Text(
          'Hapus Barang?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Yakin ingin menghapus "${item.itemName}"?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Batal', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _repo.delete(item.id);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

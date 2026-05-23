import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
          // ✅ bottom: false agar konten bisa masuk ke bawah
          // dan nav bar glass terlihat mengambang
          bottom: false,
          child: StreamBuilder<List<LendingModel>>(
            stream: _lendingStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                      color: AppColors.blueAccent, strokeWidth: 2),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('⚠️', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text('Terjadi kesalahan saat memuat data',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 15)),
                    ],
                  ),
                );
              }

              final items = snapshot.data ?? [];
              final activeItems = items.where((i) => !i.isReturned).toList();
              final overdueItems = items
                  .where((i) =>
                      !i.isReturned &&
                      i.targetReturnDate.isBefore(DateTime.now()))
                  .toList();
              final returnedItems =
                  items.where((i) => i.isReturned).toList();

              return CustomScrollView(
                slivers: [
                  // ── Header ────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.blueAccent.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.inventory_2_outlined,
                                color: AppColors.blueAccent, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Barang Dipinjam',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Catat & pantau barang pinjaman',
                                  style: TextStyle(
                                      color: AppColors.textMuted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Stat Cards ──────────────────────────────────────
                  if (items.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                label: 'Aktif',
                                value: '${activeItems.length}',
                                icon: Icons.hourglass_empty_rounded,
                                color: AppColors.blueAccent,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatCard(
                                label: 'Terlambat',
                                value: '${overdueItems.length}',
                                icon: Icons.warning_amber_rounded,
                                color: overdueItems.isEmpty
                                    ? AppColors.greenSuccess
                                    : AppColors.expense,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatCard(
                                label: 'Selesai',
                                value: '${returnedItems.length}',
                                icon: Icons.check_circle_outline_rounded,
                                color: AppColors.greenSuccess,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ── Empty State ───────────────────────────────────
                  if (items.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: AppColors.blueAccent
                                    .withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.inventory_2_outlined,
                                  size: 52, color: AppColors.textDim),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Belum ada barang dipinjam',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap tombol + untuk menambah catatan',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    // ── Item List ────────────────────────────────────
                    SliverPadding(
                      // ✅ padding bawah 120 agar konten tidak tertutup nav bar
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = items[index];
                            final isOverdue = !item.isReturned &&
                                item.targetReturnDate
                                    .isBefore(DateTime.now());

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GlassContainer(
                                borderRadius: 20,
                                padding: EdgeInsets.zero,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Column(
                                    children: [
                                      if (isOverdue)
                                        Container(
                                            height: 3,
                                            color: AppColors.expense),
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Custom checkbox
                                            GestureDetector(
                                              onTap: () =>
                                                  _repo.toggleStatus(
                                                      item.id,
                                                      item.isReturned),
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                    milliseconds: 200),
                                                width: 26,
                                                height: 26,
                                                margin: const EdgeInsets.only(
                                                    right: 12, top: 2),
                                                decoration: BoxDecoration(
                                                  color: item.isReturned
                                                      ? AppColors.greenSuccess
                                                      : Colors.transparent,
                                                  border: Border.all(
                                                    color: item.isReturned
                                                        ? AppColors
                                                            .greenSuccess
                                                        : AppColors
                                                            .borderAccent,
                                                    width: 2,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(7),
                                                ),
                                                child: item.isReturned
                                                    ? const Icon(
                                                        Icons.check_rounded,
                                                        color: Colors.white,
                                                        size: 15)
                                                    : null,
                                              ),
                                            ),

                                            // Content
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          item.itemName,
                                                          style: TextStyle(
                                                            color: item
                                                                    .isReturned
                                                                ? AppColors
                                                                    .textMuted
                                                                : AppColors
                                                                    .textPrimary,
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            decoration: item
                                                                    .isReturned
                                                                ? TextDecoration
                                                                    .lineThrough
                                                                : null,
                                                          ),
                                                        ),
                                                      ),
                                                      if (item.isReturned)
                                                        const _Badge(
                                                            'Dikembalikan',
                                                            AppColors
                                                                .greenSuccess)
                                                      else if (isOverdue)
                                                        const _Badge('Terlambat',
                                                            AppColors.expense),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                          Icons
                                                              .person_outline_rounded,
                                                          size: 13,
                                                          color: AppColors
                                                              .textMuted),
                                                      const SizedBox(width: 4),
                                                      Text(item.borrowerName,
                                                          style: TextStyle(
                                                              color: AppColors
                                                                  .textSecondary,
                                                              fontSize: 13)),
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding: const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 6,
                                                            vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: AppColors
                                                              .borderAccent
                                                              .withValues(
                                                                  alpha: 0.6),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(5),
                                                        ),
                                                        child: Text(
                                                            item.category,
                                                            style: TextStyle(
                                                                color: AppColors
                                                                    .textMuted,
                                                                fontSize: 11)),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        isOverdue
                                                            ? Icons
                                                                .warning_amber_rounded
                                                            : Icons
                                                                .calendar_today_outlined,
                                                        size: 13,
                                                        color: isOverdue
                                                            ? AppColors.expense
                                                            : AppColors
                                                                .textMuted,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Tenggat: ${DateFormat('dd MMM yyyy').format(item.targetReturnDate)}',
                                                        style: TextStyle(
                                                          color: isOverdue
                                                              ? AppColors
                                                                  .expense
                                                              : AppColors
                                                                  .textMuted,
                                                          fontSize: 12,
                                                          fontWeight: isOverdue
                                                              ? FontWeight.bold
                                                              : FontWeight
                                                                  .normal,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  if (item.imageUrl != null && item.imageUrl!.isNotEmpty) ...[
                                                    const SizedBox(height: 10),
                                                    GestureDetector(
                                                      onTap: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (ctx) => Dialog(
                                                            backgroundColor: Colors.transparent,
                                                            insetPadding: const EdgeInsets.all(16),
                                                            child: Column(
                                                              mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                Align(
                                                                  alignment: Alignment.topRight,
                                                                  child: IconButton(
                                                                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                                                                    onPressed: () => Navigator.pop(ctx),
                                                                  ),
                                                                ),
                                                                ClipRRect(
                                                                  borderRadius: BorderRadius.circular(16),
                                                                  child: item.imageUrl!.startsWith('data:image/')
                                                                      ? Image.memory(
                                                                          base64Decode(item.imageUrl!.split(',').last),
                                                                          fit: BoxFit.contain,
                                                                        )
                                                                      : Image.network(
                                                                          item.imageUrl!,
                                                                          fit: BoxFit.contain,
                                                                        ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                      child: Hero(
                                                        tag: 'lending_img_${item.id}',
                                                        child: Container(
                                                          height: 120,
                                                          width: double.infinity,
                                                          decoration: BoxDecoration(
                                                            borderRadius: BorderRadius.circular(14),
                                                            border: Border.all(color: AppColors.borderAccent),
                                                          ),
                                                          child: ClipRRect(
                                                            borderRadius: BorderRadius.circular(14),
                                                            child: item.imageUrl!.startsWith('data:image/')
                                                                ? Image.memory(
                                                                    base64Decode(item.imageUrl!.split(',').last),
                                                                    fit: BoxFit.cover,
                                                                    width: double.infinity,
                                                                    height: 120,
                                                                  )
                                                                : Image.network(
                                                                    item.imageUrl!,
                                                                    fit: BoxFit.cover,
                                                                    width: double.infinity,
                                                                    height: 120,
                                                                    errorBuilder: (context, error, stackTrace) => Container(
                                                                      color: AppColors.bgCard,
                                                                      child: Icon(Icons.broken_image_outlined, color: AppColors.textMuted),
                                                                    ),
                                                                  ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),

                                            // Menu
                                            PopupMenuButton(
                                              icon: Icon(Icons.more_vert,
                                                  color: AppColors.textMuted,
                                                  size: 20),
                                              color: AppColors.bgCard,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          14)),
                                              itemBuilder: (ctx) => [
                                                PopupMenuItem(
                                                  value: 'edit',
                                                  child: Row(children: [
                                                    Icon(Icons.edit_outlined,
                                                        size: 16,
                                                        color: AppColors
                                                            .blueAccent),
                                                    const SizedBox(width: 8),
                                                    Text('Edit',
                                                        style: TextStyle(
                                                            color: AppColors
                                                                .textPrimary)),
                                                  ]),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'delete',
                                                  child: Row(children: [
                                                    Icon(
                                                        Icons
                                                            .delete_outline_rounded,
                                                        size: 16,
                                                        color:
                                                            AppColors.expense),
                                                    SizedBox(width: 8),
                                                    Text('Hapus',
                                                        style: TextStyle(
                                                            color: AppColors
                                                                .expense)),
                                                  ]),
                                                ),
                                              ],
                                              onSelected: (val) {
                                                if (val == 'edit') {
                                                  _openForm(item);
                                                } else {
                                                  _showDeleteConfirmation(
                                                      item);
                                                }
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
                          },
                          childCount: items.length,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: FloatingActionButton(
          onPressed: () => _openForm(),
          backgroundColor: AppColors.blueAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const CircleBorder(
              side: BorderSide(color: Colors.transparent)),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(LendingModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hapus Barang?',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold)),
        content: Text(
          'Yakin ingin menghapus "${item.itemName}"?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Batal',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _repo.delete(item.id);
            },
            child: const Text('Hapus',
                style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style:
                  TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

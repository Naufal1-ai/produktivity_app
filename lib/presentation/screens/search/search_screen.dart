import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:productivity/core/theme/app_theme.dart';
import 'package:productivity/core/utils/currency_utils.dart';
import 'package:productivity/data/models/transaction_model.dart';
import 'package:productivity/data/repositories/transaction_repository.dart';
import 'package:productivity/presentation/widgets/common_widgets.dart';
import 'package:productivity/presentation/widgets/glass_container.dart';
import 'package:productivity/presentation/widgets/transaction_form_sheet.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _repo = TransactionRepository();
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _filterType; // null = semua, 'pemasukan', 'pengeluaran'
  String? _filterCategory;
  late final Stream<List<TransactionModel>> _transactionStream;

  @override
  void initState() {
    super.initState();
    _transactionStream = _repo.watchAll();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<TransactionModel> _applyFilter(List<TransactionModel> all) {
    var result = all;

    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      result = result.where((t) {
        return t.category.toLowerCase().contains(q) ||
            t.note.toLowerCase().contains(q) ||
            CurrencyUtils.format(t.amount).contains(q);
      }).toList();
    }

    if (_filterType != null) {
      result = result.where((t) => t.type == _filterType).toList();
    }

    if (_filterCategory != null) {
      result = result.where((t) => t.category == _filterCategory).toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    // Karena dipanggil di dalam FinanceScreen yang sudah punya GridBackground,
    // kita hilangkan Scaffold agar background tembus.
    return Column(
      children: [
        // ── Search Bar ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: GlassContainer(
            borderRadius: 20,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: TextField(
              controller: _searchCtrl,
              autofocus: false,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Cari catatan, kategori, atau jumlah...',
                hintStyle: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
                prefixIcon: Icon(Icons.search_rounded,
                    color: AppColors.blueAccent, size: 22),
                suffixIcon: _query.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                        child: Container(
                          margin: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.borderAccent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close_rounded,
                              color: AppColors.textPrimary, size: 14),
                        ),
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        ),

        // ── Filter Chips ──────────────────────────────────────────────────────
        SizedBox(
          height: 40,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: [
              _FilterChip(
                label: 'Semua',
                selected: _filterType == null && _filterCategory == null,
                onTap: () => setState(() {
                  _filterType = null;
                  _filterCategory = null;
                }),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: '📈 Pemasukan',
                selected: _filterType == 'pemasukan',
                color: AppColors.income,
                onTap: () => setState(() {
                  _filterType = _filterType == 'pemasukan' ? null : 'pemasukan';
                  _filterCategory = null;
                }),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: '📉 Pengeluaran',
                selected: _filterType == 'pengeluaran',
                color: AppColors.expense,
                onTap: () => setState(() {
                  _filterType =
                      _filterType == 'pengeluaran' ? null : 'pengeluaran';
                  _filterCategory = null;
                }),
              ),
              const SizedBox(width: 8),
              ...kTransactionCategories.map((cat) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: cat,
                      selected: _filterCategory == cat,
                      onTap: () => setState(() {
                        _filterCategory = _filterCategory == cat ? null : cat;
                        _filterType = null;
                      }),
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Results ───────────────────────────────────────────────────────────
        Expanded(
          child: StreamBuilder<List<TransactionModel>>(
            stream: _transactionStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                      color: AppColors.blueAccent, strokeWidth: 2),
                );
              }

              final all = snapshot.data ?? [];
              final filtered = _applyFilter(all);

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.blueAccent.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.search_off_rounded,
                            size: 48, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _query.isEmpty && _filterType == null
                            ? 'Belum ada transaksi'
                            : 'Tidak ada hasil ditemukan',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      if (_query.isNotEmpty || _filterType != null)
                        Text(
                          'Coba ubah kata kunci atau hapus filter pencarian',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 13),
                        ),
                    ],
                  ),
                );
              }

              // Group by month
              final Map<String, List<TransactionModel>> grouped = {};
              for (final tx in filtered) {
                final key = DateFormat('MMMM yyyy', 'id_ID').format(tx.date);
                grouped.putIfAbsent(key, () => []).add(tx);
              }

              return Column(
                children: [
                  // Result summary
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.borderAccent.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${filtered.length} hasil',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Total: ',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 12),
                        ),
                        Text(
                          CurrencyUtils.formatCompact(filtered.fold(
                              0.0,
                              (s, t) =>
                                  s + (t.isIncome ? t.amount : -t.amount))),
                          style: TextStyle(
                            color: filtered.fold(
                                        0.0,
                                        (s, t) =>
                                            s +
                                            (t.isIncome
                                                ? t.amount
                                                : -t.amount)) >=
                                    0
                                ? AppColors.income
                                : AppColors.expense,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.white,
                          ],
                          stops: [0.0, 0.05],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                        children: grouped.entries.map((entry) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionLabel(entry.key),
                              ...entry.value.map(
                                (tx) => TransactionTile(
                                  tx: tx,
                                  onEdit: () => showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) =>
                                        TransactionFormSheet(existing: tx),
                                  ),
                                  onDelete: () => _repo.delete(tx.id),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.blueAccent;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? c.withValues(alpha: 0.15) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c.withValues(alpha: 0.6) : AppColors.borderAccent,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? c : AppColors.textMuted,
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

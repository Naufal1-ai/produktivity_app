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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header + search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: GlassContainer(
                borderRadius: 24,
                color: AppColors.isDark
                    ? null
                    : const Color.fromARGB(255, 255, 255, 255)
                        .withValues(alpha: 0.8),
                border: Border.all(
                    color: AppColors.blueAccent.withValues(alpha: 0.12)),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CARI',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(letterSpacing: 1.4)),
                    const SizedBox(height: 2),
                    Text('🔍 Pencarian Transaksi',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchCtrl,
                      autofocus: false,
                      style:
                          TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Cari kategori, catatan, atau jumlah...',
                        prefixIcon: Icon(Icons.search,
                            color: AppColors.textMuted, size: 20),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close,
                                    color: AppColors.textMuted, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _query = '');
                                },
                              )
                            : null,
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ],
                ),
              ),
            ),

            // Filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GlassContainer(
                borderRadius: 20,
                color: AppColors.isDark
                    ? null
                    : Colors.white.withValues(alpha: 0.72),
                border: Border.all(
                    color: AppColors.blueAccent.withValues(alpha: 0.12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: SizedBox(
                  height: 38,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(
                        label: 'Semua',
                        selected:
                            _filterType == null && _filterCategory == null,
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
                          _filterType =
                              _filterType == 'pemasukan' ? null : 'pemasukan';
                          _filterCategory = null;
                        }),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: '📉 Pengeluaran',
                        selected: _filterType == 'pengeluaran',
                        color: AppColors.expense,
                        onTap: () => setState(() {
                          _filterType = _filterType == 'pengeluaran'
                              ? null
                              : 'pengeluaran';
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
                                _filterCategory =
                                    _filterCategory == cat ? null : cat;
                                _filterType = null;
                              }),
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Results
            Expanded(
              child: StreamBuilder<List<TransactionModel>>(
                stream: _repo.watchAll(),
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔍', style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 12),
                          Text(
                            _query.isEmpty && _filterType == null
                                ? 'Belum ada transaksi'
                                : 'Tidak ada hasil untuk\n"${_query.isNotEmpty ? _query : (_filterType ?? _filterCategory ?? '')}"',
                            textAlign: TextAlign.center,
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
                    final key =
                        DateFormat('MMMM yyyy', 'id_ID').format(tx.date);
                    grouped.putIfAbsent(key, () => []).add(tx);
                  }

                  return Column(
                    children: [
                      // Result count
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Row(
                          children: [
                            Text(
                              '${filtered.length} transaksi ditemukan',
                              style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                  letterSpacing: 0.5),
                            ),
                            const Spacer(),
                            Text(
                              'Total: ${CurrencyUtils.formatCompact(filtered.fold(0.0, (s, t) => s + (t.isIncome ? t.amount : -t.amount)))}',
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
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
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
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
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
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.withValues(alpha: 0.12) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c.withValues(alpha: 0.5) : AppColors.borderAccent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? c : AppColors.textMuted,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

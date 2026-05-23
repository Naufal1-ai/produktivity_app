import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:productivity/core/theme/app_theme.dart';
import 'package:productivity/core/utils/currency_utils.dart';
import 'package:productivity/data/models/budget_model.dart';
import 'package:productivity/data/models/transaction_model.dart';
import 'package:productivity/data/repositories/budget_repository.dart';
import 'package:productivity/data/repositories/transaction_repository.dart';
import 'package:productivity/presentation/widgets/common_widgets.dart';
import 'package:productivity/presentation/widgets/glass_container.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _budgetRepo = BudgetRepository();
  final _txRepo = TransactionRepository();
  DateTime _selectedMonth = DateTime.now();
  late Stream<List<BudgetModel>> _budgetStream;
  late Stream<List<TransactionModel>> _txStream;

  @override
  void initState() {
    super.initState();
    _budgetStream = _budgetRepo.watchByMonth(_selectedMonth);
    _txStream = _txRepo.watchByMonth(_selectedMonth);
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Hapus Scaffold & SafeArea — sudah ditangani FinanceScreen
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ANGGARAN',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(letterSpacing: 1.4)),
              GestureDetector(
                onTap: _pickMonth,
                child: GlassContainer(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  borderRadius: 18,
                  color:
                      AppColors.isDark ? null : Colors.white.withValues(alpha: 0.75),
                  border:
                      Border.all(color: AppColors.blueAccent.withValues(alpha: 0.15)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_month_outlined,
                          size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        DateUtils2.formatMonth(_selectedMonth),
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            'Tap kategori untuk set anggaran. Swipe kiri untuk hapus.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),

        // Content
        Expanded(
          child: StreamBuilder<List<BudgetModel>>(
            stream: _budgetStream,
            builder: (context, budgetSnap) {
              return StreamBuilder<List<TransactionModel>>(
                stream: _txStream,
                builder: (context, txSnap) {
                  final budgets = budgetSnap.data ?? [];
                  final txList = txSnap.data ?? [];

                  final Map<String, double> spent = {};
                  for (final tx in txList.where((t) => !t.isIncome)) {
                    spent[tx.category] = (spent[tx.category] ?? 0) + tx.amount;
                  }

                  final budgetedCats = budgets.map((b) => b.category).toSet();

                  final unbudgetedCats = spent.keys
                      .where((c) => !budgetedCats.contains(c))
                      .toList()
                    ..sort();

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    children: [
                      if (budgets.isNotEmpty) ...[
                        const SectionLabel('Anggaran Aktif'),
                        ...budgets.map((b) {
                          final s = spent[b.category] ?? 0;
                          return _BudgetTile(
                            budget: b,
                            spent: s,
                            onTap: () =>
                                _openBudgetForm(b.category, existing: b),
                            onDelete: () => _budgetRepo.delete(b.id),
                          );
                        }),
                      ],
                      if (unbudgetedCats.isNotEmpty) ...[
                        const SectionLabel('Pengeluaran Tanpa Anggaran'),
                        ...unbudgetedCats.map((cat) {
                          return _UnbudgetedTile(
                            category: cat,
                            spent: spent[cat]!,
                            onTap: () => _openBudgetForm(cat),
                          );
                        }),
                      ],
                      const SectionLabel('Tambah Anggaran Kategori'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: kTransactionCategories.map((cat) {
                          final hasBudget = budgetedCats.contains(cat);
                          return GestureDetector(
                            onTap:
                                hasBudget ? null : () => _openBudgetForm(cat),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: hasBudget
                                    ? AppColors.blueDark
                                    : AppColors.bgCard,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: hasBudget
                                      ? AppColors.blueBorder
                                      : AppColors.borderAccent,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (hasBudget) ...[
                                    Icon(Icons.check,
                                        size: 12, color: AppColors.blueAccent),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    cat,
                                    style: TextStyle(
                                      color: hasBudget
                                          ? AppColors.blueAccent
                                          : AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openBudgetForm(String category, {BudgetModel? existing}) async {
    final ctrl = TextEditingController(
        text: existing != null ? existing.limit.toInt().toString() : '');
    bool loading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) => Container(
          decoration: BoxDecoration(
            color: AppColors.bgCardAlt,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.borderAccent,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                existing != null
                    ? 'Edit Anggaran · $category'
                    : 'Set Anggaran · $category',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth),
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Batas Anggaran',
                  prefixText: 'Rp ',
                  prefixStyle: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          if (ctrl.text.isEmpty) return;
                          setBS(() => loading = true);
                          await _budgetRepo.upsert(BudgetModel(
                            id: existing?.id ?? '',
                            category: category,
                            limit: double.parse(ctrl.text),
                            month: _selectedMonth.month,
                            year: _selectedMonth.year,
                          ));
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                  child: loading
                      ? SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.blueText),
                        )
                      : Text(existing != null
                          ? 'Simpan Perubahan'
                          : 'Set Anggaran'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final months = List.generate(12, (i) => DateTime(now.year, now.month - i));
    await showModalBottomSheet(
      context: context,
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
                borderRadius: BorderRadius.circular(2)),
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
                        setState(() {
                          _selectedMonth = m;
                          _budgetStream = _budgetRepo.watchByMonth(m);
                          _txStream = _txRepo.watchByMonth(m);
                        });
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

// ─── Budget Tile ──────────────────────────────────────────────────────────────
class _BudgetTile extends StatelessWidget {
  final BudgetModel budget;
  final double spent;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BudgetTile({
    required this.budget,
    required this.spent,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final pct = budget.limit > 0 ? (spent / budget.limit).clamp(0.0, 1.0) : 0.0;
    final isOver = spent > budget.limit;
    final remaining = budget.limit - spent;
    final barColor = pct >= 1.0
        ? AppColors.expense
        : pct >= 0.8
            ? const Color(0xFFFBBF24)
            : AppColors.income;

    return Dismissible(
      key: Key('budget_${budget.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.expense.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.expense),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.bgCard,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Hapus anggaran?',
                style: TextStyle(color: AppColors.textPrimary)),
            content: Text(budget.category,
                style: TextStyle(color: AppColors.textSecondary)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child:
                    Text('Batal', style: TextStyle(color: AppColors.textMuted)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Hapus',
                    style: TextStyle(color: AppColors.expense)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: GlassContainer(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          borderRadius: 18,
          color: AppColors.isDark ? null : Colors.white.withValues(alpha: 0.72),
          border: Border.all(
            color: isOver
                ? AppColors.expense.withValues(alpha: 0.4)
                : AppColors.border,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(budget.category,
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  if (isOver)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.expense.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.expense.withValues(alpha: 0.3)),
                      ),
                      child: const Text('Melebihi!',
                          style: TextStyle(
                              color: AppColors.expense, fontSize: 10)),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${CurrencyUtils.formatCompact(spent)} / ${CurrencyUtils.formatCompact(budget.limit)}',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  Text(
                    isOver
                        ? 'Lebih ${CurrencyUtils.formatCompact(-remaining)}'
                        : 'Sisa ${CurrencyUtils.formatCompact(remaining)}',
                    style: TextStyle(
                      color: isOver ? AppColors.expense : AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Unbudgeted Tile ──────────────────────────────────────────────────────────
class _UnbudgetedTile extends StatelessWidget {
  final String category;
  final double spent;
  final VoidCallback onTap;

  const _UnbudgetedTile({
    required this.category,
    required this.spent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: 18,
        color: AppColors.isDark ? null : Colors.white.withValues(alpha: 0.72),
        border:
            Border.all(color: AppColors.borderAccent, style: BorderStyle.solid),
        child: Row(
          children: [
            Icon(Icons.add_circle_outline, color: AppColors.textDim, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(category,
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(CurrencyUtils.formatCompact(spent),
                    style: const TextStyle(
                        color: AppColors.expense,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                Text('Tap untuk set budget',
                    style: TextStyle(color: AppColors.textDim, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

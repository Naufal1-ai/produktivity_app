import 'package:flutter/material.dart';
import 'package:productivity/core/theme/app_theme.dart';
import 'package:productivity/core/utils/currency_utils.dart';
import 'package:productivity/data/models/transaction_model.dart';

// ─── Balance Card ────────────────────────────────────────────────────────────

class BalanceCard extends StatelessWidget {
  final double balance;
  final double totalIncome;
  final double totalExpense;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.totalIncome,
    required this.totalExpense,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.blueMid,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.blueBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SALDO SAAT INI',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.blueMuted,
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyUtils.format(balance),
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color:
                      balance >= 0 ? AppColors.textPrimary : AppColors.expense,
                  fontSize: 32,
                  letterSpacing: -1,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Diperbarui baru saja',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.blueMuted.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatChip(
                label: 'PEMASUKAN',
                value: CurrencyUtils.formatCompact(totalIncome),
                color: AppColors.income,
              ),
              const SizedBox(width: 10),
              _StatChip(
                label: 'PENGELUARAN',
                value: CurrencyUtils.formatCompact(totalExpense),
                color: AppColors.expense,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.isDark
              ? Colors.black.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: AppColors.textDim,
                    fontSize: 10,
                    letterSpacing: 0.8)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ─── Transaction Tile ────────────────────────────────────────────────────────

class TransactionTile extends StatelessWidget {
  final TransactionModel tx;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TransactionTile({
    super.key,
    required this.tx,
    required this.onEdit,
    required this.onDelete,
  });

  String get _emoji {
    const map = {
      'Gaji': '💰',
      'Freelance': '💻',
      'Investasi': '📈',
      'Bonus': '🎁',
      'Makan & Minum': '🍜',
      'Transport': '🚗',
      'Belanja': '🛒',
      'Tagihan': '📄',
      'Kesehatan': '🏥',
      'Hiburan': '🎬',
      'Pendidikan': '📚',
      'Bensin': '⛽',
    };
    return map[tx.category] ?? (tx.isIncome ? '💰' : '💸');
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(tx.id),
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
            title: Text('Hapus transaksi?',
                style: TextStyle(color: AppColors.textPrimary)),
            content: Text(tx.category,
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
        onTap: onEdit,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: tx.isIncome
                      ? (AppColors.isDark ? AppColors.blueDark : AppColors.blueAccent.withValues(alpha: 0.12))
                      : (AppColors.isDark ? const Color(0xFF1F0E0E) : AppColors.expense.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                    child: Text(_emoji, style: const TextStyle(fontSize: 18))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.category,
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(
                      tx.note.isEmpty
                          ? DateUtils2.formatDisplay(tx.date)
                          : '${tx.note} · ${DateUtils2.formatDisplay(tx.date)}',
                      style: TextStyle(color: AppColors.textDim, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                CurrencyUtils.formatSigned(tx.amount, tx.type),
                style: TextStyle(
                  color: tx.isIncome ? AppColors.income : AppColors.expense,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section Label ───────────────────────────────────────────────────────────

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
            color: AppColors.textMuted, fontSize: 11, letterSpacing: 1.0),
      ),
    );
  }
}

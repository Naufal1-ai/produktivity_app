import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:productivity/core/theme/app_theme.dart';
import 'package:productivity/core/utils/currency_utils.dart';
import 'package:productivity/data/models/transaction_model.dart';
import 'package:productivity/data/repositories/transaction_repository.dart';

class TransactionFormSheet extends StatefulWidget {
  final TransactionModel? existing; // null = add new

  const TransactionFormSheet({super.key, this.existing});

  @override
  State<TransactionFormSheet> createState() => _TransactionFormSheetState();
}

class _TransactionFormSheetState extends State<TransactionFormSheet> {
  final _repo = TransactionRepository();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String _type = 'pengeluaran';
  String? _category;
  DateTime _date = DateTime.now();
  bool _loading = false;

  bool get _isEditing => widget.existing != null;
  List<String> get _categories => kTransactionCategories;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final tx = widget.existing!;
      _type = tx.type;
      _category = tx.category;
      _amountCtrl.text = tx.amount.toInt().toString();
      _noteCtrl.text = tx.note;
      _date = tx.date;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_amountCtrl.text.isEmpty || _category == null) return;
    setState(() => _loading = true);
    try {
      final tx = TransactionModel(
        id: widget.existing?.id ?? '',
        amount: double.parse(_amountCtrl.text.replaceAll('.', '')),
        type: _type,
        category: _category!,
        note: _noteCtrl.text.trim(),
        date: _date,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
      );
      if (_isEditing) {
        await _repo.update(tx);
      } else {
        await _repo.add(tx);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.expense),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCardAlt,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderAccent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            _isEditing ? 'Edit Transaksi' : 'Tambah Transaksi',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),

          // Type toggle
          Row(
            children: [
              _TypeButton(
                label: 'Pengeluaran',
                selected: _type == 'pengeluaran',
                color: AppColors.expense,
                onTap: () => setState(() {
                  _type = 'pengeluaran';
                  _category = null;
                }),
              ),
              const SizedBox(width: 10),
              _TypeButton(
                label: 'Pemasukan',
                selected: _type == 'pemasukan',
                color: AppColors.income,
                onTap: () => setState(() {
                  _type = 'pemasukan';
                  _category = null;
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Amount
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Jumlah',
              prefixText: 'Rp ',
              prefixStyle: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 12),

          // Category dropdown
          DropdownButtonFormField<String>(
            value: _categories.contains(_category) ? _category : null,
            dropdownColor: AppColors.bgCard,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(labelText: 'Kategori'),
            items: _categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v),
          ),
          const SizedBox(height: 12),

          // Note
          TextField(
            controller: _noteCtrl,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
          ),
          const SizedBox(height: 12),

          // Date picker
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                builder: (ctx, child) => Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: ColorScheme.dark(
                      primary: AppColors.blueAccent,
                      surface: AppColors.bgCard,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) setState(() => _date = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderAccent),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      color: AppColors.textMuted, size: 16),
                  const SizedBox(width: 10),
                  Text(DateUtils2.formatDisplay(_date),
                      style: TextStyle(
                          color: AppColors.textPrimary, fontSize: 14)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.blueText),
                    )
                  : Text(_isEditing ? 'Simpan Perubahan' : 'Tambah Transaksi'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.15) : AppColors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.5)
                  : AppColors.borderAccent,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? color : AppColors.textMuted,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

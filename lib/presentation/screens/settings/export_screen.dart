import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:productivity/core/theme/app_theme.dart';
import 'package:productivity/presentation/widgets/glass_container.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:productivity/data/models/transaction_model.dart';
import 'package:productivity/data/repositories/transaction_repository.dart';
import 'package:intl/intl.dart';

class ExportScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const ExportScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final TransactionRepository _repo = TransactionRepository();
  bool _isExporting = false;
  List<TransactionModel> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final transactions = await _repo.getAll();
    setState(() => _transactions = transactions);
  }

  Future<String> _getExportDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${directory.path}/exports');

    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    return exportDir.path;
  }

  Future<void> _exportToCSV() async {
    if (_transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.noData),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      final exportPath = await _getExportDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'transactions_$timestamp.csv';
      final filePath = '$exportPath/$fileName';

      // Prepare CSV data
      final csvData = [
        ['Tanggal', 'Jenis', 'Kategori', 'Jumlah', 'Catatan'], // Header
        ..._transactions.map((tx) => [
              DateFormat('dd/MM/yyyy HH:mm').format(tx.date),
              tx.isIncome ? 'Pemasukan' : 'Pengeluaran',
              tx.category,
              tx.amount.toString(),
              tx.note ?? '',
            ]),
      ];

      final csvString = const ListToCsvConverter().convert(csvData);
      final file = File(filePath);
      await file.writeAsString(csvString);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context)!.exportSuccess}: $fileName',
          ),
          backgroundColor: AppColors.income,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${AppLocalizations.of(context)!.exportFailed}: ${e.toString()}'),
          backgroundColor: AppColors.expense,
        ),
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportToPDF() async {
    if (_transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.noData),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      final exportPath = await _getExportDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'transactions_$timestamp.pdf';
      final filePath = '$exportPath/$fileName';

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text('Laporan Transaksi Keuangan',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                  'Dibuat pada: ${DateFormat('dd MMMM yyyy HH:mm').format(DateTime.now())}'),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Tanggal', 'Jenis', 'Kategori', 'Jumlah', 'Catatan'],
                data: _transactions
                    .map((tx) => [
                          DateFormat('dd/MM/yyyy HH:mm').format(tx.date),
                          tx.isIncome ? 'Pemasukan' : 'Pengeluaran',
                          tx.category,
                          'Rp ${tx.amount.toStringAsFixed(0)}',
                          tx.note ?? '',
                        ])
                    .toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerLeft,
              ),
              pw.SizedBox(height: 20),
              pw.Text('Total Transaksi: ${_transactions.length}'),
              pw.Text(
                  'Total Pemasukan: Rp ${_calculateTotal(true).toStringAsFixed(0)}'),
              pw.Text(
                  'Total Pengeluaran: Rp ${_calculateTotal(false).toStringAsFixed(0)}'),
            ];
          },
        ),
      );

      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context)!.exportSuccess}: $fileName',
          ),
          backgroundColor: AppColors.income,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${AppLocalizations.of(context)!.exportFailed}: ${e.toString()}'),
          backgroundColor: AppColors.expense,
        ),
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  double _calculateTotal(bool isIncome) {
    return _transactions
        .where((tx) => tx.isIncome == isIncome)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.exportData),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Section
              GlassContainer(
                borderRadius: 16,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.blueAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.download,
                            color: AppColors.blueAccent,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.exportData,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Export data transaksi Anda dalam format CSV atau PDF',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stats Section
              GlassContainer(
                borderRadius: 16,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ringkasan Data',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Total Transaksi',
                            value: _transactions.length.toString(),
                            icon: Icons.receipt,
                            color: AppColors.blueAccent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Pemasukan',
                            value:
                                'Rp ${_calculateTotal(true).toStringAsFixed(0)}',
                            icon: Icons.trending_up,
                            color: AppColors.income,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Pengeluaran',
                            value:
                                'Rp ${_calculateTotal(false).toStringAsFixed(0)}',
                            icon: Icons.trending_down,
                            color: AppColors.expense,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Saldo',
                            value:
                                'Rp ${(_calculateTotal(true) - _calculateTotal(false)).toStringAsFixed(0)}',
                            icon: Icons.account_balance_wallet,
                            color: (_calculateTotal(true) -
                                        _calculateTotal(false)) >=
                                    0
                                ? AppColors.income
                                : AppColors.expense,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Export Options
              GlassContainer(
                borderRadius: 16,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih Format Export',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 20),

                    // CSV Export
                    _ExportOption(
                      title: l10n.exportCSV,
                      subtitle:
                          'Format CSV untuk spreadsheet (Excel, Google Sheets)',
                      icon: Icons.table_chart,
                      onTap: _isExporting ? null : _exportToCSV,
                      isLoading: _isExporting,
                    ),
                    const SizedBox(height: 16),

                    // PDF Export
                    _ExportOption(
                      title: l10n.exportPDF,
                      subtitle: 'Format PDF untuk dokumen dan cetak',
                      icon: Icons.picture_as_pdf,
                      onTap: _isExporting ? null : _exportToPDF,
                      isLoading: _isExporting,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Note Section
              GlassContainer(
                borderRadius: 16,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Catatan',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textMuted,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'File akan disimpan di folder Download perangkat Anda. Pastikan memberikan izin akses penyimpanan saat diminta.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
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
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isLoading;

  const _ExportOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderAccent),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppColors.blueAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}

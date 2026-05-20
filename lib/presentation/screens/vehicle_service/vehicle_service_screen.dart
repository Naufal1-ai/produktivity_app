import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:productivity/core/theme/app_theme.dart';
import 'package:productivity/presentation/widgets/grid_background.dart';
import 'package:productivity/presentation/widgets/glass_container.dart';
import 'package:productivity/providers/vehicle_service_provider.dart';
import 'package:productivity/data/models/vehicle_service_model.dart';
import 'package:intl/intl.dart';

class VehicleServiceScreen extends StatefulWidget {
  const VehicleServiceScreen({super.key});

  @override
  State<VehicleServiceScreen> createState() => _VehicleServiceScreenState();
}

class _VehicleServiceScreenState extends State<VehicleServiceScreen> {
  final _currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehicleServiceProvider>().initialize();
    });
  }

  void _showAddEditDialog([VehicleServiceModel? service]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddEditServiceSheet(service: service),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.isDark ? const Color(0xFF0F1117) : AppColors.bg,
      body: GridBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────
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
                        Icons.two_wheeler_rounded,
                        color: AppColors.blueAccent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jadwal Servis',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Riwayat perawatan kendaraan',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Body ──────────────────────────────────────────────────
              Expanded(
                child: Consumer<VehicleServiceProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: AppColors.blueAccent,
                          strokeWidth: 2,
                        ),
                      );
                    }

                    final services = provider.services;

                    if (services.isEmpty) {
                      return _buildEmptyState();
                    }

                    // ── Summary card ────────────────────────────────────
                    final dueCount = services
                        .where((s) =>
                            s.nextServiceDate != null &&
                            s.nextServiceDate!.isBefore(DateTime.now()))
                        .length;
                    final totalCost = services.fold<double>(
                        0.0, (sum, s) => sum + s.cost);

                    return CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    label: 'Total Riwayat',
                                    value: '${services.length} servis',
                                    icon: Icons.history_rounded,
                                    color: AppColors.blueAccent,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StatCard(
                                    label: 'Perlu Servis',
                                    value: '$dueCount kendaraan',
                                    icon: Icons.warning_amber_rounded,
                                    color: dueCount > 0
                                        ? AppColors.expense
                                        : AppColors.greenSuccess,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StatCard(
                                    label: 'Total Biaya',
                                    value: _currencyFormat.format(totalCost),
                                    icon: Icons.payments_outlined,
                                    color: AppColors.purple,
                                    smallText: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final service = services[index];
                                return _ServiceCard(
                                  service: service,
                                  currencyFormat: _currencyFormat,
                                  onEdit: () => _showAddEditDialog(service),
                                  onDelete: () => _confirmDelete(context, provider, service),
                                );
                              },
                              childCount: services.length,
                            ),
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
          onPressed: _showAddEditDialog,
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

  void _confirmDelete(
      BuildContext context, VehicleServiceProvider provider, VehicleServiceModel service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hapus Data',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          'Hapus riwayat "${service.title}"?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              provider.deleteService(service.id);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.blueAccent.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.two_wheeler_rounded,
              size: 56,
              color: AppColors.textDim,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Belum ada riwayat servis.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Klik tombol di bawah untuk menambah data baru.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Stat card ──────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool smallText;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.smallText = false,
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
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: smallText ? 11 : 13,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
        ],
      ),
    );
  }
}

// ── Service card ───────────────────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  final VehicleServiceModel service;
  final NumberFormat currencyFormat;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ServiceCard({
    required this.service,
    required this.currencyFormat,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDue = service.nextServiceDate != null &&
        service.nextServiceDate!.isBefore(DateTime.now());

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        borderRadius: 20,
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top colored accent line if due
              if (isDue)
                Container(
                  height: 3,
                  color: AppColors.expense,
                ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Title row ──────────────────────────────────────
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDue
                                ? AppColors.expense.withValues(alpha: 0.12)
                                : AppColors.blueAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.build_circle_outlined,
                            size: 18,
                            color: isDue ? AppColors.expense : AppColors.blueAccent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.title,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('dd MMM yyyy').format(service.date),
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.expense.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            currencyFormat.format(service.cost),
                            style: const TextStyle(
                              color: AppColors.expense,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ── Info chips ─────────────────────────────────────
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _InfoChip(
                          icon: Icons.speed_rounded,
                          label: '${service.odometer} km',
                        ),
                        if (service.notes.isNotEmpty) ...{
                          const SizedBox(width: 8),
                          Expanded(
                            child: _InfoChip(
                              icon: Icons.notes_rounded,
                              label: service.notes,
                              expand: true,
                            ),
                          ),
                        },
                      ],
                    ),

                    // ── Next service badge ─────────────────────────────
                    if (service.nextServiceDate != null) ...{
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDue
                              ? AppColors.expense.withValues(alpha: 0.10)
                              : AppColors.blueAccent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDue
                                ? AppColors.expense.withValues(alpha: 0.3)
                                : AppColors.blueAccent.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isDue
                                  ? Icons.warning_amber_rounded
                                  : Icons.event_available_rounded,
                              size: 14,
                              color: isDue
                                  ? AppColors.expense
                                  : AppColors.blueAccent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isDue
                                  ? 'Sudah jatuh tempo! ${DateFormat('dd MMM yyyy').format(service.nextServiceDate!)}'
                                  : 'Servis berikutnya: ${DateFormat('dd MMM yyyy').format(service.nextServiceDate!)}',
                              style: TextStyle(
                                color: isDue
                                    ? AppColors.expense
                                    : AppColors.blueAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    },

                    // ── Actions ────────────────────────────────────────
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: onEdit,
                          icon: Icon(Icons.edit_outlined,
                              size: 14, color: AppColors.blueAccent),
                          label: Text('Edit',
                              style: TextStyle(
                                  color: AppColors.blueAccent, fontSize: 13)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                          ),
                        ),
                        const SizedBox(width: 4),
                        TextButton.icon(
                          onPressed: onDelete,
                          icon: Icon(Icons.delete_outline_rounded,
                              size: 14, color: AppColors.expense),
                          label: const Text('Hapus',
                              style: TextStyle(
                                  color: AppColors.expense, fontSize: 13)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                          ),
                        ),
                      ],
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool expand;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.borderAccent.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textMuted),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    return child;
  }
}

// ── Add/Edit bottom sheet ──────────────────────────────────────────────────────

class _AddEditServiceSheet extends StatefulWidget {
  final VehicleServiceModel? service;

  const _AddEditServiceSheet({this.service});

  @override
  State<_AddEditServiceSheet> createState() => _AddEditServiceSheetState();
}

class _AddEditServiceSheetState extends State<_AddEditServiceSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late TextEditingController _costController;
  late TextEditingController _odometerController;
  DateTime _date = DateTime.now();
  DateTime? _nextServiceDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.service?.title ?? 'Ganti Oli');
    _notesController =
        TextEditingController(text: widget.service?.notes ?? '');
    _costController = TextEditingController(
        text: widget.service?.cost.toInt().toString() ?? '');
    _odometerController =
        TextEditingController(text: widget.service?.odometer.toString() ?? '');
    _date = widget.service?.date ?? DateTime.now();
    _nextServiceDate = widget.service?.nextServiceDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _costController.dispose();
    _odometerController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isNext) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isNext
          ? (_nextServiceDate ?? DateTime.now().add(const Duration(days: 60)))
          : _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isNext) {
          _nextServiceDate = picked;
        } else {
          _date = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final provider = context.read<VehicleServiceProvider>();
      final service = VehicleServiceModel(
        id: widget.service?.id ?? '',
        title: _titleController.text.trim(),
        notes: _notesController.text.trim(),
        date: _date,
        cost: double.tryParse(_costController.text) ?? 0.0,
        odometer: int.tryParse(_odometerController.text) ?? 0,
        nextServiceDate: _nextServiceDate,
        createdAt: widget.service?.createdAt ?? DateTime.now(),
      );
      if (widget.service == null) {
        await provider.addService(service);
      } else {
        await provider.updateService(service);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
        top: 24,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
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

              Text(
                widget.service == null
                    ? 'Tambah Jadwal Servis'
                    : 'Edit Jadwal Servis',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Catat riwayat perawatan kendaraan Anda',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _titleController,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Jenis Servis (Oli, CVT, dll)',
                  prefixIcon: Icon(Icons.build_outlined),
                ),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _odometerController,
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Kilometer',
                        prefixIcon: Icon(Icons.speed_outlined),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _costController,
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Biaya (Rp)',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Date picker
              _DatePickerTile(
                label:
                    'Tanggal Servis: ${DateFormat('dd MMM yyyy').format(_date)}',
                icon: Icons.calendar_today_outlined,
                onTap: () => _selectDate(false),
              ),
              const SizedBox(height: 10),

              // Next service date picker
              Row(
                children: [
                  Expanded(
                    child: _DatePickerTile(
                      label: _nextServiceDate == null
                          ? 'Set Jadwal Berikutnya (Opsional)'
                          : 'Berikutnya: ${DateFormat('dd MMM yyyy').format(_nextServiceDate!)}',
                      icon: Icons.event_available_outlined,
                      onTap: () => _selectDate(true),
                      isAccent: _nextServiceDate != null,
                    ),
                  ),
                  if (_nextServiceDate != null) ...{
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.clear, color: AppColors.textMuted),
                      onPressed: () => setState(() => _nextServiceDate = null),
                    ),
                  },
                ],
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _notesController,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Catatan tambahan (Opsional)',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text(
                          'Simpan',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isAccent;

  const _DatePickerTile({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          border: Border.all(color: AppColors.borderAccent),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color:
                    isAccent ? AppColors.blueAccent : AppColors.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isAccent
                      ? AppColors.blueAccent
                      : AppColors.textMuted,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

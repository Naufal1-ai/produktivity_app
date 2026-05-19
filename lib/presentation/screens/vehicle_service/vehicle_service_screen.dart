import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:productivity/core/theme/app_theme.dart';
import 'package:productivity/providers/vehicle_service_provider.dart';
import 'package:productivity/data/models/vehicle_service_model.dart';
import 'package:intl/intl.dart';

class VehicleServiceScreen extends StatefulWidget {
  const VehicleServiceScreen({super.key});

  @override
  State<VehicleServiceScreen> createState() => _VehicleServiceScreenState();
}

class _VehicleServiceScreenState extends State<VehicleServiceScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

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
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Jadwal Servis Motor', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.bg,
        elevation: 0,
      ),
      body: Consumer<VehicleServiceProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final services = provider.services;

          if (services.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              final isDue = service.nextServiceDate != null && 
                            service.nextServiceDate!.isBefore(DateTime.now());
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDue ? Colors.redAccent.withValues(alpha: 0.5) : AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          service.title,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _currencyFormat.format(service.cost),
                          style: TextStyle(
                            color: AppColors.expense,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: AppColors.textDim),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd MMM yyyy').format(service.date),
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.speed, size: 14, color: AppColors.textDim),
                        const SizedBox(width: 4),
                        Text(
                          '${service.odometer} km',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                    if (service.notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        service.notes,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                    if (service.nextServiceDate != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDue ? Colors.redAccent.withValues(alpha: 0.1) : AppColors.blueAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning_amber_rounded, 
                              size: 16, 
                              color: isDue ? Colors.redAccent : AppColors.blueAccent,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Servis Berikutnya: ${DateFormat('dd MMM yyyy').format(service.nextServiceDate!)}',
                              style: TextStyle(
                                color: isDue ? Colors.redAccent : AppColors.blueAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _showAddEditDialog(service),
                          child: Text('Edit', style: TextStyle(color: AppColors.blueAccent)),
                        ),
                        TextButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Hapus Data'),
                                content: const Text('Apakah Anda yakin ingin menghapus data servis ini?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                                  TextButton(
                                    onPressed: () {
                                      provider.deleteService(service.id);
                                      Navigator.pop(ctx);
                                    },
                                    child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Text('Hapus', style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEditDialog,
        backgroundColor: AppColors.blueAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Servis', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.two_wheeler, size: 80, color: AppColors.textDim.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'Belum ada riwayat servis.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Klik tombol di bawah untuk menambah data baru.',
            style: TextStyle(color: AppColors.textDim, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

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
    _titleController = TextEditingController(text: widget.service?.title ?? 'Ganti Oli');
    _notesController = TextEditingController(text: widget.service?.notes ?? '');
    _costController = TextEditingController(
        text: widget.service?.cost.toInt().toString() ?? '');
    _odometerController = TextEditingController(
        text: widget.service?.odometer.toString() ?? '');
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

  Future<void> _selectDate(BuildContext context, bool isNext) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isNext ? (_nextServiceDate ?? DateTime.now().add(const Duration(days: 60))) : _date,
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
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 24,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.service == null ? 'Tambah Jadwal Servis' : 'Edit Jadwal Servis',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Jenis Servis (Oli, CVT, dll)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.build),
                ),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _odometerController,
                      decoration: InputDecoration(
                        labelText: 'Kilometer Saat Ini',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.speed),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _costController,
                      decoration: InputDecoration(
                        labelText: 'Biaya (Rp)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 20),
                            const SizedBox(width: 8),
                            Text('Tanggal: ${DateFormat('dd MMM yyyy').format(_date)}'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.event_available, size: 20, color: AppColors.blueAccent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _nextServiceDate == null
                                    ? 'Set Jadwal Berikutnya (Opsional)'
                                    : 'Berikutnya: ${DateFormat('dd MMM yyyy').format(_nextServiceDate!)}',
                                style: TextStyle(
                                  color: _nextServiceDate == null ? Colors.grey : AppColors.blueAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_nextServiceDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _nextServiceDate = null),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Catatan tambahan (Opsional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.notes),
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Simpan', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

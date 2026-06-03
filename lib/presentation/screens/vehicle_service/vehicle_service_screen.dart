import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:productivity/core/theme/app_theme.dart';
import 'package:productivity/presentation/widgets/grid_background.dart';
import 'package:productivity/presentation/widgets/glass_container.dart';
import 'package:productivity/providers/vehicle_service_provider.dart';
import 'package:productivity/providers/notification_settings_provider.dart';
import 'package:productivity/data/models/vehicle_service_model.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

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

  void _logPartFromCatalog(Map<String, dynamic> item) {
    final parsedPrice = double.tryParse(item['price'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
    final lastOdometer = context.read<VehicleServiceProvider>().services.isNotEmpty
        ? context.read<VehicleServiceProvider>().services.first.odometer
        : 0;

    final part = VehiclePart(
      name: item['name'] as String,
      code: item['code'] as String,
      price: parsedPrice,
      brand: 'AHM',
      imageUrl: item['image'] as String? ?? '',
    );

    final dummyService = VehicleServiceModel(
      id: '',
      title: 'Ganti ${item['name']}',
      notes: 'Pemasangan komponen baru sesuai spesifikasi pabrikan.',
      date: DateTime.now(),
      cost: parsedPrice,
      odometer: lastOdometer,
      createdAt: DateTime.now(),
      parts: [part],
    );

    _showAddEditDialog(dummyService);
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
      backgroundColor: Colors.transparent,
      body: GridBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // —————————————————————————————————————————————— Header ——————————————————————————————————————————————
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
                          'Log Servis',
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

              // —————————————————————————————————————————————— Body ——————————————————————————————————————————————
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
                      // Trigger notification update setiap kali data dimuat
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        context
                            .read<NotificationSettingsProvider>()
                            .updateServiceReminder(services);
                      });
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                        child: Column(
                          children: [
                            const _NotificationToggleCard(),
                            const SizedBox(height: 12),
                            _Cb150rCatalogCard(onUsePart: _logPartFromCatalog),
                            const SizedBox(height: 20),
                            _buildEmptyState(),
                          ],
                        ),
                      );
                    }

                    // ————————————————————————————————————— Summary card ———————————————————————————————————————————
                    final dueCount = services
                        .where((s) =>
                            s.nextServiceDate != null &&
                            s.nextServiceDate!.isBefore(DateTime.now()))
                        .length;
                    final totalCost =
                        services.fold<double>(0.0, (sum, s) => sum + s.cost);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
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
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                              itemCount: services.length + 2,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  // Trigger notification update setiap data berubah
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    context
                                        .read<NotificationSettingsProvider>()
                                        .updateServiceReminder(services);
                                  });
                                  return const Padding(
                                    padding: EdgeInsets.only(bottom: 12),
                                    child: _NotificationToggleCard(),
                                  );
                                }
                                if (index == 1) {
                                  return _Cb150rCatalogCard(onUsePart: _logPartFromCatalog);
                                }
                                final service = services[index - 2];
                                return _ServiceCard(
                                  service: service,
                                  currencyFormat: _currencyFormat,
                                  onEdit: () => _showAddEditDialog(service),
                                  onDelete: () => _confirmDelete(
                                      context, provider, service),
                                );
                              },
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
          shape:
              const CircleBorder(side: BorderSide(color: Colors.transparent)),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, VehicleServiceProvider provider,
      VehicleServiceModel service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hapus Data',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
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
            child:
                const Text('Hapus', style: TextStyle(color: AppColors.expense)),
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

// ── Notification Toggle Card ────────────────────────────────────────────────

class _NotificationToggleCard extends StatelessWidget {
  const _NotificationToggleCard();

  @override
  Widget build(BuildContext context) {
    return Consumer2<NotificationSettingsProvider, VehicleServiceProvider>(
      builder: (context, settingsProvider, vehicleProvider, child) {
        final isEnabled = settingsProvider.serviceReminderEnabled;
        return GlassContainer(
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isEnabled ? AppColors.blueAccent : AppColors.textDim).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                  color: isEnabled ? AppColors.blueAccent : AppColors.textDim,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pin Pengingat Servis',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kunci info servis motor di atas bar notifikasi HP Anda',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: isEnabled,
                activeThumbColor: AppColors.blueAccent,
                activeTrackColor: AppColors.blueAccent.withValues(alpha: 0.3),
                inactiveThumbColor: AppColors.textDim,
                inactiveTrackColor: AppColors.bgCardAlt,
                onChanged: (val) {
                  settingsProvider.setServiceReminder(
                    enabled: val,
                    services: vehicleProvider.services,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Stat card ───────────────────────────────────────────────────────────────

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

// ── Service card ────────────────────────────────────────────────────────────

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
    final cardImageUrl = service.imageUrl;

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
                    // ── Title row ──────────────────────────────────────────
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
                            color: isDue
                                ? AppColors.expense
                                : AppColors.blueAccent,
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

                    // ── Info chips ─────────────────────────────────────────
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _InfoChip(
                          icon: Icons.speed_rounded,
                          label: '${service.odometer} km',
                        ),
                        if (service.notes.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: _InfoChip(
                              icon: Icons.notes_rounded,
                              label: service.notes,
                              expand: true,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // ── Installed Parts List ───────────────────────────────
                    if (service.parts.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        '🛠️ Komponen Terpasang (${service.parts.length}):',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Column(
                        children: service.parts.map((part) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.bgCardAlt.withValues(alpha: 0.4),
                              border: Border.all(color: AppColors.borderAccent.withValues(alpha: 0.5)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                if (part.imageUrl.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: FadeInImage.assetNetwork(
                                        placeholder: 'assets/logo.png',
                                        image: part.imageUrl,
                                        fit: BoxFit.cover,
                                        imageErrorBuilder: (context, error, stackTrace) {
                                          return const Icon(Icons.build_rounded, size: 16);
                                        },
                                      ),
                                    ),
                                  )
                                else
                                  Icon(Icons.build_rounded, size: 12, color: AppColors.blueAccent),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        part.name,
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (part.brand.isNotEmpty || part.code.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            if (part.brand.isNotEmpty) ...[
                                              Text(
                                                part.brand,
                                                style: TextStyle(color: AppColors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(width: 6),
                                            ],
                                            if (part.code.isNotEmpty)
                                              Text(
                                                'Code: ${part.code}',
                                                style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Text(
                                  currencyFormat.format(part.price),
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (part.code.isNotEmpty) ...[
                                  const SizedBox(width: 10),
                                  IconButton(
                                    icon: const Icon(Icons.copy_rounded, size: 12),
                                    color: AppColors.textMuted,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: part.code));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Kode part "${part.code}" disalin!'),
                                          duration: const Duration(seconds: 1),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )).toList(),
                      ),
                    ],



                    // ── Next service badge ─────────────────────────────────
                    if (service.nextServiceDate != null) ...[
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
                    ],

                    // ── Image Odometer / Nota ──────────────────────────────
                    if (cardImageUrl != null && cardImageUrl.isNotEmpty) ...[
                      const SizedBox(height: 12),
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
                                    child: cardImageUrl.startsWith('data:image/')
                                        ? Image.memory(
                                            base64Decode(cardImageUrl.split(',').last),
                                            fit: BoxFit.contain,
                                          )
                                        : Image.network(
                                            cardImageUrl,
                                            fit: BoxFit.contain,
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Hero(
                          tag: 'service_img_${service.id}',
                          child: Container(
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.borderAccent),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: cardImageUrl.startsWith('data:image/')
                                  ? Image.memory(
                                      base64Decode(cardImageUrl.split(',').last),
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: 120,
                                    )
                                  : Image.network(
                                      cardImageUrl,
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

                    // ── Actions ────────────────────────────────────────────
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
                          icon: const Icon(Icons.delete_outline_rounded,
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

// ── Add/Edit bottom sheet ──────────────────────────────────────────────────

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
  List<VehiclePart> _parts = [];

  File? _imageFile;
  bool _deleteImage = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.service?.title ?? 'Ganti Oli');
    _notesController = TextEditingController(text: widget.service?.notes ?? '');
    _costController = TextEditingController(
        text: widget.service?.cost.toInt().toString() ?? '');
    _odometerController =
        TextEditingController(text: widget.service?.odometer.toString() ?? '');
    _date = widget.service?.date ?? DateTime.now();
    _nextServiceDate = widget.service?.nextServiceDate;
    _parts = widget.service?.parts != null
        ? List<VehiclePart>.from(widget.service!.parts)
        : [];
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 30,
        maxWidth: 500,
        maxHeight: 500,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _deleteImage = false;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
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
    if (!mounted) return;
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

  void _showAddPartDialog() {
    final nameCtrl = TextEditingController();
    final brandCtrl = TextEditingController(text: 'AHM');
    final codeCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Tambah Komponen', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Nama Komponen (misal: Kampas Rem)'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: brandCtrl,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Merek (misal: AHM, Bendix)'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: codeCtrl,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Nomor/Kode Part (Opsional)'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: priceCtrl,
                style: TextStyle(color: AppColors.textPrimary),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Harga (Rp)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              final price = double.tryParse(priceCtrl.text) ?? 0.0;
              setState(() {
                _parts.add(VehiclePart(
                  name: nameCtrl.text.trim(),
                  brand: brandCtrl.text.trim(),
                  code: codeCtrl.text.trim(),
                  price: price,
                ));
                double partsSum = _parts.fold(0.0, (sum, p) => sum + p.price);
                if (_costController.text.isEmpty || double.tryParse(_costController.text) == 0.0) {
                  _costController.text = partsSum.toInt().toString();
                }
              });
              Navigator.pop(ctx);
            },
            child: Text('Tambah', style: TextStyle(color: AppColors.blueAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
        imageUrl: widget.service?.imageUrl,
        parts: _parts,
      );
      if (widget.service == null || widget.service!.id.isEmpty) {
        await provider.addService(service, imageFile: _imageFile);
      } else {
        await provider.updateService(service, imageFile: _imageFile, deleteImage: _deleteImage);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
                    ? 'Tambah Log Servis'
                    : 'Edit Log Servis',
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
                  if (_nextServiceDate != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.clear, color: AppColors.textMuted),
                      onPressed: () => setState(() => _nextServiceDate = null),
                    ),
                  ],
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

              // â”€â”€ Suku Cadang/Komponen Terpasang â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ðŸ› ï¸ Komponen Terpasang (${_parts.length})',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showAddPartDialog,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Tambah Part', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.blueAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_parts.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    border: Border.all(color: AppColors.borderAccent, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      'Belum ada komponen tercatat.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ),
                )
              else
                Column(
                  children: List.generate(_parts.length, (idx) {
                    final part = _parts[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          border: Border.all(color: AppColors.borderAccent),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            if (part.imageUrl.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  width: 34,
                                  height: 34,
                                  child: FadeInImage.assetNetwork(
                                    placeholder: 'assets/logo.png',
                                    image: part.imageUrl,
                                    fit: BoxFit.cover,
                                    imageErrorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.build_rounded, size: 18);
                                    },
                                  ),
                                ),
                              )
                            else
                              Icon(Icons.build_rounded, size: 14, color: AppColors.blueAccent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    part.name,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (part.brand.isNotEmpty || part.code.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        if (part.brand.isNotEmpty) ...[
                                          Text(
                                            part.brand,
                                            style: TextStyle(color: AppColors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                        if (part.code.isNotEmpty)
                                          Text(
                                            'Code: ${part.code}',
                                            style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                                          ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Text(
                              NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(part.price),
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 16),
                              color: AppColors.expense,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setState(() {
                                  _parts.removeAt(idx);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),

              // â”€â”€ Image Picker UI â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              const SizedBox(height: 16),
              Text(
                'Foto Odometer / Nota (Opsional)',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              if (_imageFile != null || (widget.service?.imageUrl != null && widget.service!.imageUrl!.isNotEmpty && !_deleteImage))
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderAccent),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: _imageFile != null
                              ? Image.file(
                                  _imageFile!,
                                  fit: BoxFit.cover,
                                )
                              : (widget.service?.imageUrl?.startsWith('data:image/') ?? false)
                                  ? Image.memory(
                                      base64Decode(widget.service!.imageUrl!.split(',').last),
                                      fit: BoxFit.cover,
                                    )
                                  : Image.network(
                                      widget.service?.imageUrl ?? '',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                                    ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _imageFile = null;
                              if (widget.service?.imageUrl != null && widget.service!.imageUrl!.isNotEmpty) {
                                _deleteImage = true;
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickImage(ImageSource.camera),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            border: Border.all(color: AppColors.borderAccent),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_outlined, color: AppColors.blueAccent, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Kamera',
                                style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickImage(ImageSource.gallery),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            border: Border.all(color: AppColors.borderAccent),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.photo_library_outlined, color: AppColors.blueAccent, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Galeri',
                                style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
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
                color: isAccent ? AppColors.blueAccent : AppColors.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isAccent ? AppColors.blueAccent : AppColors.textMuted,
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


class _Cb150rCatalogCard extends StatefulWidget {
  final Function(Map<String, dynamic>)? onUsePart;

  const _Cb150rCatalogCard({this.onUsePart});

  @override
  State<_Cb150rCatalogCard> createState() => _Cb150rCatalogCardState();
}

class _Cb150rCatalogCardState extends State<_Cb150rCatalogCard> {
  bool _isExpanded = false;
  int _activeCategoryIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static const List<Color> _catColors = [
    Color(0xFF3B82F6),
    Color(0xFFEF4444),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFF8B5CF6),
  ];

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Mesin & Oli',
      'icon': Icons.opacity_rounded,
      'items': <Map<String, dynamic>>[
        {
          'name': 'Oli Mesin SPX 1 (10W-30)',
          'code': '08234-2MA-K8LU0',
          'desc': 'Oli mesin original premium Honda untuk CB150R StreetFire, diformulasikan untuk performa sport harian.',
          'spec': '10W-30 Â· 1.2 Liter Â· API SN / JASO MA2',
          'interval': 'Ganti tiap 2.000â€“3.000 km',
          'price': 'Rp 72.000',
          'icon': Icons.opacity_rounded,
        },
        {
          'name': 'Busi NGK Iridium',
          'code': '31916-K97-T01',
          'desc': 'Busi dual-iridium premium, respons pengapian lebih cepat dan masa pakai 3x lebih lama dari busi biasa.',
          'spec': 'NGK MR9C-9N Â· Gap: 0.7â€“0.8 mm',
          'interval': 'Ganti tiap 24.000 km',
          'price': 'Rp 75.000',
          'icon': Icons.electric_bolt_rounded,
        },
        {
          'name': 'Filter Oli',
          'code': '15412-MGS-D21',
          'desc': 'Filter oli cartridge original AHM. Disarankan diganti setiap penggantian oli kedua.',
          'spec': 'OEM AHM Â· Thread: M20xP1.5',
          'interval': 'Ganti tiap 6.000 km',
          'price': 'Rp 85.000',
          'icon': Icons.filter_alt_rounded,
        },
        {
          'name': 'Coolant / Air Radiator',
          'code': '08C50-C30-G30',
          'desc': 'Cairan pendingin radiator khusus Honda CB150R. Jangan dicampur air keran biasa.',
          'spec': '0.63 Liter Â· Pre-mixed Â· -35 s/d +110 derajat C',
          'interval': 'Ganti tiap 24.000 km',
          'price': 'Rp 22.000',
          'icon': Icons.water_drop_rounded,
        },
      ],
    },
    {
      'name': 'Rem & Roda',
      'icon': Icons.album_rounded,
      'items': <Map<String, dynamic>>[
        {
          'name': 'Kampas Rem Depan',
          'code': '06455-K56-N01',
          'desc': 'Brake pad disc depan original AHM untuk kaliper Nissin. Performa pengereman konsisten.',
          'spec': 'Tipe: Sintered Â· Kaliper: Nissin 2-piston',
          'interval': 'Cek tiap 6.000 km / ganti jika tipis',
          'price': 'Rp 65.000',
          'icon': Icons.radio_button_checked_rounded,
        },
        {
          'name': 'Kampas Rem Belakang',
          'code': '06435-KSP-B01',
          'desc': 'Brake pad disc belakang original AHM. Durabilitas lebih tinggi dari kampas aftermarket.',
          'spec': 'Tipe: Sintered Â· Kaliper: Nissin 1-piston',
          'interval': 'Cek tiap 8.000 km / ganti jika tipis',
          'price': 'Rp 55.000',
          'icon': Icons.radio_button_unchecked_rounded,
        },
        {
          'name': 'Ban Depan Tubeless',
          'code': 'IRC SS-560 Front',
          'desc': 'Ban depan tubeless OEM CB150R, traksi kering dan basah terjamin.',
          'spec': '100/80-17 Â· 52P Â· Tubeless',
          'interval': 'Cek tekanan tiap 2 minggu: 29 psi',
          'price': 'Rp 320.000',
          'icon': Icons.circle_outlined,
        },
        {
          'name': 'Ban Belakang Tubeless',
          'code': 'IRC SS-560 Rear',
          'desc': 'Ban belakang tubeless OEM CB150R dengan karakteristik ban sport.',
          'spec': '130/70-17 Â· 62P Â· Tubeless',
          'interval': 'Cek tekanan tiap 2 minggu: 33 psi',
          'price': 'Rp 480.000',
          'icon': Icons.circle,
        },
        {
          'name': 'Minyak Rem (DOT 4)',
          'code': '08200-9001L',
          'desc': 'Minyak rem Honda DOT 4, wajib diganti berkala karena menyerap kelembaban udara.',
          'spec': 'DOT 4 Â· Titik didih dry: 230 C / wet: 155 C',
          'interval': 'Ganti tiap 2 tahun',
          'price': 'Rp 35.000',
          'icon': Icons.invert_colors_rounded,
        },
      ],
    },
    {
      'name': 'Filter & Listrik',
      'icon': Icons.bolt_rounded,
      'items': <Map<String, dynamic>>[
        {
          'name': 'Filter Udara',
          'code': '17211-K15-900',
          'desc': 'Filter udara viscous element original AHM. Jika kotor, performa mesin turun signifikan.',
          'spec': 'Tipe: Foam viscous Â· OEM K15G',
          'interval': 'Bersihkan tiap 8.000 km Â· Ganti tiap 24.000 km',
          'price': 'Rp 80.000',
          'icon': Icons.air_rounded,
        },
        {
          'name': 'Aki Kering YTZ6V',
          'code': '31500-KZR-602',
          'desc': 'Aki MF original. Tegangan normal 12.8V-13.2V. Jika di bawah 12V, segera isi ulang.',
          'spec': '12V Â· 5Ah Â· 90 CCA Â· YTZ6V / GTZ6V',
          'interval': 'Cek tiap 6 bulan Â· Ganti tiap 2â€“3 tahun',
          'price': 'Rp 265.000',
          'icon': Icons.battery_charging_full_rounded,
        },
        {
          'name': 'Sekring 10A',
          'code': '38221-SGE-003',
          'desc': 'Sekring blade mini 10A untuk sirkuit utama kelistrikan. Bawa selalu sebagai cadangan.',
          'spec': '10 Ampere Â· Tipe: Mini blade Â· Warna: merah',
          'interval': 'Ganti hanya jika putus',
          'price': 'Rp 5.000',
          'icon': Icons.electrical_services_rounded,
        },
        {
          'name': 'Bohlam Lampu Depan',
          'code': '34901-KZL-B01',
          'desc': 'Lampu halogen HS1 untuk headlamp CB150R. Pastikan pola sinar tidak silau setelah ganti.',
          'spec': 'HS1 Â· 12V 35/35W Â· PX43t',
          'interval': 'Ganti jika mati / redup',
          'price': 'Rp 45.000',
          'icon': Icons.wb_incandescent_rounded,
        },
      ],
    },
    {
      'name': 'Rantai & Transmisi',
      'icon': Icons.settings_rounded,
      'items': <Map<String, dynamic>>[
        {
          'name': 'Rantai & Gear Set',
          'code': '06401-K56-N10',
          'desc': 'Kit rantai & gear set lengkap AHM. Ganti rantai dan gear bersamaan untuk optimal.',
          'spec': 'Rantai 428-124L Â· Gear depan 15T Â· Gear belakang 46T',
          'interval': 'Pelumas tiap 500 km Â· Ganti tiap 15.000 km',
          'price': 'Rp 345.000',
          'icon': Icons.settings_input_component_rounded,
        },
        {
          'name': 'Kabel Kopling',
          'code': '22870-K56-N00',
          'desc': 'Kabel kopling berlapis inner teflon untuk perpindahan yang ringan dan responsif.',
          'spec': 'Tipe: Teflon-lined Â· AHM OEM',
          'interval': 'Stel ulang tiap 6.000 km Â· Ganti jika seret',
          'price': 'Rp 38.000',
          'icon': Icons.cable_rounded,
        },
        {
          'name': 'Kabel Gas Set (Push/Pull)',
          'code': '17910-K56-N01',
          'desc': 'Set kabel gas push-pull original. Pastikan play bebas 2-3 mm di ujung grip.',
          'spec': 'Push + Pull Â· Tipe: Stainless inner',
          'interval': 'Cek kebebasan play tiap 6.000 km',
          'price': 'Rp 65.000',
          'icon': Icons.tune_rounded,
        },
        {
          'name': 'Oli Garpu (Fork Oil)',
          'code': '08254-10G-Y00',
          'desc': 'Oli suspensi garpu depan Honda. Penting untuk karakter handling yang presisi.',
          'spec': 'Honda Ultra Cushion Oil Â· 2x 135ml',
          'interval': 'Ganti tiap 20.000 km',
          'price': 'Rp 48.000',
          'icon': Icons.vertical_align_center_rounded,
        },
      ],
    },
    {
      'name': 'Suspensi & Rangka',
      'icon': Icons.architecture_rounded,
      'items': <Map<String, dynamic>>[
        {
          'name': 'Seal Garpu Depan',
          'code': '51490-K56-N01',
          'desc': 'Seal oli garpu kiri/kanan. Jika bocor, segera ganti untuk mencegah kerusakan tabung garpu.',
          'spec': 'ID 33mm x OD 46mm x H 11mm',
          'interval': 'Ganti jika bocor / tiap 30.000 km',
          'price': 'Rp 55.000',
          'icon': Icons.compress_rounded,
        },
        {
          'name': 'Sokbreker Belakang',
          'code': '52400-K56-N01',
          'desc': 'Monosok belakang original CB150R. Jika terasa limbung atau mental-mental, waktunya diganti.',
          'spec': 'Tipe: Mono shock Â· Travel: 104mm Â· Preload adj.',
          'interval': 'Cek tiap 10.000 km Â· Ganti tiap 30.000 km',
          'price': 'Rp 450.000',
          'icon': Icons.swap_vert_rounded,
        },
        {
          'name': 'Bearing Setang (Steering)',
          'code': '53215-K56-N00',
          'desc': 'Bearing dudukan setang. Jika setang terasa ada jeda atau berat di posisi tertentu, segera ganti.',
          'spec': 'Tipe: Ball bearing Â· Set atas dan bawah',
          'interval': 'Ganti tiap 30.000 km / jika oblak',
          'price': 'Rp 120.000',
          'icon': Icons.blur_circular_rounded,
        },
      ],
    },
  ];

  List<Map<String, dynamic>> get _filteredItems {
    final items = _categories[_activeCategoryIndex]['items'] as List<Map<String, dynamic>>;
    if (_searchQuery.isEmpty) return items;
    final q = _searchQuery.toLowerCase();
    return items.where((item) {
      return (item['name'] as String).toLowerCase().contains(q) ||
          (item['code'] as String).toLowerCase().contains(q) ||
          (item['spec'] as String).toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _catColors[_activeCategoryIndex % _catColors.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        borderRadius: 20,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF3B82F6).withValues(alpha: 0.22),
                          const Color(0xFF6366F1).withValues(alpha: 0.22),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.two_wheeler_rounded, color: Color(0xFF60A5FA), size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Katalog Part & Spek CB150R 2019',
                          style: TextStyle(
                            color: Color(0xFF60A5FA),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_categories.length} kategori Â· ${_categories.fold(0, (s, c) => s + (c["items"] as List).length)} komponen terdaftar',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF60A5FA), size: 22),
                  ),
                ],
              ),
            ),

            // â”€â”€ Expanded Body â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            AnimatedSize(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeInOutCubic,
              child: _isExpanded
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // Spec summary banner
                        _buildSpecBanner(),

                        const SizedBox(height: 16),

                        // Search bar
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.bgCardAlt.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.borderAccent),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                            onChanged: (v) => setState(() => _searchQuery = v.trim()),
                            decoration: InputDecoration(
                              hintText: 'Cari nama part, kode OEM, atau spesifikasi...',
                              hintStyle: TextStyle(color: AppColors.textDim, fontSize: 12),
                              prefixIcon: Icon(Icons.search_rounded, color: AppColors.textDim, size: 18),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.close_rounded, color: AppColors.textDim, size: 16),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Category chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(_categories.length, (idx) {
                              final cat = _categories[idx];
                              final isActive = idx == _activeCategoryIndex;
                              final color = _catColors[idx % _catColors.length];
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    _activeCategoryIndex = idx;
                                    _searchController.clear();
                                    _searchQuery = '';
                                  }),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isActive ? color.withValues(alpha: 0.15) : AppColors.bgCard,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isActive ? color : AppColors.borderAccent,
                                        width: isActive ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          cat['icon'] as IconData,
                                          size: 13,
                                          color: isActive ? color : AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          cat['name'] as String,
                                          style: TextStyle(
                                            color: isActive ? color : AppColors.textSecondary,
                                            fontSize: 12,
                                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Part items with animated switcher
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: Column(
                            key: ValueKey('$_activeCategoryIndex-$_searchQuery'),
                            children: _filteredItems.isEmpty
                                ? [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 24),
                                      child: Center(
                                        child: Text(
                                          'Tidak ada part yang cocok dengan "$_searchQuery"',
                                          style: TextStyle(color: AppColors.textDim, fontSize: 12),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ]
                                : _filteredItems.map((item) => _buildPartCard(item, catColor, context)).toList(),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF1E293B)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.motorcycle_rounded, color: Color(0xFF60A5FA), size: 14),
              SizedBox(width: 6),
              Text(
                'Honda CB150R StreetFire 2019 (K15G)',
                style: TextStyle(
                  color: Color(0xFF93C5FD),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _specCell('Engine', '149cc DOHC'),
              _specCell('Power', '17.1 hp'),
              _specCell('Torque', '13.7 Nm'),
              _specCell('Fuel', 'PGM-FI'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _specCell(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildPartCard(Map<String, dynamic> item, Color catColor, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderAccent),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: icon + name + desc
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: catColor.withValues(alpha: 0.25)),
                    ),
                    alignment: Alignment.center,
                    child: Icon(item['icon'] as IconData, color: catColor, size: 21),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'] as String,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['desc'] as String,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Spec pill
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: catColor.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.tune_rounded, size: 11, color: catColor.withValues(alpha: 0.8)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item['spec'] as String,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Interval
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 11, color: AppColors.textDim),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      item['interval'] as String,
                      style: TextStyle(color: AppColors.textDim, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
            const Divider(height: 1, indent: 12, endIndent: 12),

            // Bottom bar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.bgCardAlt,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: catColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      item['code'] as String,
                      style: TextStyle(
                        color: catColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    item['price'] as String,
                    style: const TextStyle(
                      color: AppColors.expense,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.copy_all_rounded, size: 16),
                    color: AppColors.textDim,
                    tooltip: 'Salin kode OEM',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: item['code'] as String));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Kode OEM "${item["code"]}" disalin!'),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  if (widget.onUsePart != null) ...[
                    const SizedBox(width: 4),
                    ElevatedButton.icon(
                      onPressed: () => widget.onUsePart!(item),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 13),
                      label: const Text('Gunakan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                        foregroundColor: const Color(0xFF60A5FA),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


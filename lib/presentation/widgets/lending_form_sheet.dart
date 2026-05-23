import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:productivity/core/theme/app_theme.dart';
import 'package:productivity/core/utils/image_helper.dart';
import 'package:productivity/data/models/lending_model.dart';
import 'package:productivity/data/repositories/lending_repository.dart';
import 'package:productivity/presentation/widgets/glass_container.dart';
import 'package:productivity/services/notification_service.dart';

class LendingFormSheet extends StatefulWidget {
  final LendingModel? existing;

  const LendingFormSheet({super.key, this.existing});

  @override
  State<LendingFormSheet> createState() => _LendingFormSheetState();
}

class _LendingFormSheetState extends State<LendingFormSheet> {
  final _repo = LendingRepository();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _itemNameCtrl;
  late TextEditingController _borrowerCtrl;
  late TextEditingController _noteCtrl;

  File? _imageFile;
  bool _deleteImage = false;
  final ImagePicker _picker = ImagePicker();

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

  DateTime _borrowDate = DateTime.now();
  DateTime _targetDate = DateTime.now().add(const Duration(days: 3));
  String _category = 'Buku';
  bool _isLoading = false;

  final List<String> _categories = [
    'Buku',
    'Komponen',
    'Alat Tulis',
    'Elektronik',
    'Lainnya'
  ];

  @override
  void initState() {
    super.initState();
    _itemNameCtrl = TextEditingController(text: widget.existing?.itemName);
    _borrowerCtrl = TextEditingController(text: widget.existing?.borrowerName);
    _noteCtrl = TextEditingController(text: widget.existing?.note);

    if (widget.existing != null) {
      _borrowDate = widget.existing!.borrowDate;
      _targetDate = widget.existing!.targetReturnDate;
      _category = widget.existing!.category;
    }
  }

  @override
  void dispose() {
    _itemNameCtrl.dispose();
    _borrowerCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isTargetDate) async {
    final initial = isTargetDate ? _targetDate : _borrowDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isTargetDate) {
          _targetDate = picked;
        } else {
          _borrowDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    String? finalImageUrl = widget.existing?.imageUrl;
    if (_deleteImage) {
      finalImageUrl = '';
    } else if (_imageFile != null) {
      finalImageUrl = await ImageHelper.fileToBase64(_imageFile!);
    }

    final item = LendingModel(
      id: widget.existing?.id ?? '',
      itemName: _itemNameCtrl.text.trim(),
      borrowerName: _borrowerCtrl.text.trim(),
      borrowDate: _borrowDate,
      targetReturnDate: _targetDate,
      category: _category,
      note: _noteCtrl.text.trim(),
      isReturned: widget.existing?.isReturned ?? false,
      imageUrl: finalImageUrl,
    );

    try {
      if (widget.existing == null) {
        await _repo.add(item);
      } else {
        await _repo.update(item);
      }

      // Simulasi memicu notifikasi jika mendekati tenggat.
      // Idealnya ini dijadwalkan menggunakan plugin timezone.
      if (_targetDate.difference(DateTime.now()).inDays <= 1) {
        try {
          NotificationService()
              .showLendingReminder(item.itemName, item.borrowerName);
        } catch (_) {
          // Abaikan error notifikasi agar tidak membatalkan form tutup
        }
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      decoration: BoxDecoration(
        color: AppColors.bgCardAlt,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.existing == null
                    ? 'Tambah Peminjaman'
                    : 'Edit Peminjaman',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _itemNameCtrl,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Nama Barang',
                  labelStyle: TextStyle(color: AppColors.textMuted),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _borrowerCtrl,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Nama Peminjam',
                  labelStyle: TextStyle(color: AppColors.textMuted),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                dropdownColor: AppColors.bgCard,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  labelStyle: TextStyle(color: AppColors.textMuted),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: _categories.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: (val) => setState(() => _category = val!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(false),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text('Tgl Pinjam',
                                style: TextStyle(
                                    color: AppColors.textMuted, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                                '${_borrowDate.day}/${_borrowDate.month}/${_borrowDate.year}',
                                style: TextStyle(color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(true),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text('Tenggat Kembali',
                                style: TextStyle(
                                    color: AppColors.textMuted, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                                '${_targetDate.day}/${_targetDate.month}/${_targetDate.year}',
                                style: TextStyle(color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteCtrl,
                style: TextStyle(color: AppColors.textPrimary),
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Catatan',
                  labelStyle: TextStyle(color: AppColors.textMuted),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Foto Kondisi Barang (Opsional)',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              if (_imageFile != null || (widget.existing?.imageUrl != null && widget.existing!.imageUrl!.isNotEmpty && !_deleteImage)) ...[
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
                              : widget.existing!.imageUrl!.startsWith('data:image/')
                                  ? Image.memory(
                                      base64Decode(widget.existing!.imageUrl!.split(',').last),
                                      fit: BoxFit.cover,
                                    )
                                  : Image.network(
                                      widget.existing!.imageUrl!,
                                      fit: BoxFit.cover,
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
                              if (widget.existing?.imageUrl != null && widget.existing!.imageUrl!.isNotEmpty) {
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
                ),
              ] else ...[
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
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Simpan',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

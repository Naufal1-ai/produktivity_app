import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:productivity/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Key SharedPreferences untuk menyimpan foto profil dalam format Base64
/// (mendukung Web, Android, dan iOS tanpa path_provider)
const String kLocalPhotoPathKey = 'local_profile_photo_path'; // tetap untuk kompatibilitas
const String kLocalPhotoBase64Key = 'local_profile_photo_base64';

class EditProfileScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const EditProfileScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  Uint8List? _imageBytes;     // Preview / gambar baru yang dipilih
  Uint8List? _savedPhotoBytes; // Gambar yang sudah tersimpan sebelumnya
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();

    // Prioritaskan nama dari SharedPreferences, fallback ke Firebase
    final savedName = prefs.getString('profile_name');
    _nameController.text = savedName ?? user?.displayName ?? '';
    _emailController.text = user?.email ?? '';

    // Load foto yang tersimpan (Base64)
    final base64Photo = prefs.getString(kLocalPhotoBase64Key);
    Uint8List? savedBytes;
    if (base64Photo != null && base64Photo.isNotEmpty) {
      try {
        savedBytes = base64Decode(base64Photo);
      } catch (_) {
        savedBytes = null;
      }
    }

    if (!mounted) return;
    setState(() {
      _phoneController.text = prefs.getString('profile_phone') ?? '';
      _addressController.text = prefs.getString('profile_address') ?? '';
      _savedPhotoBytes = savedBytes;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih gambar: $e'),
          backgroundColor: AppColors.expense,
        ),
      );
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      // Simpan foto baru sebagai Base64 jika ada gambar yang dipilih
      if (_imageBytes != null) {
        final base64String = base64Encode(_imageBytes!);
        await prefs.setString(kLocalPhotoBase64Key, base64String);
        setState(() {
          _savedPhotoBytes = _imageBytes;
          _imageBytes = null; // clear preview setelah tersimpan
        });
      }

      // Simpan data profil ke SharedPreferences
      await prefs.setString('profile_name', _nameController.text.trim());
      await prefs.setString('profile_phone', _phoneController.text.trim());
      await prefs.setString('profile_address', _addressController.text.trim());

      // Update display name di Firebase Auth jika user sedang login
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName(_nameController.text.trim());
        await user.reload();
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui'),
          backgroundColor: AppColors.income,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui profil: $e'),
          backgroundColor: AppColors.expense,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField(
    String label,
    String hint,
    IconData? suffixIcon,
    TextEditingController? controller, {
    bool enabled = true,
    int maxLines = 1,
    bool isPhone = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.isDark ? AppColors.bg : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.isDark
                  ? AppColors.borderAccent
                  : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            maxLines: maxLines,
            style: TextStyle(
              color: enabled ? AppColors.textPrimary : AppColors.textMuted,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  TextStyle(color: AppColors.textMuted.withValues(alpha: 0.6)),
              prefixIcon: isPhone
                  ? Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 24,
                            height: 16,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: Colors.grey[300],
                              image: const DecorationImage(
                                image: AssetImage('assets/logo.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '+62',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                              width: 1,
                              height: 20,
                              color: AppColors.border),
                          const SizedBox(width: 8),
                        ],
                      ),
                    )
                  : null,
              suffixIcon: suffixIcon != null
                  ? Icon(suffixIcon,
                      color: AppColors.textPrimary, size: 20)
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  /// Bangun widget avatar berdasarkan prioritas:
  /// 1. Gambar baru yang dipilih (preview, belum disimpan)
  /// 2. Gambar tersimpan sebelumnya (dari Base64 SharedPreferences)
  /// 3. Ikon default
  Widget _buildAvatar() {
    final displayBytes = _imageBytes ?? _savedPhotoBytes;
    if (displayBytes != null) {
      return Image.memory(
        displayBytes,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
      );
    }
    return const Icon(Icons.person, color: Colors.white, size: 60);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.isDark
          ? const Color(0xFF0F1117)
          : const Color(0xFFE2E8F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              decoration: BoxDecoration(
                color: AppColors.isDark ? AppColors.bgCard : Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Foto Profil ─────────────────────────────────
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: const BoxDecoration(
                              color: Color(0xFFC4C4C4),
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(child: _buildAvatar()),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.15),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ketuk foto untuk mengganti',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Form Fields ──────────────────────────────────
                    _buildTextField('Full Name', 'Your Name',
                        Icons.person, _nameController),
                    _buildTextField('Email Address',
                        'example@your.email', Icons.email, _emailController,
                        enabled: false),
                    _buildTextField('Phone Number', '1234 5678 9101',
                        Icons.phone, _phoneController,
                        isPhone: true),
                    _buildTextField('Home Address', 'Your Address', null,
                        _addressController,
                        maxLines: 3),

                    const SizedBox(height: 20),

                    // ── Tombol Simpan ────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0FA99D),
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                'Update Profile',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Tombol Batal ────────────────────────────────
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

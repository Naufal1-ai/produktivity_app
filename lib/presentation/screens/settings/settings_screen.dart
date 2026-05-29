import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:productivity/core/theme/app_theme.dart';
import 'package:productivity/core/theme/app_style_theme.dart';
import 'package:productivity/main.dart' show appStyleNotifier;
import 'package:productivity/presentation/widgets/glass_container.dart';
import 'package:productivity/l10n/app_localizations.dart';
import 'package:productivity/services/settings_service.dart';
import 'package:productivity/presentation/screens/settings/edit_profile_screen.dart'
    show EditProfileScreen, kLocalPhotoBase64Key;
import 'package:productivity/presentation/screens/settings/support_screen.dart';
import 'package:productivity/presentation/screens/settings/pin_setup_screen.dart';
import 'package:productivity/presentation/screens/settings/theme_color_screen.dart';
import 'package:productivity/presentation/screens/settings/language_screen.dart';
import 'package:productivity/presentation/screens/settings/export_screen.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const SettingsScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  User? get _user => FirebaseAuth.instance.currentUser;
  late SettingsService _settingsService;
  bool _dailyReminder = false;
  bool _weeklyReminder = false;
  AppStyleTheme _appStyle = AppStyleTheme.modern;
  bool _isInitialized = false;
  Uint8List? _savedPhotoBytes; // Foto profil dari Base64 SharedPreferences
  String? _profileName; // Nama yang disimpan lokal

  @override
  void initState() {
    super.initState();
    _settingsService = SettingsService();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _settingsService.init();
    final prefs = await SharedPreferences.getInstance();
    Uint8List? photoBytes;
    final base64Photo = prefs.getString(kLocalPhotoBase64Key);
    if (base64Photo != null && base64Photo.isNotEmpty) {
      try {
        photoBytes = base64Decode(base64Photo);
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _dailyReminder = _settingsService.dailyReminder;
      _weeklyReminder = _settingsService.weeklyReminder;
      _appStyle = _settingsService.appStyle;
      _savedPhotoBytes = photoBytes;
      _profileName = prefs.getString('profile_name');
      _isInitialized = true;
    });
  }

  /// Tampilkan avatar dari Base64 bytes, fallback ke ikon default
  Widget _buildLocalAvatar(double size) {
    if (_savedPhotoBytes != null) {
      return ClipOval(
        child: Image.memory(
          _savedPhotoBytes!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }
    return Icon(
      Icons.person,
      color: Colors.white,
      size: size * 0.5,
    );
  }

  void _showAppStylePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppColors.borderAccent)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gaya Tampilan',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              ...AppStyleTheme.values.map((style) {
                final isSelected = style == _appStyle;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.blueAccent.withValues(alpha: 0.14)
                          : AppColors.bgCardAlt,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.blueAccent
                            : AppColors.borderAccent,
                      ),
                    ),
                    child: Icon(
                      style == AppStyleTheme.saweriaClassic
                          ? Icons.volunteer_activism_outlined
                          : Icons.auto_awesome_outlined,
                      color: isSelected
                          ? AppColors.blueAccent
                          : AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    style.label,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    style == AppStyleTheme.saweriaClassic
                        ? 'Nuansa klasik hijau Saweria dengan kartu lebih solid.'
                        : 'Tampilan bawaan aplikasi saat ini.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: AppColors.blueAccent)
                      : null,
                  onTap: () {
                    setState(() => _appStyle = style);
                    _settingsService.appStyle = style;
                    appStyleNotifier.value = style;
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.settings),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.textPrimary,
        ),
        body: const SafeArea(
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
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
              // Profile Section
              GlassContainer(
                showRetroWindowBar: true,
                retroWindowBarColor: AppColors.retroPink,
                borderRadius: 16,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profil',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.blueMid,
                                AppColors.blueAccent,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.blueAccent.withValues(alpha: 0.2),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                          child: _buildLocalAvatar(60),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _profileName ??
                                    _user?.displayName ??
                                    'Pengguna',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                _user?.email ?? '',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            final changed = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditProfileScreen(
                                  onToggleTheme: widget.onToggleTheme,
                                  isDarkMode: widget.isDarkMode,
                                ),
                              ),
                            );
                            if (changed == true) {
                              // Reload foto dan nama setelah kembali dari edit profile
                              final prefs =
                                  await SharedPreferences.getInstance();
                              Uint8List? newBytes;
                              final b64 = prefs.getString(kLocalPhotoBase64Key);
                              if (b64 != null && b64.isNotEmpty) {
                                try {
                                  newBytes = base64Decode(b64);
                                } catch (_) {}
                              }
                              if (!mounted) return;
                              setState(() {
                                _savedPhotoBytes = newBytes;
                                _profileName = prefs.getString('profile_name');
                              });
                            }
                          },
                          icon: Icon(
                            Icons.edit,
                            color: AppColors.blueAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Appearance Section
              GlassContainer(
                showRetroWindowBar: true,
                retroWindowBarColor: AppColors.retroTeal,
                borderRadius: 16,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tampilan',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _SettingsItem(
                      icon: widget.isDarkMode
                          ? Icons.light_mode
                          : Icons.dark_mode,
                      title: widget.isDarkMode ? 'Mode Terang' : 'Mode Gelap',
                      subtitle: 'Ubah tema aplikasi',
                      onTap: widget.onToggleTheme,
                      trailing: Switch(
                        value: widget.isDarkMode,
                        onChanged: (_) => widget.onToggleTheme(),
                        activeThumbColor: AppColors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SettingsItem(
                      icon: Icons.palette_outlined,
                      title: 'Warna Tema',
                      subtitle: 'Pilih aksen warna Productivity',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ThemeColorScreen(
                              onToggleTheme: widget.onToggleTheme,
                              isDarkMode: widget.isDarkMode,
                            ),
                          ),
                        );
                      },
                      trailing: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.blueAccent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.borderAccent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SettingsItem(
                      icon: Icons.dashboard_customize_outlined,
                      title: 'Gaya Tampilan',
                      subtitle: _appStyle.label,
                      onTap: _showAppStylePicker,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.blueAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.blueBorder),
                        ),
                        child: Text(
                          _appStyle == AppStyleTheme.saweriaClassic
                              ? 'Saweria'
                              : 'Modern',
                          style: TextStyle(
                            color: AppColors.blueAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Notifications Section
              GlassContainer(
                showRetroWindowBar: true,
                retroWindowBarColor: AppColors.retroYellow,
                borderRadius: 16,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifikasi',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _SettingsItem(
                      icon: Icons.notifications,
                      title: 'Pengingat Harian',
                      subtitle: 'Aktifkan pengingat transaksi harian',
                      onTap: () {},
                      trailing: Switch(
                        value: _dailyReminder,
                        onChanged: (value) {
                          setState(() {
                            _dailyReminder = value;
                            _settingsService.dailyReminder = value;
                          });
                        },
                        activeThumbColor: AppColors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SettingsItem(
                      icon: Icons.notifications_active,
                      title: 'Pengingat Mingguan',
                      subtitle: 'Aktifkan pengingat ringkasan mingguan',
                      onTap: () {},
                      trailing: Switch(
                        value: _weeklyReminder,
                        onChanged: (value) {
                          setState(() {
                            _weeklyReminder = value;
                            _settingsService.weeklyReminder = value;
                          });
                        },
                        activeThumbColor: AppColors.blueAccent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Security Section
              GlassContainer(
                showRetroWindowBar: true,
                retroWindowBarColor: AppColors.retroBlue,
                borderRadius: 16,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Keamanan',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _SettingsItem(
                      icon: Icons.lock,
                      title: 'PIN Aplikasi',
                      subtitle: 'Aktifkan PIN untuk membuka aplikasi',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PinSetupScreen(
                              onToggleTheme: widget.onToggleTheme,
                              isDarkMode: widget.isDarkMode,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Backup & Export Section
              GlassContainer(
                showRetroWindowBar: true,
                retroWindowBarColor: AppColors.retroPink,
                borderRadius: 16,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Backup & Export',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _SettingsItem(
                      icon: Icons.backup,
                      title: 'Backup Data',
                      subtitle: 'Backup data ke cloud',
                      onTap: () {},
                    ),
                    const SizedBox(height: 8),
                    _SettingsItem(
                      icon: Icons.download,
                      title: 'Export Data',
                      subtitle: 'Export data dalam format CSV/PDF',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ExportScreen(
                              onToggleTheme: widget.onToggleTheme,
                              isDarkMode: widget.isDarkMode,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Language Section
              GlassContainer(
                showRetroWindowBar: true,
                retroWindowBarColor: AppColors.retroTeal,
                borderRadius: 16,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bahasa',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _SettingsItem(
                      icon: Icons.language,
                      title: 'Bahasa Aplikasi',
                      subtitle: 'Pilih bahasa yang digunakan',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LanguageScreen(
                              onToggleTheme: widget.onToggleTheme,
                              isDarkMode: widget.isDarkMode,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Support Section
              GlassContainer(
                showRetroWindowBar: true,
                retroWindowBarColor: AppColors.retroYellow,
                borderRadius: 16,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bantuan',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _SettingsItem(
                      icon: Icons.help_outline,
                      title: 'FAQ & Bantuan',
                      subtitle: 'Pertanyaan umum dan dukungan',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SupportScreen(
                              onToggleTheme: widget.onToggleTheme,
                              isDarkMode: widget.isDarkMode,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Account Section
              GlassContainer(
                showRetroWindowBar: true,
                retroWindowBarColor: AppColors.retroBlue,
                borderRadius: 16,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Akun',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _SettingsItem(
                      icon: Icons.logout,
                      title: 'Keluar',
                      subtitle: 'Keluar dari akun Anda',
                      onTap: () async {
                        final navigator = Navigator.of(context);
                        await FirebaseAuth.instance.signOut();
                        if (!mounted) return;
                        navigator.pushReplacementNamed('/');
                      },
                      textColor: AppColors.expense,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // App Info
              GlassContainer(
                showRetroWindowBar: true,
                retroWindowBarColor: AppColors.retroPink,
                borderRadius: 16,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tentang Aplikasi',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _SettingsItem(
                      icon: Icons.info_outline,
                      title: 'Versi 2.1.0',
                      subtitle: 'Dibuat oleh Naufal Khalil Aldeza',
                      onTap: () {},
                      showArrow: false,
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

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? textColor;
  final bool showArrow;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.textColor,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.blueAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: textColor ?? AppColors.blueAccent,
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
                      color: textColor ?? AppColors.textPrimary,
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
            if (trailing != null) trailing!,
            if (showArrow && trailing == null)
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

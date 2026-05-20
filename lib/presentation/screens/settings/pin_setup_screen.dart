import 'package:flutter/material.dart';
import 'package:productivity/core/theme/app_theme.dart';
import 'package:productivity/presentation/widgets/glass_container.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:productivity/services/settings_service.dart';

class PinSetupScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const PinSetupScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  late SettingsService _settingsService;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _settingsService = SettingsService();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    await _settingsService.init();
    if (!mounted) return;
    setState(() => _isInitialized = true);
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _setupPin() async {
    if (!_validateInputs()) return;

    setState(() => _isLoading = true);

    try {
      if (!_settingsService.isInitialized) {
        await _settingsService.init();
      }
      _settingsService.pin = _pinController.text;
      _settingsService.pinEnabled = true;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pinSetSuccess),
          backgroundColor: AppColors.income,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.expense,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _validateInputs() {
    final l10n = AppLocalizations.of(context)!;

    if (_pinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pinRequired),
          backgroundColor: AppColors.expense,
        ),
      );
      return false;
    }

    if (_pinController.text.length < 4 || _pinController.text.length > 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pinLength),
          backgroundColor: AppColors.expense,
        ),
      );
      return false;
    }

    if (_pinController.text != _confirmPinController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pinNotMatch),
          backgroundColor: AppColors.expense,
        ),
      );
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.enablePIN),
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
        title: Text(
          _settingsService.pinEnabled ? l10n.changePIN : l10n.enablePIN,
        ),
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
                            color: AppColors.blueAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.lock,
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
                                _settingsService.pinEnabled
                                    ? 'Ubah PIN'
                                    : 'Aktifkan PIN',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _settingsService.pinEnabled
                                    ? 'Masukkan PIN baru untuk mengganti PIN lama'
                                    : 'PIN akan digunakan untuk membuka aplikasi',
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

              // PIN Input Section
              GlassContainer(
                borderRadius: 16,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Setup PIN',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 20),

                    // PIN Field
                    TextFormField(
                      controller: _pinController,
                      decoration: InputDecoration(
                        labelText: l10n.enterPIN,
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: AppColors.textMuted,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.borderAccent,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.borderAccent,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.blueAccent,
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 6,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.pinRequired;
                        }
                        if (value.length < 4 || value.length > 6) {
                          return l10n.pinLength;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Confirm PIN Field
                    TextFormField(
                      controller: _confirmPinController,
                      decoration: InputDecoration(
                        labelText: l10n.confirmPIN,
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: AppColors.textMuted,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.borderAccent,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.borderAccent,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.blueAccent,
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 6,
                      validator: (value) {
                        if (value != _pinController.text) {
                          return l10n.pinNotMatch;
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _setupPin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _settingsService.pinEnabled
                              ? 'Ubah PIN'
                              : 'Aktifkan PIN',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              if (_settingsService.pinEnabled) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      final shouldDisable = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Nonaktifkan PIN'),
                          content: const Text(
                              'Apakah Anda yakin ingin menonaktifkan PIN?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Batal'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.expense,
                              ),
                              child: const Text('Nonaktifkan'),
                            ),
                          ],
                        ),
                      );

                      if (shouldDisable == true) {
                        _settingsService.pinEnabled = false;
                        _settingsService.pin = null;
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('PIN berhasil dinonaktifkan'),
                            backgroundColor: AppColors.income,
                          ),
                        );
                        Navigator.pop(context);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.expense),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Nonaktifkan PIN',
                      style: TextStyle(
                        color: AppColors.expense,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

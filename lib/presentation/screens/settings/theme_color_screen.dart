import 'package:flutter/material.dart';
import 'package:productivity/core/theme/app_theme.dart';
import 'package:productivity/main.dart' show themeColorNotifier;
import 'package:productivity/presentation/widgets/glass_container.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:productivity/services/settings_service.dart';

class ThemeColorScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const ThemeColorScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<ThemeColorScreen> createState() => _ThemeColorScreenState();
}

class _ThemeColorScreenState extends State<ThemeColorScreen> {
  late SettingsService _settingsService;
  late Color _selectedColor;
  bool _isInitialized = false;

  final List<_ThemeColorOption> _availableColors = const [
    _ThemeColorOption('Focus Indigo', Color(0xFF4F46E5)),
    _ThemeColorOption('Productive Blue', Color(0xFF2563EB)),
    _ThemeColorOption('Momentum Teal', Color(0xFF0F766E)),
    _ThemeColorOption('Growth Green', Color(0xFF16A34A)),
    _ThemeColorOption('Energy Amber', Color(0xFFF59E0B)),
    _ThemeColorOption('Creative Rose', Color(0xFFE11D48)),
    _ThemeColorOption('Deep Purple', Color(0xFF7C3AED)),
    _ThemeColorOption('Calm Cyan', Color(0xFF0891B2)),
  ];

  @override
  void initState() {
    super.initState();
    _settingsService = SettingsService();
    _loadThemeSettings();
  }

  Future<void> _loadThemeSettings() async {
    await _settingsService.init();
    _selectedColor = _settingsService.themeColor;
    if (!mounted) return;
    setState(() => _isInitialized = true);
  }

  void _selectColor(_ThemeColorOption option) {
    setState(() => _selectedColor = option.color);
    _settingsService.themeColor = option.color;
    themeColorNotifier.value = option.color;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tema ${option.name} diterapkan'),
        backgroundColor: option.color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.themeColor),
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
        title: Text(l10n.themeColor),
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
              GlassContainer(
                borderRadius: 20,
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.blueAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.palette_outlined,
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
                                l10n.themeColor,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sesuaikan aksen warna Productivity sesuai gaya kerja Anda.',
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
              GlassContainer(
                borderRadius: 20,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih Warna',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 20),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.35,
                      ),
                      itemCount: _availableColors.length,
                      itemBuilder: (context, index) {
                        final option = _availableColors[index];
                        final color = option.color;
                        final isSelected = color == _selectedColor;

                        return GestureDetector(
                          onTap: () => _selectColor(option),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? color : AppColors.border,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.22),
                                        blurRadius: 18,
                                        offset: const Offset(0, 8),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check,
                                          color: Colors.white, size: 16)
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    option.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              GlassContainer(
                borderRadius: 20,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pratinjau',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _selectedColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _selectedColor.withValues(alpha: 0.34),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _selectedColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.bolt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Productivity',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Warna tema diterapkan ke navigasi, tombol, dan aksen UI.',
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

class _ThemeColorOption {
  final String name;
  final Color color;

  const _ThemeColorOption(this.name, this.color);
}

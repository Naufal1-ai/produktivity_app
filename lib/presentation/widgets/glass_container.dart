import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:productivity/core/theme/app_theme.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blur;
  final Color? color;
  final Border? border;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.padding,
    this.margin,
    this.blur = 20.0,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final effectiveBlur = isMobile ? 0.0 : blur;
    final defaultColor = AppColors.isDark
        ? Colors.white.withValues(alpha: isMobile ? 0.08 : 0.06)
        : Colors.white.withValues(alpha: isMobile ? 0.88 : 0.72);

    final defaultBorder = Border.all(
      color: AppColors.isDark
          ? Colors.white.withValues(alpha: 0.1)
          : AppColors.blueAccent.withValues(alpha: 0.12),
      width: 1.0,
    );

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.isDark
                ? Colors.black.withValues(alpha: 0.14)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: effectiveBlur == 0
            ? _buildContent(defaultColor, defaultBorder)
            : BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: effectiveBlur,
                  sigmaY: effectiveBlur,
                ),
                child: _buildContent(defaultColor, defaultBorder),
              ),
      ),
    );
  }

  Widget _buildContent(Color defaultColor, Border defaultBorder) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? defaultColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? defaultBorder,
      ),
      child: child,
    );
  }
}

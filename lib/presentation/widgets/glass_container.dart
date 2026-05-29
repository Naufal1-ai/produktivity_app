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
  final bool showRetroWindowBar;
  final Color? retroWindowBarColor;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.padding,
    this.margin,
    this.blur = 20.0,
    this.color,
    this.border,
    this.showRetroWindowBar = false,
    this.retroWindowBarColor,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final isSaweriaClassic = AppColors.isSaweriaClassic;
    final effectiveBlur = isMobile || isSaweriaClassic ? 0.0 : blur;
    final defaultColor = isSaweriaClassic
        ? AppColors.bgCard
        : AppColors.isDark
            ? Colors.white.withValues(alpha: isMobile ? 0.08 : 0.06)
            : (isMobile ? Colors.white : Colors.white.withValues(alpha: 0.85));

    final defaultBorderWidth = isSaweriaClassic ? 2.5 : 1.0;
    final defaultBorder = Border.all(
      color: isSaweriaClassic
          ? AppColors.borderAccent
          : AppColors.isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
      width: defaultBorderWidth,
    );

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          if (isSaweriaClassic)
            BoxShadow(
              color: AppColors.retroInk, // Solid hard shadow
              blurRadius: 0,
              offset: const Offset(6, 6), // Classic retro offset thicker
            )
          else
            BoxShadow(
              color: AppColors.isDark
                  ? Colors.black.withValues(alpha: 0.14)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: AppColors.isDark ? 22 : 16,
              offset:
                  AppColors.isDark ? const Offset(0, 10) : const Offset(0, 6),
            )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: effectiveBlur == 0
            ? _buildContent(defaultColor, defaultBorder, isSaweriaClassic, defaultBorderWidth)
            : BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: effectiveBlur,
                  sigmaY: effectiveBlur,
                ),
                child: _buildContent(defaultColor, defaultBorder, isSaweriaClassic, defaultBorderWidth),
              ),
      ),
    );
  }

  Widget _buildContent(Color defaultColor, Border defaultBorder, bool isSaweriaClassic, double borderWidth) {
    Widget content = child;

    if (isSaweriaClassic && showRetroWindowBar) {
      content = Stack(
        fit: StackFit.passthrough,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 28),
            child: Padding(
              padding: padding ?? EdgeInsets.zero,
              child: child,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 28,
              decoration: BoxDecoration(
                color: retroWindowBarColor ?? AppColors.retroBlue,
                border: Border(bottom: BorderSide(color: AppColors.borderAccent, width: borderWidth)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _buildDot(AppColors.retroPink),
                  const SizedBox(width: 6),
                  _buildDot(AppColors.retroYellow),
                  const SizedBox(width: 6),
                  _buildDot(AppColors.retroTeal),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      content = Padding(
        padding: padding ?? EdgeInsets.zero,
        child: child,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: color ?? defaultColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? defaultBorder,
      ),
      child: content,
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.retroInk, width: 1.5),
      ),
    );
  }
}

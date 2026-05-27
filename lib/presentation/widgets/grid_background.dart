import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:productivity/core/theme/app_theme.dart';

/// Inherited widget used to detect if GridBackground is already rendered
/// in the ancestor tree, preventing duplicate ambient orbs.
class _GridBackgroundScope extends InheritedWidget {
  const _GridBackgroundScope({required super.child});

  static bool isInScope(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_GridBackgroundScope>() != null;
  }

  @override
  bool updateShouldNotify(_GridBackgroundScope oldWidget) => false;
}

class GridBackground extends StatelessWidget {
  final Widget child;

  const GridBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    // If already inside a GridBackground, just render child to avoid duplicating orbs
    final alreadyInScope = _GridBackgroundScope.isInScope(context);

    if (alreadyInScope) {
      return _GridBackgroundScope(child: child);
    }

    return _GridBackgroundScope(
      child: Stack(
        children: [
          // iOS style ambient colorful orbs
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.blueAccent.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            top: 200,
            right: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.purple.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: 50,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.income.withValues(alpha: 0.08),
              ),
            ),
          ),

          // Blur layer to blend the orbs into a mesh gradient.
          if (!isMobile)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),

          // Subtle grid overlay
          if (AppColors.isDark)
            Positioned.fill(
              child: CustomPaint(
                painter: _GridPainter(
                  color: AppColors.borderAccent.withValues(alpha: 0.05),
                  spacing: 30.0,
                ),
              ),
            ),

          // Foreground content
          child,
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  final double spacing;

  _GridPainter({required this.color, required this.spacing});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    for (double i = 0; i <= size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i <= size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

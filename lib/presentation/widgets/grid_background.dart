import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:productivity/core/theme/app_theme.dart';

/// Inherited widget used to detect if GridBackground is already rendered
/// in the ancestor tree, preventing duplicate ambient orbs.
class _GridBackgroundScope extends InheritedWidget {
  const _GridBackgroundScope({required super.child});

  static bool isInScope(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_GridBackgroundScope>() !=
        null;
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
    final isSaweriaClassic = AppColors.isSaweriaClassic;

    if (alreadyInScope) {
      return _GridBackgroundScope(child: child);
    }

    return _GridBackgroundScope(
      child: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(
              color:
                  AppColors.bg.withValues(alpha: isSaweriaClassic ? 1 : 0.72),
            ),
          ),
          if (isSaweriaClassic)
            Positioned.fill(
              child: CustomPaint(
                painter: _RetroDotPainter(
                  dotColor: AppColors.retroInk.withValues(alpha: 0.12),
                  ringColor: AppColors.retroTeal.withValues(alpha: 0.18),
                ),
              ),
            ),
          // iOS style ambient colorful orbs
          if (!isSaweriaClassic) ...[
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
          ],

          // Blur layer to blend the orbs into a mesh gradient.
          if (!isMobile && !isSaweriaClassic)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),

          // Subtle grid overlay
          if (AppColors.isDark && !isSaweriaClassic)
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

class _RetroDotPainter extends CustomPainter {
  final Color dotColor;
  final Color ringColor; // kept for compatibility if passed, though unused now

  _RetroDotPainter({required this.dotColor, required this.ringColor});

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    int points = 5;
    double innerRadius = radius / 2.5;
    double step = (math.pi * 2) / points;
    double angle = -math.pi / 2;

    Path path = Path();
    for (int i = 0; i < points; i++) {
      double x = center.dx + radius * math.cos(angle);
      double y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      angle += step / 2;
      path.lineTo(center.dx + innerRadius * math.cos(angle), center.dy + innerRadius * math.sin(angle));
      angle += step / 2;
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()..color = dotColor;
    const spacing = 32.0;

    for (double y = 16; y < size.height; y += spacing) {
      for (double x = 16; x < size.width; x += spacing) {
        // Draw a small star pattern
        _drawStar(canvas, Offset(x, y), 3.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

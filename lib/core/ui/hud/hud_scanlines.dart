// lib/core/ui/hud/hud_scanlines.dart
// Overlay de scanlines horizontal — sutil textura industrial.
// opacity 0.035, líneas cada 3 px. No interactivo. Se desactiva con reduced-motion.
import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_motion.dart';

class HudScanlines extends StatelessWidget {
  final Widget child;
  final double opacity;
  final double lineSpacing;

  const HudScanlines({
    super.key,
    required this.child,
    this.opacity = 0.035,
    this.lineSpacing = 3,
  });

  @override
  Widget build(BuildContext context) {
    if (AppMotion.isReduced(context)) return child;

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _ScanlinePainter(
                opacity: opacity,
                lineSpacing: lineSpacing,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  final double opacity;
  final double lineSpacing;

  const _ScanlinePainter({required this.opacity, required this.lineSpacing});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: opacity)
      ..strokeWidth = 1;

    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      y += lineSpacing;
    }
  }

  @override
  bool shouldRepaint(_ScanlinePainter old) =>
      old.opacity != opacity || old.lineSpacing != lineSpacing;
}

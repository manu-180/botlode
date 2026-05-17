// lib/core/ui/hud/hud_grid_texture.dart
// Retícula técnica tenue para fondos de panel (opacity 0.04).
// CustomPainter — no interactivo.
import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';

class HudGridTexture extends StatelessWidget {
  final Widget? child;
  final double opacity;
  final double cellSize;

  const HudGridTexture({
    super.key,
    this.child,
    this.opacity = 0.04,
    this.cellSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (child != null) child!,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _GridPainter(opacity: opacity, cellSize: cellSize),
            ),
          ),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  final double opacity;
  final double cellSize;

  const _GridPainter({required this.opacity, required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: opacity)
      ..strokeWidth = 0.5;

    // Líneas verticales
    double x = 0;
    while (x <= size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      x += cellSize;
    }

    // Líneas horizontales
    double y = 0;
    while (y <= size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      y += cellSize;
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.opacity != opacity || old.cellSize != cellSize;
}

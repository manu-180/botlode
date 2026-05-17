// lib/core/ui/hud/hud_corner_brackets.dart
// Escuadras de esquina tipo HUD — marcan jerarquía en paneles principales.
// Usar SOLO en paneles primarios, modales y el panel de crédito (no en cada caja).
import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';

class HudCornerBrackets extends StatelessWidget {
  final Widget child;
  final Color color;
  final double armLength;
  final double strokeWidth;
  final EdgeInsets padding;

  const HudCornerBrackets({
    super.key,
    required this.child,
    this.color = AppColors.borderGold,
    this.armLength = 18,
    this.strokeWidth = 1.5,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BracketPainter(
        color: color,
        armLength: armLength,
        strokeWidth: strokeWidth,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _BracketPainter extends CustomPainter {
  final Color color;
  final double armLength;
  final double strokeWidth;

  const _BracketPainter({
    required this.color,
    required this.armLength,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final arm = armLength;
    final w = size.width;
    final h = size.height;

    // ── Top-left ──
    canvas.drawLine(Offset(0, arm), Offset(0, 0), paint);
    canvas.drawLine(Offset(0, 0), Offset(arm, 0), paint);

    // ── Top-right ──
    canvas.drawLine(Offset(w - arm, 0), Offset(w, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, arm), paint);

    // ── Bottom-right ──
    canvas.drawLine(Offset(w, h - arm), Offset(w, h), paint);
    canvas.drawLine(Offset(w, h), Offset(w - arm, h), paint);

    // ── Bottom-left ──
    canvas.drawLine(Offset(arm, h), Offset(0, h), paint);
    canvas.drawLine(Offset(0, h), Offset(0, h - arm), paint);
  }

  @override
  bool shouldRepaint(_BracketPainter old) =>
      old.color != color ||
      old.armLength != armLength ||
      old.strokeWidth != strokeWidth;
}

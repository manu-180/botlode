// lib/core/ui/hud/hud_corner_brackets.dart
// Escuadras de esquina tipo HUD — marcan jerarquía en paneles principales.
// Usar SOLO en paneles primarios, modales y el panel de crédito (no en cada caja).
// No captura puntero (IgnorePointer sobre el painter).
import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';

class HudCornerBrackets extends StatelessWidget {
  final Widget child;
  final Color color;
  final double armLength;
  final double thickness;
  final double inset;
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

  const HudCornerBrackets({
    super.key,
    required this.child,
    this.color = AppColors.borderGold,
    this.armLength = 20,
    this.thickness = 1.5,
    this.inset = 0,
    this.topLeft = true,
    this.topRight = true,
    this.bottomLeft = true,
    this.bottomRight = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _BracketPainter(
                color: color,
                armLength: armLength,
                strokeWidth: thickness,
                inset: inset,
                topLeft: topLeft,
                topRight: topRight,
                bottomLeft: bottomLeft,
                bottomRight: bottomRight,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BracketPainter extends CustomPainter {
  final Color color;
  final double armLength;
  final double strokeWidth;
  final double inset;
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

  const _BracketPainter({
    required this.color,
    required this.armLength,
    required this.strokeWidth,
    required this.inset,
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final arm = armLength;
    final i = inset;
    final l = i;
    final t = i;
    final r = size.width - i;
    final b = size.height - i;

    if (topLeft) {
      canvas.drawLine(Offset(l, t + arm), Offset(l, t), paint);
      canvas.drawLine(Offset(l, t), Offset(l + arm, t), paint);
    }
    if (topRight) {
      canvas.drawLine(Offset(r - arm, t), Offset(r, t), paint);
      canvas.drawLine(Offset(r, t), Offset(r, t + arm), paint);
    }
    if (bottomRight) {
      canvas.drawLine(Offset(r, b - arm), Offset(r, b), paint);
      canvas.drawLine(Offset(r, b), Offset(r - arm, b), paint);
    }
    if (bottomLeft) {
      canvas.drawLine(Offset(l + arm, b), Offset(l, b), paint);
      canvas.drawLine(Offset(l, b), Offset(l, b - arm), paint);
    }
  }

  @override
  bool shouldRepaint(_BracketPainter old) =>
      old.color != color ||
      old.armLength != armLength ||
      old.strokeWidth != strokeWidth ||
      old.inset != inset ||
      old.topLeft != topLeft ||
      old.topRight != topRight ||
      old.bottomLeft != bottomLeft ||
      old.bottomRight != bottomRight;
}

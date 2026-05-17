// Archivo: lib/core/ui/widgets/app_spinner.dart
//
// Regla de uso: AppSpinner es para acciones puntuales (botón enviando) o cargas
// indeterminadas cortas (<300 ms de umbral de decisión). Para contenido estructurado
// usar SkeletonBase / skeleton_patterns.dart.
// Acompañar con texto «Cargando…»/«Procesando…» para lectores de pantalla.

import 'dart:math' show pi;

import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:flutter/material.dart';

class AppSpinner extends StatefulWidget {
  final double size;
  final Color? arcColor;
  final double strokeWidth;

  const AppSpinner({
    super.key,
    this.size = 20,
    this.arcColor,
    this.strokeWidth = 2.5,
  });

  @override
  State<AppSpinner> createState() => _AppSpinnerState();
}

class _AppSpinnerState extends State<AppSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.durTicker, // 900 ms per full rotation
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final arcColor = widget.arcColor ?? AppColors.gold;
    final isGold = arcColor == AppColors.gold;

    // Reduced motion: keep spinning (functional feedback) but skip glow.
    // The rotation itself continues as per spec.

    Widget spinner = AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _SpinnerPainter(
          progress: _controller.value,
          arcColor: arcColor,
          strokeWidth: widget.strokeWidth,
          trackColor: AppColors.borderDefault,
        ),
      ),
    );

    if (isGold && !AppMotion.reduced(context)) {
      // Very subtle glow around the arc — glowGold token, not pulsing.
      spinner = Container(
        width: widget.size,
        height: widget.size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: AppDimens.glowGold,
        ),
        child: spinner,
      );
    } else {
      spinner = SizedBox(width: widget.size, height: widget.size, child: spinner);
    }

    return spinner;
  }
}

class _SpinnerPainter extends CustomPainter {
  final double progress;
  final Color arcColor;
  final double strokeWidth;
  final Color trackColor;

  const _SpinnerPainter({
    required this.progress,
    required this.arcColor,
    required this.strokeWidth,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track: full circle at borderDefault.
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Arc: ~80° (≈1.4 rad) in arcColor, rounded caps, rotating.
    const sweepAngle = 1.4; // ~80 degrees
    final startAngle = (progress * 2 * pi) - (pi / 2);

    final arcPaint = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);
  }

  @override
  bool shouldRepaint(_SpinnerPainter old) =>
      old.progress != progress || old.arcColor != arcColor;
}

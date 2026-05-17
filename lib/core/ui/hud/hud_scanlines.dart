// lib/core/ui/hud/hud_scanlines.dart
// Overlay de scanlines horizontal — sutil textura industrial.
// opacity 0.035, líneas cada 3 px. No interactivo. Se desactiva con reduced-motion.
import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_motion.dart';

class HudScanlines extends StatefulWidget {
  final Widget child;
  final double opacity;
  final double lineSpacing;
  final bool animate;

  const HudScanlines({
    super.key,
    required this.child,
    this.opacity = 0.035,
    this.lineSpacing = 3,
    this.animate = false,
  });

  @override
  State<HudScanlines> createState() => _HudScanlinesState();
}

class _HudScanlinesState extends State<HudScanlines>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppMotion.durScanlinesCycle,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  void _syncAnimation() {
    final reduced = AppMotion.isReduced(context);
    if (widget.animate && !reduced) {
      if (!_ctrl.isAnimating) _ctrl.repeat();
    } else {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void didUpdateWidget(HudScanlines old) {
    super.didUpdateWidget(old);
    _syncAnimation();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.isReduced(context);

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: widget.animate && !reduced
                ? AnimatedBuilder(
                    animation: _ctrl,
                    builder: (_, __) => CustomPaint(
                      painter: _ScanlinePainter(
                        opacity: widget.opacity,
                        lineSpacing: widget.lineSpacing,
                        offsetFraction: _ctrl.value,
                      ),
                    ),
                  )
                : CustomPaint(
                    painter: _ScanlinePainter(
                      opacity: widget.opacity,
                      lineSpacing: widget.lineSpacing,
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
  final double offsetFraction;

  const _ScanlinePainter({
    required this.opacity,
    required this.lineSpacing,
    this.offsetFraction = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: opacity)
      ..strokeWidth = 1;

    final offset = offsetFraction * lineSpacing;
    double y = -lineSpacing + offset;
    while (y < size.height) {
      if (y >= 0) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
      y += lineSpacing;
    }
  }

  @override
  bool shouldRepaint(_ScanlinePainter old) =>
      old.opacity != opacity ||
      old.lineSpacing != lineSpacing ||
      old.offsetFraction != offsetFraction;
}

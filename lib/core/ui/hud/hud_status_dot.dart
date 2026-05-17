// lib/core/ui/hud/hud_status_dot.dart
// Punto de estado con halo de glow pulsante.
// Respeta reduced-motion (sin pulso si está activo reduced-motion).
import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_motion.dart';

enum HudDotStatus { online, warning, offline, processing }

class HudStatusDot extends StatefulWidget {
  final HudDotStatus status;
  final double size;

  const HudStatusDot({
    super.key,
    required this.status,
    this.size = 8,
  });

  @override
  State<HudStatusDot> createState() => _HudStatusDotState();
}

class _HudStatusDotState extends State<HudStatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppMotion.durHeartbeat,
    );
    _pulse = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _updateAnimation();
  }

  @override
  void didUpdateWidget(HudStatusDot old) {
    super.didUpdateWidget(old);
    if (old.status != widget.status) _updateAnimation();
  }

  void _updateAnimation() {
    if (widget.status == HudDotStatus.online ||
        widget.status == HudDotStatus.processing) {
      _ctrl.repeat(reverse: true);
    } else {
      _ctrl.stop();
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _color => switch (widget.status) {
        HudDotStatus.online     => AppColors.success,
        HudDotStatus.warning    => AppColors.warning,
        HudDotStatus.offline    => AppColors.danger,
        HudDotStatus.processing => AppColors.cyan,
      };

  Color get _glow => switch (widget.status) {
        HudDotStatus.online     => AppColors.successGlow,
        HudDotStatus.warning    => AppColors.warningGlow,
        HudDotStatus.offline    => AppColors.dangerGlow,
        HudDotStatus.processing => AppColors.cyanGlow,
      };

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.isReduced(context);
    final shouldAnimate = !reduced &&
        (widget.status == HudDotStatus.online ||
            widget.status == HudDotStatus.processing);

    Widget dot = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: _glow, blurRadius: 8, spreadRadius: 1),
        ],
      ),
    );

    if (shouldAnimate) {
      dot = AnimatedBuilder(
        animation: _pulse,
        builder: (_, child) => Opacity(
          opacity: _pulse.value,
          child: child,
        ),
        child: dot,
      );
    }

    return dot;
  }
}

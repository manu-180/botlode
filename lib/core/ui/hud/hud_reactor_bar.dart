// lib/core/ui/hud/hud_reactor_bar.dart
// Barra de reactor que «late» con glow — indica energía/estado activo.
// Solo latido en estado activo. Respeta reduced-motion.
import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_dimens.dart';
import '../../config/theme/app_motion.dart';

class HudReactorBar extends StatefulWidget {
  final bool active;
  final Color activeColor;
  final Color inactiveColor;
  final double height;
  final double width;
  final bool horizontal;

  const HudReactorBar({
    super.key,
    this.active = true,
    this.activeColor = AppColors.gold,
    this.inactiveColor = AppColors.borderDefault,
    this.height = 3,
    this.width = double.infinity,
    this.horizontal = true,
  });

  @override
  State<HudReactorBar> createState() => _HudReactorBarState();
}

class _HudReactorBarState extends State<HudReactorBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppMotion.durHeartbeat,
    );
    _opacity = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.active) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(HudReactorBar old) {
    super.didUpdateWidget(old);
    if (widget.active != old.active) {
      if (widget.active) {
        _ctrl.repeat(reverse: true);
      } else {
        _ctrl.stop();
        _ctrl.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.isReduced(context);
    final color = widget.active ? widget.activeColor : widget.inactiveColor;
    final glow = widget.active
        ? AppDimens.glowStatus(color)
        : AppDimens.elev0;

    Widget bar = Container(
      width: widget.horizontal ? widget.width : widget.height,
      height: widget.horizontal ? widget.height : widget.width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(widget.height),
        boxShadow: glow,
      ),
    );

    if (widget.active && !reduced) {
      bar = AnimatedBuilder(
        animation: _opacity,
        builder: (_, child) => Opacity(opacity: _opacity.value, child: child),
        child: bar,
      );
    }

    return bar;
  }
}

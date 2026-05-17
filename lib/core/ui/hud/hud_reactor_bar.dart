// lib/core/ui/hud/hud_reactor_bar.dart
// Barra de reactor que «late» con glow — indica energía/estado activo.
// Respeta reduced-motion. No captura puntero.
import 'package:flutter/material.dart';
import '../../config/theme/app_dimens.dart';
import '../../config/theme/app_motion.dart';

class HudReactorBar extends StatefulWidget {
  final Axis axis;
  final double thickness;
  final double? length;
  final Color color;
  final bool pulsing;

  const HudReactorBar({
    super.key,
    this.axis = Axis.vertical,
    this.thickness = 3,
    this.length,
    required this.color,
    this.pulsing = true,
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
      CurvedAnimation(parent: _ctrl, curve: AppMotion.easeStandard),
    );
    if (widget.pulsing) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(HudReactorBar old) {
    super.didUpdateWidget(old);
    if (widget.pulsing != old.pulsing) {
      if (widget.pulsing) {
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
    final isH = widget.axis == Axis.horizontal;
    final len = widget.length;

    Widget bar = Container(
      width: isH ? (len ?? double.infinity) : widget.thickness,
      height: isH ? widget.thickness : (len ?? double.infinity),
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
        boxShadow: AppDimens.glowStatus(widget.color),
      ),
    );

    if (widget.pulsing && !reduced) {
      bar = AnimatedBuilder(
        animation: _opacity,
        builder: (_, child) => Opacity(opacity: _opacity.value, child: child),
        child: bar,
      );
    }

    return bar;
  }
}

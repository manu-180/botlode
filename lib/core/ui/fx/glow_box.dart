// Archivo: lib/core/ui/fx/glow_box.dart
//
// GlowBox — wrapper que aplica un glow tokenizado + sombra de elevación al hijo.
//
// REGLA DE COMPOSICIÓN (§6.4):
//   Un elemento usa exactamente UNA sombra de elevación + COMO MÁXIMO UN glow.
//   GlowBox hace cumplir esto por construcción: [elevation] recibe una sola
//   lista de la escala (elev0..elev3) y [glow]/[statusColor] aportan un único glow.
//   Nunca pasar dos glows; nunca incluir sombras de glow dentro de [elevation].
//
// COMPOSICIONES VÁLIDAS:
//   Card en reposo:           GlowBox(glow: AppGlow.none, elevation: AppDimens.elev1)
//   Card en hover:            GlowBox(glow: AppGlow.gold, elevation: AppDimens.elev2)
//   Botón primario activo:    GlowBox(glow: AppGlow.gold, animated: true, ...)
//   Modal:                    no añadir GlowBox — GlassDecoration.modal trae elev3
//   Estado online:            GlowBox(statusColor: AppColors.success, ...)
//
// COMPOSICIONES PROHIBIDAS:
//   ✗ GlowBox(glow: AppGlow.gold, statusColor: AppColors.danger, ...)  → dos glows
//   ✗ elevation: [...AppDimens.elev2, ...AppDimens.glowGold]            → glow en elevation

import 'package:flutter/material.dart';
import '../../config/theme/app_dimens.dart';
import '../../config/theme/app_motion.dart';

/// Tipos de glow predefinidos. Usar [AppGlow.none] para reposo sin emisión.
enum AppGlow { none, gold, cyan }

/// Envuelve [child] con un [BoxDecoration] que combina una sombra de elevación
/// con un glow tokenizado.
///
/// [glow] — glow predefinido. Ignorado si [statusColor] != null.
/// [statusColor] — color de estado genérico; genera un glow via [AppDimens.glowStatus].
///   Usar para éxito, advertencia, peligro, etc. Tiene prioridad sobre [glow].
/// [elevation] — sombra de elevación de la escala (elev0..elev3). Default elev0.
/// [borderRadius] — radio del DecoratedBox para que el glow siga la forma del hijo.
/// [animated] — si true, el glow late ~1600 ms (P5). Respeta reduced-motion.
class GlowBox extends StatefulWidget {
  final Widget child;
  final AppGlow glow;
  final Color? statusColor;
  final List<BoxShadow> elevation;
  final BorderRadius? borderRadius;
  final bool animated;

  const GlowBox({
    super.key,
    required this.child,
    this.glow = AppGlow.none,
    this.statusColor,
    this.elevation = AppDimens.elev0,
    this.borderRadius,
    this.animated = false,
  });

  @override
  State<GlowBox> createState() => _GlowBoxState();
}

class _GlowBoxState extends State<GlowBox>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _pulse;

  @override
  void initState() {
    super.initState();
    if (widget.animated) _setupController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(GlowBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animated != oldWidget.animated) {
      if (widget.animated) {
        _setupController();
        _syncAnimation();
      } else {
        _controller?.dispose();
        _controller = null;
        _pulse = null;
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _setupController() {
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.durHeartbeat,
    );
    _pulse = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller!, curve: AppMotion.easeStandard),
    );
  }

  void _syncAnimation() {
    final ctrl = _controller;
    if (ctrl == null) return;
    if (AppMotion.reduced(context)) {
      ctrl.stop();
      ctrl.value = 1.0;
    } else if (!ctrl.isAnimating) {
      ctrl.repeat(reverse: true);
    }
  }

  List<BoxShadow> _resolveGlow() {
    if (widget.statusColor != null) {
      return AppDimens.glowStatus(widget.statusColor!);
    }
    return switch (widget.glow) {
      AppGlow.gold => AppDimens.glowGold,
      AppGlow.cyan => AppDimens.glowCyan,
      AppGlow.none => const [],
    };
  }

  List<BoxShadow> _scaledGlow(double factor) {
    final base = _resolveGlow();
    if (base.isEmpty) return base;
    final s = base.first;
    return [
      BoxShadow(
        color: s.color.withValues(alpha: s.color.a * factor),
        blurRadius: s.blurRadius,
        spreadRadius: s.spreadRadius,
        offset: s.offset,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.animated && _pulse != null) {
      return AnimatedBuilder(
        animation: _pulse!,
        builder: (context, child) {
          final glowList = AppMotion.reduced(context)
              ? _resolveGlow()
              : _scaledGlow(_pulse!.value);
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              boxShadow: [...widget.elevation, ...glowList],
            ),
            child: child,
          );
        },
        child: widget.child,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        boxShadow: [...widget.elevation, ..._resolveGlow()],
      ),
      child: widget.child,
    );
  }
}

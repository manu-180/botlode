// Archivo: lib/core/ui/widgets/skeleton_base.dart
//
// Regla de uso: mostrar skeleton cuando una carga de contenido estructurado
// puede superar 300 ms. Por debajo de ese umbral, no mostrar nada.
// Crossfade skeleton→contenido: AnimatedSwitcher(duration: AppMotion.durBase,
// switchInCurve: AppMotion.easeStandard, switchOutCurve: AppMotion.easeStandard).

import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SkeletonBase extends StatelessWidget {
  final double? width;
  final double? height;
  final double radius;
  final BoxShape shape;
  final EdgeInsetsGeometry? margin;

  const SkeletonBase({
    super.key,
    this.width,
    this.height,
    this.radius = AppDimens.radiusS,
    this.shape = BoxShape.rectangle,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduced(context);

    final box = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.surfaceHud,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle
            ? BorderRadius.circular(radius)
            : null,
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1,
        ),
      ),
    );

    if (reduce) {
      // Reduced motion: slow opacity pulse (0.6↔1.0), no diagonal sweep.
      return Semantics(
        label: 'Cargando',
        liveRegion: false,
        child: ExcludeSemantics(
          child: box
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fadeIn(
                begin: 0.6,
                duration: AppMotion.durHeartbeat,
                curve: AppMotion.easeStandard,
              ),
        ),
      );
    }

    // Full motion: diagonal golden sheen sweep — barely perceptible, «caro y silencioso».
    return Semantics(
      label: 'Cargando',
      liveRegion: false,
      child: ExcludeSemantics(
        child: box
            .animate(onPlay: (c) => c.repeat())
            .shimmer(
              duration: AppMotion.durSkeletonCycle,
              color: AppColors.goldBright.withValues(alpha: 0.06),
              angle: 0.25,
            ),
      ),
    );
  }
}

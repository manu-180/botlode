// lib/core/ui/decorations/glass_decoration.dart
// GlassDecoration: BoxDecoration con glassmorphism + borde hairline.
// GlassPanel: widget conveniente con BackdropFilter + blur.
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_dimens.dart';

/// Decoración de vidrio sin blur (para contenedores que no necesitan BackdropFilter).
class GlassDecoration {
  static BoxDecoration standard({
    BorderRadius? borderRadius,
    bool strong = false,
    Color? borderColor,
    List<BoxShadow>? boxShadow,
  }) =>
      BoxDecoration(
        color: strong ? AppColors.glassSurfaceStrong : AppColors.glassSurface,
        borderRadius: borderRadius ?? AppDimens.brL,
        border: Border.all(
          color: borderColor ?? AppColors.glassBorder,
          width: 1,
        ),
        boxShadow: boxShadow ?? AppDimens.elev1,
      );

  /// Variante dorada para paneles de énfasis.
  static BoxDecoration gold({BorderRadius? borderRadius}) => BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: borderRadius ?? AppDimens.brL,
        border: Border.all(color: AppColors.borderGold, width: 1),
        boxShadow: AppDimens.glowGold,
      );

  /// Variante cyan para paneles de datos activos.
  static BoxDecoration cyan({BorderRadius? borderRadius}) => BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: borderRadius ?? AppDimens.brL,
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: AppDimens.glowCyan,
      );
}

/// Panel de vidrio real con BackdropFilter (blur).
/// Usar para overlays y modales donde el blur añade profundidad real.
/// NOTA: BackdropFilter es costoso — no usar en listas largas.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final double blur;
  final bool strong;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final List<BoxShadow>? boxShadow;

  const GlassPanel({
    super.key,
    required this.child,
    this.blur = 12,
    this.strong = false,
    this.borderRadius,
    this.borderColor,
    this.padding,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? AppDimens.brL;

    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: GlassDecoration.standard(
            borderRadius: br,
            strong: strong,
            borderColor: borderColor,
            boxShadow: boxShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}

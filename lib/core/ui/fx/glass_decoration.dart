// Archivo: lib/core/ui/fx/glass_decoration.dart
//
// GlassDecoration — factory canónica de BoxDecoration para superficies de vidrio.
//
// RECETA CANÓNICA — PANEL DE VIDRIO ESTÁNDAR:
//   FrostedBlur(
//     sigma: 14,
//     clip: AppDimens.brL,
//     child: Container(
//       decoration: GlassDecoration.panel(gradientFill: true),
//       child: ...,
//     ),
//   )
//   // + opcionalmente HudCornerBrackets alrededor para paneles jerárquicos.
//
// REGLA: GlassDecoration NO aplica blur — lo hace FrostedBlur.
// REGLA: GlassDecoration NO aplica glows — los pone GlowBox.
// REGLA: una sombra de elevación + como máximo un glow (gestionado por GlowBox).
//
// El highlight superior de 1 px se logra usando Border con top = glassHighlightTop
// y los demás lados = borderDefault. Resultado: borde superior ~1 px más claro,
// simulando el reflejo de luz en el canto del cristal (§3.1.3, §4.2).

import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_dimens.dart';

/// Factory de [BoxDecoration] para superficies de vidrio esmerilado.
/// No instanciar directamente — usar los factory methods estáticos.
class GlassDecoration {
  GlassDecoration._();

  // ─── PANEL ───────────────────────────────────────────────────────────────

  /// Panel de vidrio estándar. Combinar con [FrostedBlur] para esmerilado real.
  ///
  /// [gradientFill] — si true, usa [AppColors.gradPanel] en vez del color plano.
  /// [radius] — radio de esquinas; default [AppDimens.radiusL].
  /// [fill] — color de relleno; ignorado si [gradientFill] es true.
  /// [border] — borde completo; si null, genera borde con highlight superior.
  /// [shadow] — sombra de elevación; default [AppDimens.elev1].
  static BoxDecoration panel({
    double radius = AppDimens.radiusL,
    Color? fill,
    Border? border,
    List<BoxShadow>? shadow,
    bool gradientFill = false,
  }) {
    final br = BorderRadius.circular(radius);
    return BoxDecoration(
      color: gradientFill ? null : (fill ?? AppColors.glassSurface),
      gradient: gradientFill ? AppColors.gradPanel : null,
      borderRadius: br,
      border: border ?? _highlightBorder(),
      boxShadow: shadow ?? AppDimens.elev1,
    );
  }

  // ─── MODAL ───────────────────────────────────────────────────────────────

  /// Superficie de modal (más opaca → mayor legibilidad del contenido).
  /// No añadir glow sobre modales; el glow distraería del contenido.
  ///
  /// [radius] — default [AppDimens.radiusXL].
  /// [fill] — default [AppColors.glassSurfaceStrong].
  /// [shadow] — default [AppDimens.elev3].
  static BoxDecoration modal({
    double radius = AppDimens.radiusXL,
    Color? fill,
    Border? border,
    List<BoxShadow>? shadow,
  }) {
    final br = BorderRadius.circular(radius);
    return BoxDecoration(
      color: fill ?? AppColors.glassSurfaceStrong,
      borderRadius: br,
      border: border ?? _highlightBorder(),
      boxShadow: shadow ?? AppDimens.elev3,
    );
  }

  // ─── HUD ─────────────────────────────────────────────────────────────────

  /// Superficie HUD/terminal: fondo oscuro y sólido, sin transparencia.
  /// Uso: overlays de lecturas de datos, readouts de estado de bot.
  ///
  /// [radius] — default [AppDimens.radiusM].
  static BoxDecoration hud({
    double radius = AppDimens.radiusM,
    Color? fill,
    Border? border,
    List<BoxShadow>? shadow,
  }) {
    final br = BorderRadius.circular(radius);
    return BoxDecoration(
      color: fill ?? AppColors.surfaceHud,
      borderRadius: br,
      border: border ??
          Border.all(color: AppColors.borderDefault, width: 1),
      boxShadow: shadow ?? AppDimens.elev1,
    );
  }

  // ─── INTERNO ─────────────────────────────────────────────────────────────

  /// Borde con highlight de 1 px en el lado superior (§3.1.3 «la luz tiene fuente»).
  /// El borde superior usa [AppColors.glassHighlightTop] (~6 % blanco);
  /// los demás lados usan [AppColors.borderDefault] (~10 % blanco).
  static Border _highlightBorder() => const Border(
        top: BorderSide(color: AppColors.glassHighlightTop, width: 1),
        left: BorderSide(color: AppColors.borderDefault, width: 1),
        right: BorderSide(color: AppColors.borderDefault, width: 1),
        bottom: BorderSide(color: AppColors.borderDefault, width: 1),
      );
}

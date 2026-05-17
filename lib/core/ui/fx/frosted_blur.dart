// Archivo: lib/core/ui/fx/frosted_blur.dart
//
// FrostedBlur — encapsula BackdropFilter + ImageFilter.blur para esmerilado real.
//
// REGLAS DE PERFORMANCE (leer antes de usar):
//   1. Usar el menor sigma que se vea bien — default 14; modales 18–22.
//   2. NO anidar un FrostedBlur dentro de otro FrostedBlur.
//   3. NO usar FrostedBlur en ítems de listas largas que scrollean —
//      preferir GlassDecoration con color sólido/semitransparente sin blur.
//   4. SIEMPRE pasar [clip] coincidiendo con el radio del Container interior
//      para que el blur no se derrame fuera de la forma.
//
// USO TÍPICO (combinar con GlassDecoration.panel):
//   FrostedBlur(
//     sigma: 14,
//     clip: AppDimens.brL,
//     child: Container(
//       decoration: GlassDecoration.panel(gradientFill: true),
//       child: ...,
//     ),
//   )
//
// Para scrim de modales usar sigma 20:
//   FrostedBlur(sigma: 20, clip: AppDimens.brXL, child: ...)

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../config/theme/app_dimens.dart';

/// Encapsula [BackdropFilter] con [ImageFilter.blur] y recorte [ClipRRect].
///
/// [sigma] — intensidad del blur (sigmaX = sigmaY). Default 14.
///   Paneles: 12–16. Scrims de modal: 18–22. No exceder 24 en desktop.
/// [clip] — [BorderRadius] de recorte; debe coincidir con el del contenedor
///   hijo. Default [AppDimens.brL].
class FrostedBlur extends StatelessWidget {
  final Widget child;
  final double sigma;
  final BorderRadius? clip;

  const FrostedBlur({
    super.key,
    required this.child,
    this.sigma = 14,
    this.clip,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: clip ?? AppDimens.brL,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: child,
      ),
    );
  }
}

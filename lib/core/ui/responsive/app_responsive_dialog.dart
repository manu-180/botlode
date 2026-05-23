// Archivo: lib/core/ui/responsive/app_responsive_dialog.dart
//
// Helper para envolver diálogos con constraints responsivos. En mobile el
// `insetPadding` por defecto deja muy poco margen y el contenido tiende a
// pegarse al borde; en desktop conviene limitar `maxWidth` para que diálogos
// muy anchos no se vean ridículos.
//
// Uso típico:
//   showDialog(
//     context: context,
//     builder: (_) => AppResponsiveDialog(
//       maxWidth: 480,
//       child: ...,
//     ),
//   );

import 'package:flutter/material.dart';

class AppResponsiveDialog extends StatelessWidget {
  const AppResponsiveDialog({
    super.key,
    required this.child,
    this.maxWidth = 480,
    this.maxHeightFraction = 0.92,
    this.backgroundColor,
    this.shape,
  });

  final Widget child;
  final double maxWidth;
  final double maxHeightFraction;
  final Color? backgroundColor;
  final ShapeBorder? shape;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final isMobile = media.width < 600;
    final maxHeight = media.height * maxHeightFraction;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 40,
        vertical: isMobile ? 24 : 24,
      ),
      backgroundColor: backgroundColor,
      shape: shape,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        ),
        child: SingleChildScrollView(child: child),
      ),
    );
  }
}

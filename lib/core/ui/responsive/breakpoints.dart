// Archivo: lib/core/ui/responsive/breakpoints.dart
//
// Breakpoints y helpers para layouts responsive. Centraliza los anchos donde
// la app cambia de "mobile" → "tablet" → "desktop" para que los widgets no
// inventen sus propios umbrales.
//
// Convención:
//   < 600  → mobile  (phones portrait)
//   < 1024 → tablet  (tablets, phones landscape, small laptops)
//   ≥ 1024 → desktop (laptops, monitores)

import 'package:flutter/widgets.dart';

enum FormFactor { mobile, tablet, desktop }

class Breakpoints {
  const Breakpoints._();

  static const double mobileMax = 600;
  static const double tabletMax = 1024;

  /// Devuelve el form factor a partir del ancho actual.
  static FormFactor fromWidth(double width) {
    if (width < mobileMax) return FormFactor.mobile;
    if (width < tabletMax) return FormFactor.tablet;
    return FormFactor.desktop;
  }

  /// Helper para usar desde un BuildContext sin LayoutBuilder.
  static FormFactor of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return fromWidth(width);
  }

  /// True si el ancho actual es mobile.
  static bool isMobile(BuildContext context) =>
      of(context) == FormFactor.mobile;

  /// True si el ancho actual es tablet.
  static bool isTablet(BuildContext context) =>
      of(context) == FormFactor.tablet;

  /// True si el ancho actual es desktop.
  static bool isDesktop(BuildContext context) =>
      of(context) == FormFactor.desktop;

  /// True si NO es mobile (tablet o desktop).
  static bool isAtLeastTablet(BuildContext context) =>
      of(context) != FormFactor.mobile;

  /// Padding horizontal recomendado por form factor.
  static double horizontalPadding(FormFactor ff) => switch (ff) {
        FormFactor.mobile => 16,
        FormFactor.tablet => 24,
        FormFactor.desktop => 32,
      };

  /// maxCrossAxisExtent recomendado para grids con tarjetas tipo tile.
  static double gridTileExtent(FormFactor ff) => switch (ff) {
        FormFactor.mobile => 220,
        FormFactor.tablet => 320,
        FormFactor.desktop => 400,
      };
}

/// Widget builder que pasa el form factor actual a su hijo.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, FormFactor formFactor) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ff = Breakpoints.fromWidth(constraints.maxWidth);
        return builder(context, ff);
      },
    );
  }
}

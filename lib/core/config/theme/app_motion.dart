// lib/core/config/theme/app_motion.dart
// Sistema de motion «Hangar OS»: duraciones, curvas, reduced-motion.
// Todas las animaciones DEBEN usar estos tokens. Cero magic numbers de ms/curva fuera.
import 'package:flutter/material.dart';

class AppMotion {
  // ─── DURACIONES ───────────────────────────────────────────────────────────
  static const Duration durInstant    = Duration(milliseconds: 90);   // color en hover/press
  static const Duration durFast       = Duration(milliseconds: 160);  // micro-interacciones
  static const Duration durBase       = Duration(milliseconds: 240);  // transiciones estándar
  static const Duration durSlow       = Duration(milliseconds: 320);  // entradas de modal
  static const Duration durDeliberate = Duration(milliseconds: 420);  // reveals escénicos
  static const Duration durTicker     = Duration(milliseconds: 900);  // conteo numérico

  // Salida = ~65 % de la entrada
  static const Duration durFastExit   = Duration(milliseconds: 100);
  static const Duration durBaseExit   = Duration(milliseconds: 155);
  static const Duration durSlowExit   = Duration(milliseconds: 210);

  // Shimmer / latido (largo)
  static const Duration durShimmer    = Duration(milliseconds: 3100);
  static const Duration durHeartbeat  = Duration(milliseconds: 1600);

  // Escalonado de listas
  static const Duration durStagger    = Duration(milliseconds: 36);

  // ─── CURVAS ───────────────────────────────────────────────────────────────
  /// Entrada premium (expo-out).
  static const Curve easeEntrance = Cubic(0.16, 1.0, 0.3, 1.0);

  /// Salida estándar.
  static const Curve easeExit = Cubic(0.4, 0.0, 1.0, 1.0);

  /// Transiciones de estado generales.
  static const Curve easeStandard = Curves.easeInOutCubic;

  /// Para conteo de cifras.
  static const Curve easeTicker = Curves.easeOutExpo;

  /// Hover suave.
  static const Curve easeHover = Curves.easeOut;

  // ─── SPRING ───────────────────────────────────────────────────────────────
  static const SpringDescription springSoft = SpringDescription(
    mass: 1,
    stiffness: 90,
    damping: 20,
  );

  // ─── REDUCED MOTION ───────────────────────────────────────────────────────
  /// Lee la preferencia del sistema operativo / accesibilidad de Flutter.
  /// Usar en cada widget que anima para respetar la accesibilidad.
  static bool isReduced(BuildContext context) =>
      MediaQuery.of(context).disableAnimations;

  /// Duración efectiva: si reduced-motion está activo devuelve durInstant,
  /// si no devuelve el valor normal.
  static Duration effective(BuildContext context, Duration normal) =>
      isReduced(context) ? durInstant : normal;

  /// Curva efectiva: si reduced-motion está activo devuelve linear.
  static Curve effectiveCurve(BuildContext context, Curve normal) =>
      isReduced(context) ? Curves.linear : normal;

  // ─── PATRONES ─────────────────────────────────────────────────────────────

  /// Retraso de entrada escalonada para el ítem `index` de una lista.
  /// Máximo 10 ítems escalonados; el resto entra sin retraso adicional.
  static Duration staggerDelay(int index) =>
      Duration(milliseconds: durStagger.inMilliseconds * index.clamp(0, 10));

  /// Offset de slide de entrada/salida de pantalla (16 px).
  static const double slideOffset = 16.0;

  /// Escala de press para elementos interactivos.
  static const double pressScale = 0.97;
}

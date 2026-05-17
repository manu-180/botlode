// Archivo: lib/core/config/theme/app_motion.dart
//
// Sistema de motion «Hangar OS» — fuente única de verdad de duraciones, curvas,
// física de resorte y reduced-motion. Ningún widget puede usar una Duration
// mágica ni una Curve inventada: toda animación referencia un token de AppMotion.
//
// Regla: ninguna animación de UI supera durDeliberate (420 ms).
// Las animaciones son interrumpibles y nunca bloquean el input.
//
// USO:
//   AnimatedScale(duration: AppMotion.durInstant, curve: AppMotion.easeEntrance, ...)
//   AnimatedContainer(duration: AppMotion.durFast, curve: AppMotion.easeStandard, ...)
//   final reduce = AppMotion.reduced(context); // gating de shimmer/latido/blobs
//   duración de salida: AppMotion.exitOf(AppMotion.durSlow)

import 'package:flutter/material.dart';

class AppMotion {
  AppMotion._();

  // --- DURACIONES ---

  static const Duration durInstant    = Duration(milliseconds: 90);   // color en hover/press
  static const Duration durFast       = Duration(milliseconds: 160);  // micro-interacciones, hover de card
  static const Duration durBase       = Duration(milliseconds: 240);  // transiciones estándar (paneles, tabs)
  static const Duration durSlow       = Duration(milliseconds: 320);  // entrada de modal, transición de pantalla
  static const Duration durDeliberate = Duration(milliseconds: 420);  // reveals escénicos (TOPE de UI)
  static const Duration durTicker     = Duration(milliseconds: 900);  // conteo de cifras numéricas

  /// Devuelve ~65 % de la duración de entrada (regla de salida §7.1).
  static Duration exitOf(Duration entrance) =>
      Duration(milliseconds: (entrance.inMilliseconds * 0.65).round());

  // Duraciones auxiliares para componentes específicos
  static const Duration durShimmer   = Duration(milliseconds: 3100); // ciclo de shimmer
  static const Duration durHeartbeat = Duration(milliseconds: 1600); // latido de reactor
  static const Duration durStagger   = Duration(milliseconds: 36);   // delay por ítem en listas

  // --- CURVAS ---

  /// Entrada premium expo-out: entradas de elementos, press release.
  static const Cubic easeEntrance = Cubic(0.16, 1.0, 0.3, 1.0);

  /// Salida estándar.
  static const Cubic easeExit = Cubic(0.4, 0.0, 1.0, 1.0);

  /// Transiciones de estado generales (hover, focus, estado).
  static const Curve easeStandard = Curves.easeInOutCubic;

  /// Para conteo de cifras (HudTicker).
  static const Curve easeTicker = Curves.easeOutExpo;

  /// Hover suave (solo desktop).
  static const Curve easeHover = Curves.easeOut;

  // --- RESORTE ---
  //
  // Se usa con SpringSimulation o AnimationController.animateWith para modales,
  // paneles y press de cards. Para press simple basta AnimatedScale con
  // easeEntrance; el resorte se reserva para reveals que se sienten físicos.
  static const SpringDescription springSoft = SpringDescription(
    mass: 1.0,
    stiffness: 90.0,
    damping: 20.0,
  );

  // --- REDUCED MOTION ---

  /// Devuelve true si el usuario pidió reducir animaciones (accesibilidad del SO).
  /// Cuando es true: sin shimmer, sin latidos, sin parallax/blobs;
  /// las transiciones se degradan a crossfade de durCrossfadeReduced.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  /// Duración a usar para el crossfade de reemplazo cuando reduced == true.
  static const Duration durCrossfadeReduced = Duration(milliseconds: 120);

  // Patrón de consumo:
  // todo widget que anime debe evaluar al inicio del build:
  //   final reduce = AppMotion.reduced(context);
  // - si reduce → usar durCrossfadeReduced + Curves.linear, sin shimmer/latido/blobs
  // - si no    → usar el token de duración/curva normal

  // --- CONSTANTES DE LAYOUT ---

  /// Offset de slide de entrada/salida de pantalla (px).
  static const double slideOffset = 16.0;

  /// Escala de press para elementos interactivos.
  static const double pressScale = 0.97;

  // --- HELPERS ---

  /// Retraso de entrada escalonada para el ítem [index] de una lista.
  /// Máximo 10 ítems escalonados; el resto entra sin retraso adicional.
  static Duration staggerDelay(int index) =>
      Duration(milliseconds: durStagger.inMilliseconds * index.clamp(0, 10));
}

// --- PATRONES (referencia para prompts 05–65) ---
//
// Los prompts de pantalla citan estos patrones por nombre. No son código;
// son la receta exacta que cada widget debe seguir.
//
// P1 · ESCALONADO DE LISTAS / GRILLAS
//   Cada ítem entra 36 ms después del anterior.
//   Animación por ítem: fade 0→1 + translateY 12→0 px, easeEntrance, durBase.
//   Máximo ~10 ítems escalonados (el ítem 11+ entra sin retraso adicional).
//   Implementación: flutter_animate con
//     .animate(delay: (index.clamp(0,10) * 36).ms)
//   o AnimationController con Interval por ítem.
//
// P2 · PRESS DE ELEMENTOS CLICKEABLES
//   onTapDown / onPointerDown → escala a 0.97 con durInstant + easeEntrance.
//   Al soltar / cancelar      → vuelve a 1.0 con durFast.
//   Usar AnimatedScale. No resorte; basta la curva expo-out.
//
// P3 · HOVER (desktop)
//   Al entrar puntero (MouseRegion): sube elevación +1 nivel, borde a
//   borderStrong/borderGold, aparece glow suave; todo con durFast + easeStandard.
//   Al salir: inverso con durFast.
//   Cursor: SystemMouseCursors.click.
//
// P4 · SHIMMER
//   Barrido de AppColors.gradGoldSheen que cruza el elemento cada 2800–3400 ms
//   (valor fijo por componente dentro del rango; no aleatorio por frame).
//   Solo en elementos activos clave (botón primario activo, panel de crédito),
//   nunca en todos.
//   SE DESACTIVA con AppMotion.reduced(context).
//
// P5 · REACTOR / LATIDO
//   Pulso de opacidad 0.6 ↔ 1.0 con período ~1600 ms (durHeartbeat),
//   curva easeStandard, AnimationController en repeat(reverse: true).
//   Solo en estado activo (un reactor offline no late).
//   SE DESACTIVA con AppMotion.reduced(context).
//
// P6 · TRANSICIÓN DE PANTALLA (go_router)
//   Fade 0→1 + slide direccional de 16 px (slideOffset).
//   Duración: durSlow. Curva: easeEntrance al entrar / easeExit al salir.
//   Avanzar = pantalla entrante viene desde derecha/abajo (+16 px); volver = inverso.
//   Con AppMotion.reduced: crossfade puro de durCrossfadeReduced, sin slide.
//
// P7 · CONTEO DE CIFRAS (HudTicker)
//   Interpola el valor con durTicker + easeTicker.
//   Con AppMotion.reduced: el valor aparece directo, sin conteo animado.

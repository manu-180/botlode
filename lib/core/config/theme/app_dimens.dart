// Archivo: lib/core/config/theme/app_dimens.dart
// Tokens de dimensión «Hangar OS»: espaciado, radios, chaflán, elevación, z-index.
// Base: rejilla de 4 px. NO usar magic numbers fuera de este archivo.
//
// USO:
// padding:      EdgeInsets.all(AppDimens.space20)
// gap:          SizedBox(height: AppDimens.space16)
// radio:        borderRadius: AppDimens.brL
// card reposo:  boxShadow: AppDimens.elev1
// card hover:   boxShadow: [...AppDimens.elev2, ...AppDimens.glowGold]
// glow estado:  boxShadow: AppDimens.glowStatus(AppColors.success)
// chaflán:      el ShapeBorder lo provee el prompt 06 con AppDimens.chamferM
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppDimens {
  AppDimens._();

  // --- ESPACIADO (escala 4px) ---
  // Padding interno de cards:         space20 o space24
  // Gap entre cards de grilla:        space20
  // Padding horizontal de pantalla (desktop): space32
  // Gaps de jerarquía de sección:     space16 / space24 / space32 / space48
  static const double space2  = 2;
  static const double space4  = 4;
  // space8 × 2 + iconM 22 px = 38 px ≥ 32 px mínimo de hit target (§10 del archivo 00).
  static const double space8  = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space40 = 40;
  static const double space48 = 48;
  static const double space64 = 64;

  // Aliases semánticos de espaciado
  static const double paddingCard       = space20;
  static const double paddingCardLarge  = space24;
  static const double paddingScreen     = space32; // horizontal en desktop
  static const double gapCard           = space20; // gap entre cards en grilla

  // --- RADIOS ---
  static const double radiusXS   = 6;    // chips compactos, micro-elementos
  static const double radiusS    = 10;   // badges, tags pequeños
  static const double radiusM    = 14;   // inputs y botones
  static const double radiusL    = 20;   // cards y paneles
  static const double radiusXL   = 28;   // modales
  static const double radiusPill = 999;  // pills/chips redondeados

  static BorderRadius get brXS   => BorderRadius.circular(radiusXS);
  static BorderRadius get brS    => BorderRadius.circular(radiusS);
  static BorderRadius get brM    => BorderRadius.circular(radiusM);
  static BorderRadius get brL    => BorderRadius.circular(radiusL);
  static BorderRadius get brXL   => BorderRadius.circular(radiusXL);
  static BorderRadius get brPill => BorderRadius.circular(radiusPill);

  // --- CHAFLÁN HUD (chamfer 45°) ---
  // El ShapeBorder/ClipPath que consume chamferM lo define el prompt 06
  // (ChamferBorder/ChamferClipper). El chaflán es para acentos jerárquicos
  // (paneles HUD, botón primario destacado, marcos de tabs), NO para todas las cajas.
  static const double chamferM = 12;

  // --- ELEVACIÓN (sombras) ---
  // Regla: un elemento usa UNA sombra de elevación + OPCIONALMENTE UN glow.
  // Nunca dos glows. Nunca sombras fuera de esta escala.
  // Para combinar: boxShadow: [...AppDimens.elev1, ...AppDimens.glowGold]
  //
  // Estados cubiertos:
  //   default  → elev1
  //   hover    → elev2 + glow opcional
  //   pressed  → elev1 (el elemento se «hunde»)
  //   active   → elev1 + glow estable
  //   modal    → elev3
  static const List<BoxShadow> elev0 = <BoxShadow>[];

  static const List<BoxShadow> elev1 = [
    BoxShadow(color: Color(0x66000000), offset: Offset(0, 2), blurRadius: 8),
  ];

  static const List<BoxShadow> elev2 = [
    BoxShadow(color: Color(0x80000000), offset: Offset(0, 8), blurRadius: 24),
  ];

  static const List<BoxShadow> elev3 = [
    BoxShadow(color: Color(0x99000000), offset: Offset(0, 16), blurRadius: 48),
  ];

  // --- GLOWS (emisión) ---
  static const List<BoxShadow> glowGold = [
    BoxShadow(color: AppColors.goldGlow, blurRadius: 24, spreadRadius: 1),
  ];

  static const List<BoxShadow> glowCyan = [
    BoxShadow(color: AppColors.cyanGlow, blurRadius: 20, spreadRadius: 1),
  ];

  static List<BoxShadow> glowStatus(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.28),
      blurRadius: 18,
      spreadRadius: 1,
    ),
  ];

  // --- Z-INDEX / CAPAS ---
  // Flutter no tiene z-index nativo. Estas constantes documentan el orden lógico
  // de capas y se usan para ordenar hijos en un Stack o como elevation lógica.
  // Garantía: scrims (zOverlay) quedan bajo modales (zModal), y estos bajo
  // toasts (zToast), asegurando que el foco y liveRegions siempre estén encima.
  static const int zBase             = 0;
  static const int zContent          = 10;
  static const int zSticky           = 20;   // toolbars sticky
  static const int zSidebar          = 30;
  static const int zTitleBar         = 40;
  static const int zOverlay          = 100;  // scrims
  static const int zModal            = 110;
  static const int zToast            = 200;
  static const int zEpicNotification = 300;

  // --- ICONOS (tamaños) ---
  // iconM es el default. iconL se reserva para jerarquía.
  // Un botón solo-ícono debe alcanzar 32×32 px de área de hit:
  // iconM 22 + space8×2 = 38 px ≥ 32 px mínimo (§10 del archivo 00).
  static const double iconXS = 14; // iconos inline en texto pequeño, badges
  static const double iconS  = 18; // iconos en labels, inputs, chips
  static const double iconM  = 22; // tamaño por defecto: botones, nav, toolbars
  static const double iconL  = 28; // iconos de encabezado, estados vacíos, acentos

  // --- HIT TARGETS ---
  static const double hitTargetMin   = 32; // mínimo desktop (§10)
  static const double hitTargetTouch = 44; // recomendado táctil

  // --- SIDEBAR ---
  static const double sidebarWidth         = 72;  // colapsado
  static const double sidebarWidthExpanded = 220;

  // --- TITLE BAR ---
  static const double titleBarHeight = 36;

  // --- VENTANA ---
  static const double windowMinWidth   = 1024;
  static const double windowMinHeight  = 600;
  static const double windowInitWidth  = 1280;
  static const double windowInitHeight = 720;
}

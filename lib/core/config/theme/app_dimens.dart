// lib/core/config/theme/app_dimens.dart
// Tokens de dimensión «Hangar OS»: espaciado, radios, chaflán, elevación, z-index.
// Base: rejilla de 4 px. NO usar magic numbers fuera de este archivo.
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppDimens {
  // ─── ESPACIADO ────────────────────────────────────────────────────────────
  static const double space2  = 2;
  static const double space4  = 4;
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
  static const double paddingCard      = space20;
  static const double paddingCardLarge = space24;
  static const double paddingScreen    = space32;  // horizontal en desktop
  static const double gapCard          = space20;  // gap entre cards en grilla

  // ─── RADIOS ───────────────────────────────────────────────────────────────
  static const double radiusXS   = 6;
  static const double radiusS    = 10;
  static const double radiusM    = 14;   // inputs, botones
  static const double radiusL    = 20;   // cards, paneles
  static const double radiusXL   = 28;   // modales
  static const double radiusPill = 999;  // badges, chips

  static BorderRadius get brXS   => BorderRadius.circular(radiusXS);
  static BorderRadius get brS    => BorderRadius.circular(radiusS);
  static BorderRadius get brM    => BorderRadius.circular(radiusM);
  static BorderRadius get brL    => BorderRadius.circular(radiusL);
  static BorderRadius get brXL   => BorderRadius.circular(radiusXL);
  static BorderRadius get brPill => BorderRadius.circular(radiusPill);

  // ─── CHAFLÁN HUD (chamfer 45°) ────────────────────────────────────────────
  // Recorte de esquina para paneles HUD y botones destacados.
  static const double chamferM = 12;

  // ─── ESCALA DE ELEVACIÓN (sombras) ────────────────────────────────────────
  static List<BoxShadow> get elev0 => const [];

  static List<BoxShadow> get elev1 => const [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.4),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get elev2 => const [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.5),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get elev3 => const [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.6),
      blurRadius: 48,
      offset: Offset(0, 16),
    ),
  ];

  static List<BoxShadow> get glowGold => const [
    BoxShadow(
      color: AppColors.goldGlow,
      blurRadius: 24,
      spreadRadius: 1,
    ),
  ];

  static List<BoxShadow> get glowCyan => const [
    BoxShadow(
      color: AppColors.cyanGlow,
      blurRadius: 20,
    ),
  ];

  static List<BoxShadow> glowStatus(Color color) => [
    BoxShadow(
      color: AppColors.glowStatus(color),
      blurRadius: 18,
    ),
  ];

  // ─── Z-INDEX / CAPAS ──────────────────────────────────────────────────────
  static const int zBase              = 0;
  static const int zContent           = 10;
  static const int zSticky            = 20;
  static const int zSidebar           = 30;
  static const int zTitleBar          = 40;
  static const int zOverlay           = 100;
  static const int zModal             = 110;
  static const int zToast             = 200;
  static const int zEpicNotification  = 300;

  // ─── TAMAÑOS DE HIT TARGET ────────────────────────────────────────────────
  static const double hitTargetMin    = 32;   // mínimo desktop
  static const double hitTargetTouch  = 44;   // recomendado táctil

  // ─── SIDEBAR ──────────────────────────────────────────────────────────────
  static const double sidebarWidth        = 72;   // colapsado
  static const double sidebarWidthExpanded= 220;

  // ─── TITLE BAR ────────────────────────────────────────────────────────────
  static const double titleBarHeight = 40;

  // ─── VENTANA ──────────────────────────────────────────────────────────────
  static const double windowMinWidth  = 1024;
  static const double windowMinHeight = 600;
  static const double windowInitWidth = 1280;
  static const double windowInitHeight= 720;
}

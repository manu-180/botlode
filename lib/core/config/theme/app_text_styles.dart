// Archivo: lib/core/config/theme/app_text_styles.dart
// Escala tipográfica canónica «Hangar OS».
// Oxanium → display / UI.  JetBrains Mono → datos HUD / terminal.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

// Reutilizable: evita instanciar FontFeature.tabularFigures() en cada getter.
const _tabular = FontFeature.tabularFigures();

class AppTextStyles {
  // Estado: aplicar .copyWith() sobre el token para estados de interacción:
  // - disabled  → .copyWith(color: AppColors.textTertiary) o Opacity 0.4 en el padre.
  // - selected/active → .copyWith(color: AppColors.gold) para nav/tabs activos.
  // - error     → .copyWith(color: AppColors.danger) en mensajes de validación.

  // ─── DISPLAY ──────────────────────────────────────────────────────────────
  static TextStyle get displayXL => const TextStyle(
    fontFamily: 'Oxanium',
    fontSize: 40,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    height: 1.15,
    color: AppColors.textPrimary,
  );

  static TextStyle get displayL => const TextStyle(
    fontFamily: 'Oxanium',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    height: 1.18,
    color: AppColors.textPrimary,
  );

  static TextStyle get displayM => const TextStyle(
    fontFamily: 'Oxanium',
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  // ─── TITLE ────────────────────────────────────────────────────────────────
  static TextStyle get titleL => const TextStyle(
    fontFamily: 'Oxanium',
    fontSize: 21,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  static TextStyle get titleM => const TextStyle(
    fontFamily: 'Oxanium',
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  // ─── LABEL (UPPERCASE — el widget consumidor aplica .toUpperCase()) ───────
  static TextStyle get label => const TextStyle(
    fontFamily: 'Oxanium',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.4,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  static TextStyle get labelSmall => const TextStyle(
    fontFamily: 'Oxanium',
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.6,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  // ─── BODY ─────────────────────────────────────────────────────────────────
  static TextStyle get bodyL => const TextStyle(
    fontFamily: 'Oxanium',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyM => const TextStyle(
    fontFamily: 'Oxanium',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyS => const TextStyle(
    fontFamily: 'Oxanium',
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  // ─── MONO / HUD ───────────────────────────────────────────────────────────
  // Figuras tabulares (_tabular) garantizan ancho idéntico por dígito;
  // los tickers numéricos no cambian de ancho al animar.
  static TextStyle get hudReadout => GoogleFonts.jetBrainsMono(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.3,
    color: AppColors.textPrimary,
    fontFeatures: const [_tabular],
  );

  static TextStyle get mono => GoogleFonts.jetBrainsMono(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.4,
    color: AppColors.textSecondary,
    fontFeatures: const [_tabular],
  );

  static TextStyle get numericTicker => GoogleFonts.jetBrainsMono(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    height: 1.0,
    color: AppColors.textPrimary,
    fontFeatures: const [_tabular],
  );
}

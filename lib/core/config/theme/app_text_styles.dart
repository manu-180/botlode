// lib/core/config/theme/app_text_styles.dart
// Escala tipográfica canónica «Hangar OS».
// Oxanium → display / UI.  JetBrains Mono → datos HUD / terminal.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // ─── DISPLAY ──────────────────────────────────────────────────────────────
  static TextStyle get displayXL => const TextStyle(
    fontFamily: 'Oxanium',
    fontSize: 40,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static TextStyle get displayL => const TextStyle(
    fontFamily: 'Oxanium',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static TextStyle get displayM => const TextStyle(
    fontFamily: 'Oxanium',
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  // ─── TITLE ────────────────────────────────────────────────────────────────
  static TextStyle get titleL => const TextStyle(
    fontFamily: 'Oxanium',
    fontSize: 21,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get titleM => const TextStyle(
    fontFamily: 'Oxanium',
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // ─── LABEL (UPPERCASE) ────────────────────────────────────────────────────
  static TextStyle get label => const TextStyle(
    fontFamily: 'Oxanium',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.4,
    color: AppColors.textSecondary,
    height: 1.2,
  );

  static TextStyle get labelSmall => const TextStyle(
    fontFamily: 'Oxanium',
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.6,
    color: AppColors.textSecondary,
    height: 1.2,
  );

  // ─── BODY ─────────────────────────────────────────────────────────────────
  static TextStyle get bodyL => const TextStyle(
    fontFamily: 'Oxanium',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle get bodyM => const TextStyle(
    fontFamily: 'Oxanium',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle get bodyS => const TextStyle(
    fontFamily: 'Oxanium',
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // ─── MONO / HUD ───────────────────────────────────────────────────────────
  static TextStyle get hudReadout => GoogleFonts.jetBrainsMono(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static TextStyle get mono => GoogleFonts.jetBrainsMono(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static TextStyle get numericTicker => GoogleFonts.jetBrainsMono(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
    height: 1.0,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

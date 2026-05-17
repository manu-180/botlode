// lib/core/config/theme/app_colors.dart
// Paleta canónica «Hangar OS» — token único de color para toda la app.
// NO usar hex sueltos fuera de este archivo.
import 'package:flutter/material.dart';

class AppColors {
  // ─── CAPAS DE FONDO ───────────────────────────────────────────────────────
  static const Color voidBlack    = Color(0xFF03070C);
  static const Color background   = Color(0xFF050A10);
  static const Color bgElevated01 = Color(0xFF0A111A);
  static const Color surface      = Color(0xFF0F1621);
  static const Color surfaceRaised= Color(0xFF141D2B);
  static const Color surfaceHud   = Color(0xFF0C1118);

  // ─── VIDRIO / GLASSMORPHISM ───────────────────────────────────────────────
  static const Color glassSurface      = Color.fromRGBO(20,  30,  45,  0.55);
  static const Color glassSurfaceStrong= Color.fromRGBO(24,  34,  50,  0.72);
  static const Color glassHighlightTop = Color.fromRGBO(255, 255, 255, 0.06);
  static const Color glassBorder       = Color.fromRGBO(255, 255, 255, 0.10);
  static const Color scrim             = Color.fromRGBO(3,   6,   11,  0.66);

  // ─── MARCA / ACENTOS ──────────────────────────────────────────────────────
  static const Color gold         = Color(0xFFFFC000);
  static const Color primary      = gold;           // alias semántico
  static const Color goldBright   = Color(0xFFFFD740);
  static const Color goldDeep     = Color(0xFFC8930A);
  static const Color goldGlow     = Color.fromRGBO(255, 192, 0,   0.35);

  static const Color cyan         = Color(0xFF00F0FF);
  static const Color secondary    = cyan;           // alias semántico
  static const Color cyanGlow     = Color.fromRGBO(0,   240, 255, 0.30);

  static const Color accentMagenta= Color(0xFFFF2FD4);
  static const Color accentViolet = Color(0xFF9B5CFF);

  // ─── ESTADOS SEMÁNTICOS ───────────────────────────────────────────────────
  static const Color success      = Color(0xFF00FF94);
  static const Color successGlow  = Color.fromRGBO(0,   255, 148, 0.28);
  static const Color warning      = Color(0xFFFF9D2E);
  static const Color warningGlow  = Color.fromRGBO(255, 157, 46,  0.28);
  static const Color danger       = Color(0xFFFF2D55);
  static const Color error        = danger;         // alias semántico
  static const Color dangerGlow   = Color.fromRGBO(255, 45,  85,  0.30);
  static const Color info         = Color(0xFF3B9DFF);

  // ─── TEXTO Y BORDES ───────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFEAF0F7);
  static const Color textSecondary = Color(0xFF9FB0C3);
  static const Color textTertiary  = Color(0xFF5E6E82);
  static const Color textOnGold    = Color(0xFF0A0A0A);

  static const Color borderSubtle  = Color.fromRGBO(255, 255, 255, 0.06);
  static const Color borderDefault = Color.fromRGBO(255, 255, 255, 0.10);
  static const Color borderStrong  = Color.fromRGBO(255, 255, 255, 0.16);
  static const Color borderGold    = Color.fromRGBO(255, 192, 0,   0.32);

  // Legacy aliases para no romper referencias existentes
  static const Color borderGlass     = borderDefault;
  static const Color borderHighlight = borderGold;

  // ─── GRADIENTES ───────────────────────────────────────────────────────────
  static const LinearGradient gradGold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldBright, gold, goldDeep],
  );

  static const LinearGradient gradGoldSheen = LinearGradient(
    colors: [
      Color.fromRGBO(255, 255, 255, 0.0),
      Color.fromRGBO(255, 255, 255, 0.4),
      Color.fromRGBO(255, 255, 255, 0.0),
    ],
  );

  static const LinearGradient gradPanel = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    transform: GradientRotation(160 * 3.14159 / 180),
    colors: [surfaceRaised, surface],
  );

  static const RadialGradient gradVoid = RadialGradient(
    colors: [bgElevated01, voidBlack],
    stops: [0.8, 1.0],
  );

  static const LinearGradient gradCyanData = LinearGradient(
    colors: [cyan, Color.fromRGBO(0, 240, 255, 0.0)],
  );

  // ─── HELPER: glow de estado genérico ─────────────────────────────────────
  static Color glowStatus(Color color) => color.withValues(alpha: 0.28);

  // ─── Alias del gradiente primario (compatibilidad) ────────────────────────
  static const LinearGradient primaryGradient = gradGold;
}

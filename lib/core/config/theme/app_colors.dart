// lib/core/config/theme/app_colors.dart
// Paleta canónica «Hangar OS» — fuente única de verdad de color para toda la app.
// NO declarar Color(0x...) sueltos fuera de este archivo.
//
// CONTRASTE VERIFICADO (WCAG 2.1, texto sobre fondo indicado)
// ─────────────────────────────────────────────────────────────
// textPrimary  (#EAF0F7) sobre surface (#0F1621)  → ~13.5:1  (AAA)
// textSecondary(#9FB0C3) sobre surface             → ~6.2:1   (AA normal)
// textTertiary (#5E6E82) sobre surface             → ~3.1:1   (AA grande / glifos UI)
// textOnGold   (#0A0A0A) sobre gold    (#FFC000)   → ~11:1    (AAA)
// gold         (#FFC000) sobre surface             → ~9:1     (uso como glifo/acento)
// danger       (#FF2D55) sobre surface             → ~4.6:1   (AA normal)
// success      (#00FF94) sobre surface             → ~10.5:1  (AAA)

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── CAPAS DE FONDO (profundidad) ────────────────────────────────────────
  // Regla: nunca usar un fondo más oscuro debajo de uno más claro.
  static const Color voidBlack     = Color(0xFF03070C); // Capa más profunda; viñeta de bordes del fondo.
  static const Color background    = Color(0xFF050A10); // Fondo base de la app.
  static const Color bgElevated01  = Color(0xFF0A111A); // Primer nivel de elevación; zonas de contenido.
  static const Color surface       = Color(0xFF0F1621); // Superficie de paneles/cards.
  static const Color surfaceRaised = Color(0xFF141D2B); // Cards en hover, modales, popovers.
  static const Color surfaceHud    = Color(0xFF0C1118); // Fondo de lecturas HUD/terminal.

  // ─── VIDRIO / GLASSMORPHISM ───────────────────────────────────────────────
  static const Color glassSurface       = Color.fromRGBO(20,  30,  45,  0.55); // Relleno de panel de vidrio (con blur).
  static const Color glassSurfaceStrong = Color.fromRGBO(24,  34,  50,  0.72); // Vidrio de modales (más opaco, legibilidad).
  static const Color glassHighlightTop  = Color.fromRGBO(255, 255, 255, 0.06); // Highlight de 1 px en el borde superior del vidrio.
  static const Color glassBorder        = Color.fromRGBO(255, 255, 255, 0.10); // Borde hairline estándar de vidrio.
  static const Color scrim              = Color.fromRGBO(3,   6,   11,  0.66); // Velo de fondo detrás de modales (66%).

  // ─── MARCA / ACENTOS ──────────────────────────────────────────────────────
  static const Color gold         = Color(0xFFFFC000); // Acción primaria, valor/dinero, branding. Oro industrial.
  static const Color goldBright   = Color(0xFFFFD740); // Punta de gradiente, highlight, hover del oro.
  static const Color goldDeep     = Color(0xFFC8930A); // Base/sombra de gradiente del oro, estado pressed.
  static const Color goldGlow     = Color.fromRGBO(255, 192, 0,   0.35); // Glow del oro.

  static const Color cyan         = Color(0xFF00F0FF); // Acento técnico/datos, estado «procesando», líneas HUD.
  static const Color secondary    = cyan;              // Alias semántico; mismo token, sin deprecar.
  static const Color cyanGlow     = Color.fromRGBO(0,   240, 255, 0.30); // Glow del cyan.

  // Acentos de mood: accentMagenta → bot «happy», accentViolet → bot «confused».
  // Reemplazan los hex sueltos #FF00D6 y #7B00FF que usaban esos estados.
  static const Color accentMagenta = Color(0xFFFF2FD4); // Mood de alegría/celebración del bot.
  static const Color accentViolet  = Color(0xFF9B5CFF); // Mood de confusión/pensamiento del bot.

  // ─── ESTADOS SEMÁNTICOS ───────────────────────────────────────────────────
  // IMPORTANTE: el color nunca es el único portador de estado.
  // Cada uso de success/warning/danger debe acompañarse de ícono + texto.
  static const Color success     = Color(0xFF00FF94);          // Activo, online, positivo.
  static const Color successGlow = Color.fromRGBO(0,   255, 148, 0.28); // Glow de éxito.
  static const Color warning     = Color(0xFFFF9D2E);          // Mantenimiento, suspendido, vence pronto.
  static const Color warningGlow = Color.fromRGBO(255, 157, 46,  0.28); // Glow de advertencia.
  static const Color danger      = Color(0xFFFF2D55);          // Crítico, error, offline, destructivo.
  static const Color dangerGlow  = Color.fromRGBO(255, 45,  85,  0.30); // Glow de error.
  static const Color info        = Color(0xFF3B9DFF);          // Informativo neutro (banners de trial, ayuda).

  // ─── TEXTO Y BORDES ───────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFEAF0F7);          // Texto principal. Contraste ≥ 13.5:1 sobre surface.
  static const Color textSecondary = Color(0xFF9FB0C3);          // Texto secundario/labels. Contraste ≥ 4.5:1.
  static const Color textTertiary  = Color(0xFF5E6E82);          // Deshabilitado, metadatos, hints. ≥ 3:1.
  static const Color textOnGold    = Color(0xFF0A0A0A);          // Texto sobre superficies doradas. Contraste ~11:1.

  static const Color borderSubtle  = Color.fromRGBO(255, 255, 255, 0.06); // Divisores internos muy sutiles.
  static const Color borderDefault = Color.fromRGBO(255, 255, 255, 0.10); // Borde estándar de cajas.
  static const Color borderStrong  = Color.fromRGBO(255, 255, 255, 0.16); // Borde de hover/foco neutro.
  static const Color borderGold    = Color.fromRGBO(255, 192, 0,   0.32); // Borde con tinte dorado para énfasis.

  // ─── GRADIENTES (getters) ─────────────────────────────────────────────────

  /// Gradiente oro: acción primaria, botones CTA, fondos de énfasis máximo.
  static LinearGradient get gradGold => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldBright, gold, goldDeep],
    stops: [0.0, 0.55, 1.0],
  );

  /// Shimmer de brillo: barrido de luz sobre superficie dorada.
  static LinearGradient get gradGoldSheen => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.transparent, Color.fromRGBO(255, 255, 255, 0.4), Colors.transparent],
    stops: [0.35, 0.5, 0.65],
  );

  /// Gradiente de panel: fondo de cards y contenedores en perspectiva leve.
  static LinearGradient get gradPanel => const LinearGradient(
    begin: Alignment(-0.3, -1.0),
    end: Alignment(0.3, 1.0),
    colors: [surfaceRaised, surface],
  );

  /// Gradiente radial de fondo: el «vacío» del espacio detrás de la UI.
  static RadialGradient get gradVoid => const RadialGradient(
    center: Alignment(0.0, -0.2),
    radius: 1.2,
    colors: [bgElevated01, voidBlack],
    stops: [0.0, 0.8],
  );

  /// Gradiente de barras/charts: fade ascendente en cyan.
  static LinearGradient get gradCyanData => const LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [cyan, Color.fromRGBO(0, 240, 255, 0.0)],
  );

  // ─── HELPER ───────────────────────────────────────────────────────────────

  /// Glow de estado genérico: aplica 28% de opacidad al color de estado.
  static Color glowStatus(Color color) => color.withValues(alpha: 0.28);

  // ─── ALIAS LEGADO (no romper imports existentes) ──────────────────────────

  @Deprecated('Usar gold')
  static const Color primary = gold;

  @Deprecated('Usar danger')
  static const Color error = danger;

  @Deprecated('Usar borderDefault')
  static const Color borderGlass = borderDefault;

  @Deprecated('Usar borderGold')
  static const Color borderHighlight = borderGold;

  @Deprecated('Usar gradGold')
  static LinearGradient get primaryGradient => gradGold;
}

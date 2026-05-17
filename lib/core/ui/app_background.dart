// lib/core/ui/app_background.dart
// Fondo ambiental «Hangar OS»: void base + glow radial + grid tenue + blobs.
// Wrappear la pantalla completa con esto. Nunca fondo plano de un color.
import 'package:flutter/material.dart';
import '../config/theme/app_colors.dart';
import 'hud/hud_grid_texture.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  final AppBackgroundVariant variant;

  const AppBackground({
    super.key,
    required this.child,
    this.variant = AppBackgroundVariant.standard,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Capa 1: gradiente void base ──────────────────────────────
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: AppColors.gradVoid,
            ),
          ),
        ),

        // ── Capa 2: glow radial ambiental (posición según variante) ──
        ..._buildGlows(),

        // ── Capa 3: retícula tenue ───────────────────────────────────
        const Positioned.fill(
          child: IgnorePointer(
            child: HudGridTexture(opacity: 0.03, cellSize: 32),
          ),
        ),

        // ── Capa 4: contenido ────────────────────────────────────────
        child,
      ],
    );
  }

  List<Widget> _buildGlows() {
    switch (variant) {
      case AppBackgroundVariant.standard:
        return [_radialGlow(Alignment.topLeft, AppColors.gold, 0.06, 500)];
      case AppBackgroundVariant.dashboard:
        return [
          _radialGlow(Alignment.topLeft, AppColors.gold, 0.07, 600),
          _radialGlow(Alignment.bottomRight, AppColors.cyan, 0.04, 400),
        ];
      case AppBackgroundVariant.billing:
        return [
          _radialGlow(Alignment.topRight, AppColors.gold, 0.08, 500),
          _radialGlow(Alignment.bottomLeft, AppColors.cyan, 0.03, 350),
        ];
      case AppBackgroundVariant.chat:
        return [
          _radialGlow(Alignment.bottomCenter, AppColors.cyan, 0.05, 450),
        ];
      case AppBackgroundVariant.login:
        return [
          _radialGlow(Alignment.center, AppColors.gold, 0.08, 700),
        ];
    }
  }

  Widget _radialGlow(
    Alignment alignment,
    Color color,
    double opacity,
    double size,
  ) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: alignment,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: opacity),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum AppBackgroundVariant {
  standard,
  dashboard,
  billing,
  chat,
  login,
}

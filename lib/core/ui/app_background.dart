// Archivo: lib/core/ui/app_background.dart
//
// Capa ambiental «Hangar OS» — elimina los fondos planos en toda la app.
// Stack de capas (fondo → frente):
//   0 · Vacío radial (gradVoid): reemplaza scaffoldBackgroundColor plano.
//   1 · Blobs de glow ambiental: 3 halos que respiran lentamente.
//   2 · Retícula técnica HUD (showGrid, default true).
//   3 · Viñeta de bordes (showVignette, default true).
//   4 · Contenido (child) — única capa interactiva.
//
// NOTA PARA PROMPT 20 (MainLayout / shell):
//   El Scaffold que envuelve AppBackground debe declarar
//   `backgroundColor: Colors.transparent` para que la capa 0 sea el
//   fondo real visible; de lo contrario el scaffoldBackgroundColor tapa
//   el gradiente.
//
// Deshabilitar capas (showGrid: false, etc.) es una excepción para
// pantallas muy densas en datos; por defecto las tres están activas.

import 'package:flutter/material.dart';

import '../config/theme/app_colors.dart';
import '../config/theme/app_motion.dart';
import 'hud/hud_grid_texture.dart';

// ─── Constantes de diseño de blobs ────────────────────────────────────────────
// Valores de la especificación visual §5.3. Son exclusivos de este componente;
// no forman parte del sistema de tokens de layout (AppDimens).

const Duration _kBlobOscillation = Duration(seconds: 16);

// Blob A — oro, esquina superior-izquierda
const double _kBlobADia  = 520.0;
const double _kBlobATop  = -160.0;
const double _kBlobALeft = -120.0;
const double _kBlobAOp   = 0.10;

// Blob B — cyan, esquina inferior-derecha
const double _kBlobBDia    = 460.0;
const double _kBlobBBottom = -180.0;
const double _kBlobBRight  = -140.0;
const double _kBlobBOp     = 0.08;

// Blob C — oro tenue, centro-derecha
const double _kBlobCDia   = 360.0;
const double _kBlobCTop   = 100.0; // blob center ≈ 280 px ≈ 40 % de 720 p
const double _kBlobCRight = -120.0;
const double _kBlobCOp    = 0.06;

// Amplitudes de oscilación por blob (±px)
const double _kBlobADriftX = 14.0;
const double _kBlobADriftY = 10.0;
const double _kBlobBDriftX = 16.0;
const double _kBlobBDriftY = 12.0;
const double _kBlobCDriftX = 10.0;
const double _kBlobCDriftY = 18.0;

// Viñeta
const double _kVignetteRadius = 1.1;
const double _kVignetteStop   = 0.55;
const double _kVignetteOp     = 0.55;

// ─── Widget público ───────────────────────────────────────────────────────────

class AppBackground extends StatefulWidget {
  final Widget child;
  final bool showGrid;
  final bool showBlobs;
  final bool showVignette;

  const AppBackground({
    super.key,
    required this.child,
    this.showGrid     = true,
    this.showBlobs    = true,
    this.showVignette = true,
  });

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blobCtrl;
  late final CurvedAnimation _forward;
  late final CurvedAnimation _flipped;

  // Blob A (oro, top-left) — misma fase que el controller
  late final Animation<double> _blobATx;
  late final Animation<double> _blobATy;

  // Blob B (cyan, bottom-right) — fase inversa: contra-movimiento natural
  late final Animation<double> _blobBTx;
  late final Animation<double> _blobBTy;

  // Blob C (oro tenue, centro-derecha) — Y en fase directa, X invertido
  late final Animation<double> _blobCTx;
  late final Animation<double> _blobCTy;

  @override
  void initState() {
    super.initState();
    _blobCtrl = AnimationController(vsync: this, duration: _kBlobOscillation);

    _forward = CurvedAnimation(
      parent: _blobCtrl,
      curve: AppMotion.easeStandard,
    );
    _flipped = CurvedAnimation(
      parent: _blobCtrl,
      curve: AppMotion.easeStandard.flipped,
    );

    _blobATx = Tween<double>(begin: -_kBlobADriftX, end: _kBlobADriftX).animate(_forward);
    _blobATy = Tween<double>(begin: -_kBlobADriftY, end: _kBlobADriftY).animate(_forward);
    _blobBTx = Tween<double>(begin: -_kBlobBDriftX, end: _kBlobBDriftX).animate(_flipped);
    _blobBTy = Tween<double>(begin: -_kBlobBDriftY, end: _kBlobBDriftY).animate(_flipped);
    _blobCTx = Tween<double>(begin: -_kBlobCDriftX, end: _kBlobCDriftX).animate(_flipped);
    _blobCTy = Tween<double>(begin: -_kBlobCDriftY, end: _kBlobCDriftY).animate(_forward);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced-motion: blobs estáticos; el controller no se inicia.
    if (AppMotion.reduced(context)) {
      _blobCtrl.stop();
    } else if (!_blobCtrl.isAnimating) {
      _blobCtrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _forward.dispose();
    _flipped.dispose();
    _blobCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Capa 0: Vacío base ──────────────────────────────────────────────
        ExcludeSemantics(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.gradVoid),
            ),
          ),
        ),

        // ── Capa 1: Blobs de glow ambiental ─────────────────────────────────
        if (widget.showBlobs)
          RepaintBoundary(
            child: ExcludeSemantics(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _blobCtrl,
                  builder: (_, __) => Stack(
                    children: [
                      // Blob A: oro, esquina superior-izquierda
                      Positioned(
                        top:  _kBlobATop  + _blobATy.value,
                        left: _kBlobALeft + _blobATx.value,
                        child: const _GlowBlob(
                          diameter: _kBlobADia,
                          color:    AppColors.gold,
                          opacity:  _kBlobAOp,
                        ),
                      ),
                      // Blob B: cyan, esquina inferior-derecha
                      Positioned(
                        bottom: _kBlobBBottom + _blobBTy.value,
                        right:  _kBlobBRight  + _blobBTx.value,
                        child: const _GlowBlob(
                          diameter: _kBlobBDia,
                          color:    AppColors.cyan,
                          opacity:  _kBlobBOp,
                        ),
                      ),
                      // Blob C: oro tenue, centro-derecha
                      Positioned(
                        top:   _kBlobCTop   + _blobCTy.value,
                        right: _kBlobCRight + _blobCTx.value,
                        child: const _GlowBlob(
                          diameter: _kBlobCDia,
                          color:    AppColors.gold,
                          opacity:  _kBlobCOp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // ── Capa 2: Retícula técnica HUD ─────────────────────────────────────
        if (widget.showGrid)
          const ExcludeSemantics(
            child: IgnorePointer(
              child: HudGridTexture(opacity: 0.04, cell: 32),
            ),
          ),

        // ── Capa 3: Viñeta de bordes ─────────────────────────────────────────
        if (widget.showVignette)
          ExcludeSemantics(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: _kVignetteRadius,
                    colors: [
                      Colors.transparent,
                      AppColors.voidBlack.withValues(alpha: _kVignetteOp),
                    ],
                    stops: const [_kVignetteStop, 1.0],
                  ),
                ),
              ),
            ),
          ),

        // ── Capa 4: Contenido ─────────────────────────────────────────────────
        widget.child,
      ],
    );
  }
}

// ─── Blob de glow (privado) ───────────────────────────────────────────────────

class _GlowBlob extends StatelessWidget {
  final double diameter;
  final Color  color;
  final double opacity;

  const _GlowBlob({
    required this.diameter,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: diameter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}

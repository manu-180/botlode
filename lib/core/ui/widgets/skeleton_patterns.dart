// Archivo: lib/core/ui/widgets/skeleton_patterns.dart
//
// Patrones compuestos de skeleton para los estados de carga de la app.
// Toda animación/color viene de SkeletonBase; estos widgets son pura composición.
//
// Crossfade hacia contenido real:
//   AnimatedSwitcher(
//     duration: AppMotion.durBase,
//     switchInCurve: AppMotion.easeStandard,
//     switchOutCurve: AppMotion.easeStandard,
//     child: isLoading ? const SkeletonCard() : RealContent(),
//   )

import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/ui/widgets/skeleton_base.dart';
import 'package:flutter/material.dart';

// ─── SkeletonCard ─────────────────────────────────────────────────────────────
// Silueta de una HoloPanel de contenido: bloque de imagen/avatar grande arriba,
// dos líneas de texto (100% y ~60% del ancho) y una pill pequeña abajo.

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image / avatar block
        const SkeletonBase(
          width: double.infinity,
          height: 120,
          radius: AppDimens.radiusL,
        ),
        const SizedBox(height: AppDimens.space12),
        // Primary text line (full width)
        const SkeletonBase(
          width: double.infinity,
          height: 14,
          radius: AppDimens.radiusXS,
        ),
        const SizedBox(height: AppDimens.space8),
        // Secondary text line (~60%)
        SkeletonBase(
          width: MediaQuery.sizeOf(context).width * 0.6,
          height: 12,
          radius: AppDimens.radiusXS,
        ),
        const SizedBox(height: AppDimens.space12),
        // Pill / badge
        const SkeletonBase(
          width: 72,
          height: 22,
          radius: AppDimens.radiusPill,
        ),
      ],
    );
  }
}

// ─── SkeletonListRow ──────────────────────────────────────────────────────────
// Fila de lista: círculo (avatar) + dos líneas de texto apiladas + pill al final.
// Altura total ≈64 px.

class SkeletonListRow extends StatelessWidget {
  const SkeletonListRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar circle
          const SkeletonBase(
            width: 40,
            height: 40,
            shape: BoxShape.circle,
          ),
          const SizedBox(width: AppDimens.space12),
          // Text lines
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBase(
                  width: double.infinity,
                  height: 13,
                  radius: AppDimens.radiusXS,
                ),
                const SizedBox(height: AppDimens.space8),
                SkeletonBase(
                  width: MediaQuery.sizeOf(context).width * 0.4,
                  height: 11,
                  radius: AppDimens.radiusXS,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimens.space12),
          // Trailing pill
          const SkeletonBase(
            width: 56,
            height: 20,
            radius: AppDimens.radiusPill,
          ),
        ],
      ),
    );
  }
}

// ─── SkeletonTableRow ─────────────────────────────────────────────────────────
// Fila de tabla: N celdas rectangulares de anchos proporcionales. Altura ≈44 px.
// [columnWidthFractions] debe sumar ≤1.0; se usan como fracciones del espacio disponible.

class SkeletonTableRow extends StatelessWidget {
  final List<double> columnWidthFractions;

  const SkeletonTableRow({
    super.key,
    this.columnWidthFractions = const [0.30, 0.25, 0.25, 0.20],
  });

  @override
  Widget build(BuildContext context) {
    final totalWidth = MediaQuery.sizeOf(context).width;
    final gapTotal = AppDimens.space12 * (columnWidthFractions.length - 1);
    final availableWidth = totalWidth - gapTotal;

    return SizedBox(
      height: 44,
      child: Row(
        children: [
          for (int i = 0; i < columnWidthFractions.length; i++) ...[
            if (i > 0) const SizedBox(width: AppDimens.space12),
            SkeletonBase(
              width: availableWidth * columnWidthFractions[i],
              height: 14,
              radius: AppDimens.radiusXS,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── SkeletonGrid ─────────────────────────────────────────────────────────────
// Grilla de N SkeletonCard con el gap space20 que usa la grilla real del dashboard.

class SkeletonGrid extends StatelessWidget {
  final int count;
  final int crossAxisCount;

  const SkeletonGrid({
    super.key,
    this.count = 6,
    this.crossAxisCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: AppDimens.space20,
        crossAxisSpacing: AppDimens.space20,
        childAspectRatio: 0.9,
      ),
      itemCount: count,
      itemBuilder: (_, __) => const SkeletonCard(),
    );
  }
}

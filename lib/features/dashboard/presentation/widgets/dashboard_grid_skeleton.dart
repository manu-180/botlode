// lib/features/dashboard/presentation/widgets/dashboard_grid_skeleton.dart
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/ui/widgets/skeleton_base.dart';
import 'package:flutter/material.dart';

/// Skeleton placeholder for a [BotCard] while the grid data is loading.
/// Replicates the BotCard layout (portrait zone + body zone) using [SkeletonBase]
/// blocks. Non-interactive; internal content is excluded from the semantics tree.
class BotCardSkeleton extends StatelessWidget {
  const BotCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cargando unidad',
      child: ExcludeSemantics(
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.glassSurface,
            borderRadius: AppDimens.brL,
            border: Border.all(color: AppColors.glassBorder),
            boxShadow: AppDimens.elev1,
          ),
          child: ClipRRect(
            borderRadius: AppDimens.brL,
            child: const Padding(
              padding: EdgeInsets.all(AppDimens.paddingCard),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _PortraitZone()),
                  SizedBox(height: AppDimens.space16),
                  _BodyZone(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Portrait zone ────────────────────────────────────────────────────────────
// Replicates: HudGridTexture background, RiveBotCardDisplay avatar (top-left),
// _StatusBadge pill (top-right), HudIdTag (bottom-left).

class _PortraitZone extends StatelessWidget {
  const _PortraitZone();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceHud,
            borderRadius: AppDimens.brS,
          ),
        ),
        // Avatar block — mirrors RiveBotCardDisplay position
        const Positioned(
          top: 0,
          left: 0,
          child: SkeletonBase(width: 54, height: 54, radius: AppDimens.radiusS),
        ),
        // Status badge pill
        const Positioned(
          top: 0,
          right: 0,
          child: SkeletonBase(
            width: 72,
            height: 20,
            radius: AppDimens.radiusPill,
          ),
        ),
        // Unit ID tag
        const Positioned(
          bottom: 0,
          left: 0,
          child: SkeletonBase(width: 80, height: 14, radius: AppDimens.radiusXS),
        ),
      ],
    );
  }
}

// ─── Body zone ────────────────────────────────────────────────────────────────
// Replicates: bot name, two description lines, metrics row (cycle %).

class _BodyZone extends StatelessWidget {
  const _BodyZone();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SkeletonBase(width: 150, height: 18, radius: AppDimens.radiusS),
        SizedBox(height: AppDimens.space8),
        Row(
          children: [
            Expanded(
              child: SkeletonBase(height: 12, radius: AppDimens.radiusXS),
            ),
          ],
        ),
        SizedBox(height: AppDimens.space4),
        SkeletonBase(width: 200, height: 12, radius: AppDimens.radiusXS),
        SizedBox(height: AppDimens.space12),
        SkeletonBase(width: 80, height: 10, radius: AppDimens.radiusXS),
      ],
    );
  }
}

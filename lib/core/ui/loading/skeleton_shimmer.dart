// lib/core/ui/loading/skeleton_shimmer.dart
// Skeleton base premium con shimmer dorado. Respeta reduced-motion.
import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_dimens.dart';
import '../../config/theme/app_motion.dart';

class SkeletonShimmer extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  const SkeletonShimmer.line({
    super.key,
    required this.width,
    this.height = 14,
    this.borderRadius,
  });

  const SkeletonShimmer.block({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<SkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppMotion.durShimmerSkeleton,
    );
    _anim = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _ctrl, curve: AppMotion.easeStandard),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  void _syncAnimation() {
    final reduced = AppMotion.isReduced(context);
    if (reduced) {
      _ctrl.stop();
    } else if (!_ctrl.isAnimating) {
      _ctrl.repeat();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.isReduced(context);
    final br = widget.borderRadius ?? AppDimens.brS;

    if (reduced) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.bgElevated01,
          borderRadius: br,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: br,
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value, 0),
            colors: [
              AppColors.bgElevated01,
              AppColors.surfaceRaised,
              AppColors.gold.withValues(alpha: 0.06),
              AppColors.surfaceRaised,
              AppColors.bgElevated01,
            ],
            stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
          ),
        ),
      ),
    );
  }
}

/// Skeleton de una card de bot (layout estándar).
class BotCardSkeleton extends StatelessWidget {
  const BotCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingCard),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimens.brL,
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonShimmer(width: 48, height: 48, borderRadius: AppDimens.brM),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonShimmer.line(width: 120),
                    const SizedBox(height: AppDimens.space4),
                    SkeletonShimmer.line(width: 80, borderRadius: AppDimens.brPill),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SkeletonShimmer.line(width: double.infinity),
          const SizedBox(height: 8),
          SkeletonShimmer.line(width: 200),
        ],
      ),
    );
  }
}

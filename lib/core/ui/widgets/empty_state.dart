// lib/core/ui/widgets/empty_state.dart
import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_dimens.dart';
import '../../config/theme/app_motion.dart';
import '../../config/theme/app_text_styles.dart';
import '../hud/hud_grid_texture.dart';

// Component-specific layout constants (from §5.2 of the design spec).
const double _kRingSize = 96;
const double _kIconSize = 40;
const double _kBorderWidth = 1.5;
const double _kEntryTranslate = 12;
const double _kMaxContentWidth = 360;

enum EmptyStateVariant { neutral, noResults }

class EmptyState extends StatefulWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.variant = EmptyStateVariant.neutral,
    this.action,
  });

  final IconData icon;
  final String title;
  final String description;
  final EmptyStateVariant variant;

  /// Typically an [AppButton] (primary, md size). Optional.
  final Widget? action;

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  int get _itemCount => 3 + (widget.action != null ? 1 : 0);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppMotion.durBase);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAnimation());
  }

  void _startAnimation() {
    if (!mounted) return;
    final reduced = AppMotion.reduced(context);
    if (reduced) {
      _ctrl.duration = AppMotion.durCrossfadeReduced;
    } else {
      final totalMs = AppMotion.durBase.inMilliseconds +
          (_itemCount - 1) * AppMotion.durStagger.inMilliseconds;
      _ctrl.duration = Duration(milliseconds: totalMs);
    }
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // Builds a staggered or reduced-motion animated wrapper for [child].
  // [index] is the item's position in the entrance sequence (0-based).
  Widget _animate(Widget child, int index, {required bool reduced}) {
    final totalMs =
        _ctrl.duration?.inMilliseconds ?? AppMotion.durBase.inMilliseconds;

    final Animation<double> anim;
    if (reduced || totalMs <= 0) {
      anim = CurvedAnimation(parent: _ctrl, curve: AppMotion.easeEntrance);
    } else {
      final startMs = AppMotion.staggerDelay(index).inMilliseconds;
      final endMs = startMs + AppMotion.durBase.inMilliseconds;
      anim = CurvedAnimation(
        parent: _ctrl,
        curve: Interval(
          startMs / totalMs,
          (endMs / totalMs).clamp(0.0, 1.0),
          curve: AppMotion.easeEntrance,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, ch) {
        final v = anim.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: v,
          child: reduced
              ? ch
              : Transform.translate(
                  offset: Offset(0, (1 - v) * _kEntryTranslate),
                  child: ch,
                ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    final iconColor = widget.variant == EmptyStateVariant.noResults
        ? AppColors.cyan.withValues(alpha: 0.6)
        : AppColors.textSecondary;

    return SizedBox.expand(
      child: HudGridTexture(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Ring + icon (decorative — excluded from semantics tree).
                _animate(
                  ExcludeSemantics(
                    child: _EmptyStateRing(
                      icon: widget.icon,
                      iconColor: iconColor,
                    ),
                  ),
                  0,
                  reduced: reduced,
                ),
                const SizedBox(height: AppDimens.space24),
                // Title + description announced together as one semantic region.
                Semantics(
                  label: '${widget.title}. ${widget.description}',
                  excludeSemantics: true,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _animate(
                        Text(
                          widget.title,
                          style: AppTextStyles.titleM,
                          textAlign: TextAlign.center,
                        ),
                        1,
                        reduced: reduced,
                      ),
                      const SizedBox(height: AppDimens.space8),
                      _animate(
                        Text(
                          widget.description,
                          style: AppTextStyles.bodyS.copyWith(
                            color: AppColors.textTertiary,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                        ),
                        2,
                        reduced: reduced,
                      ),
                    ],
                  ),
                ),
                if (widget.action != null) ...[
                  const SizedBox(height: AppDimens.space24),
                  _animate(widget.action!, 3, reduced: reduced),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyStateRing extends StatelessWidget {
  const _EmptyStateRing({required this.icon, required this.iconColor});

  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _kRingSize,
      height: _kRingSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceHud,
        border: Border.all(color: AppColors.borderDefault, width: _kBorderWidth),
        boxShadow: AppDimens.glowStatus(AppColors.cyan),
      ),
      child: Icon(icon, size: _kIconSize, color: iconColor),
    );
  }
}

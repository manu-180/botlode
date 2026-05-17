// lib/core/ui/widgets/app_badge.dart
// Badge canónico «Hangar OS» — variantes neutral / gold / cyan / danger.
// No-interactive: sin hover ni press states.
import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_dimens.dart';
import '../../config/theme/app_text_styles.dart';

// ─── Tone enum ────────────────────────────────────────────────────────────────

enum AppBadgeTone { neutral, gold, cyan, danger }

// ─── Internal tone data ───────────────────────────────────────────────────────

class _ToneData {
  final Color fill;
  final Color textColor;
  final Color borderColor;

  const _ToneData({
    required this.fill,
    required this.textColor,
    required this.borderColor,
  });
}

// Height is spec-defined and not represented in AppDimens; documented inline.
const double _kBadgeHeight = 18;
const double _kDotSize = 8;

// ─── AppBadge ─────────────────────────────────────────────────────────────────

class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    this.text,
    this.tone = AppBadgeTone.neutral,
    this.dot = false,
  }) : assert(dot || text != null, 'text is required when dot is false');

  final String? text;
  final AppBadgeTone tone;

  /// When true, renders an 8×8 filled circle instead of a text pill.
  final bool dot;

  // ─── Tone resolution ────────────────────────────────────────────────────────

  // alpha values below are badge-spec constants; AppColors has no badge-specific tokens
  _ToneData get _toneData {
    switch (tone) {
      case AppBadgeTone.neutral:
        return const _ToneData(
          fill: AppColors.surfaceRaised,
          textColor: AppColors.textSecondary,
          borderColor: AppColors.borderDefault,
        );
      case AppBadgeTone.gold:
        return _ToneData(
          fill: AppColors.gold.withValues(alpha: 0.16),
          textColor: AppColors.goldBright,
          borderColor: AppColors.borderGold,
        );
      case AppBadgeTone.cyan:
        return _ToneData(
          fill: AppColors.cyan.withValues(alpha: 0.14),
          textColor: AppColors.cyan,
          borderColor: AppColors.cyan.withValues(alpha: 0.32),
        );
      case AppBadgeTone.danger:
        return _ToneData(
          fill: AppColors.danger.withValues(alpha: 0.14),
          textColor: AppColors.danger,
          borderColor: AppColors.danger.withValues(alpha: 0.40),
        );
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (dot) {
      return ExcludeSemantics(
        child: _buildDot(),
      );
    }

    return _buildPill();
  }

  Widget _buildDot() {
    final td = _toneData;
    return SizedBox(
      width: _kDotSize,
      height: _kDotSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: td.textColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildPill() {
    final td = _toneData;
    return SizedBox(
      height: _kBadgeHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: td.fill,
          borderRadius: BorderRadius.circular(AppDimens.radiusPill),
          border: Border.all(
            color: td.borderColor,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space8,
          ),
          child: Center(
            child: Text(
              text!.toUpperCase(),
              style: AppTextStyles.labelSmall.copyWith(
                color: td.textColor,
                height: 1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

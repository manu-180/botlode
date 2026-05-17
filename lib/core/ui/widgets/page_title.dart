// lib/core/ui/widgets/page_title.dart
// PageTitle «Hangar OS» — 3 estilos: minimal, techBar, elegant.
// Usa únicamente tokens de diseño.
// Prompt-21: trailing slot, displayM, entrance anim, a11y.
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/hud/hud_divider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum PageTitleStyle { minimal, techBar, elegant }

// Design-specific pixel values not listed in AppDimens — named here to avoid magic numbers.
const double _kBarWidth = 4.0;
const double _kDotSize = 8.0;
const double _kEntranceOffsetY = 8.0;
// Shimmer highlight: white@40% barrido sobre la barra dorada.
const Color _kShimmerColor = Color.fromRGBO(255, 255, 255, 0.4);

class PageTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final PageTitleStyle style;

  /// Optional actions widget rendered on the right side of the title row.
  final Widget? trailing;

  /// Accent color used by the [elegant] style dot and [techBar] glow.
  /// Defaults to [AppColors.gold].
  final Color? accentColor;

  const PageTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.style = PageTitleStyle.techBar,
    this.trailing,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.gold;
    final reduced = AppMotion.reduced(context);

    Widget content = switch (style) {
      PageTitleStyle.minimal => _Minimal(
          title: title,
          subtitle: subtitle,
          reduced: reduced,
        ),
      PageTitleStyle.techBar => _TechBar(
          title: title,
          subtitle: subtitle,
          color: color,
          reduced: reduced,
        ),
      PageTitleStyle.elegant => _Elegant(
          title: title,
          subtitle: subtitle,
          color: color,
          reduced: reduced,
        ),
    };

    if (trailing == null) return content;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: content),
        const SizedBox(width: AppDimens.space16),
        trailing!,
      ],
    );
  }
}

// ─── MINIMAL ─────────────────────────────────────────────────────────────────

class _Minimal extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool reduced;

  const _Minimal({
    required this.title,
    this.subtitle,
    required this.reduced,
  });

  @override
  Widget build(BuildContext context) {
    Widget titleText = Semantics(
      header: true,
      child: Text(
        title,
        style: AppTextStyles.displayM.copyWith(color: AppColors.textPrimary),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );

    Widget divider = const ExcludeSemantics(
      child: HudDivider(lineColor: AppColors.borderSubtle),
    );

    if (reduced) {
      titleText = titleText
          .animate()
          .fadeIn(duration: AppMotion.durCrossfadeReduced);
      divider = divider
          .animate()
          .fadeIn(duration: AppMotion.durCrossfadeReduced);
    } else {
      titleText = titleText
          .animate()
          .fadeIn(duration: AppMotion.durBase, curve: AppMotion.easeEntrance)
          .move(
            begin: const Offset(0, _kEntranceOffsetY),
            end: Offset.zero,
            duration: AppMotion.durBase,
            curve: AppMotion.easeEntrance,
          );
      divider = divider
          .animate()
          .fadeIn(duration: AppMotion.durBase, curve: AppMotion.easeEntrance);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        titleText,
        const SizedBox(height: AppDimens.space12),
        divider,
        if (subtitle != null) ...[
          const SizedBox(height: AppDimens.space12),
          _buildSubtitle(subtitle!, reduced),
        ],
      ],
    );
  }
}

// ─── TECH BAR ────────────────────────────────────────────────────────────────

class _TechBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color color;
  final bool reduced;

  const _TechBar({
    required this.title,
    this.subtitle,
    required this.color,
    required this.reduced,
  });

  @override
  Widget build(BuildContext context) {
    // Vertical gold gradient for the bar (top-to-bottom, not diagonal).
    const barGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppColors.goldBright, AppColors.gold, AppColors.goldDeep],
      stops: [0.0, 0.55, 1.0],
    );

    Widget bar = Container(
      width: _kBarWidth,
      decoration: BoxDecoration(
        gradient: barGradient,
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
        boxShadow: AppDimens.glowStatus(color),
      ),
    );

    if (!reduced) {
      // Inner: repeating shimmer.
      bar = bar
          .animate(onPlay: (c) => c.repeat())
          .shimmer(
            duration: const Duration(milliseconds: 3200),
            color: _kShimmerColor,
          );
      // Outer: one-shot entrance (scaleY + fade).
      bar = bar
          .animate()
          .scaleY(
            begin: 0.6,
            end: 1.0,
            duration: AppMotion.durBase,
            curve: AppMotion.easeEntrance,
          )
          .fadeIn(duration: AppMotion.durBase, curve: AppMotion.easeEntrance);
    } else {
      bar = bar
          .animate()
          .fadeIn(duration: AppMotion.durCrossfadeReduced);
    }

    Widget titleText = Semantics(
      header: true,
      child: Text(
        title,
        style: AppTextStyles.displayM.copyWith(color: AppColors.textPrimary),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );

    if (!reduced) {
      titleText = titleText
          .animate()
          .fadeIn(duration: AppMotion.durBase, curve: AppMotion.easeEntrance)
          .move(
            begin: const Offset(0, _kEntranceOffsetY),
            end: Offset.zero,
            duration: AppMotion.durBase,
            curve: AppMotion.easeEntrance,
          );
    } else {
      titleText = titleText
          .animate()
          .fadeIn(duration: AppMotion.durCrossfadeReduced);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(child: bar),
          const SizedBox(width: AppDimens.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                titleText,
                if (subtitle != null) ...[
                  const SizedBox(height: AppDimens.space8),
                  _buildSubtitle(subtitle!, reduced),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ELEGANT ─────────────────────────────────────────────────────────────────

class _Elegant extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Color color;
  final bool reduced;

  const _Elegant({
    required this.title,
    this.subtitle,
    required this.color,
    required this.reduced,
  });

  @override
  State<_Elegant> createState() => _ElegantState();
}

class _ElegantState extends State<_Elegant>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppMotion.durHeartbeat,
    );
    _pulse = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: AppMotion.easeStandard),
    );
    if (!widget.reduced) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _Elegant old) {
    super.didUpdateWidget(old);
    if (widget.reduced != old.reduced) {
      if (widget.reduced) {
        _ctrl.stop();
        _ctrl.value = 1.0;
      } else if (!_ctrl.isAnimating) {
        _ctrl.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Custom pulsating dot — inline because HudStatusDot doesn't accept a Color.
    Widget dot = ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) => Opacity(
          opacity: widget.reduced ? 1.0 : _pulse.value,
          child: Container(
            width: _kDotSize,
            height: _kDotSize,
            margin: const EdgeInsets.only(top: AppDimens.space8),
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              boxShadow: AppDimens.glowStatus(widget.color),
            ),
          ),
        ),
      ),
    );

    Widget titleText = Semantics(
      header: true,
      child: Text(
        widget.title,
        style: AppTextStyles.displayM.copyWith(color: AppColors.textPrimary),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );

    if (!widget.reduced) {
      titleText = titleText
          .animate()
          .fadeIn(duration: AppMotion.durBase, curve: AppMotion.easeEntrance)
          .move(
            begin: const Offset(0, _kEntranceOffsetY),
            end: Offset.zero,
            duration: AppMotion.durBase,
            curve: AppMotion.easeEntrance,
          );
    } else {
      titleText = titleText
          .animate()
          .fadeIn(duration: AppMotion.durCrossfadeReduced);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dot,
        const SizedBox(width: AppDimens.space20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              titleText,
              if (widget.subtitle != null) ...[
                const SizedBox(height: AppDimens.space8),
                _buildSubtitle(widget.subtitle!, widget.reduced),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── SHARED HELPERS ───────────────────────────────────────────────────────────

/// Builds the subtitle text with entrance animation (staggered 36ms after title).
Widget _buildSubtitle(String subtitle, bool reduced) {
  Widget text = Text(subtitle, style: AppTextStyles.bodyS);
  if (reduced) {
    return text.animate().fadeIn(duration: AppMotion.durCrossfadeReduced);
  }
  return text
      .animate(delay: AppMotion.durStagger)
      .fadeIn(duration: AppMotion.durBase, curve: AppMotion.easeEntrance)
      .move(
        begin: const Offset(0, _kEntranceOffsetY),
        end: Offset.zero,
        duration: AppMotion.durBase,
        curve: AppMotion.easeEntrance,
      );
}

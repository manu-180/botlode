// lib/core/ui/widgets/page_title.dart
// PageTitle «Hangar OS» — 3 estilos: minimal, techBar, elegant.
// Usa únicamente tokens de diseño.
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum PageTitleStyle { minimal, techBar, elegant }

class PageTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color? accentColor;
  final PageTitleStyle style;

  const PageTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.accentColor,
    this.style = PageTitleStyle.techBar,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.gold;
    final reduced = MediaQuery.of(context).disableAnimations;

    return switch (style) {
      PageTitleStyle.minimal  => _Minimal(title: title, subtitle: subtitle, color: color, reduced: reduced),
      PageTitleStyle.techBar  => _TechBar(title: title, subtitle: subtitle, color: color, reduced: reduced),
      PageTitleStyle.elegant  => _Elegant(title: title, subtitle: subtitle, color: color, reduced: reduced),
    };
  }
}

// ─── MINIMAL ─────────────────────────────────────────────────────────────────

class _Minimal extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color color;
  final bool reduced;
  const _Minimal({required this.title, this.subtitle, required this.color, required this.reduced});

  @override
  Widget build(BuildContext context) {
    Widget underline = Container(
      width: 60,
      height: 3,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.3)],
        ),
        borderRadius: BorderRadius.circular(2),
      ),
    );
    if (!reduced) {
      underline = underline
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 3000.ms, color: Colors.white.withValues(alpha: 0.3));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.displayL.copyWith(color: AppColors.textPrimary)),
        const SizedBox(height: AppDimens.space12),
        underline,
        if (subtitle != null) ...[
          const SizedBox(height: AppDimens.space12),
          Text(subtitle!, style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary)),
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
  const _TechBar({required this.title, this.subtitle, required this.color, required this.reduced});

  @override
  Widget build(BuildContext context) {
    Widget bar = Container(
      width: 4,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.3)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(2),
        boxShadow: AppDimens.glowStatus(color),
      ),
    );
    if (!reduced) {
      bar = bar
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 3000.ms, color: Colors.white.withValues(alpha: 0.4));
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          bar,
          const SizedBox(width: AppDimens.space16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: AppTextStyles.displayL.copyWith(color: AppColors.textPrimary)),
              if (subtitle != null) ...[
                const SizedBox(height: AppDimens.space8),
                Text(subtitle!, style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── ELEGANT ─────────────────────────────────────────────────────────────────

class _Elegant extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color color;
  final bool reduced;
  const _Elegant({required this.title, this.subtitle, required this.color, required this.reduced});

  @override
  Widget build(BuildContext context) {
    Widget dot = Container(
      margin: const EdgeInsets.only(top: 8),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: AppDimens.glowStatus(color),
      ),
    );
    if (!reduced) {
      dot = dot
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 2500.ms, color: Colors.white.withValues(alpha: 0.6));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        dot,
        const SizedBox(width: AppDimens.space20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: AppTextStyles.displayL.copyWith(color: AppColors.textPrimary)),
            if (subtitle != null) ...[
              const SizedBox(height: AppDimens.space8),
              Text(subtitle!, style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary)),
            ],
          ],
        ),
      ],
    );
  }
}

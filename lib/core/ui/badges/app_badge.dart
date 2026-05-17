// lib/core/ui/badges/app_badge.dart
// Badges, chips y status tags «Hangar OS».
// Regla: el estado nunca se comunica solo por color — siempre color + ícono + texto.
import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_dimens.dart';
import '../../config/theme/app_icons.dart';
import '../../config/theme/app_motion.dart';
import '../../config/theme/app_text_styles.dart';
import '../hud/hud_status_dot.dart';

// ─── STATUS BADGE ─────────────────────────────────────────────────────────────

enum BotStatus { online, offline, warning, processing }

class StatusBadge extends StatelessWidget {
  final BotStatus status;
  final bool showLabel;

  const StatusBadge({
    super.key,
    required this.status,
    this.showLabel = true,
  });

  Color get _color => switch (status) {
        BotStatus.online     => AppColors.success,
        BotStatus.offline    => AppColors.danger,
        BotStatus.warning    => AppColors.warning,
        BotStatus.processing => AppColors.cyan,
      };

  HudStatus get _dotStatus => switch (status) {
        BotStatus.online     => HudStatus.online,
        BotStatus.offline    => HudStatus.offline,
        BotStatus.warning    => HudStatus.suspended,
        BotStatus.processing => HudStatus.processing,
      };

  String get _label => switch (status) {
        BotStatus.online     => 'Online',
        BotStatus.offline    => 'Offline',
        BotStatus.warning    => 'Advertencia',
        BotStatus.processing => 'Procesando',
      };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Estado: $_label',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space8,
          vertical: AppDimens.space4,
        ),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.12),
          borderRadius: AppDimens.brPill,
          border: Border.all(color: _color.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HudStatusDot(status: _dotStatus, size: 6),
            if (showLabel) ...[
              const SizedBox(width: 6),
              Text(
                _label.toUpperCase(),
                style: AppTextStyles.labelSmall.copyWith(color: _color),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── COUNTER BADGE ────────────────────────────────────────────────────────────

class CounterBadge extends StatelessWidget {
  final int count;
  final Color color;
  final Color textColor;

  const CounterBadge({
    super.key,
    required this.count,
    this.color = AppColors.gold,
    this.textColor = AppColors.textOnGold,
  });

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.space8, vertical: AppDimens.space2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppDimens.brPill,
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppTextStyles.labelSmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── PLAN BADGE ───────────────────────────────────────────────────────────────

class PlanBadge extends StatelessWidget {
  final String plan;
  final bool isPro;

  const PlanBadge({
    super.key,
    required this.plan,
    this.isPro = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space8,
        vertical: AppDimens.space4,
      ),
      decoration: BoxDecoration(
        gradient: isPro ? AppColors.gradGold : null,
        color: isPro ? null : AppColors.surfaceRaised,
        borderRadius: AppDimens.brPill,
        border: isPro
            ? null
            : Border.all(color: AppColors.borderDefault, width: 1),
      ),
      child: Text(
        plan.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: isPro ? AppColors.textOnGold : AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── TAG CHIP (seleccionable) ─────────────────────────────────────────────────

class AppChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.durFast,
          curve: AppMotion.easeStandard,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space12,
            vertical: AppDimens.space8,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.gold.withValues(alpha: 0.15) : AppColors.surfaceRaised,
            borderRadius: AppDimens.brPill,
            border: Border.all(
              color: selected ? AppColors.borderGold : AppColors.borderDefault,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                AppIcons.icon(icon!, size: AppDimens.iconXS, color: selected ? AppColors.gold : AppColors.textSecondary),
                const SizedBox(width: AppDimens.space8),
              ],
              Text(
                label.toUpperCase(),
                style: AppTextStyles.labelSmall.copyWith(
                  color: selected ? AppColors.gold : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


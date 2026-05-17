// Archivo: lib/features/dashboard/presentation/widgets/unit_telemetry_console.dart
// Consola de telemetría: StatusTag + HudReactorBar + micro-lecturas de la unidad.
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/hud/hud_divider.dart';
import 'package:botslode/core/ui/hud/hud_reactor_bar.dart';
import 'package:botslode/core/ui/panels/holo_panel.dart';
import 'package:botslode/core/ui/widgets/status_tag.dart';
import 'package:botslode/features/dashboard/domain/models/bot.dart';
import 'package:botslode/features/dashboard/presentation/widgets/unit_mood_colors.dart';
import 'package:flutter/material.dart';

/// Formatea una duración desde [start] hasta ahora: 'Xd Xh' o 'Xh Xm'.
String _formatUptime(DateTime start) {
  final diff = DateTime.now().difference(start);
  if (diff.isNegative) return '--';
  final days = diff.inDays;
  final hours = diff.inHours % 24;
  final minutes = diff.inMinutes % 60;
  if (days > 0) return '${days}d ${hours}h';
  return '${hours}h ${minutes}m';
}

/// Consola de telemetría con StatusTag, HudReactorBar y micro-lecturas.
class UnitTelemetryConsole extends StatelessWidget {
  final Bot bot;
  final int moodIndex;
  final UnitStatus unitStatus;

  const UnitTelemetryConsole({
    super.key,
    required this.bot,
    required this.moodIndex,
    required this.unitStatus,
  });

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    final moodColor = unitMoodColor(moodIndex);

    final bool pulsing =
        unitStatus != UnitStatus.offline && !reduced;
    final Duration reactorDuration = unitStatus == UnitStatus.processing
        ? const Duration(milliseconds: 900)
        : AppMotion.durHeartbeat;

    Widget content = HoloPanel(
      shape: HoloPanelShape.rounded,
      padding: const EdgeInsets.all(AppDimens.space16),
      borderColor: AppColors.borderDefault,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: StatusTag + label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusTag(status: unitStatus),
              Text(
                '// TELEMETRÍA',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space12),
          const HudDivider(),
          const SizedBox(height: AppDimens.space12),

          // Row 2: HudReactorBar horizontal
          HudReactorBar(
            axis: Axis.horizontal,
            thickness: 6,
            color: moodColor,
            pulsing: pulsing,
            duration: reactorDuration,
          ),
          const SizedBox(height: AppDimens.space12),

          // Row 3: 2-column readings grid
          _buildReadingsGrid(moodIndex),
        ],
      ),
    );

    // Entry animation: fade + translateY 12px, durBase, delay 60ms
    if (!reduced) {
      content = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: AppMotion.durBase,
        curve: AppMotion.easeEntrance,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1.0 - value) * 12.0),
              child: child,
            ),
          );
        },
        child: content,
      );
    } else {
      content = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: AppMotion.durCrossfadeReduced,
        curve: Curves.linear,
        builder: (context, value, child) {
          return Opacity(opacity: value, child: child);
        },
        child: content,
      );
    }

    return content;
  }

  Widget _buildReadingsGrid(int moodIdx) {
    final uptime = _formatUptime(bot.cycleStartDate);
    final shortId = bot.id.length >= 8
        ? bot.id.substring(0, 8).toUpperCase()
        : bot.id.toUpperCase();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Column 1: MODO + UPTIME
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReadingPair(label: 'MODO', value: unitMoodName(moodIdx)),
              const SizedBox(height: AppDimens.space12),
              _ReadingPair(label: 'UPTIME', value: uptime),
            ],
          ),
        ),
        const SizedBox(width: AppDimens.space12),

        // Column 2: SESIÓN + LATENCIA
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReadingPair(label: 'SESIÓN', value: shortId),
              const SizedBox(height: AppDimens.space12),
              const _ReadingPair(label: 'LATENCIA', value: '--'),
            ],
          ),
        ),
      ],
    );
  }
}

/// Par de label + valor para la grilla de micro-lecturas.
class _ReadingPair extends StatelessWidget {
  final String label;
  final String value;

  const _ReadingPair({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isEmpty = value == '--';
    return Semantics(
      label: '$label: $value',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: AppDimens.space2),
            Text(
              value,
              style: AppTextStyles.hudReadout.copyWith(
                color: isEmpty ? AppColors.textTertiary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

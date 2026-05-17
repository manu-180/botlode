// Archivo: lib/features/dashboard/presentation/widgets/metric_card.dart
// Tarjeta de telemetría reutilizable «Hangar OS».
// Muestra: ícono + label, HudTicker de valor, micro-tendencia y barra de progreso opcional.
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/hud/hud_ticker.dart';
import 'package:botslode/core/ui/panels/holo_panel.dart';
import 'package:flutter/material.dart';

const _kTrendIconSize = 12.0;

class MetricCard extends StatefulWidget {
  final String label;
  final double value;
  final String unit;
  final IconData icon;
  final Color accentColor;

  /// null = sin datos ("--"), positivo = tendencia arriba, negativo = tendencia abajo.
  final double? trendPercent;

  final bool showProgress;

  /// 0..1, solo se usa cuando [showProgress] es true.
  final double progress;

  final Widget? trailingAction;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    this.accentColor = AppColors.cyan,
    this.trendPercent,
    this.showProgress = false,
    this.progress = 0.0,
    this.trailingAction,
  });

  @override
  State<MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<MetricCard> {
  bool _hovered = false;
  double _lastProgress = 0.0;

  @override
  void didUpdateWidget(MetricCard old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress) {
      _lastProgress = old.progress.clamp(0.0, 1.0);
    }
  }

  String get _semanticsLabel {
    final trendLabel = widget.trendPercent == null
        ? '--'
        : widget.trendPercent! > 0
            ? '+${widget.trendPercent!.toStringAsFixed(1)}%'
            : '${widget.trendPercent!.toStringAsFixed(1)}%';
    return '${widget.label}: ${widget.value.toStringAsFixed(1)} ${widget.unit}, tendencia $trendLabel';
  }

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduced(context);

    return Semantics(
      label: _semanticsLabel,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: HoloPanel(
          borderColor: AppColors.borderDefault,
          padding: const EdgeInsets.all(AppDimens.space20),
          glowAccent: _hovered ? widget.accentColor : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row: icon + label + optional trailing
              Row(
                children: [
                  Icon(
                    widget.icon,
                    size: AppDimens.iconS,
                    color: widget.accentColor,
                  ),
                  const SizedBox(width: AppDimens.space8),
                  Expanded(
                    child: Text(
                      widget.label.toUpperCase(),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (widget.trailingAction != null) widget.trailingAction!,
                ],
              ),

              const SizedBox(height: AppDimens.space16),

              // Ticker row: value + unit
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  HudTicker(
                    value: widget.value,
                    decimals: 1,
                    style: AppTextStyles.numericTicker.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    animate: !reduce,
                  ),
                  const SizedBox(width: AppDimens.space8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppDimens.space4),
                    child: Text(
                      widget.unit,
                      style: AppTextStyles.bodyS.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDimens.space8),

              // Micro-trend row
              _buildTrendRow(),

              // Optional progress bar
              if (widget.showProgress) ...[
                const SizedBox(height: AppDimens.space12),
                _buildProgressBar(reduce),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendRow() {
    final tp = widget.trendPercent;

    if (tp == null) {
      return Row(
        children: [
          Text(
            '--',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: AppDimens.space4),
          Text(
            'vs. ciclo previo',
            style: AppTextStyles.bodyS.copyWith(color: AppColors.textTertiary),
          ),
        ],
      );
    }

    final Color trendColor;
    final IconData trendIcon;
    final String trendText;

    if (tp > 0) {
      trendColor = AppColors.success;
      trendIcon = Icons.trending_up_rounded;
      trendText = '+${tp.toStringAsFixed(1)}%';
    } else if (tp < 0) {
      trendColor = AppColors.danger;
      trendIcon = Icons.trending_down_rounded;
      trendText = '${tp.toStringAsFixed(1)}%';
    } else {
      trendColor = AppColors.textTertiary;
      trendIcon = Icons.trending_flat_rounded;
      trendText = '0.0%';
    }

    return Row(
      children: [
        Icon(trendIcon, size: _kTrendIconSize, color: trendColor),
        const SizedBox(width: AppDimens.space4),
        Text(
          trendText,
          style: AppTextStyles.labelSmall.copyWith(color: trendColor),
        ),
        const SizedBox(width: AppDimens.space4),
        Text(
          'vs. ciclo previo',
          style: AppTextStyles.bodyS.copyWith(color: AppColors.textTertiary),
        ),
      ],
    );
  }

  Widget _buildProgressBar(bool reduce) {
    final clampedProgress = widget.progress.clamp(0.0, 1.0);

    return Container(
      height: AppDimens.space4,
      decoration: BoxDecoration(
        color: AppColors.surfaceHud,
        borderRadius: AppDimens.brPill,
      ),
      child: ClipRRect(
        borderRadius: AppDimens.brPill,
        child: reduce
            ? FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: clampedProgress,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.gradGold,
                    borderRadius: AppDimens.brPill,
                  ),
                ),
              )
            : TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: _lastProgress, end: clampedProgress),
                duration: AppMotion.durSlow,
                curve: AppMotion.easeStandard,
                builder: (context, value, _) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.gradGold,
                      borderRadius: AppDimens.brPill,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

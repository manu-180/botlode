// Archivo: lib/features/dashboard/presentation/widgets/usage_chart.dart
// Mini gráfico de área para actividad de mensajes «Hangar OS».
// Usa fl_chart cuando hay datos; EmptyState cuando no hay datos.
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/panels/holo_panel.dart';
import 'package:botslode/core/ui/states/empty_state.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

const _kChartHeight = 180.0;
const _kAxisFontSize = 10.0;
const _kAxisBottomReserved = 20.0;
const _kAxisLeftReserved = 28.0;

class UsageChart extends StatefulWidget {
  final List<FlSpot> dataPoints;
  final int total;

  /// Etiqueta del día pico para Semantics. Null si no hay datos.
  final String? peakLabel;

  const UsageChart({
    super.key,
    required this.dataPoints,
    required this.total,
    this.peakLabel,
  });

  @override
  State<UsageChart> createState() => _UsageChartState();
}

class _UsageChartState extends State<UsageChart> {
  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduced(context);

    return Semantics(
      label:
          'Mensajes últimos 14 días, total ${widget.total}${widget.peakLabel != null ? ", pico el día ${widget.peakLabel}" : ""}',
      child: HoloPanel(
        borderColor: AppColors.borderDefault,
        padding: const EdgeInsets.all(AppDimens.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Text(
                    '// MENSAJES · ÚLTIMOS 14 DÍAS',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                // Total count chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.space8,
                    vertical: AppDimens.space2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHud,
                    borderRadius: AppDimens.brS,
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: Text(
                    '${widget.total}',
                    style: AppTextStyles.mono.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimens.space16),

            // Chart or empty state
            SizedBox(
              height: _kChartHeight,
              child: widget.dataPoints.isEmpty
                  ? const EmptyState(
                      icon: Icons.bar_chart_rounded,
                      title: 'Sin actividad registrada todavía',
                    )
                  : _buildChart(reduce),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(bool reduce) {
    final chart = LineChart(
      _buildChartData(),
      duration: reduce ? Duration.zero : AppMotion.durBase,
    );

    if (reduce) return chart;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: AppMotion.durDeliberate,
      curve: AppMotion.easeEntrance,
      builder: (context, value, child) => Opacity(opacity: value, child: child),
      child: chart,
    );
  }

  LineChartData _buildChartData() {
    return LineChartData(
      lineBarsData: [
        LineChartBarData(
          spots: widget.dataPoints,
          isCurved: true,
          curveSmoothness: 0.35,
          color: AppColors.cyan,
          barWidth: 2,
          dotData: FlDotData(
            show: false, // default hidden
            checkToShowDot: (spot, barData) => false,
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: AppColors.gradCyanData,
          ),
        ),
      ],
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => const FlLine(
          color: AppColors.borderSubtle,
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) => Text(
              'D${value.toInt()}',
              style: AppTextStyles.mono.copyWith(
                color: AppColors.textTertiary,
                fontSize: _kAxisFontSize,
              ),
            ),
            reservedSize: _kAxisBottomReserved,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) => Text(
              value.toInt().toString(),
              style: AppTextStyles.mono.copyWith(
                color: AppColors.textTertiary,
                fontSize: _kAxisFontSize,
              ),
            ),
            reservedSize: _kAxisLeftReserved,
          ),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        getTouchedSpotIndicator: (barData, spotIndexes) {
          return spotIndexes.map((idx) {
            return TouchedSpotIndicatorData(
              FlLine(
                color: AppColors.cyan.withValues(alpha: 0.3),
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
              FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.cyan,
                  strokeWidth: 2,
                  strokeColor: AppColors.surfaceRaised,
                ),
              ),
            );
          }).toList();
        },
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.surfaceRaised,
          getTooltipItems: (spots) => spots
              .map(
                (s) => LineTooltipItem(
                  s.y.toStringAsFixed(0),
                  AppTextStyles.hudReadout,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

// Archivo: lib/features/dashboard/presentation/widgets/tabs/bot_dashboard_tab.dart
// Tab 0 del detalle de bot — bento-grid de telemetría con animaciones escalonadas.
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/ui/hud/hud_divider.dart';
import 'package:botslode/core/ui/widgets/error_feedback_card.dart';
import 'package:botslode/core/ui/widgets/skeleton_base.dart';
import 'package:botslode/features/dashboard/domain/models/bot.dart';
import 'package:botslode/features/dashboard/presentation/widgets/metric_card.dart';
import 'package:botslode/features/dashboard/presentation/widgets/usage_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BotDashboardTab extends StatelessWidget {
  final Bot bot;
  final bool isActive;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function()? onRetry;

  const BotDashboardTab({
    super.key,
    required this.bot,
    required this.isActive,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
  });

  // --- Helpers de estado de bot ---

  Color _statusColor() => switch (bot.status) {
        BotStatus.active => AppColors.success,
        BotStatus.maintenance => AppColors.warning,
        BotStatus.disabled => AppColors.danger,
        BotStatus.creditSuspended => AppColors.danger,
      };

  double _statusScore() => switch (bot.status) {
        BotStatus.active => 100.0,
        BotStatus.maintenance => 60.0,
        BotStatus.disabled => 0.0,
        BotStatus.creditSuspended => 0.0,
      };

  // --- Datos de las tarjetas ---

  List<_CardData> _cardData() => [
        const _CardData(
          label: 'MENSAJES HOY',
          value: 0.0,
          unit: 'msgs',
          icon: Icons.chat_bubble_outline_rounded,
          accentColor: AppColors.cyan,
          trendPercent: null,
        ),
        const _CardData(
          label: 'SESIONES',
          value: 0.0,
          unit: 'sesiones',
          icon: Icons.groups_rounded,
          accentColor: AppColors.cyan,
          trendPercent: null,
        ),
        _CardData(
          label: 'TIEMPO ACTIVO',
          value: bot.daysActivePrecise * 24,
          unit: 'hs',
          icon: Icons.access_time_rounded,
          accentColor: AppColors.gold,
          trendPercent: null,
        ),
        _CardData(
          label: 'ESTADO DE CICLO',
          value: _statusScore(),
          unit: '%',
          icon: Icons.power_settings_new_rounded,
          accentColor: _statusColor(),
          trendPercent: null,
        ),
        _CardData(
          label: 'CONSUMO DEL CICLO',
          value: bot.daysActivePrecise,
          unit: 'días',
          icon: Icons.timeline_rounded,
          accentColor: AppColors.gold,
          trendPercent: null,
          showProgress: true,
          progress: bot.cycleProgress,
        ),
      ];

  // --- Build de una tarjeta individual con animación de entrada ---

  Widget _animatedCard({
    required Widget child,
    required int index,
    required bool reduce,
  }) {
    if (reduce) {
      return child
          .animate()
          .fadeIn(duration: AppMotion.durCrossfadeReduced);
    }

    return child
        .animate(delay: AppMotion.staggerDelay(index))
        .fadeIn(
          duration: AppMotion.durBase,
          curve: AppMotion.easeEntrance,
        )
        .moveY(
          begin: 12,
          end: 0,
          duration: AppMotion.durBase,
          curve: AppMotion.easeEntrance,
        );
  }

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduced(context);
    final cards = _cardData();

    if (isLoading) {
      return Semantics(
        label: 'Cargando métricas',
        liveRegion: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppDimens.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HudDivider(label: 'RENDIMIENTO'),
              const SizedBox(height: AppDimens.space16),
              _buildSkeletonGrid(),
              const SizedBox(height: AppDimens.space32),
              const HudDivider(label: 'ACTIVIDAD'),
              const SizedBox(height: AppDimens.space16),
              _buildChartSkeleton(),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppDimens.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HudDivider(label: 'RENDIMIENTO'),
          const SizedBox(height: AppDimens.space16),

          // Bento grid
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final use2Col = width >= 580;

              if (use2Col) {
                return _build2ColGrid(cards, reduce);
              } else {
                return _build1ColGrid(cards, reduce);
              }
            },
          ),

          const SizedBox(height: AppDimens.space32),
          const HudDivider(label: 'ACTIVIDAD'),
          const SizedBox(height: AppDimens.space16),

          // Usage chart (index 5 = after all 5 metric cards)
          errorMessage != null
              ? ErrorFeedbackCard(
                  title: 'Error al cargar métricas',
                  message: errorMessage!,
                  onRetry: onRetry ?? () async {},
                  variant: ErrorVariant.inline,
                )
              : _animatedCard(
                  index: 5,
                  reduce: reduce,
                  child: const UsageChart(
                    dataPoints: <FlSpot>[],
                    total: 0,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildSkeletonGrid() {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildCardSkeleton()),
              const SizedBox(width: AppDimens.space20),
              Expanded(child: _buildCardSkeleton()),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.space20),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildCardSkeleton()),
              const SizedBox(width: AppDimens.space20),
              Expanded(child: _buildCardSkeleton()),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.space20),
        _buildCardSkeleton(), // full-width
      ],
    );
  }

  Widget _buildCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space20),
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: AppDimens.brL,
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBase(width: 100, height: 10),
          SizedBox(height: AppDimens.space16),
          SkeletonBase(width: 72, height: 28),
          SizedBox(height: AppDimens.space8),
          SkeletonBase(width: 120, height: 10),
        ],
      ),
    );
  }

  Widget _buildChartSkeleton() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space24),
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: AppDimens.brL,
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBase(width: 220, height: 10),
          SizedBox(height: AppDimens.space16),
          SkeletonBase(width: double.infinity, height: 180),
        ],
      ),
    );
  }

  Widget _build2ColGrid(List<_CardData> cards, bool reduce) {
    // cards[0..3] = 4 first cards in 2×2 grid
    // cards[4]   = full-width span
    return Column(
      children: [
        // Row 1: MENSAJES HOY + SESIONES
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _animatedCard(
                  index: 0,
                  reduce: reduce,
                  child: _buildMetricCard(cards[0]),
                ),
              ),
              const SizedBox(width: AppDimens.space20),
              Expanded(
                child: _animatedCard(
                  index: 1,
                  reduce: reduce,
                  child: _buildMetricCard(cards[1]),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppDimens.space20),

        // Row 2: TIEMPO ACTIVO + ESTADO DE CICLO
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _animatedCard(
                  index: 2,
                  reduce: reduce,
                  child: _buildMetricCard(cards[2]),
                ),
              ),
              const SizedBox(width: AppDimens.space20),
              Expanded(
                child: _animatedCard(
                  index: 3,
                  reduce: reduce,
                  child: _buildMetricCard(cards[3]),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppDimens.space20),

        // Row 3: CONSUMO DEL CICLO (full width)
        _animatedCard(
          index: 4,
          reduce: reduce,
          child: _buildMetricCard(cards[4]),
        ),
      ],
    );
  }

  Widget _build1ColGrid(List<_CardData> cards, bool reduce) {
    return Column(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(height: AppDimens.space20),
          _animatedCard(
            index: i,
            reduce: reduce,
            child: _buildMetricCard(cards[i]),
          ),
        ],
      ],
    );
  }

  Widget _buildMetricCard(_CardData data) {
    return MetricCard(
      label: data.label,
      value: data.value,
      unit: data.unit,
      icon: data.icon,
      accentColor: data.accentColor,
      trendPercent: data.trendPercent,
      showProgress: data.showProgress,
      progress: data.progress,
    );
  }
}

// Estructura interna de datos por tarjeta
class _CardData {
  final String label;
  final double value;
  final String unit;
  final IconData icon;
  final Color accentColor;
  final double? trendPercent;
  final bool showProgress;
  final double progress;

  const _CardData({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.accentColor,
    this.trendPercent,
    this.showProgress = false,
    this.progress = 0.0,
  });
}

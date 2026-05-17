// lib/features/dashboard/presentation/widgets/credit_hud_panel.dart
// Panel de crédito HUD — instrumento sci-fi del Hangar OS.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_dimens.dart';
import '../../../../core/config/theme/app_motion.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../../../core/ui/buttons/app_button.dart';
import '../../../../core/ui/hud/hud.dart';
import '../../../../core/ui/panels/holo_panel.dart';
import '../../../../core/ui/widgets/skeleton_base.dart';
import '../../../billing/presentation/providers/billing_provider.dart';

class CreditHudPanel extends StatelessWidget {
  final AsyncValue<BillingState> billingAsync;
  final VoidCallback onAssemble;
  final VoidCallback onPayCard;
  final VoidCallback onPayLink;

  const CreditHudPanel({
    super.key,
    required this.billingAsync,
    required this.onAssemble,
    required this.onPayCard,
    required this.onPayLink,
  });

  @override
  Widget build(BuildContext context) {
    if (billingAsync.isLoading ||
        (billingAsync.value == null && !billingAsync.hasError)) {
      return _buildSkeleton();
    }

    if (billingAsync.hasError) {
      return _buildError();
    }

    final billing = billingAsync.value!;
    return _buildPanel(billing);
  }

  Widget _buildSkeleton() {
    return ClipPath(
      clipper: const ChamferClipper(chamfer: AppDimens.chamferM),
      child: Container(
        height: 130,
        decoration: const ShapeDecoration(
          color: AppColors.glassSurface,
          shape: ChamferBorder(
            chamfer: AppDimens.chamferM,
            side: BorderSide(color: AppColors.glassBorder),
          ),
        ),
        padding: const EdgeInsets.all(AppDimens.space20),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBase(width: 80, height: 24),
            SizedBox(height: AppDimens.space12),
            SkeletonBase(width: double.infinity, height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      decoration: ShapeDecoration(
        shape: ChamferBorder(
          chamfer: AppDimens.chamferM,
          side: BorderSide(
            color: AppColors.danger.withValues(alpha: 0.6),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.space20),
        child: Text(
          'No se pudo leer el estado de crédito',
          style: AppTextStyles.bodyS.copyWith(color: AppColors.danger),
        ),
      ),
    );
  }

  Widget _buildPanel(BillingState billing) {
    final health = billing.health;
    final usagePercent = billing.usagePercentage;

    final stateColor = switch (health) {
      FinanceHealth.stable   => AppColors.gold,
      FinanceHealth.warning  => AppColors.warning,
      FinanceHealth.critical => AppColors.danger,
    };

    final borderColor = switch (health) {
      FinanceHealth.stable   => AppColors.borderGold,
      FinanceHealth.warning  => AppColors.warning.withValues(alpha: 0.5),
      FinanceHealth.critical => AppColors.danger.withValues(alpha: 0.6),
    };

    final glowColor = switch (health) {
      FinanceHealth.stable   => AppColors.goldGlow,
      FinanceHealth.warning  => AppColors.warningGlow,
      FinanceHealth.critical => AppColors.dangerGlow,
    };

    final reactorDuration = switch (health) {
      FinanceHealth.stable   => const Duration(milliseconds: 1800),
      FinanceHealth.warning  => AppMotion.durHeartbeat,
      FinanceHealth.critical => const Duration(milliseconds: 1100),
    };

    final labelText =
        health == FinanceHealth.critical ? '!!! CRÉDITO AGOTADO !!!' : 'USO DE CRÉDITO';

    final available =
        (billing.creditLimit - billing.totalDebt).clamp(0.0, double.infinity);

    return Semantics(
      liveRegion: true,
      label:
          'Crédito usado: \$${billing.totalDebt.toInt()} de \$${billing.creditLimit.toInt()}, estado: ${health.name}',
      child: HudCornerBrackets(
        color: borderColor,
        child: HoloPanel(
            shape: HoloPanelShape.chamfer,
            padding: EdgeInsets.zero,
            cornerBrackets: false,
            scanlines: true,
            borderColor: borderColor,
            glowAccent: glowColor,
            child: Stack(
              children: [
                const Positioned.fill(
                  child: IgnorePointer(
                    child: HudGridTexture(opacity: 0.04),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppDimens.space20),
                  child: _buildContent(
                    billing: billing,
                    health: health,
                    usagePercent: usagePercent,
                    stateColor: stateColor,
                    reactorDuration: reactorDuration,
                    labelText: labelText,
                    available: available,
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildContent({
    required BillingState billing,
    required FinanceHealth health,
    required double usagePercent,
    required Color stateColor,
    required Duration reactorDuration,
    required String labelText,
    required double available,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HudReactorBar(
          axis: Axis.vertical,
          thickness: 6,
          color: stateColor,
          pulsing: true,
          duration: reactorDuration,
        ),
        const SizedBox(width: AppDimens.space16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: AppMotion.durBase,
                child: Text(
                  labelText,
                  key: ValueKey(health),
                  style: AppTextStyles.label.copyWith(
                    color: stateColor,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.space8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  HudTicker(
                    value: billing.totalDebt,
                    prefix: '\$ ',
                    decimals: 2,
                    style: AppTextStyles.numericTicker.copyWith(
                      color: stateColor,
                      fontSize: 28,
                    ),
                  ),
                  Text(
                    ' / \$${billing.creditLimit.toInt()}',
                    style: AppTextStyles.hudReadout.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.space12),
              HudSegmentedBar(value: usagePercent),
              const SizedBox(height: AppDimens.space12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _MicroReading(
                    label: 'LÍMITE',
                    value: '\$${billing.creditLimit.toInt()}',
                    valueColor: AppColors.textSecondary,
                  ),
                  _MicroReading(
                    label: 'DISPONIBLE',
                    value: '\$${available.toInt()}',
                    valueColor: stateColor,
                  ),
                  _MicroReading(
                    label: 'USO',
                    value: '${(usagePercent * 100).round()}%',
                    valueColor: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.space16),
              _SmartActionButton(
                isCritical: health == FinanceHealth.critical,
                hasCard: billing.primaryCard != null,
                debtAmount: billing.totalDebt,
                onAssemble: onAssemble,
                onPayCard: onPayCard,
                onPayLink: onPayLink,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── MICRO READING ────────────────────────────────────────────────────────────

class _MicroReading extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _MicroReading({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.hudReadout.copyWith(color: valueColor),
        ),
      ],
    );
  }
}

// ─── SMART ACTION BUTTON ──────────────────────────────────────────────────────

class _SmartActionButton extends StatelessWidget {
  final bool isCritical;
  final bool hasCard;
  final double debtAmount;
  final VoidCallback onAssemble;
  final VoidCallback onPayCard;
  final VoidCallback onPayLink;

  const _SmartActionButton({
    required this.isCritical,
    required this.hasCard,
    required this.debtAmount,
    required this.onAssemble,
    required this.onPayCard,
    required this.onPayLink,
  });

  @override
  Widget build(BuildContext context) {
    if (!isCritical) {
      return AppButton.primary(
        label: 'Ensamblar unidad',
        onPressed: onAssemble,
        leadingIcon: Icons.add_rounded,
      );
    }
    if (hasCard) {
      return AppButton.danger(
        label: 'Pagar \$${debtAmount.toInt()} ahora',
        onPressed: onPayCard,
        leadingIcon: Icons.flash_on_rounded,
      );
    }
    return AppButton.secondary(
      label: 'Pagar online',
      onPressed: onPayLink,
      leadingIcon: FontAwesomeIcons.handshake,
    );
  }
}

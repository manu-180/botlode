// lib/features/dashboard/presentation/views/dashboard_view.dart
// Dashboard «Bahía de Carga» — Hangar OS. Grilla de unidades + HUD de crédito.
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/buttons/app_button.dart';
import 'package:botslode/core/ui/hud/hud_corner_brackets.dart';
import 'package:botslode/core/ui/hud/hud_reactor_bar.dart';
import 'package:botslode/core/ui/hud/hud_ticker.dart';
import 'package:botslode/core/ui/loading/skeleton_shimmer.dart';
import 'package:botslode/core/ui/states/empty_state.dart';
import 'package:botslode/core/ui/states/error_state.dart';
import 'package:botslode/core/ui/widgets/page_title.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/widgets/payment_checkout_modal.dart';
import 'package:botslode/features/dashboard/presentation/providers/dashboard_controller.dart';
import 'package:botslode/features/dashboard/presentation/widgets/bot_card.dart';
import 'package:botslode/features/dashboard/presentation/widgets/create_bot_modal.dart';
import 'package:botslode/features/dashboard/presentation/widgets/dashboard_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class _DialogSubmitIntent extends Intent {
  const _DialogSubmitIntent();
}

class DashboardView extends ConsumerWidget {
  static const String routeName = 'dashboard';

  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final botsAsync = ref.watch(filteredBotsProvider);
    final billingAsync = ref.watch(billingProvider);

    final billingState = billingAsync.valueOrNull;
    final totalDebt   = billingState?.totalDebt ?? 0.0;
    final limit       = billingState?.creditLimit ?? 0.0;
    final dollarRate  = billingState?.dollarRate ?? 1200.0;
    final statusColor = billingState?.statusColor ?? AppColors.gold;
    final usagePercent= billingState?.usagePercentage ?? 0.0;
    final isCritical  = billingState?.health == FinanceHealth.critical;
    final hasCard     = billingState?.primaryCard != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingScreen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── HEADER ────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PageTitle(
                  title: 'BAHÍA DE CARGA',
                  subtitle: 'Gestión operativa de unidades autónomas',
                  style: PageTitleStyle.techBar,
                ),
                _CreditHudPanel(
                  totalDebt: totalDebt,
                  limit: limit,
                  dollarRate: dollarRate,
                  statusColor: statusColor,
                  usagePercent: usagePercent,
                  isCritical: isCritical,
                  hasCard: hasCard,
                  onAssemble: () => showDialog(
                    context: context,
                    builder: (_) => const CreateBotModal(),
                  ),
                  onPayCard: () => _confirmPayment(context, ref, totalDebt),
                  onPayLink: () => showDialog(
                    context: context,
                    builder: (_) => PaymentCheckoutModal(
                      amount: totalDebt,
                      exchangeRate: dollarRate,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimens.space24),
            const DashboardToolbar(),
            const SizedBox(height: AppDimens.space24),

            // ─── GRID ───────────────────────────────────────────────
            Expanded(
              child: botsAsync.when(
                loading: () => const _DashboardSkeleton(),
                error: (err, _) => ErrorScreen(
                  title: 'Error de enlace',
                  message: err.toString(),
                  retryLabel: 'Reintentar',
                  onRetry: () => ref.invalidate(filteredBotsProvider),
                ),
                data: (bots) => bots.isEmpty
                    ? EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No se encontraron unidades',
                        message: 'Ensambla tu primer bot para comenzar.',
                        actionLabel: 'Ensamblar unidad',
                        onAction: () => showDialog(
                          context: context,
                          builder: (_) => const CreateBotModal(),
                        ),
                      )
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 400,
                          childAspectRatio: 1.4,
                          crossAxisSpacing: AppDimens.gapCard,
                          mainAxisSpacing: AppDimens.gapCard,
                        ),
                        itemCount: bots.length,
                        itemBuilder: (context, index) {
                          final bot = bots[index];
                          return BotCard(
                            bot: bot,
                            staggerIndex: index,
                            onTap: () => context.goNamed(
                              'bot_detail',
                              pathParameters: {'botId': bot.id},
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmPayment(BuildContext context, WidgetRef ref, double amount) {
    showDialog(
      context: context,
      builder: (c) => Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): _DialogSubmitIntent()
        },
        child: Actions(
          actions: {
            _DialogSubmitIntent: CallbackAction<_DialogSubmitIntent>(
              onInvoke: (_) {
                Navigator.pop(c);
                ref.read(billingProvider.notifier).processPayment(amount);
                return null;
              },
            ),
          },
          child: AlertDialog(
            backgroundColor: AppColors.surfaceRaised,
            shape: RoundedRectangleBorder(
              borderRadius: AppDimens.brXL,
              side: const BorderSide(color: AppColors.success),
            ),
            title: Text(
              'CONFIRMAR PAGO RÁPIDO',
              style: AppTextStyles.titleL,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Se debitará el total adeudado de su tarjeta principal.',
                  style: AppTextStyles.bodyM.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDimens.space20),
                HudTicker(
                  value: amount,
                  prefix: '\$ ',
                  suffix: ' USD',
                  decimals: 2,
                  style: AppTextStyles.numericTicker.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            actions: [
              AppButton.ghost(
                label: 'Cancelar',
                onPressed: () => Navigator.pop(c),
              ),
              AppButton.primary(
                label: 'Pagar ahora',
                onPressed: () {
                  Navigator.pop(c);
                  ref.read(billingProvider.notifier).processPayment(amount);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── CREDIT HUD PANEL ─────────────────────────────────────────────────────────

class _CreditHudPanel extends StatelessWidget {
  final double totalDebt;
  final double limit;
  final double dollarRate;
  final Color statusColor;
  final double usagePercent;
  final bool isCritical;
  final bool hasCard;
  final VoidCallback onAssemble;
  final VoidCallback onPayCard;
  final VoidCallback onPayLink;

  const _CreditHudPanel({
    required this.totalDebt,
    required this.limit,
    required this.dollarRate,
    required this.statusColor,
    required this.usagePercent,
    required this.isCritical,
    required this.hasCard,
    required this.onAssemble,
    required this.onPayCard,
    required this.onPayLink,
  });

  @override
  Widget build(BuildContext context) {
    return HudCornerBrackets(
      color: statusColor.withValues(alpha: 0.5),
      child: AnimatedContainer(
        duration: AppMotion.durBase,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space20,
          vertical: AppDimens.space16,
        ),
        decoration: BoxDecoration(
          color: AppColors.glassSurface,
          borderRadius: AppDimens.brL,
          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          boxShadow: AppDimens.glowStatus(statusColor),
        ),
        child: Row(
          children: [
            // ── Lectura de crédito ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isCritical ? '!!! CRÉDITO AGOTADO !!!' : 'USO DE CRÉDITO',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: statusColor,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: AppDimens.space4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    HudTicker(
                      value: totalDebt,
                      prefix: '\$ ',
                      decimals: 2,
                      style: AppTextStyles.numericTicker.copyWith(
                        color: statusColor,
                        fontSize: 24,
                      ),
                    ),
                    Text(
                      ' / \$${limit.toInt()}',
                      style: AppTextStyles.bodyM.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.space8),
                HudReactorBar(
                  axis: Axis.horizontal,
                  pulsing: !isCritical,
                  color: statusColor,
                  length: 150,
                  thickness: 4,
                ),
              ],
            ),
            const SizedBox(width: AppDimens.space24),
            // ── CTA mutante ──
            _SmartActionButton(
              isCritical: isCritical,
              hasCard: hasCard,
              debtAmount: totalDebt,
              onAssemble: onAssemble,
              onPayCard: onPayCard,
              onPayLink: onPayLink,
            ),
          ],
        ),
      ),
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

// ─── DASHBOARD SKELETON ───────────────────────────────────────────────────────

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        childAspectRatio: 1.4,
        crossAxisSpacing: AppDimens.gapCard,
        mainAxisSpacing: AppDimens.gapCard,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const BotCardSkeleton(),
    );
  }
}

// Archivo: lib/features/billing/presentation/widgets/subscription_summary_card.dart
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/billing/domain/models/plan.dart';
import 'package:botslode/features/billing/presentation/widgets/empty_state.dart';
import 'package:botslode/features/billing/domain/models/subscription.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class SubscriptionSummaryCard extends ConsumerWidget {
  const SubscriptionSummaryCard({
    super.key,
    this.onChangePlan,
    this.onCancel,
    this.onReactivate,
    this.onUpdatePayment,
    this.onCompletePayment,
    this.onViewPlans,
    this.now,
  });

  final VoidCallback? onChangePlan;
  final VoidCallback? onCancel;
  final VoidCallback? onReactivate;
  final VoidCallback? onUpdatePayment;
  final VoidCallback? onCompletePayment;
  final VoidCallback? onViewPlans;

  @visibleForTesting
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billingAsync = ref.watch(billingV2Provider);
    return billingAsync.when(
      loading: _buildSkeleton,
      error: (_, __) => const SizedBox.shrink(),
      data: (state) {
        final sub = state.subscription;
        if (sub == null) {
          return BillingEmptyState(
            illustration: const Icon(Icons.workspace_premium_rounded, size: 48, color: Colors.white24),
            title: 'No tenés una suscripción activa',
            subtitle: 'Elegí un plan para comenzar a usar BotLode.',
            ctaLabel: 'Ver planes',
            onCta: onViewPlans,
          );
        }
        final plan =
            state.availablePlans.where((p) => p.id == sub.planId).firstOrNull;
        return _CardBody(
          subscription: sub,
          plan: plan,
          now: now ?? DateTime.now(),
          onChangePlan: onChangePlan,
          onCancel: onCancel,
          onReactivate: onReactivate,
          onUpdatePayment: onUpdatePayment,
          onCompletePayment: onCompletePayment,
        );
      },
    );
  }

  static Widget _buildSkeleton() => Container(
        height: 180,
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F13),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderGlass),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.subscription,
    required this.plan,
    required this.now,
    this.onChangePlan,
    this.onCancel,
    this.onReactivate,
    this.onUpdatePayment,
    this.onCompletePayment,
  });

  final Subscription subscription;
  final Plan? plan;
  final DateTime now;
  final VoidCallback? onChangePlan;
  final VoidCallback? onCancel;
  final VoidCallback? onReactivate;
  final VoidCallback? onUpdatePayment;
  final VoidCallback? onCompletePayment;

  static final _dateFmt = DateFormat('d MMM yyyy');

  Color get _borderColor {
    if (subscription.cancelAtPeriodEnd) {
      return AppColors.warning.withValues(alpha: 0.4);
    }
    return switch (subscription.status) {
      SubscriptionStatus.active => AppColors.primary.withValues(alpha: 0.3),
      SubscriptionStatus.trialing => AppColors.secondary.withValues(alpha: 0.3),
      SubscriptionStatus.pastDue => AppColors.warning.withValues(alpha: 0.4),
      SubscriptionStatus.canceled => AppColors.error.withValues(alpha: 0.2),
      SubscriptionStatus.incomplete => AppColors.warning.withValues(alpha: 0.4),
    };
  }

  @override
  Widget build(BuildContext context) {
    final planName = plan?.name ?? subscription.planId;
    final priceText = plan != null ? _formatPrice(plan!) : null;
    final periodEndFormatted = subscription.currentPeriodEnd != null
        ? _dateFmt.format(subscription.currentPeriodEnd!)
        : null;

    final isActiveOrTrialing =
        subscription.status == SubscriptionStatus.active ||
            subscription.status == SubscriptionStatus.trialing;

    final showChangePlan = isActiveOrTrialing;
    final showCancel = isActiveOrTrialing && !subscription.cancelAtPeriodEnd;
    final showReactivate = subscription.cancelAtPeriodEnd;
    final showUpdatePayment =
        subscription.status == SubscriptionStatus.pastDue;
    final showCompletePayment =
        subscription.status == SubscriptionStatus.incomplete;

    final hasActions = showChangePlan ||
        showCancel ||
        showReactivate ||
        showUpdatePayment ||
        showCompletePayment;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F13),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header group: plan name + price + status merged for screen readers
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tu suscripción',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    Semantics(
                      label: 'Estado de suscripción: ${_statusLabel(subscription.status)}',
                      child: _StatusChip(status: subscription.status),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Plan name
                Text(
                  planName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // Price
                if (priceText != null) ...[
                  const SizedBox(height: 4),
                  Semantics(
                    label: 'Precio: $priceText',
                    child: Text(
                      priceText,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Trial info
          if (subscription.status == SubscriptionStatus.trialing &&
              subscription.trialEnd != null) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.hourglass_top_rounded,
              color: AppColors.secondary,
              text:
                  'Trial: ${subscription.trialEnd!.difference(now).inDays} días restantes',
            ),
          ],

          // Period end info
          if (subscription.cancelAtPeriodEnd &&
              periodEndFormatted != null) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.event_rounded,
              color: AppColors.warning,
              text: 'Tu suscripción finaliza el $periodEndFormatted',
            ),
          ] else if (periodEndFormatted != null &&
              subscription.status != SubscriptionStatus.canceled &&
              subscription.status != SubscriptionStatus.incomplete) ...[
            const SizedBox(height: 10),
            Semantics(
              label: 'Próxima renovación: $periodEndFormatted',
              child: _InfoRow(
                icon: Icons.calendar_today_rounded,
                color: Colors.white54,
                text: 'Próximo cobro: $periodEndFormatted',
              ),
            ),
          ],

          // Past due warning
          if (subscription.status == SubscriptionStatus.pastDue) ...[
            const SizedBox(height: 10),
            const _InfoRow(
              icon: Icons.warning_rounded,
              color: AppColors.error,
              text: 'Cobro pendiente',
              bold: true,
            ),
          ],

          // Incomplete / SCA pending
          if (subscription.status == SubscriptionStatus.incomplete) ...[
            const SizedBox(height: 10),
            const _InfoRow(
              icon: Icons.lock_outline_rounded,
              color: AppColors.warning,
              text: 'Pago incompleto — se requiere autenticación',
            ),
          ],

          // Action buttons
          if (hasActions) ...[
            const SizedBox(height: 20),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (showChangePlan)
                  _ActionButton(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Cambiar plan',
                    onPressed: onChangePlan,
                    filled: true,
                  ),
                if (showReactivate)
                  _ActionButton(
                    icon: Icons.replay_rounded,
                    label: 'Reactivar',
                    onPressed: onReactivate,
                    filled: true,
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.black,
                  ),
                if (showUpdatePayment)
                  _ActionButton(
                    icon: Icons.credit_card_rounded,
                    label: 'Actualizar pago',
                    onPressed: onUpdatePayment,
                    filled: true,
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.black,
                  ),
                if (showCompletePayment)
                  _ActionButton(
                    icon: Icons.lock_open_rounded,
                    label: 'Completar pago',
                    onPressed: onCompletePayment,
                    filled: true,
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.black,
                  ),
                if (showCancel)
                  _ActionButton(
                    icon: Icons.cancel_outlined,
                    label: 'Cancelar',
                    onPressed: onCancel,
                    filled: false,
                    foregroundColor: AppColors.error,
                    borderColor: AppColors.error.withValues(alpha: 0.4),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _formatPrice(Plan plan) {
    final price = plan.priceCents / 100;
    final suffix =
        plan.interval == BillingInterval.month ? '/mes' : '/año';
    return '\$${price.toStringAsFixed(2)}$suffix';
  }

  static String _statusLabel(SubscriptionStatus status) =>
      switch (status) {
        SubscriptionStatus.active => 'Activa',
        SubscriptionStatus.trialing => 'En período de prueba',
        SubscriptionStatus.pastDue => 'Cobro pendiente',
        SubscriptionStatus.canceled => 'Cancelada',
        SubscriptionStatus.incomplete => 'Incompleta',
      };
}

// ---------------------------------------------------------------------------

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final SubscriptionStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = _config(status);
    return Semantics(
      label: 'Estado: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static (String, IconData, Color) _config(SubscriptionStatus status) =>
      switch (status) {
        SubscriptionStatus.trialing => (
          'TRIAL',
          Icons.hourglass_top_rounded,
          AppColors.secondary,
        ),
        SubscriptionStatus.active => (
          'ACTIVA',
          Icons.check_circle_rounded,
          AppColors.success,
        ),
        SubscriptionStatus.pastDue => (
          'VENCIDA',
          Icons.warning_rounded,
          AppColors.warning,
        ),
        SubscriptionStatus.canceled => (
          'CANCELADA',
          Icons.cancel_rounded,
          AppColors.error,
        ),
        SubscriptionStatus.incomplete => (
          'INCOMPLETA',
          Icons.pending_rounded,
          AppColors.warning,
        ),
      };
}

// ---------------------------------------------------------------------------

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.color,
    required this.text,
    this.bold = false,
  });

  final IconData icon;
  final Color color;
  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.filled,
    this.backgroundColor = AppColors.primary,
    this.foregroundColor = Colors.black,
    this.borderColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 6),
        Text(label),
      ],
    );

    if (filled) {
      return SizedBox(
        height: 48,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: content,
        ),
      );
    }

    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: foregroundColor,
          side: BorderSide(color: borderColor ?? foregroundColor),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: content,
      ),
    );
  }
}

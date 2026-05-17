// Archivo: lib/features/billing/presentation/widgets/subscription_summary_card.dart
// HUD-styled telemetry panel for subscription summary — Hangar OS.
// Rewritten as part of T4·12 digital card redesign.
import 'dart:async';

import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/hud/hud_corner_brackets.dart';
import 'package:botslode/core/ui/hud/hud_divider.dart';
import 'package:botslode/core/ui/hud/hud_grid_texture.dart';
import 'package:botslode/core/ui/hud/hud_ticker.dart';
import 'package:botslode/core/ui/panels/holo_panel.dart';
import 'package:botslode/core/ui/widgets/app_button.dart';
import 'package:botslode/core/ui/widgets/skeleton_base.dart';
import 'package:botslode/features/billing/domain/models/plan.dart';
import 'package:botslode/features/billing/domain/models/subscription.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// Public entry point
// ---------------------------------------------------------------------------

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
            illustration: const Icon(
              Icons.workspace_premium_rounded,
              size: 48,
              color: AppColors.textTertiary,
            ),
            title: 'Sin suscripción activa',
            subtitle: 'Elegí un plan para comenzar.',
            ctaLabel: 'VER PLANES',
            onCta: onViewPlans,
          );
        }
        final plan =
            state.availablePlans.where((p) => p.id == sub.planId).firstOrNull;
        return _SubscriptionCardBody(
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

  static Widget _buildSkeleton() {
    return HoloPanel(
      cornerBrackets: true,
      padding: const EdgeInsets.all(AppDimens.space24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBase(
                    width: 100,
                    height: 10,
                    radius: AppDimens.radiusXS,
                  ),
                  const SizedBox(height: AppDimens.space8),
                  SkeletonBase(
                    width: 160,
                    height: 20,
                    radius: AppDimens.radiusS,
                  ),
                ],
              ),
              SkeletonBase(
                width: 72,
                height: 22,
                radius: AppDimens.radiusPill,
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space20),
          // Readings row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBase(
                      width: double.infinity,
                      height: 10,
                      radius: AppDimens.radiusXS,
                    ),
                    const SizedBox(height: AppDimens.space8),
                    SkeletonBase(
                      width: 100,
                      height: 28,
                      radius: AppDimens.radiusS,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimens.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBase(
                      width: double.infinity,
                      height: 10,
                      radius: AppDimens.radiusXS,
                    ),
                    const SizedBox(height: AppDimens.space8),
                    SkeletonBase(
                      width: 80,
                      height: 18,
                      radius: AppDimens.radiusS,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space20),
          // Cycle bar
          SkeletonBase(
            width: double.infinity,
            height: 8,
            radius: AppDimens.radiusPill,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card body (Stateful — Timer for countdown)
// ---------------------------------------------------------------------------

class _SubscriptionCardBody extends StatefulWidget {
  const _SubscriptionCardBody({
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

  @override
  State<_SubscriptionCardBody> createState() => _SubscriptionCardBodyState();
}

class _SubscriptionCardBodyState extends State<_SubscriptionCardBody> {
  Timer? _countdownTimer;
  late DateTime _now;
  bool _tickerReady = false;

  static final _dateFmtFull = DateFormat('d MMM yyyy');

  @override
  void initState() {
    super.initState();
    _now = widget.now;
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _tickerReady = true);
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ---- Color treatment -------------------------------------------------------

  bool get _isCancelAtPeriodEnd => widget.subscription.cancelAtPeriodEnd;

  Color get _accentColor {
    if (_isCancelAtPeriodEnd) return AppColors.warning;
    return switch (widget.subscription.status) {
      SubscriptionStatus.active    => AppColors.gold,
      SubscriptionStatus.trialing  => AppColors.cyan,
      SubscriptionStatus.pastDue   => AppColors.warning,
      SubscriptionStatus.incomplete => AppColors.warning,
      SubscriptionStatus.canceled  => AppColors.danger,
    };
  }

  Color get _borderColor {
    if (_isCancelAtPeriodEnd) {
      return AppColors.warning.withValues(alpha: 0.4);
    }
    return switch (widget.subscription.status) {
      SubscriptionStatus.active    => AppColors.borderGold,
      SubscriptionStatus.trialing  => AppColors.cyan.withValues(alpha: 0.4),
      SubscriptionStatus.pastDue   => AppColors.warning,
      SubscriptionStatus.incomplete => AppColors.warning,
      SubscriptionStatus.canceled  => AppColors.danger.withValues(alpha: 0.4),
    };
  }

  Color get _bracketColor {
    if (_isCancelAtPeriodEnd) return AppColors.warning;
    return switch (widget.subscription.status) {
      SubscriptionStatus.active    => AppColors.borderGold,
      SubscriptionStatus.trialing  => AppColors.cyan,
      SubscriptionStatus.pastDue   => AppColors.warning,
      SubscriptionStatus.incomplete => AppColors.warning,
      SubscriptionStatus.canceled  => AppColors.danger,
    };
  }

  bool get _isCanceled =>
      widget.subscription.status == SubscriptionStatus.canceled &&
      !_isCancelAtPeriodEnd;

  // ---- Countdown string ------------------------------------------------------

  String _countdownText() {
    final end = widget.subscription.currentPeriodEnd;
    if (end == null) return '—';

    // For fully canceled (no cancelAtPeriodEnd), show the date instead
    if (widget.subscription.status == SubscriptionStatus.canceled &&
        !_isCancelAtPeriodEnd) {
      return _dateFmtFull.format(end);
    }

    final diff = end.difference(_now);
    if (diff.isNegative) return '0 D · 00 H';
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    return '${days} D · ${hours.toString().padLeft(2, '0')} H';
  }

  String get _countdownLabel =>
      (_isCancelAtPeriodEnd ||
              widget.subscription.status == SubscriptionStatus.canceled)
          ? 'FINALIZA EN'
          : 'RENUEVA EN';

  // ---- Action visibility flags -----------------------------------------------

  bool get _showChangePlan =>
      widget.subscription.status == SubscriptionStatus.active ||
      widget.subscription.status == SubscriptionStatus.trialing;

  bool get _showCancel =>
      _showChangePlan && !_isCancelAtPeriodEnd;

  bool get _showReactivate => _isCancelAtPeriodEnd;

  bool get _showUpdatePayment =>
      widget.subscription.status == SubscriptionStatus.pastDue;

  bool get _showCompletePayment =>
      widget.subscription.status == SubscriptionStatus.incomplete;

  bool get _hasActions =>
      _showChangePlan ||
      _showCancel ||
      _showReactivate ||
      _showUpdatePayment ||
      _showCompletePayment;

  // ---- Info rows to show -----------------------------------------------------

  List<_InfoRowData> get _infoRows {
    final rows = <_InfoRowData>[];
    final end = widget.subscription.currentPeriodEnd;

    if (widget.subscription.status == SubscriptionStatus.trialing && end != null) {
      final daysLeft = end.difference(_now).inDays.clamp(0, 9999);
      rows.add(_InfoRowData(
        icon: Icons.hourglass_top_rounded,
        color: AppColors.cyan,
        text: 'Trial: $daysLeft días restantes',
      ));
    }

    if (_isCancelAtPeriodEnd && end != null) {
      rows.add(_InfoRowData(
        icon: Icons.event_rounded,
        color: AppColors.warning,
        text: 'Tu suscripción finaliza el ${_dateFmtFull.format(end)}',
      ));
    }

    if (widget.subscription.status == SubscriptionStatus.pastDue) {
      rows.add(const _InfoRowData(
        icon: Icons.warning_rounded,
        color: AppColors.warning,
        text: 'Cobro pendiente',
        bold: true,
      ));
    }

    if (widget.subscription.status == SubscriptionStatus.incomplete) {
      rows.add(const _InfoRowData(
        icon: Icons.lock_outline_rounded,
        color: AppColors.warning,
        text: 'Pago incompleto — se requiere autenticación',
      ));
    }

    return rows;
  }

  // ---- Build -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final sub = widget.subscription;
    final plan = widget.plan;
    final planName = plan?.name ?? sub.planId;
    final countdownText = _countdownText();
    final infoRows = _infoRows;

    Widget body = HudCornerBrackets(
      color: _bracketColor,
      child: HoloPanel(
        cornerBrackets: false,
        shape: HoloPanelShape.rounded,
        padding: const EdgeInsets.all(AppDimens.space24),
        borderColor: _borderColor,
        child: HudGridTexture(
        opacity: 0.04,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────────────────
            MergeSemantics(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: label + plan name
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '// SUSCRIPCIÓN',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        planName,
                        style: AppTextStyles.titleL.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  // Right: status tag
                  _BillingStatusTag(
                    status: sub.status,
                    cancelAtPeriodEnd: _isCancelAtPeriodEnd,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimens.space20),

            // ── Readings row ─────────────────────────────────────────────────
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: renewal amount
                  Expanded(
                    child: Semantics(
                      label: plan != null
                          ? 'Próxima renovación: \$${plan.priceMonthly.toStringAsFixed(2)} por mes'
                          : 'Próxima renovación: sin información',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PRÓXIMO COBRO',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: AppDimens.space8),
                          if (plan != null)
                            HudTicker(
                              value: _tickerReady ? plan.priceMonthly : 0.0,
                              prefix: '\$',
                              suffix: '/mes',
                              decimals: 2,
                              style: AppTextStyles.numericTicker
                                  .copyWith(color: _accentColor),
                            )
                          else
                            Text(
                              '—',
                              style: AppTextStyles.numericTicker.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Vertical divider
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.space16,
                    ),
                    child: VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: AppColors.borderSubtle,
                    ),
                  ),

                  // Right: countdown
                  Expanded(
                    child: Semantics(
                      label: sub.status == SubscriptionStatus.active
                          ? 'Próxima renovación en: $countdownText'
                          : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _countdownLabel,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: AppDimens.space8),
                          AnimatedSwitcher(
                            duration: AppMotion.durBase,
                            child: Text(
                              countdownText,
                              key: ValueKey(countdownText),
                              style: AppTextStyles.hudReadout.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimens.space20),

            // ── Cycle progress bar ────────────────────────────────────────────
            if (sub.currentPeriodStart != null &&
                sub.currentPeriodEnd != null) ...[
              _CycleProgressBar(
                start: sub.currentPeriodStart!,
                end: sub.currentPeriodEnd!,
                now: _now,
                accentColor: _accentColor,
                status: sub.status,
                cancelAtPeriodEnd: _isCancelAtPeriodEnd,
              ),
              const SizedBox(height: AppDimens.space20),
            ],

            // ── Info rows ─────────────────────────────────────────────────────
            for (final row in infoRows) ...[
              _InfoRow(
                icon: row.icon,
                color: row.color,
                text: row.text,
                bold: row.bold,
              ),
              const SizedBox(height: AppDimens.space8),
            ],

            // ── Action buttons ────────────────────────────────────────────────
            if (_hasActions) ...[
              const SizedBox(height: AppDimens.space8),
              HudDivider(lineColor: AppColors.borderSubtle),
              const SizedBox(height: AppDimens.space16),
              Wrap(
                spacing: AppDimens.space8,
                runSpacing: AppDimens.space8,
                children: [
                  if (_showChangePlan && widget.onChangePlan != null)
                    AppButton.primary(
                      label: 'CAMBIAR PLAN',
                      leadingIcon: Icons.swap_horiz_rounded,
                      onPressed: widget.onChangePlan,
                      size: AppButtonSize.md,
                    ),
                  if (_showReactivate && widget.onReactivate != null)
                    AppButton.primary(
                      label: 'REACTIVAR',
                      leadingIcon: Icons.replay_rounded,
                      onPressed: widget.onReactivate,
                      size: AppButtonSize.md,
                    ),
                  if (_showUpdatePayment && widget.onUpdatePayment != null)
                    AppButton(
                      label: 'ACTUALIZAR PAGO',
                      variant: AppButtonVariant.danger,
                      leadingIcon: Icons.credit_card_rounded,
                      onPressed: widget.onUpdatePayment,
                      size: AppButtonSize.md,
                    ),
                  if (_showCompletePayment && widget.onCompletePayment != null)
                    AppButton(
                      label: 'COMPLETAR PAGO',
                      variant: AppButtonVariant.danger,
                      leadingIcon: Icons.lock_open_rounded,
                      onPressed: widget.onCompletePayment,
                      size: AppButtonSize.md,
                    ),
                  if (_showCancel && widget.onCancel != null)
                    AppButton(
                      label: 'CANCELAR',
                      variant: AppButtonVariant.danger,
                      leadingIcon: Icons.cancel_outlined,
                      onPressed: widget.onCancel,
                      size: AppButtonSize.md,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
      ),
    );

    // Entry animation: fade + translateY (HoloPanel handles its own entry,
    // but we add flutter_animate for the outer content as well).
    body = body
        .animate()
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

    // Desaturated / dimmed for fully canceled
    if (_isCanceled) {
      body = Opacity(opacity: 0.65, child: body);
    }

    return body;
  }
}

// ---------------------------------------------------------------------------
// Cycle progress bar (Stateful — TweenAnimationBuilder + dot pulse)
// ---------------------------------------------------------------------------

class _CycleProgressBar extends StatefulWidget {
  const _CycleProgressBar({
    required this.start,
    required this.end,
    required this.now,
    required this.accentColor,
    required this.status,
    required this.cancelAtPeriodEnd,
  });

  final DateTime start;
  final DateTime end;
  final DateTime now;
  final Color accentColor;
  final SubscriptionStatus status;
  final bool cancelAtPeriodEnd;

  @override
  State<_CycleProgressBar> createState() => _CycleProgressBarState();
}

class _CycleProgressBarState extends State<_CycleProgressBar>
    with SingleTickerProviderStateMixin {
  AnimationController? _dotPulseCtrl;
  Animation<double>? _dotOpacity;

  static final _barDateFmt = DateFormat('d MMM');

  @override
  void initState() {
    super.initState();
    // Pulse only for active status
    if (widget.status == SubscriptionStatus.active &&
        !widget.cancelAtPeriodEnd) {
      _dotPulseCtrl = AnimationController(
        vsync: this,
        duration: AppMotion.durHeartbeat,
      );
      _dotOpacity = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(
          parent: _dotPulseCtrl!,
          curve: AppMotion.easeStandard,
        ),
      );
      _dotPulseCtrl!.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _dotPulseCtrl?.dispose();
    super.dispose();
  }

  double get _progress {
    final totalMs =
        widget.end.difference(widget.start).inMilliseconds.toDouble();
    if (totalMs <= 0) return 0;
    final elapsedMs =
        widget.now.difference(widget.start).inMilliseconds.toDouble();
    return (elapsedMs / totalMs).clamp(0.0, 1.0);
  }

  // Fill gradient per status/cancelAtPeriodEnd
  LinearGradient _fillGradient(Color accent) {
    return LinearGradient(
      colors: [accent.withValues(alpha: 0.6), accent],
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    final targetProgress = _progress;
    final startLabel = _barDateFmt.format(widget.start);
    final endLabel = _barDateFmt.format(widget.end);

    return Semantics(
      label:
          'Ciclo de facturación al ${(targetProgress * 100).toStringAsFixed(0)}%',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bar
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: targetProgress),
            duration: reduced ? Duration.zero : AppMotion.durSlow,
            curve: AppMotion.easeStandard,
            builder: (context, value, _) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final barWidth = constraints.maxWidth;
                  final fillWidth = barWidth * value;
                  final dotX = fillWidth.clamp(0.0, barWidth);

                  Widget dot = Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.accentColor,
                      boxShadow: AppDimens.glowStatus(widget.accentColor),
                    ),
                  );

                  // Pulse for active
                  if (_dotOpacity != null && !reduced) {
                    dot = AnimatedBuilder(
                      animation: _dotOpacity!,
                      builder: (_, child) =>
                          Opacity(opacity: _dotOpacity!.value, child: child),
                      child: dot,
                    );
                  }

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Track
                      Container(
                        height: 8,
                        width: barWidth,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHud,
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusPill),
                          border: Border.all(
                            color: AppColors.borderSubtle,
                            width: 1,
                          ),
                        ),
                      ),
                      // Fill
                      if (fillWidth > 0)
                        Container(
                          height: 8,
                          width: fillWidth.clamp(0.0, barWidth),
                          decoration: BoxDecoration(
                            gradient: _fillGradient(widget.accentColor),
                            borderRadius:
                                BorderRadius.circular(AppDimens.radiusPill),
                          ),
                        ),
                      // Dot at progress position
                      Positioned(
                        left: dotX - 4,
                        top: 0,
                        child: dot,
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: AppDimens.space4),
          // Date labels below bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                startLabel,
                style: AppTextStyles.mono.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              Text(
                endLabel,
                style: AppTextStyles.mono.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Billing status tag
// ---------------------------------------------------------------------------

class _BillingStatusTag extends StatelessWidget {
  const _BillingStatusTag({
    required this.status,
    required this.cancelAtPeriodEnd,
  });

  final SubscriptionStatus status;
  final bool cancelAtPeriodEnd;

  static (IconData, String, Color) _config(
    SubscriptionStatus status,
    bool cancelAtPeriodEnd,
  ) {
    if (cancelAtPeriodEnd) {
      return (Icons.event_rounded, 'FINALIZA', AppColors.warning);
    }
    return switch (status) {
      SubscriptionStatus.active =>
        (Icons.check_circle_rounded, 'ACTIVA', AppColors.success),
      SubscriptionStatus.trialing =>
        (Icons.hourglass_top_rounded, 'TRIAL', AppColors.cyan),
      SubscriptionStatus.pastDue =>
        (Icons.warning_rounded, 'VENCIDA', AppColors.warning),
      SubscriptionStatus.canceled =>
        (Icons.cancel_rounded, 'CANCELADA', AppColors.danger),
      SubscriptionStatus.incomplete =>
        (Icons.pending_rounded, 'INCOMPLETA', AppColors.warning),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = _config(status, cancelAtPeriodEnd);

    return Semantics(
      label: 'Estado de suscripción: $label',
      child: ExcludeSemantics(
        child: Container(
          height: 22,
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppDimens.radiusPill),
            border: Border.all(
              color: color.withValues(alpha: 0.32),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: AppDimens.space8),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info row (restyled)
// ---------------------------------------------------------------------------

class _InfoRowData {
  const _InfoRowData({
    required this.icon,
    required this.color,
    required this.text,
    this.bold = false,
  });
  final IconData icon;
  final Color color;
  final String text;
  final bool bold;
}

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
        Icon(icon, size: AppDimens.iconXS, color: color),
        const SizedBox(width: AppDimens.space8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyM.copyWith(
              color: color,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}

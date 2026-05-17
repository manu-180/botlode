// Archivo: lib/features/billing/presentation/widgets/dunning_warning_banner.dart
//
// T4·19 — DunningWarningBanner (HUD redesign T4-60)
//
// Banner HUD Hangar OS persistente (no descartable) para suscripción en `past_due`.
// Usa HudCornerBrackets, HudReactorBar y HudScanlines del design system.
// Incluye animación de entrada slide-down.
//
// Severidad:
//   currentPeriodEnd futuro → warning (AppColors.warning), icon error_outline_rounded
//   ya vencido / null       → danger  (AppColors.danger),  icon report_rounded
//
// El banner solo se renderiza cuando:
//   - El provider tiene datos (no loading/error).
//   - sub.status == SubscriptionStatus.pastDue.
//
// A diferencia de TrialCountdownBanner, este banner NO es descartable.

import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/hud/hud_corner_brackets.dart';
import 'package:botslode/core/ui/hud/hud_reactor_bar.dart';
import 'package:botslode/core/ui/hud/hud_scanlines.dart';
import 'package:botslode/core/ui/widgets/app_button.dart';
import 'package:botslode/features/billing/domain/models/subscription.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/widgets/add_card_modal.dart';
import 'package:botslode/l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class DunningWarningBanner extends ConsumerStatefulWidget {
  /// Override de fecha para tests deterministas.
  @visibleForTesting
  final DateTime? now;

  /// Override de la acción retryPayment para tests (evita llamar al provider).
  @visibleForTesting
  final Future<void> Function()? retryPaymentOverride;

  const DunningWarningBanner({
    super.key,
    this.now,
    this.retryPaymentOverride,
  });

  @override
  ConsumerState<DunningWarningBanner> createState() =>
      _DunningWarningBannerState();
}

class _DunningWarningBannerState extends ConsumerState<DunningWarningBanner> {
  bool _isRetrying = false;

  static final _dateFormat = DateFormat('dd/MM/yyyy');

  void _openUpdatePaymentMethod() {
    AddCardModal.show(context);
  }

  Future<void> _handleRetry() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);
    try {
      if (widget.retryPaymentOverride != null) {
        await widget.retryPaymentOverride!();
      } else {
        await ref.read(billingV2Provider.notifier).retryPayment();
      }
    } on BillingException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (_) {
      // Silenciar errores no estructurados.
    } finally {
      if (mounted) setState(() => _isRetrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final billingAsync = ref.watch(billingV2Provider);

    return billingAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (state) {
        final sub = state.subscription;
        if (sub == null || sub.status != SubscriptionStatus.pastDue) {
          return const SizedBox.shrink();
        }

        final now = widget.now ?? DateTime.now();
        final gracePeriodEnd = sub.currentPeriodEnd;
        final dateStr = gracePeriodEnd != null
            ? _dateFormat.format(gracePeriodEnd.toLocal())
            : null;

        // Determine severity based on whether grace period is still active
        final bool isGraceActive =
            gracePeriodEnd != null && gracePeriodEnd.isAfter(now);

        final severityColor =
            isGraceActive ? AppColors.warning : AppColors.danger;
        final severityIcon = isGraceActive
            ? Icons.error_outline_rounded
            : Icons.report_rounded;

        return _AnimatedBannerEntry(
          child: _DunningBannerBody(
            dateStr: dateStr,
            lastErrorMessage: state.errorMessage,
            isRetrying: _isRetrying,
            severityColor: severityColor,
            severityIcon: severityIcon,
            onUpdatePaymentMethod: _openUpdatePaymentMethod,
            onRetryPayment: _handleRetry,
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _AnimatedBannerEntry — slide-down + fade entrance
// ---------------------------------------------------------------------------

class _AnimatedBannerEntry extends StatefulWidget {
  final Widget child;
  const _AnimatedBannerEntry({required this.child});

  @override
  State<_AnimatedBannerEntry> createState() => _AnimatedBannerEntryState();
}

class _AnimatedBannerEntryState extends State<_AnimatedBannerEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppMotion.durSlow);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: AppMotion.easeEntrance));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: AppMotion.easeEntrance));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.isReduced(context);
    if (reduced) return widget.child;
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ---------------------------------------------------------------------------
// _DunningBannerBody — presentación pura (sin acceso al provider)
// ---------------------------------------------------------------------------

class _DunningBannerBody extends StatelessWidget {
  const _DunningBannerBody({
    required this.dateStr,
    required this.lastErrorMessage,
    required this.isRetrying,
    required this.severityColor,
    required this.severityIcon,
    required this.onUpdatePaymentMethod,
    required this.onRetryPayment,
  });

  final String? dateStr;
  final String? lastErrorMessage;
  final bool isRetrying;
  final Color severityColor;
  final IconData severityIcon;
  final VoidCallback onUpdatePaymentMethod;
  final VoidCallback onRetryPayment;

  @override
  Widget build(BuildContext context) {
    final mainText = dateStr != null
        ? 'Actualizá tu método de pago. Tu acceso podría suspenderse el $dateStr.'
        : 'Actualizá tu método de pago. Tu acceso podría suspenderse pronto.';

    return Semantics(
      liveRegion: true,
      label: 'Advertencia: pago fallido. $mainText',
      child: HudCornerBrackets(
        color: severityColor,
        armLength: 12,
        thickness: 1.0,
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppDimens.space16,
            vertical: AppDimens.space8,
          ),
          padding: const EdgeInsets.all(AppDimens.space16),
          decoration: BoxDecoration(
            color: severityColor.withValues(alpha: 0.08),
            border: Border.all(
              color: severityColor.withValues(alpha: 0.35),
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
          ),
          child: HudScanlines(
            opacity: 0.035,
            animate: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header row: reactor bar + icon + text
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HudReactorBar(
                      axis: Axis.vertical,
                      thickness: 3,
                      color: severityColor,
                      pulsing: true,
                    ),
                    const SizedBox(width: AppDimens.space12),

                    ExcludeSemantics(
                      child: Icon(severityIcon, color: severityColor, size: 20),
                    ),
                    const SizedBox(width: AppDimens.space12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'PAGO RECHAZADO',
                            style: AppTextStyles.label
                                .copyWith(color: severityColor),
                          ),
                          const SizedBox(height: AppDimens.space4),
                          Text(
                            mainText,
                            style: AppTextStyles.bodyS.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (lastErrorMessage != null) ...[
                            const SizedBox(height: AppDimens.space4),
                            Text(
                              lastErrorMessage!,
                              style: AppTextStyles.mono.copyWith(
                                color: AppColors.textTertiary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppDimens.space12),

                // CTA primaria
                AppButton(
                  label: AppStrings.billingDunningUpdatePayment,
                  variant: AppButtonVariant.danger,
                  size: AppButtonSize.md,
                  expand: true,
                  onPressed: onUpdatePaymentMethod,
                ),

                const SizedBox(height: AppDimens.space8),

                // CTA secundaria — retry
                Semantics(
                  label: isRetrying
                      ? 'Reintentando cobro...'
                      : 'Reintentar cobro - suscripción en riesgo',
                  button: true,
                  child: AppButton(
                    label: AppStrings.billingDunningRetryCharge,
                    variant: AppButtonVariant.ghost,
                    size: AppButtonSize.md,
                    expand: true,
                    loading: isRetrying,
                    onPressed: isRetrying ? null : onRetryPayment,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

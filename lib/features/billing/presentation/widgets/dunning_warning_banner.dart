// Archivo: lib/features/billing/presentation/widgets/dunning_warning_banner.dart
//
// T4·19 — DunningWarningBanner
//
// Banner rojo persistente (no descartable) que aparece cuando la suscripción
// está en `past_due`. Incluye:
//   - Mensaje principal con fecha de suspensión estimada (currentPeriodEnd).
//   - Último error de cobro si está disponible en el estado de billing.
//   - CTA primaria: "Actualizar método de pago" → abre AddCardModal.
//   - CTA secundaria: "Reintentar cobro" → llama retryPayment() en el provider.
//
// El banner solo se renderiza cuando:
//   - El provider tiene datos (no loading/error).
//   - sub.status == SubscriptionStatus.pastDue.
//
// A diferencia de TrialCountdownBanner, este banner NO es descartable.

import 'package:botslode/core/config/theme/app_colors.dart';
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
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddCardModal(),
    );
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
            backgroundColor: AppColors.error,
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

        final gracePeriodEnd = sub.currentPeriodEnd;
        final dateStr = gracePeriodEnd != null
            ? _dateFormat.format(gracePeriodEnd.toLocal())
            : null;

        return _DunningBannerBody(
          dateStr: dateStr,
          lastErrorMessage: state.errorMessage,
          isRetrying: _isRetrying,
          onUpdatePaymentMethod: _openUpdatePaymentMethod,
          onRetryPayment: _handleRetry,
        );
      },
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
    required this.onUpdatePaymentMethod,
    required this.onRetryPayment,
  });

  final String? dateStr;
  final String? lastErrorMessage;
  final bool isRetrying;
  final VoidCallback onUpdatePaymentMethod;
  final VoidCallback onRetryPayment;

  @override
  Widget build(BuildContext context) {
    const color = AppColors.error;

    final mainText = dateStr != null
        ? 'No pudimos cobrar tu suscripción. Tu acceso podría suspenderse el $dateStr.'
        : 'No pudimos cobrar tu suscripción. Tu acceso podría suspenderse pronto.';

    return Semantics(
      label: 'Advertencia: pago fallido. $mainText',
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: icon + title + message
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Decorative icon — meaning is conveyed by the parent
                // Semantics label; exclude to avoid redundant announcement.
                const ExcludeSemantics(
                  child: Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.error_outline_rounded,
                      color: color,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Pago fallido',
                        style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mainText,
                        style: const TextStyle(
                          color: Color(0xCCFF003C), // error a 80% opacidad
                          fontSize: 12,
                        ),
                      ),
                      if (lastErrorMessage != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          lastErrorMessage!,
                          style: const TextStyle(
                            color: Color(0x99FF003C), // error a 60% opacidad
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // CTA primaria
            Semantics(
              label: 'Actualizar método de pago - suscripción en riesgo',
              button: true,
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: onUpdatePaymentMethod,
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(AppStrings.billingDunningUpdatePayment),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // CTA secundaria
            Semantics(
              label: isRetrying
                  ? 'Reintentando cobro...'
                  : 'Reintentar cobro - suscripción en riesgo',
              button: true,
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: isRetrying ? null : onRetryPayment,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0x66FF003C), // error a 40% opacidad
                    ),
                    foregroundColor: color,
                  ),
                  child: isRetrying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: color,
                          ),
                        )
                      : const Text(AppStrings.billingDunningRetryCharge),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

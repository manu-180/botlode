// Archivo: lib/features/billing/presentation/widgets/trial_countdown_banner.dart
//
// T4·18 — TrialCountdownBanner
//
// Banner Material 3 que muestra el conteo regresivo del período de prueba con
// color y severidad adaptados a la cantidad de días restantes. Incluye un CTA
// para agregar un método de pago cuando el tenant no tiene uno configurado.
//
// Severidad (basada en días calendario, no horas):
//   daysLeft > 7  → cyan   (AppColors.secondary) — informativo
//   daysLeft 3–7  → naranja (AppColors.warning)   — advertencia
//   daysLeft ≤ 2  → rojo   (AppColors.error)      — crítico
//
// El banner solo se renderiza cuando:
//   - El provider tiene datos (no loading/error).
//   - sub.status == SubscriptionStatus.trialing && sub.trialEnd != null.
//   - El usuario no lo descartó (_dismissed == false).

import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/billing/domain/models/subscription.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/widgets/add_card_modal.dart';
import 'package:botslode/l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TrialCountdownBanner extends ConsumerStatefulWidget {
  /// Hook de fecha para tests deterministas. En producción usa `DateTime.now()`.
  @visibleForTesting
  final DateTime? now;

  const TrialCountdownBanner({super.key, this.now});

  @override
  ConsumerState<TrialCountdownBanner> createState() =>
      _TrialCountdownBannerState();
}

class _TrialCountdownBannerState extends ConsumerState<TrialCountdownBanner> {
  bool _dismissed = false;

  // ---------------------------------------------------------------------------
  // Days calculation (date boundary, local timezone, clamped ≥ 0)
  // ---------------------------------------------------------------------------

  static int _daysLeft(DateTime trialEnd, DateTime now) {
    final localEnd = trialEnd.toLocal();
    final localNow = now.toLocal();
    final days = DateTime(localEnd.year, localEnd.month, localEnd.day)
        .difference(DateTime(localNow.year, localNow.month, localNow.day))
        .inDays;
    return days.clamp(0, 9999);
  }

  // ---------------------------------------------------------------------------
  // Severity mapping
  // ---------------------------------------------------------------------------

  static ({Color color, IconData icon}) _severity(int daysLeft) {
    if (daysLeft > 7) {
      return (color: AppColors.secondary, icon: Icons.hourglass_top_rounded);
    }
    if (daysLeft >= 3) {
      return (color: AppColors.warning, icon: Icons.hourglass_bottom_rounded);
    }
    return (color: AppColors.error, icon: Icons.hourglass_disabled_rounded);
  }

  // ---------------------------------------------------------------------------
  // Open AddCardModal
  // ---------------------------------------------------------------------------

  void _openAddCard() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddCardModal(),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final billingAsync = ref.watch(billingV2Provider);

    return billingAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (state) {
        final sub = state.subscription;

        if (sub == null ||
            sub.status != SubscriptionStatus.trialing ||
            sub.trialEnd == null) {
          return const SizedBox.shrink();
        }

        final now = widget.now ?? DateTime.now();
        final daysLeft = _daysLeft(sub.trialEnd!, now);
        final hasDefaultPaymentMethod =
            state.defaultPaymentMethodId != null;
        final sev = _severity(daysLeft);

        return _BannerBody(
          daysLeft: daysLeft,
          hasDefaultPaymentMethod: hasDefaultPaymentMethod,
          color: sev.color,
          icon: sev.icon,
          onDismiss: () => setState(() => _dismissed = true),
          onAddPaymentMethod: _openAddCard,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _BannerBody — presentación pura (sin acceso al provider)
// ---------------------------------------------------------------------------

class _BannerBody extends StatelessWidget {
  const _BannerBody({
    required this.daysLeft,
    required this.hasDefaultPaymentMethod,
    required this.color,
    required this.icon,
    required this.onDismiss,
    required this.onAddPaymentMethod,
  });

  final int daysLeft;
  final bool hasDefaultPaymentMethod;
  final Color color;
  final IconData icon;
  final VoidCallback onDismiss;
  final VoidCallback onAddPaymentMethod;

  @override
  Widget build(BuildContext context) {
    final dayLabel =
        'Trial: $daysLeft día${daysLeft == 1 ? '' : 's'} restante${daysLeft == 1 ? '' : 's'}';

    // El botón CTA usa texto negro sobre cyan, blanco sobre naranja/rojo.
    final bool isCyan = color == AppColors.secondary;
    final Color foregroundColor =
        isCyan ? Colors.black : Colors.white;

    return Semantics(
      label: 'Trial activo: $daysLeft días restantes',
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Severity icon — decorative; meaning is conveyed by the
            // Semantics label on the parent container.
            ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(icon, color: color, size: 20),
              ),
            ),
            const SizedBox(width: 12),

            // Content column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    dayLabel,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Subtitle + CTA (only when no default payment method)
                  if (!hasDefaultPaymentMethod) ...[
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.billingTrialAddPaymentWarning,
                      style: TextStyle(
                        color: color.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Semantics(
                      label: 'Agregar método de pago - quedan $daysLeft días de trial',
                      button: true,
                      child: SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: onAddPaymentMethod,
                          style: FilledButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: foregroundColor,
                          ),
                          child: const Text(AppStrings.billingTrialAddPaymentCta),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Dismiss button (40×40 touch target)
            SizedBox(
              width: 40,
              height: 40,
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: 18,
                tooltip: 'Cerrar',
                onPressed: onDismiss,
                icon: Icon(Icons.close, color: color.withValues(alpha: 0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

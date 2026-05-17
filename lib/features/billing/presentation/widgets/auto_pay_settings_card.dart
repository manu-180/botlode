// Archivo: lib/features/billing/presentation/widgets/auto_pay_settings_card.dart
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/widgets/manage_cards_modal.dart';
import 'package:botslode/l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AutoPaySettingsCard extends ConsumerStatefulWidget {
  const AutoPaySettingsCard({super.key});

  @override
  ConsumerState<AutoPaySettingsCard> createState() => _AutoPaySettingsCardState();
}

class _AutoPaySettingsCardState extends ConsumerState<AutoPaySettingsCard> {
  bool _isMutating = false;

  Future<void> _onToggle(bool enableAutoRenew, BuildContext context) async {
    if (_isMutating) return;

    // Capture messenger before async gap to avoid use_build_context_synchronously.
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isMutating = true);

    try {
      if (enableAutoRenew) {
        await ref.read(billingV2Provider.notifier).reactivateSubscription();
      } else {
        await ref.read(billingV2Provider.notifier).cancelSubscription();
      }
    } on BillingException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.billingAutoPayUpdateError)),
      );
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  void _openManageCards(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ManageCardsModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billingAsync = ref.watch(billingV2Provider);

    return billingAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (state) {
        final subscription = state.subscription;
        if (subscription == null) return const SizedBox.shrink();

        final defaultPm = state.paymentMethods
            .where((pm) => pm.isDefault)
            .firstOrNull;
        final hasDefaultPm = defaultPm != null;
        final autoRenew = !subscription.cancelAtPeriodEnd;
        final switchEnabled = hasDefaultPm && !_isMutating;

        final borderColor = (autoRenew && hasDefaultPm)
            ? AppColors.primary.withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.1);

        return Container(
          margin: const EdgeInsets.only(top: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F13),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cobro automático',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Se renueva automáticamente al final del período de facturación.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Tooltip(
                      message: autoRenew
                          ? 'El cobro se realiza automáticamente al vencer el período.'
                          : 'Tu suscripción no se renovará automáticamente y se cancelará al fin del período.',
                      child: Semantics(
                        label: 'Pago automático ${autoRenew ? "activado" : "desactivado"}',
                        toggled: autoRenew,
                        enabled: switchEnabled,
                        excludeSemantics: true,
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Center(
                            child: Switch(
                              value: autoRenew,
                              onChanged: switchEnabled
                                  ? (val) => _onToggle(val, context)
                                  : null,
                              activeThumbColor: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                if (hasDefaultPm)
                  Semantics(
                    label: 'Tarjeta para pago automático: terminada en ${defaultPm.last4 ?? '—'}',
                    button: true,
                    hint: 'Toca para administrar tarjetas',
                    child: GestureDetector(
                      onTap: () => _openManageCards(context),
                      child: Row(
                        children: [
                          ExcludeSemantics(
                            child: Icon(
                              Icons.credit_card,
                              color: Colors.white.withValues(alpha: 0.4),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text.rich(
                            TextSpan(
                              text: 'Se cobrará a ',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: 12,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      '${(defaultPm.brand?.isNotEmpty == true ? '${defaultPm.brand} ' : '')}•••• ${defaultPm.last4 ?? '—'}',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Semantics(
                    label: 'Advertencia: Agregá un método de pago para activar el cobro automático.',
                    liveRegion: true,
                    child: Row(
                      children: [
                        ExcludeSemantics(
                          child: Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.warning,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Agregá un método de pago para activar.',
                            style: TextStyle(color: AppColors.warning, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

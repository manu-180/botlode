// Archivo: lib/features/billing/presentation/widgets/manage_cards_modal.dart
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/billing/domain/models/payment_method.dart';
import 'package:botslode/features/billing/presentation/widgets/empty_state.dart';
import 'package:botslode/features/billing/domain/models/subscription.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/widgets/add_card_modal.dart';
import 'package:botslode/l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum _CardAction { setDefault, delete }

const _kActiveStatuses = {
  SubscriptionStatus.active,
  SubscriptionStatus.trialing,
  SubscriptionStatus.pastDue,
};

class ManageCardsModal extends ConsumerWidget {
  const ManageCardsModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billingAsync = ref.watch(billingV2Provider);

    return billingAsync.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox(),
      data: (state) {
        final methods = state.paymentMethods;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 16,
            right: 16,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                  decoration: const BoxDecoration(
                    color: Color(0xFF09090B),
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    border: Border.fromBorderSide(
                      BorderSide(color: Colors.white24, width: 1),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black54, blurRadius: 30, offset: Offset(0, 10)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // HEADER
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Semantics(
                            header: true,
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "GESTIÓN DE MÉTODOS",
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontFamily: 'Oxanium',
                                    fontSize: 10,
                                    letterSpacing: 2.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Tus Tarjetas",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: Colors.white54),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // LISTA DE TARJETAS
                      if (methods.isEmpty)
                        _buildEmptyState(context)
                      else
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: methods.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (_, index) =>
                                _buildCardItem(context, ref, methods[index]),
                          ),
                        ),

                      const SizedBox(height: 30),

                      // CTA AGREGAR TARJETA
                      Semantics(
                        label: 'Agregar nueva tarjeta de pago',
                        button: true,
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => const AddCardModal(),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              foregroundColor: AppColors.primary,
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text(
                              AppStrings.billingManageCardsAddNew,
                              style: TextStyle(
                                fontFamily: 'Oxanium',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
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

  Widget _buildCardItem(BuildContext context, WidgetRef ref, PaymentMethod pm) {
    final isDefault = pm.isDefault;
    final last4 = pm.last4 ?? '—';
    final brand = (pm.brand ?? '').isNotEmpty ? pm.brand! : 'desconocida';

    return Semantics(
      label: 'Tarjeta terminada en $last4, $brand',
      button: false,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDefault
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDefault ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Brand icon (decorative — label is on the card Semantics above)
            ExcludeSemantics(
              child: Container(
                width: 50,
                height: 35,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(child: _buildBrandIcon(pm.brand)),
              ),
            ),
            const SizedBox(width: 15),

            // Card number + expiry
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "•••• ${pm.last4 ?? '—'}",
                    style: TextStyle(
                      color: isDefault ? AppColors.primary : Colors.white,
                      fontFamily: 'Courier',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _expiryLabel(pm),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 10,
                      fontFamily: 'Oxanium',
                    ),
                  ),
                ],
              ),
            ),

            // Default badge (decorative label — card Semantics already conveys this)
            if (isDefault) ...[
              ExcludeSemantics(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "PREDETERMINADA",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],

            // Overflow menu (all cards)
            Semantics(
              label: 'Opciones para tarjeta terminada en $last4',
              child: PopupMenuButton<_CardAction>(
                icon: const Icon(Icons.more_vert, color: Colors.white54, size: 20),
                color: const Color(0xFF1A1A1D),
                tooltip: 'Opciones',
                itemBuilder: (_) => [
                  if (!isDefault)
                    const PopupMenuItem(
                      value: _CardAction.setDefault,
                      child: Text(
                        "Establecer como predeterminada",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  PopupMenuItem(
                    value: _CardAction.delete,
                    child: Semantics(
                      label: 'Eliminar tarjeta terminada en $last4',
                      child: const Text(
                        AppStrings.billingManageCardsDelete,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
                onSelected: (action) {
                  switch (action) {
                    case _CardAction.setDefault:
                      _setDefault(context, ref, pm.id);
                    case _CardAction.delete:
                      _handleDelete(context, ref, pm.id);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return BillingEmptyState(
      illustration: const Icon(Icons.credit_card_off_rounded, size: 48, color: Colors.white24),
      title: 'Aún no agregaste métodos de pago',
      subtitle: 'Agregá una tarjeta para habilitar el cobro automático.',
      ctaLabel: 'Agregar tarjeta',
      onCta: () {
        Navigator.pop(context);
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const AddCardModal(),
        );
      },
    );
  }

  Widget _buildBrandIcon(String? brand) {
    final b = brand?.toLowerCase();
    if (b == 'visa') {
      return const FaIcon(FontAwesomeIcons.ccVisa, color: Colors.white70, size: 20);
    }
    if (b == 'mastercard') {
      return const FaIcon(FontAwesomeIcons.ccMastercard, color: Colors.white70, size: 20);
    }
    if (b == 'amex' || b == 'american_express') {
      return const FaIcon(FontAwesomeIcons.ccAmex, color: Colors.white70, size: 20);
    }
    if (b == 'discover') {
      return const FaIcon(FontAwesomeIcons.ccDiscover, color: Colors.white70, size: 20);
    }
    return const Icon(Icons.credit_card, color: Colors.white70, size: 20);
  }

  String _expiryLabel(PaymentMethod pm) {
    final brand = (pm.brand ?? '').toUpperCase();
    final month = pm.expMonth?.toString().padLeft(2, '0');
    final year = pm.expYear;
    if (month != null && year != null) {
      return brand.isNotEmpty ? '$brand  ·  $month/$year' : '$month/$year';
    }
    return brand.isNotEmpty ? brand : '—';
  }

  Future<void> _setDefault(BuildContext context, WidgetRef ref, String id) async {
    try {
      await ref.read(billingV2Provider.notifier).setDefaultPaymentMethod(id);
    } on BillingException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.billingManageCardsUpdateError),
          ),
        );
      }
    }
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref, String id) async {
    final current = ref.read(billingV2Provider).valueOrNull;
    final methods = current?.paymentMethods ?? [];
    final subscription = current?.subscription;
    final hasActiveSub =
        subscription != null && _kActiveStatuses.contains(subscription.status);

    // Guard: cannot delete the only payment method while there is an active subscription.
    if (methods.length == 1 && hasActiveSub) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "No podés eliminar tu único método de pago con una suscripción activa. "
              "Primero agregá otra tarjeta.",
            ),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF09090B),
        title: const Text(AppStrings.billingManageCardsDeleteTitle, style: TextStyle(color: Colors.white)),
        content: const Text(
          "Al eliminar esta tarjeta se quitará de tus métodos de pago. "
          "Si tenés cobros pendientes podría afectar tu suscripción.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          // autofocus on Cancel keeps focus on the safe action (WCAG).
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.billingManageCardsDeleteCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppStrings.billingManageCardsDeleteConfirm, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      await ref.read(billingV2Provider.notifier).removePaymentMethod(id);
    } on BillingException catch (e) {
      if (context.mounted) {
        final msg = e.code == 'only_pm_active'
            ? "No podés eliminar tu único método de pago con una suscripción activa."
            : e.message;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.billingManageCardsDeleteError),
          ),
        );
      }
    }
  }
}

// Archivo: lib/features/billing/presentation/widgets/reactivate_subscription_flow.dart
//
// T4·17 — ReactivateSubscriptionFlow
//
// Entry point: showReactivateFlow(BuildContext, WidgetRef)
// Simple confirm dialog for reactivating a subscription with cancelAtPeriodEnd=true.
// If no default payment method is registered, shows a blocked state and redirects
// the user to AddCardModal instead of allowing reactivation.

import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/widgets/add_card_modal.dart';
import 'package:botslode/l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// Internal result token
// ---------------------------------------------------------------------------

enum _ReactivateResult { addCard }

// ---------------------------------------------------------------------------
// Public entry point
// ---------------------------------------------------------------------------

/// Shows the reactivation confirm dialog.
///
/// If [billingV2Provider] has no default payment method, shows a blocked dialog
/// and opens [AddCardModal] when the user confirms. The providers are shared with
/// the dialog via [UncontrolledProviderScope] so no Supabase re-initialization
/// occurs.
Future<void> showReactivateFlow(BuildContext context, WidgetRef ref) async {
  final container = ProviderScope.containerOf(context);

  final result = await showDialog<_ReactivateResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => UncontrolledProviderScope(
      container: container,
      child: const _ReactivateDialog(),
    ),
  );

  if (result == _ReactivateResult.addCard && context.mounted) {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddCardModal(),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal dialog widget
// ---------------------------------------------------------------------------

class _ReactivateDialog extends ConsumerStatefulWidget {
  const _ReactivateDialog();

  @override
  ConsumerState<_ReactivateDialog> createState() => _ReactivateDialogState();
}

class _ReactivateDialogState extends ConsumerState<_ReactivateDialog> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _onReactivate() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(billingV2Provider.notifier).reactivateSubscription();
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.billingReactivateSuccess)),
      );
    } on BillingException catch (e) {
      if (!mounted) return;
      if (e.code == 'not_implemented') {
        navigator.pop();
        messenger.showSnackBar(
          const SnackBar(content: Text(AppStrings.billingReactivateComingSoon)),
        );
      } else {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No pudimos procesar la reactivación. Intentá de nuevo.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(billingV2Provider).valueOrNull;
    final sub = state?.subscription;
    final defaultPm =
        state?.paymentMethods.where((pm) => pm.isDefault).firstOrNull;

    if (defaultPm == null) {
      return _buildBlockedDialog();
    }

    final periodEndStr = sub?.currentPeriodEnd != null
        ? DateFormat('dd/MM/yyyy').format(sub!.currentPeriodEnd!)
        : '—';

    final pmLabel = [
      if (defaultPm.brand?.isNotEmpty == true) defaultPm.brand!,
      '•••• ${defaultPm.last4 ?? '—'}',
    ].join(' ');

    // Resolve current plan price for accessibility labels.
    final plan = sub != null
        ? state?.availablePlans.where((p) => p.id == sub.planId).firstOrNull
        : null;
    final planPriceStr = plan != null
        ? '\$${(plan.priceCents / 100).toStringAsFixed(2)}/mes'
        : '';

    return _buildConfirmDialog(periodEndStr, pmLabel, planPriceStr);
  }

  // ---------------------------------------------------------------------------
  // Blocked state — no default payment method
  // ---------------------------------------------------------------------------

  Widget _buildBlockedDialog() {
    return AlertDialog(
      backgroundColor: const Color(0xFF0F0F13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Método de pago requerido',
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'Oxanium',
          fontWeight: FontWeight.bold,
        ),
      ),
      content: const Text(
        'Necesitás agregar un método de pago antes de reactivar tu suscripción.',
        style: TextStyle(color: AppColors.textSecondary, height: 1.5),
      ),
      actions: [
        TextButton(
          key: const Key('cancelar_btn'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            AppStrings.billingCheckoutCancel,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        FilledButton(
          key: const Key('agregar_metodo_btn'),
          onPressed: () =>
              Navigator.of(context).pop(_ReactivateResult.addCard),
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text(
            'Agregar método',
            style: TextStyle(
              fontFamily: 'Oxanium',
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Confirm state — has default payment method
  // ---------------------------------------------------------------------------

  Widget _buildConfirmDialog(
      String periodEndStr, String pmLabel, String planPriceStr) {
    final reactivateLabel = planPriceStr.isNotEmpty
        ? 'Reactivar suscripción - se cobrará $planPriceStr'
        : 'Reactivar suscripción';

    return AlertDialog(
      backgroundColor: const Color(0xFF0F0F13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          ExcludeSemantics(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Reactivar suscripción',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Oxanium',
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vas a reactivar tu suscripción. Se cobrará automáticamente '
            'el $periodEndStr a $pmLabel.',
            style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Semantics(
              label: 'Error al reactivar: ${_errorMessage!}',
              liveRegion: true,
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          key: const Key('cancelar_btn'),
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text(
            AppStrings.billingCheckoutCancel,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        Semantics(
          label: _isLoading
              ? 'Procesando reactivación, por favor espere'
              : reactivateLabel,
          liveRegion: _isLoading,
          child: FilledButton(
            key: const Key('reactivar_btn'),
            onPressed: _isLoading ? null : _onReactivate,
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Text(
                    'Reactivar',
                    style: TextStyle(
                      fontFamily: 'Oxanium',
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

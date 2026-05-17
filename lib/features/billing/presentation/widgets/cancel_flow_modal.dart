// Archivo: lib/features/billing/presentation/widgets/cancel_flow_modal.dart
//
// T4·16 — CancelFlowModal
//
// Two-step cancellation modal:
//   Step 1 — Reason selection (radio + optional comment).
//   Step 2 — Confirmation with consequences and CTAs.
//
// Opens as a Dialog on desktop (width ≥ 600) or as a ModalBottomSheet on
// mobile/narrow windows.

import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// Public entry point
// ---------------------------------------------------------------------------

/// Shows the two-step cancel-flow modal.
///
/// Reads [billingV2Provider] to obtain [Subscription.currentPeriodEnd] so the
/// confirmation screen can display "activa hasta {fecha}".
Future<void> showCancelFlowModal(BuildContext context, WidgetRef ref) async {
  final isDesktop = MediaQuery.of(context).size.width >= 600;

  // Capture the container before opening the overlay so providers are shared.
  final container = ProviderScope.containerOf(context);

  final modal = UncontrolledProviderScope(
    container: container,
    child: const _CancelFlowModal(),
  );

  if (isDesktop) {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => modal,
    );
  } else {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => modal,
    );
  }
}

// ---------------------------------------------------------------------------
// Reason options
// ---------------------------------------------------------------------------

enum _CancelReason {
  muyCaro('Muy caro'),
  noLoUso('No lo uso'),
  faltanFeatures('Faltan features'),
  otro('Otro');

  const _CancelReason(this.label);
  final String label;
}

// ---------------------------------------------------------------------------
// Internal widget
// ---------------------------------------------------------------------------

class _CancelFlowModal extends ConsumerStatefulWidget {
  const _CancelFlowModal();

  @override
  ConsumerState<_CancelFlowModal> createState() => _CancelFlowModalState();
}

class _CancelFlowModalState extends ConsumerState<_CancelFlowModal> {
  // Step management (0 = reason, 1 = confirmation)
  int _step = 0;

  // Step 1 state
  _CancelReason? _selectedReason;
  final _commentController = TextEditingController();

  // Step 2 mutation state
  bool _cancelling = false;
  String? _mutationError;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String get _selectedReasonText {
    if (_selectedReason == null) return '';
    final comment = _commentController.text.trim();
    final base = _selectedReason!.label;
    if (comment.isNotEmpty) return '$base: $comment';
    return base;
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _goToStep2() {
    if (_selectedReason == null) return;
    setState(() {
      _step = 1;
      _mutationError = null;
    });
  }

  void _goBackToStep1() {
    setState(() {
      _step = 0;
      _mutationError = null;
    });
  }

  Future<void> _confirmCancel(String fecha) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _cancelling = true;
      _mutationError = null;
    });

    try {
      await ref
          .read(billingV2Provider.notifier)
          .cancelSubscription(reason: _selectedReasonText);

      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('${AppStrings.billingCancelSuccessPrefix}$fecha'),
        ),
      );
    } on BillingException catch (e) {
      if (!mounted) return;
      if (e.code == 'not_implemented') {
        navigator.pop();
        messenger.showSnackBar(
          const SnackBar(content: Text(AppStrings.billingCancelComingSoon)),
        );
      } else {
        setState(() {
          _mutationError = e.message;
          _cancelling = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mutationError = AppStrings.billingCancelErrorMsg;
        _cancelling = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Watch billingV2Provider in build() so the auto-dispose provider stays
    // alive for the modal's lifetime and the date is available for step 2.
    final billingAsync = ref.watch(billingV2Provider);
    final periodEnd = billingAsync.valueOrNull?.subscription?.currentPeriodEnd;
    final fechaStr =
        periodEnd != null ? DateFormat('dd/MM/yyyy').format(periodEnd) : '—';

    final isDesktop = MediaQuery.of(context).size.width >= 600;
    final stepLabel = _step == 0
        ? 'Paso 1 de 2 del proceso de cancelación'
        : 'Paso 2 de 2 del proceso de cancelación';
    final content = Semantics(
      label: stepLabel,
      child: _step == 0 ? _buildStep1() : _buildStep2(fechaStr),
    );

    if (isDesktop) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: _ModalContainer(child: content),
        ),
      );
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => _ModalContainer(
        child: SingleChildScrollView(
          controller: scrollController,
          child: content,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 1 — Reason
  // ---------------------------------------------------------------------------

  Widget _buildStep1() {
    final canContinue = _selectedReason != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStep1Header(),
        const SizedBox(height: 24),
        ..._CancelReason.values.map((reason) => _ReasonRadioTile(
              reason: reason,
              selected: _selectedReason == reason,
              onTap: () => setState(() => _selectedReason = reason),
            )),
        const SizedBox(height: 16),
        _buildCommentField(),
        const SizedBox(height: 28),
        _buildStep1Actions(canContinue),
      ],
    );
  }

  Widget _buildStep1Header() {
    return Row(
      children: [
        ExcludeSemantics(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cancel_outlined,
              color: AppColors.error,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              AppStrings.billingCancelWhyTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Oxanium',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentField() {
    return TextField(
      controller: _commentController,
      maxLines: 3,
      minLines: 1,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: AppStrings.billingCancelFeedbackLabel,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.borderGlass),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.6)),
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
      ),
    );
  }

  Widget _buildStep1Actions(bool canContinue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          key: const Key('continuar_btn'),
          onPressed: canContinue ? _goToStep2 : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black,
            disabledBackgroundColor:
                AppColors.primary.withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            AppStrings.billingCancelContinue,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),
        Semantics(
          label: 'Mantener mi suscripción activa',
          button: true,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(AppStrings.billingCancelKeepSubscription),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 2 — Confirmation
  // ---------------------------------------------------------------------------

  Widget _buildStep2(String fecha) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStep2Header(),
        const SizedBox(height: 24),
        _ConsequencesBullets(fecha: fecha),
        if (_mutationError != null) ...[
          const SizedBox(height: 12),
          _buildMutationError(_mutationError!),
        ],
        const SizedBox(height: 28),
        _buildStep2Actions(fecha),
      ],
    );
  }

  Widget _buildStep2Header() {
    return Row(
      children: [
        // Back button
        Semantics(
          label: 'Volver al paso anterior',
          button: true,
          child: GestureDetector(
            onTap: _cancelling ? null : _goBackToStep1,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderGlass),
              ),
              child: const ExcludeSemantics(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textSecondary,
                  size: 14,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              'Confirmá la cancelación',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Oxanium',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMutationError(String message) {
    return Semantics(
      liveRegion: true,
      label: 'Error: $message',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2Actions(String fecha) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary CTA — keep subscription (tab order: first)
        Semantics(
          label: 'Mantener mi suscripción activa',
          button: true,
          child: FilledButton(
            key: const Key('mantener_btn'),
            onPressed: _cancelling ? null : () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              disabledBackgroundColor:
                  AppColors.primary.withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Mantener mi suscripción',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Secondary CTA — confirm cancellation (destructive, tab order: last)
        Semantics(
          label: 'Cancelar suscripción definitivamente - esta acción no puede deshacerse',
          button: true,
          child: OutlinedButton(
            key: const Key('confirmar_cancel_btn'),
            onPressed: _cancelling ? null : () => _confirmCancel(fecha),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.7)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _cancelling
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.error,
                    ),
                  )
                : const Text(
                    'Confirmar cancelación',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Consequence bullets
// ---------------------------------------------------------------------------

class _ConsequencesBullets extends StatelessWidget {
  const _ConsequencesBullets({required this.fecha});

  final String fecha;

  @override
  Widget build(BuildContext context) {
    final bullets = [
      'Tus bots seguirán activos hasta $fecha',
      'Las conversaciones acumuladas se conservan',
      'Podés reactivar en cualquier momento antes de esa fecha',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGlass),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: bullets
            .map(
              (text) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.textSecondary,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reason radio tile
// ---------------------------------------------------------------------------

class _ReasonRadioTile extends StatelessWidget {
  const _ReasonRadioTile({
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  final _CancelReason reason;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Motivo de cancelación: ${reason.label}',
      selected: selected,
      button: true,
      child: GestureDetector(
      key: ValueKey('radio_${reason.label}'),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.5)
                : AppColors.borderGlass,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      selected ? AppColors.primary : AppColors.textSecondary,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              reason.label,
              style: TextStyle(
                color: selected ? AppColors.primary : Colors.white,
                fontSize: 13,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

// ---------------------------------------------------------------------------
// Modal container decoration (shared with proration_preview_modal pattern)
// ---------------------------------------------------------------------------

class _ModalContainer extends StatelessWidget {
  const _ModalContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF09090B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGlass),
      ),
      child: child,
    );
  }
}

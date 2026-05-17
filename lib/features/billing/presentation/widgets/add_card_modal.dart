// Archivo: lib/features/billing/presentation/widgets/add_card_modal.dart
//
// T4·09 — AddCardModal — gateway-aware modal for adding a payment method.
//
// Design contract:
//   - Gateway is read from billingV2Provider.subscription.gateway.
//   - null gateway → blocks all actions, shows configuration error.
//   - stripe → StripeElementsCardForm for tokenization.
//   - mp    → MercadoPagoBrickForm for tokenization.
//   - Token lifecycle: subform calls onToken → _pendingToken set → user taps
//     GUARDAR → addPaymentMethod called → modal closes on success only.
//   - PAN never appears in this widget at any point.
//   - "Establecer como predeterminado" checkbox passes setAsDefault to provider.

import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/billing/domain/models/subscription.dart';
import 'package:botslode/features/billing/domain/services/payment_error_service.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/widgets/mercadopago_brick_form.dart';
import 'package:botslode/features/billing/presentation/widgets/stripe_elements_card_form.dart';
import 'package:botslode/l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class AddCardModal extends ConsumerStatefulWidget {
  /// DI hook for Stripe tokenization — for testing only.
  final Future<PaymentMethod> Function(PaymentMethodParams)? stripeCreatePmOverride;

  /// Amount in centavos passed to MercadoPago Brick on initialization.
  /// Use 0 for pure card-vault flows; callers may pass a real amount when
  /// the Brick requires a non-zero value to render.
  final int mpAmountCents;

  const AddCardModal({
    super.key,
    this.stripeCreatePmOverride,
    this.mpAmountCents = 0,
  });

  @override
  ConsumerState<AddCardModal> createState() => _AddCardModalState();
}

class _AddCardModalState extends ConsumerState<AddCardModal> {
  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  String? _pendingToken;
  bool _setAsDefault = false;
  bool _isSaving = false;
  bool _hasSucceeded = false;
  bool _hasFailed = false;
  String _failureTitle = '';
  String _failureMessage = '';

  // ---------------------------------------------------------------------------
  // Token lifecycle (called by subforms)
  // ---------------------------------------------------------------------------

  void _onTokenReceived(String token) {
    setState(() {
      _pendingToken = token;
      _hasFailed = false;
      _failureTitle = '';
      _failureMessage = '';
    });
  }

  void _onSubformError(String message) {
    setState(() {
      _hasFailed = true;
      _failureTitle = 'ERROR DE TOKENIZACIÓN';
      _failureMessage = message;
    });
  }

  // ---------------------------------------------------------------------------
  // Save action
  // ---------------------------------------------------------------------------

  Future<void> _onSave() async {
    final token = _pendingToken;
    if (token == null || _isSaving) return;

    setState(() {
      _isSaving = true;
      // Clear token immediately to prevent double-submit if subform fires again.
      _pendingToken = null;
    });

    try {
      await ref.read(billingV2Provider.notifier).addPaymentMethod(
            token,
            setAsDefault: _setAsDefault,
          );

      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _hasSucceeded = true;
      });

      await Future.delayed(const Duration(milliseconds: 2000));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      final rawError =
          e is BillingException ? '${e.code} ${e.message}' : e.toString();
      final errorDetails = PaymentErrorService.parseError(rawError);
      setState(() {
        _isSaving = false;
        _hasFailed = true;
        _failureTitle = errorDetails.title;
        _failureMessage = errorDetails.message;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final gateway =
        ref.watch(billingV2Provider).value?.subscription?.gateway;

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
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF09090B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderGlass),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 30,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: _buildContent(gateway),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(PaymentGateway? gateway) {
    if (_hasSucceeded) return _buildSuccessState();
    if (_hasFailed) return _buildFailureState();
    return _buildNormalState(gateway);
  }

  // ---------------------------------------------------------------------------
  // Normal state
  // ---------------------------------------------------------------------------

  Widget _buildNormalState(PaymentGateway? gateway) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.credit_card_outlined,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: const Text(
                        AppStrings.billingAddCardTitle,
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Oxanium',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.38),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppStrings.billingAddCardSecurityNote,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.38),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Gateway subform ─────────────────────────────────────────────────
          _buildGatewaySubform(gateway),

          // ── Default checkbox (only when gateway is configured) ──────────────
          if (gateway != null) ...[
            const SizedBox(height: 16),
            _buildDefaultCheckbox(),
          ],

          const SizedBox(height: 20),

          // ── Footer ──────────────────────────────────────────────────────────
          _buildFooter(showSaveButton: gateway != null),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Gateway subform switch
  // ---------------------------------------------------------------------------

  Widget _buildGatewaySubform(PaymentGateway? gateway) {
    switch (gateway) {
      case PaymentGateway.stripe:
        return StripeElementsCardForm(
          onToken: _onTokenReceived,
          onError: _onSubformError,
          createPaymentMethodOverride: widget.stripeCreatePmOverride,
        );

      case PaymentGateway.mp:
        return MercadoPagoBrickForm(
          onToken: _onTokenReceived,
          onError: _onSubformError,
          amountCents: widget.mpAmountCents,
          mpPublicKey: const String.fromEnvironment(
            'MP_PUBLIC_KEY',
            defaultValue: '',
          ),
          fallbackCheckoutUrl: null,
        );

      case null:
        return _buildUnknownGatewayError();
    }
  }

  Widget _buildUnknownGatewayError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.error,
            size: 36,
          ),
          const SizedBox(height: 12),
          const Text(
            AppStrings.billingAddCardGatewayNotConfiguredTitle,
            style: TextStyle(
              color: AppColors.error,
              fontFamily: 'Oxanium',
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.billingAddCardGatewayNotConfiguredMsg,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Default checkbox
  // ---------------------------------------------------------------------------

  Widget _buildDefaultCheckbox() {
    return Semantics(
      label: 'Usar como tarjeta predeterminada para pagos',
      checked: _setAsDefault,
      child: InkWell(
        onTap: () => setState(() => _setAsDefault = !_setAsDefault),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: ExcludeSemantics(
                  child: Checkbox(
                    value: _setAsDefault,
                    onChanged: (v) => setState(() => _setAsDefault = v ?? false),
                    activeColor: AppColors.primary,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.38)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                AppStrings.billingAddCardSetDefault,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Footer
  // ---------------------------------------------------------------------------

  Widget _buildFooter({required bool showSaveButton}) {
    final bool saveEnabled = _pendingToken != null && !_isSaving;

    final cancelButton = Expanded(
      child: OutlinedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          foregroundColor: Colors.white,
        ),
        child: const Text(
          AppStrings.billingAddCardCancel,
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

    if (!showSaveButton) {
      return Row(children: [cancelButton]);
    }

    return Row(
      children: [
        cancelButton,
        const SizedBox(width: 12),
        Expanded(
          child: Semantics(
            label: 'Agregar tarjeta de crédito/débito',
            button: true,
            enabled: saveEnabled,
            child: ElevatedButton(
              onPressed: saveEnabled ? _onSave : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.2),
                foregroundColor: Colors.black,
                disabledForegroundColor:
                    Colors.black.withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black),
                    )
                  : const Text(
                      AppStrings.billingAddCardSave,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Oxanium',
                        letterSpacing: 1.5,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Success state
  // ---------------------------------------------------------------------------

  Widget _buildSuccessState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.success, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withValues(alpha: 0.15),
                blurRadius: 15,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(
            Icons.check_rounded,
            color: AppColors.success,
            size: 44,
          ),
        )
            .animate()
            .scale(duration: 400.ms, curve: Curves.elasticOut)
            .then()
            .animate(onPlay: (c) => c.repeat(period: 3.seconds))
            .shimmer(
                duration: 1.5.seconds,
                color: Colors.white.withValues(alpha: 0.4),
                angle: 0.5),

        const SizedBox(height: 20),

        const Text(
          AppStrings.billingAddCardSuccessTitle,
          style: TextStyle(
            color: AppColors.success,
            fontFamily: 'Oxanium',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ).animate().fadeIn().moveY(begin: 8, end: 0),

        const SizedBox(height: 10),

        Text(
          AppStrings.billingAddCardSuccessMsg,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
          ),
        ).animate().fadeIn(delay: 200.ms),

        const SizedBox(height: 24),

        Text(
          AppStrings.billingAddCardClosing,
          style: TextStyle(
            color: AppColors.success.withValues(alpha: 0.5),
            fontSize: 10,
            fontFamily: 'Courier',
            letterSpacing: 2.0,
          ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Failure state
  // ---------------------------------------------------------------------------

  Widget _buildFailureState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
                color: AppColors.error.withValues(alpha: 0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withValues(alpha: 0.15),
                blurRadius: 15,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(
            Icons.gpp_bad_rounded,
            color: AppColors.error,
            size: 36,
          ),
        )
            .animate(onPlay: (c) => c.repeat(period: 3.seconds))
            .shimmer(
                duration: 1.5.seconds,
                color: Colors.white.withValues(alpha: 0.4),
                angle: 0.5),

        const SizedBox(height: 20),

        Text(
          _failureTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.error,
            fontFamily: 'Oxanium',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),

        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Text(
            _failureMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),

        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  AppStrings.billingCheckoutClose,
                  style: TextStyle(fontSize: 12, letterSpacing: 1.5),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => setState(() {
                  _hasFailed = false;
                  _failureTitle = '';
                  _failureMessage = '';
                }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'REINTENTAR',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

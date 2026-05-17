// Archivo: lib/features/billing/presentation/widgets/payment_checkout_modal.dart
//
// T4·06 — PaymentCheckoutModal with Stripe / MercadoPago gateway switch.
//
// Design contract:
//   - Gateway is read from billingV2Provider.subscription.gateway.
//   - null gateway → blocks all payment actions, shows configuration error.
//   - stripe → embeds StripeElementsCardForm for tokenization.
//   - mp    → embeds MercadoPagoBrickForm for tokenization.
//   - Token lifecycle: subform calls onToken → _pendingToken set → user taps
//     PAGAR → addPaymentMethod called → modal closes on success only.
//   - PAN never appears in this widget at any point.
//   - idempotencyKey is never shown in UI (used in notifier call, T5).

import 'dart:ui';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/billing/domain/models/subscription.dart';

// ---------------------------------------------------------------------------
// Billing interval
// ---------------------------------------------------------------------------

enum BillingInterval { month, year }
import 'package:botslode/features/billing/domain/services/payment_error_service.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/widgets/mercadopago_brick_form.dart';
import 'package:botslode/features/billing/presentation/widgets/stripe_elements_card_form.dart';
import 'package:botslode/l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Keyboard shortcut intent
// ---------------------------------------------------------------------------

class _DialogSubmitIntent extends Intent {
  const _DialogSubmitIntent();
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class PaymentCheckoutModal extends ConsumerStatefulWidget {
  /// USD amount for display and ARS conversion.
  final double amount;

  /// USD → ARS exchange rate used to compute the approximate ARS total.
  final double exchangeRate;

  /// Plan name shown in the modal header.
  final String planName;

  /// Billing frequency shown in the modal header (month / year).
  final BillingInterval frequency;

  /// Idempotency key passed to the notifier — never displayed to the user.
  final String idempotencyKey;

  const PaymentCheckoutModal({
    super.key,
    required this.amount,
    required this.exchangeRate,
    this.planName = '',
    this.frequency = BillingInterval.month,
    this.idempotencyKey = '',
  });

  @override
  ConsumerState<PaymentCheckoutModal> createState() =>
      _PaymentCheckoutModalState();
}

class _PaymentCheckoutModalState extends ConsumerState<PaymentCheckoutModal> {
  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  /// Token received from the gateway subform — never logged.
  String? _pendingToken;

  /// True while addPaymentMethod is in-flight.
  bool _isMutating = false;

  /// True when the backend returned an error.
  bool _hasFailed = false;

  /// True when the backend call succeeded (success UI then pop).
  bool _hasSucceeded = false;

  String _failureTitle = '';
  String _failureMessage = '';

  // ---------------------------------------------------------------------------
  // Token lifecycle callbacks (called by sub-forms)
  // ---------------------------------------------------------------------------

  /// Called by the gateway subform when tokenization succeeds.
  /// Stores the token and enables the PAGAR button — does NOT call backend yet.
  void _onTokenReceived(String token) {
    setState(() {
      _pendingToken = token;
      // Clear any previous error so the user sees the enabled button.
      _hasFailed = false;
      _failureTitle = '';
      _failureMessage = '';
    });
  }

  /// Called by the gateway subform when tokenization fails.
  void _onSubformError(String message) {
    setState(() {
      _hasFailed = true;
      _failureTitle = 'ERROR DE TOKENIZACIÓN';
      _failureMessage = message;
    });
  }

  // ---------------------------------------------------------------------------
  // Pay action
  // ---------------------------------------------------------------------------

  Future<void> _onConfirmPay() async {
    final token = _pendingToken;
    if (token == null || _isMutating) return;

    setState(() {
      _isMutating = true;
      // Clear token immediately so a subform callback mid-flight cannot create
      // a misleading "ready" indicator while the mutation is in-flight.
      _pendingToken = null;
    });

    try {
      // TODO(T5): pass widget.idempotencyKey once addPaymentMethod accepts it.
      await ref.read(billingV2Provider.notifier).addPaymentMethod(
            token,
            setAsDefault: true,
          );

      if (!mounted) return;

      setState(() {
        _isMutating = false;
        _hasSucceeded = true;
      });

      // Brief success display before auto-close.
      await Future.delayed(const Duration(milliseconds: 2500));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      // For BillingException, pass code + message so PaymentErrorService can
      // pattern-match structured error codes when T5 wires real exceptions.
      final String rawError;
      if (e is BillingException) {
        rawError = '${e.code} ${e.message}';
      } else {
        rawError = e.toString();
      }
      final errorDetails = PaymentErrorService.parseError(rawError);
      setState(() {
        _isMutating = false;
        _hasFailed = true;
        _failureTitle = errorDetails.title;
        _failureMessage = errorDetails.message;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String get _frequencyLabel =>
      widget.frequency == BillingInterval.month ? 'mensual' : 'anual';

  List<Color> get _currentGradient {
    if (_hasFailed) {
      return [AppColors.error, AppColors.error.withValues(alpha: 0.2)];
    }
    if (_hasSucceeded) {
      return [AppColors.success, AppColors.success.withValues(alpha: 0.2)];
    }
    return [AppColors.primary.withValues(alpha: 0.3), Colors.transparent];
  }

  Color get _currentShadowColor {
    if (_hasFailed) return AppColors.error.withValues(alpha: 0.1);
    if (_hasSucceeded) return AppColors.success.withValues(alpha: 0.2);
    return Colors.black.withValues(alpha: 0.5);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final billingV2 = ref.watch(billingV2Provider);
    final gateway = billingV2.value?.subscription?.gateway;
    final double approxARS = widget.amount * widget.exchangeRate;

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): _DialogSubmitIntent(),
      },
      child: Actions(
        actions: {
          _DialogSubmitIntent: CallbackAction<_DialogSubmitIntent>(
            onInvoke: (_) {
              if (!_hasFailed && !_hasSucceeded) _onConfirmPay();
              return null;
            },
          ),
        },
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 480,
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: _currentGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _currentShadowColor,
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF09090B),
                  borderRadius: BorderRadius.circular(23),
                  border: Border.all(color: AppColors.borderGlass),
                ),
                child: _buildContent(gateway, approxARS),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(PaymentGateway? gateway, double approxARS) {
    if (_hasFailed) return _buildFailureState();
    if (_hasSucceeded) return _buildSuccessState();
    return _buildNormalState(gateway, approxARS);
  }

  // ---------------------------------------------------------------------------
  // Normal state
  // ---------------------------------------------------------------------------

  Widget _buildNormalState(PaymentGateway? gateway, double approxARS) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          const ExcludeSemantics(child: Icon(Icons.hub_rounded, color: AppColors.primary, size: 40)),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: const Text(
              'CHECKOUT',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                letterSpacing: 3.0,
                fontSize: 10,
                fontFamily: 'Courier',
              ),
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: 'Total a pagar: \$${widget.amount.toStringAsFixed(2)} USD - Plan ${widget.planName} $_frequencyLabel',
            child: Text(
              '${widget.planName}  ·  \$${widget.amount.toStringAsFixed(2)} USD  ·  $_frequencyLabel',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Oxanium',
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ExcludeSemantics(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Text(
                '≈ \$ ${_formatARS(approxARS)} ARS',
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ── Gateway subform ─────────────────────────────────────────────────
          _buildGatewayBody(gateway, approxARS),

          const SizedBox(height: 24),

          // ── Footer buttons ──────────────────────────────────────────────────
          // When gateway is null (error block), only CANCELAR is shown.
          _buildFooter(showPayButton: gateway != null),
        ],
      ),
    );
  }

  /// Formats ARS amount with thousand-separator dots (e.g. 1.200.000).
  String _formatARS(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  // ---------------------------------------------------------------------------
  // Gateway body switch
  // ---------------------------------------------------------------------------

  Widget _buildGatewayBody(PaymentGateway? gateway, double approxARS) {
    switch (gateway) {
      case PaymentGateway.stripe:
        return StripeElementsCardForm(
          onToken: _onTokenReceived,
          onError: _onSubformError,
        );

      case PaymentGateway.mp:
        return MercadoPagoBrickForm(
          onToken: _onTokenReceived,
          onError: _onSubformError,
          amountCents: (widget.amount * widget.exchangeRate * 100).round(),
          mpPublicKey: const String.fromEnvironment(
            'MP_PUBLIC_KEY',
            defaultValue: '',
          ),
          fallbackCheckoutUrl: null, // TODO(T5): pass real URL
        );

      case null:
        return _buildUnknownGatewayError();
    }
  }

  /// Shown when [subscription.gateway] is null.
  /// All payment actions are blocked in this state.
  Widget _buildUnknownGatewayError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
            size: 40,
          ),
          const SizedBox(height: 16),
          const Text(
            AppStrings.billingAddCardGatewayNotConfiguredTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.error,
              fontFamily: 'Oxanium',
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            AppStrings.billingAddCardGatewayNotConfiguredMsg,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Footer
  // ---------------------------------------------------------------------------

  Widget _buildFooter({bool showPayButton = true}) {
    final bool payEnabled = _pendingToken != null && !_isMutating;

    final cancelarButton = Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
              color: AppColors.error.withValues(alpha: 0.3), width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            AppStrings.billingAddCardCancel,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 11,
              letterSpacing: 2.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );

    if (!showPayButton) {
      // Unknown gateway: only show CANCELAR, full width.
      return Row(children: [cancelarButton]);
    }

    return Row(
      children: [
        // CANCELAR
        cancelarButton,

        const SizedBox(width: 12),

        // PAGAR
        Expanded(
          child: Semantics(
            label: _isMutating
                ? 'Procesando pago, por favor espere'
                : 'Confirmar pago de \$${widget.amount.toStringAsFixed(2)} - Plan ${widget.planName}',
            liveRegion: _isMutating,
            child: ElevatedButton(
              onPressed: payEnabled ? _onConfirmPay : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.2),
                foregroundColor: Colors.black,
                disabledForegroundColor:
                    Colors.black.withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isMutating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text(
                      'PAGAR',
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
  // Failure state
  // ---------------------------------------------------------------------------

  Widget _buildFailureState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
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
          child:
              const Icon(Icons.gpp_bad_rounded, color: AppColors.error, size: 40),
        )
            .animate(onPlay: (c) => c.repeat(period: 3.seconds))
            .shimmer(
                duration: 1.5.seconds,
                color: Colors.white.withValues(alpha: 0.4),
                angle: 0.5),

        const SizedBox(height: 24),

        Text(
          _failureTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.error,
            fontFamily: 'Oxanium',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Text(
            _failureMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),

        const SizedBox(height: 32),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(AppStrings.billingCheckoutClose),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasFailed = false;
                    _failureTitle = '';
                    _failureMessage = '';
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'REINTENTAR',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
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
          padding: const EdgeInsets.all(24),
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
          child: const Icon(Icons.check_rounded,
              color: AppColors.success, size: 48),
        )
            .animate()
            .scale(duration: 400.ms, curve: Curves.elasticOut)
            .then()
            .animate(onPlay: (c) => c.repeat(period: 3.seconds))
            .shimmer(
                duration: 1.5.seconds,
                color: Colors.white.withValues(alpha: 0.4),
                angle: 0.5),

        const SizedBox(height: 24),

        const Text(
          AppStrings.billingAddCardSuccessTitle,
          style: TextStyle(
            color: AppColors.success,
            fontFamily: 'Oxanium',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ).animate().fadeIn().moveY(begin: 10, end: 0),

        const SizedBox(height: 12),

        Text(
          AppStrings.billingAddCardSuccessMsg,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
            height: 1.5,
          ),
        ).animate().fadeIn(delay: 200.ms),

        const SizedBox(height: 32),

        Text(
          AppStrings.billingAddCardClosing,
          style: TextStyle(
            color: AppColors.success.withValues(alpha: 0.5),
            fontSize: 10,
            fontFamily: 'Courier',
            letterSpacing: 2.0,
          ),
        ).animate().fadeIn(delay: 500.ms),
      ],
    );
  }
}

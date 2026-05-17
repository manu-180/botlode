// Archivo: lib/features/billing/presentation/widgets/payment_checkout_modal.dart
//
// T4·54 — PaymentCheckoutModal: Hangar OS «terminal de transacción segura».
//
// Design contract:
//   - Gateway es leído de billingV2Provider.subscription.gateway.
//   - null gateway → bloquea todo pago, muestra error de configuración.
//   - stripe → embebe StripeElementsCardForm.
//   - mp    → embebe MercadoPagoBrickForm.
//   - Token lifecycle: subformulario llama onToken → _pendingToken set →
//     usuario presiona PAGAR → addPaymentMethod llamado → modal cierra.
//   - PAN nunca aparece en este widget.
//   - idempotencyKey nunca se muestra (se pasa al notifier).

import 'dart:ui';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/buttons/app_button.dart';
import 'package:botslode/core/ui/hud/hud.dart';
import 'package:botslode/core/ui/panels/holo_panel.dart';
import 'package:botslode/features/billing/domain/models/subscription.dart';
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
// Billing interval
// ---------------------------------------------------------------------------

enum BillingInterval { month, year }

// ---------------------------------------------------------------------------
// Keyboard intents
// ---------------------------------------------------------------------------

class _DialogSubmitIntent extends Intent {
  const _DialogSubmitIntent();
}

class _DialogDismissIntent extends Intent {
  const _DialogDismissIntent();
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class PaymentCheckoutModal extends ConsumerStatefulWidget {
  /// USD amount for display and ARS conversion.
  final double amount;

  /// USD → ARS exchange rate used to compute approximate ARS total.
  final double exchangeRate;

  /// Plan name shown in the modal header.
  final String planName;

  /// Billing frequency shown in the modal header.
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

class _PaymentCheckoutModalState extends ConsumerState<PaymentCheckoutModal>
    with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────

  // Ring and closing bar dimensions (§5.7–5.8).
  static const double _kStateRingSize = 88;
  static const double _kStateIconSize = 40;
  static const double _kStateGlowBlur = 20;
  static const double _kStateGlowSpread = 2;
  static const double _kClosingBarWidth = 120;
  // Modal layout constants.
  static const double _kScrimBlur = 12;
  static const double _kModalWidth = 480;
  static const double _kCheckoutIconSize = 32;
  static const double _kStateRingBorderWidth = 2;
  static const double _kGatewayBorderWidth = 1.5;
  // Typography micro-adjustments.
  static const double _kLetterSpacingLabel = 1.8;
  static const double _kLetterSpacingAmount = 2.0;
  static const double _kLetterSpacingError = 1.5;
  static const double _kFontSizeRateLabel = 11;
  // Auto-close and animation timing.
  static const int _kAutoCloseMs = 2500;
  static const double _kEntryScaleBegin = 0.94;
  static const double _kEntryScaleDelta = 0.06;
  static const double _kSuccessSlideY = 8.0;
  static const int _kSuccessTextDelayMs = 200;
  // Shake animation (failure ring).
  static const double _kShakeOffset1 = 4.0;
  static const double _kShakeOffset2 = 8.0;
  static const int _kShakeDur1Ms = 45;
  static const int _kShakeDur2Ms = 70;
  static const int _kShakeDelayMs = 40;
  // Alpha values for semi-transparent color layers.
  static const double _kAlphaStateBorder = 0.50;
  static const double _kAlphaRingBg = 0.10;
  static const double _kAlphaDangerBg = 0.06;
  static const double _kAlphaDangerBorder = 0.40;
  static const double _kAlphaSuccessBg = 0.15;
  static const double _kAlphaClosingText = 0.5;

  String? _pendingToken;
  bool _isMutating = false;
  bool _hasFailed = false;
  bool _hasSucceeded = false;
  String _failureTitle = '';
  String _failureMessage = '';

  // HudTicker starts at 0 and counts up after mount (P7 pattern).
  double _tickerAmount = 0;

  // Modal entry animation (scale 0.94→1 + fade).
  late final AnimationController _entryCtrl;
  late final Animation<double> _entryAnim;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: AppMotion.durSlow);
    _entryAnim = CurvedAnimation(
      parent: _entryCtrl,
      curve: AppMotion.easeEntrance,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduce = AppMotion.reduced(context);
      if (reduce) {
        _entryCtrl.value = 1.0;
      } else {
        _entryCtrl.forward();
      }
      // Trigger ticker count from 0 → amount (P7).
      setState(() => _tickerAmount = widget.amount);
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── Subform callbacks ──────────────────────────────────────────────────────

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

  // ── Pay action ─────────────────────────────────────────────────────────────

  Future<void> _onConfirmPay() async {
    final token = _pendingToken;
    if (token == null || _isMutating) return;

    setState(() {
      _isMutating = true;
      // Clear token immediately so mid-flight callbacks don't re-enable button.
      _pendingToken = null;
    });

    try {
      await ref.read(billingV2Provider.notifier).addPaymentMethod(
            token,
            setAsDefault: true,
          );
      if (!mounted) return;
      setState(() {
        _isMutating = false;
        _hasSucceeded = true;
      });
      await Future.delayed(const Duration(milliseconds: _kAutoCloseMs));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      final rawError =
          e is BillingException ? '${e.code} ${e.message}' : e.toString();
      final err = PaymentErrorService.parseError(rawError);
      setState(() {
        _isMutating = false;
        _hasFailed = true;
        _failureTitle = err.title;
        _failureMessage = err.message;
      });
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String get _frequencyLabel =>
      widget.frequency == BillingInterval.month ? 'Mensual' : 'Anual';

  String _formatARS(double amount) => amount
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );

  Color get _stateBorderColor {
    if (_hasFailed) return AppColors.danger.withValues(alpha: _kAlphaStateBorder);
    if (_hasSucceeded) return AppColors.success.withValues(alpha: _kAlphaStateBorder);
    return AppColors.borderGold;
  }

  List<BoxShadow> get _stateGlow {
    if (_hasFailed) return AppDimens.glowStatus(AppColors.danger);
    if (_hasSucceeded) return AppDimens.glowStatus(AppColors.success);
    return AppDimens.glowGold;
  }

  String get _contentKey {
    if (_hasFailed) return 'failure';
    if (_hasSucceeded) return 'success';
    return 'normal';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final billingV2 = ref.watch(billingV2Provider);
    final gateway = billingV2.value?.subscription?.gateway;
    final double approxARS = widget.amount * widget.exchangeRate;
    final reduced = AppMotion.reduced(context);

    return PopScope(
      // Block barrier tap and Escape while payment is in-flight.
      canPop: !_isMutating,
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): _DialogSubmitIntent(),
          SingleActivator(LogicalKeyboardKey.escape): _DialogDismissIntent(),
        },
        child: Actions(
          actions: {
            _DialogSubmitIntent: CallbackAction<_DialogSubmitIntent>(
              onInvoke: (_) {
                if (!_hasFailed &&
                    !_hasSucceeded &&
                    _pendingToken != null &&
                    !_isMutating) {
                  _onConfirmPay();
                }
                return null;
              },
            ),
            _DialogDismissIntent: CallbackAction<_DialogDismissIntent>(
              onInvoke: (_) {
                if (!_isMutating) Navigator.of(context).pop();
                return null;
              },
            ),
          },
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: _kScrimBlur, sigmaY: _kScrimBlur),
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: AnimatedBuilder(
                animation: _entryAnim,
                builder: (_, child) {
                  final t = _entryAnim.value;
                  return Opacity(
                    opacity: t,
                    child: reduced
                        ? child!
                        : Transform.scale(
                            scale: _kEntryScaleBegin + _kEntryScaleDelta * t,
                            child: child,
                          ),
                  );
                },
                child: SizedBox(
                  width: _kModalWidth,
                  child: AnimatedContainer(
                    duration: AppMotion.durSlow,
                    curve: AppMotion.easeStandard,
                    decoration: BoxDecoration(
                      boxShadow: [...AppDimens.elev3, ..._stateGlow],
                    ),
                    child: HoloPanel(
                      shape: HoloPanelShape.chamfer,
                      cornerBrackets: true,
                      padding: const EdgeInsets.all(AppDimens.space32),
                      borderColor: _stateBorderColor,
                      child: AnimatedSwitcher(
                        duration: reduced
                            ? AppMotion.durCrossfadeReduced
                            : AppMotion.durBase,
                        child: KeyedSubtree(
                          key: ValueKey(_contentKey),
                          child: _buildContent(gateway, approxARS, reduced),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
      PaymentGateway? gateway, double approxARS, bool reduced) {
    if (_hasFailed) return _buildFailureState(reduced);
    if (_hasSucceeded) return _buildSuccessState(reduced);
    return _buildNormalState(gateway, approxARS, reduced);
  }

  // ── Normal state ───────────────────────────────────────────────────────────

  Widget _buildNormalState(
      PaymentGateway? gateway, double approxARS, bool reduced) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: AppDimens.space20),
          Semantics(
            label: 'Total a pagar: \$${widget.amount.toStringAsFixed(2)} USD,'
                ' aproximadamente \$${_formatARS(approxARS)} ARS,'
                ' Plan ${widget.planName} $_frequencyLabel',
            excludeSemantics: true,
            child: _buildAmountHero(approxARS, reduced),
          ),
          const SizedBox(height: AppDimens.space16),
          _buildBillingSummary(),
          const SizedBox(height: AppDimens.space24),
          _buildGatewayBody(gateway, approxARS),
          const SizedBox(height: AppDimens.space24),
          _buildFooter(showPayButton: gateway != null),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const ExcludeSemantics(
          child: Icon(Icons.hub_rounded, color: AppColors.gold, size: _kCheckoutIconSize),
        ),
        const SizedBox(height: AppDimens.space12),
        Semantics(
          header: true,
          child: Text(
            '// CHECKOUT',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: _kLetterSpacingLabel,
            ),
          ),
        ),
        const SizedBox(height: AppDimens.space8),
        Text(
          '${widget.planName}  ·  $_frequencyLabel'.toUpperCase(),
          textAlign: TextAlign.center,
          style: AppTextStyles.titleM.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppDimens.space16),
        const HudDivider(),
      ],
    );
  }

  Widget _buildAmountHero(double approxARS, bool reduced) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.space20),
      decoration: BoxDecoration(
        color: AppColors.surfaceHud,
        borderRadius: AppDimens.brM,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Text(
            'TOTAL A PAGAR',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: _kLetterSpacingAmount,
            ),
          ),
          const SizedBox(height: AppDimens.space12),
          // USD row — hero amount
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '\$',
                style: AppTextStyles.titleM.copyWith(color: AppColors.gold),
              ),
              const SizedBox(width: AppDimens.space4),
              HudTicker(
                value: _tickerAmount,
                decimals: 2,
                animate: !reduced,
                style: AppTextStyles.numericTicker.copyWith(color: AppColors.gold),
              ),
              const SizedBox(width: AppDimens.space8),
              Text(
                'USD',
                style: AppTextStyles.bodyS.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space8),
          // ARS conversion
          Text(
            '≈ \$ ${_formatARS(approxARS)} ARS',
            style: AppTextStyles.hudReadout.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimens.space4),
          Text(
            'TC ${widget.exchangeRate.toStringAsFixed(0)}',
            style: AppTextStyles.mono.copyWith(
              color: AppColors.textTertiary,
              fontSize: _kFontSizeRateLabel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingSummary() {
    final period =
        widget.frequency == BillingInterval.month ? 'mes' : 'año';
    final rows = [
      'Acceso al Plan ${widget.planName} por 1 $period',
      'Renovación automática',
    ];
    return Column(
      children: rows
          .map(
            (text) => Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: AppDimens.space4),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_rounded,
                    size: AppDimens.iconXS,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: AppDimens.space8),
                  Expanded(
                    child: Text(
                      text,
                      style: AppTextStyles.bodyS
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  // ── Gateway body ───────────────────────────────────────────────────────────

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
          fallbackCheckoutUrl: null,
        );
      case null:
        return _buildUnknownGatewayError();
    }
  }

  Widget _buildUnknownGatewayError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space20,
        vertical: AppDimens.space24,
      ),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: _kAlphaDangerBg),
        borderRadius: AppDimens.brM,
        border: Border.all(
          color: AppColors.danger.withValues(alpha: _kAlphaDangerBorder),
          width: _kGatewayBorderWidth,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.danger,
            size: AppDimens.iconL,
          ),
          const SizedBox(height: AppDimens.space16),
          Text(
            AppStrings.billingAddCardGatewayNotConfiguredTitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.label.copyWith(
              color: AppColors.danger,
              letterSpacing: _kLetterSpacingError,
            ),
          ),
          const SizedBox(height: AppDimens.space8),
          Text(
            AppStrings.billingAddCardGatewayNotConfiguredMsg,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyM
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────

  Widget _buildFooter({bool showPayButton = true}) {
    final bool payEnabled = _pendingToken != null && !_isMutating;

    final cancelBtn = Expanded(
      child: AppButton.danger(
        label: AppStrings.billingAddCardCancel,
        onPressed: _isMutating ? null : () => Navigator.of(context).pop(),
        size: AppButtonSize.lg,
      ),
    );

    if (!showPayButton) {
      return Row(children: [cancelBtn]);
    }

    return Row(
      children: [
        cancelBtn,
        const SizedBox(width: AppDimens.space12),
        Expanded(
          child: Semantics(
            label: _isMutating
                ? 'Procesando pago, por favor espere'
                : 'Confirmar pago de \$${widget.amount.toStringAsFixed(2)} USD,'
                    ' Plan ${widget.planName}',
            liveRegion: _isMutating,
            child: AppButton.primary(
              label: 'PAGAR',
              onPressed: payEnabled ? _onConfirmPay : null,
              size: AppButtonSize.lg,
              loading: _isMutating,
            ),
          ),
        ),
      ],
    );
  }

  // ── Success state ──────────────────────────────────────────────────────────

  Widget _buildSuccessState(bool reduced) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStateRing(
          icon: Icons.check_rounded,
          color: AppColors.success,
          glowColor: AppColors.successGlow,
          reduced: reduced,
          shake: false,
        ),
        const SizedBox(height: AppDimens.space24),
        Text(
          'PAGO CONFIRMADO',
          style: AppTextStyles.titleL.copyWith(
            color: AppColors.success,
            letterSpacing: _kLetterSpacingAmount,
          ),
        )
            .animate()
            .fadeIn(
              duration: reduced
                  ? AppMotion.durCrossfadeReduced
                  : AppMotion.durBase,
            )
            .moveY(
              begin: _kSuccessSlideY,
              end: 0,
              duration: reduced
                  ? AppMotion.durCrossfadeReduced
                  : AppMotion.durBase,
              curve: AppMotion.easeEntrance,
            ),
        const SizedBox(height: AppDimens.space12),
        Text(
          AppStrings.billingAddCardSuccessMsg,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
        ).animate().fadeIn(
              delay: reduced ? Duration.zero : _kSuccessTextDelayMs.ms,
              duration: reduced
                  ? AppMotion.durCrossfadeReduced
                  : AppMotion.durBase,
            ),
        const SizedBox(height: AppDimens.space32),
        _buildClosingIndicator(reduced),
      ],
    );
  }

  Widget _buildClosingIndicator(bool reduced) {
    return Column(
      children: [
        if (!reduced)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.0, end: 0.0),
            duration: const Duration(milliseconds: _kAutoCloseMs),
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.radiusPill),
              child: SizedBox(
                width: _kClosingBarWidth,
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor:
                      AppColors.success.withValues(alpha: _kAlphaSuccessBg),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.success),
                ),
              ),
            ),
          ),
        if (!reduced) const SizedBox(height: AppDimens.space8),
        Text(
          AppStrings.billingAddCardClosing,
          style: AppTextStyles.mono.copyWith(
            color: AppColors.success.withValues(alpha: _kAlphaClosingText),
            letterSpacing: _kLetterSpacingAmount,
          ),
        ),
      ],
    );
  }

  // ── Failure state ──────────────────────────────────────────────────────────

  Widget _buildFailureState(bool reduced) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStateRing(
          icon: Icons.gpp_bad_rounded,
          color: AppColors.danger,
          glowColor: AppColors.dangerGlow,
          reduced: reduced,
          shake: true,
        ),
        const SizedBox(height: AppDimens.space24),
        Semantics(
          liveRegion: true,
          child: Text(
            _failureTitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleL.copyWith(
              color: AppColors.danger,
              letterSpacing: _kLetterSpacingError,
            ),
          ),
        ),
        const SizedBox(height: AppDimens.space12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimens.space16),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: _kAlphaDangerBg),
            borderRadius: AppDimens.brM,
            border: Border.all(
              color: AppColors.danger.withValues(alpha: _kAlphaDangerBorder),
            ),
          ),
          child: Text(
            _failureMessage,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyM.copyWith(color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(height: AppDimens.space32),
        Row(
          children: [
            Expanded(
              child: AppButton.secondary(
                label: AppStrings.billingCheckoutClose,
                onPressed: () => Navigator.of(context).pop(),
                size: AppButtonSize.lg,
              ),
            ),
            const SizedBox(width: AppDimens.space12),
            Expanded(
              child: AppButton.primary(
                label: 'REINTENTAR',
                onPressed: () => setState(() {
                  // Token is intentionally not restored: the subform must re-tokenize
                  // to guarantee a fresh, single-use token after a failed payment attempt.
                  _hasFailed = false;
                  _failureTitle = '';
                  _failureMessage = '';
                }),
                size: AppButtonSize.lg,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── State ring (shared between success / failure) ──────────────────────────

  Widget _buildStateRing({
    required IconData icon,
    required Color color,
    required Color glowColor,
    required bool reduced,
    required bool shake,
  }) {
    final ring = Container(
      width: _kStateRingSize,
      height: _kStateRingSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: _kAlphaRingBg),
        border: Border.all(color: color, width: _kStateRingBorderWidth),
        boxShadow: [
          BoxShadow(color: glowColor, blurRadius: _kStateGlowBlur, spreadRadius: _kStateGlowSpread),
        ],
      ),
      child: Icon(icon, color: color, size: _kStateIconSize),
    );

    if (reduced) return ring;

    if (shake) {
      // Failure: scale entrance then micro-shake (≤ 4 px horizontal, once).
      return ring
          .animate()
          .scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1.0, 1.0),
            duration: AppMotion.durBase,
            curve: AppMotion.easeEntrance,
          )
          .then(delay: _kShakeDelayMs.ms)
          .moveX(begin: 0, end: _kShakeOffset1, duration: _kShakeDur1Ms.ms, curve: AppMotion.easeExit)
          .moveX(begin: 0, end: -_kShakeOffset2, duration: _kShakeDur2Ms.ms, curve: AppMotion.easeStandard)
          .moveX(begin: 0, end: _kShakeOffset2, duration: _kShakeDur2Ms.ms, curve: AppMotion.easeStandard)
          .moveX(begin: 0, end: -_kShakeOffset1, duration: _kShakeDur1Ms.ms, curve: AppMotion.easeHover);
    }

    // Success: elastic scale entrance.
    return ring.animate().scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1.0, 1.0),
          duration: AppMotion.durDeliberate,
          curve: AppMotion.easeEntrance,
        );
  }
}

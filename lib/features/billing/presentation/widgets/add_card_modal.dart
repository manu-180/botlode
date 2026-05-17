// Archivo: lib/features/billing/presentation/widgets/add_card_modal.dart
//
// T4·51 — AddCardModal rediseñado como panel HoloPanel del Hangar OS.
// Presentación: showDialog centrado + scrim + BackdropFilter.
// Usa AddCardModal.show(context) para abrir correctamente.

import 'dart:async';
import 'dart:ui';

import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/buttons/app_button.dart';
import 'package:botslode/core/ui/hud/hud_chamfer.dart';
import 'package:botslode/core/ui/hud/hud_corner_brackets.dart';
import 'package:botslode/core/ui/hud/hud_divider.dart';
import 'package:botslode/features/billing/domain/models/subscription.dart';
import 'package:botslode/features/billing/domain/services/payment_error_service.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/widgets/mercadopago_brick_form.dart';
import 'package:botslode/features/billing/presentation/widgets/stripe_elements_card_form.dart';
import 'package:botslode/l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class AddCardModal extends ConsumerStatefulWidget {
  /// DI hook for Stripe tokenization — for testing only.
  final Future<PaymentMethod> Function(PaymentMethodParams)? stripeCreatePmOverride;

  /// Amount in centavos passed to MercadoPago Brick on initialization.
  final int mpAmountCents;

  const AddCardModal({
    super.key,
    this.stripeCreatePmOverride,
    this.mpAmountCents = 0,
  });

  /// Presents the modal as a centered HoloPanel dialog over a scrim + blur.
  static Future<void> show(
    BuildContext context, {
    Future<PaymentMethod> Function(PaymentMethodParams)? stripeCreatePmOverride,
    int mpAmountCents = 0,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.transparent, // widget handles its own scrim
      barrierDismissible: false,
      useSafeArea: false,
      builder: (_) => AddCardModal(
        stripeCreatePmOverride: stripeCreatePmOverride,
        mpAmountCents: mpAmountCents,
      ),
    );
  }

  @override
  ConsumerState<AddCardModal> createState() => _AddCardModalState();
}

class _AddCardModalState extends ConsumerState<AddCardModal>
    with TickerProviderStateMixin {
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
  bool _subformTouched = false;
  int _countdown = 2;

  // ---------------------------------------------------------------------------
  // Animation controllers
  // ---------------------------------------------------------------------------

  late final AnimationController _entryCtrl;
  late final AnimationController _successCtrl;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this);
    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _successCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.of(context).pop();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduced = AppMotion.reduced(context);
      if (reduced) {
        _entryCtrl.duration = AppMotion.durCrossfadeReduced;
        _entryCtrl.forward();
      } else {
        _entryCtrl.animateWith(
          SpringSimulation(AppMotion.springSoft, 0, 1, 0),
        );
      }
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _successCtrl.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Token lifecycle (called by subforms)
  // ---------------------------------------------------------------------------

  void _onTokenReceived(String token) {
    setState(() {
      _pendingToken = token;
      _subformTouched = true;
      _hasFailed = false;
      _failureTitle = '';
      _failureMessage = '';
    });
  }

  void _onSubformError(String message) {
    setState(() {
      _subformTouched = true;
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
        _countdown = 2;
      });

      _successCtrl.forward(from: 0);
      _countdownTimer = Timer.periodic(const Duration(milliseconds: 1000), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        setState(() => _countdown--);
        if (_countdown <= 0) t.cancel();
      });
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
  // Dismiss & discard logic
  // ---------------------------------------------------------------------------

  bool get _hasPendingData => _pendingToken != null || _subformTouched;

  void _handleCancel() {
    if (_isSaving) return;
    if (_hasPendingData) {
      _showDiscardConfirm();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _handleScrimTap() {
    if (_isSaving || _hasSucceeded) return;
    if (_hasFailed) {
      Navigator.of(context).pop();
      return;
    }
    if (_hasPendingData) {
      _showDiscardConfirm();
    } else {
      Navigator.of(context).pop();
    }
  }

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      _handleCancel();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _showDiscardConfirm() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Material(
        type: MaterialType.transparency,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Container(
              margin: const EdgeInsets.all(AppDimens.space24),
              padding: const EdgeInsets.all(AppDimens.space24),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: AppDimens.brL,
                border: Border.all(color: AppColors.borderDefault),
                boxShadow: AppDimens.elev3,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¿DESCARTAR LOS DATOS?',
                    style: AppTextStyles.titleM,
                  ),
                  const SizedBox(height: AppDimens.space8),
                  Text(
                    'Perderás la información ingresada.',
                    style: AppTextStyles.bodyM
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppDimens.space24),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton.secondary(
                          label: 'SEGUIR EDITANDO',
                          onPressed: () => Navigator.of(ctx).pop(false),
                          expand: true,
                        ),
                      ),
                      const SizedBox(width: AppDimens.space12),
                      Expanded(
                        child: AppButton.danger(
                          label: 'DESCARTAR',
                          onPressed: () => Navigator.of(ctx).pop(true),
                          expand: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if ((confirm ?? false) && mounted) {
      Navigator.of(context).pop();
    }
  }

  // ---------------------------------------------------------------------------
  // Build — full-screen overlay
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: FocusScope(
        autofocus: true,
        onKeyEvent: (_, event) => _handleKeyEvent(event),
        child: Stack(
          children: [
            // Scrim + backdrop blur
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 11, sigmaY: 11),
                child: GestureDetector(
                  onTap: _handleScrimTap,
                  behavior: HitTestBehavior.opaque,
                  child: Container(color: AppColors.scrim),
                ),
              ),
            ),
            // Centered modal panel
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimens.space24),
                  child: _buildAnimatedPanel(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedPanel(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    return AnimatedBuilder(
      animation: _entryCtrl,
      builder: (_, child) {
        final t = _entryCtrl.value.clamp(0.0, 1.0);
        final opacity = (t * 2).clamp(0.0, 1.0);
        if (reduced) {
          return Opacity(opacity: opacity, child: child);
        }
        final scale = (0.94 + 0.06 * t).clamp(0.0, 1.06);
        return Opacity(
          opacity: opacity,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: _buildPanelContainer(context),
    );
  }

  Widget _buildPanelContainer(BuildContext context) {
    final gateway = ref.watch(billingV2Provider).value?.subscription?.gateway;

    final content = SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.space24),
        child: _buildContent(gateway),
      ),
    );

    Widget panel = Container(
      decoration: const ShapeDecoration(
        color: Colors.transparent,
        shape: ChamferBorder(
          chamfer: AppDimens.chamferM,
          side: BorderSide(color: AppColors.glassBorder, width: 1.0),
        ),
        shadows: AppDimens.elev3,
      ),
      child: ClipPath(
        clipper: const ChamferClipper(chamfer: AppDimens.chamferM),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Stack(
            children: [
              // Glass fill (modal opacity)
              Positioned.fill(
                child: Container(color: AppColors.glassSurfaceStrong),
              ),
              // Top highlight
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 1,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.glassHighlightTop,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Content
              content,
            ],
          ),
        ),
      ),
    );

    return HudCornerBrackets(
      color: AppColors.borderGold,
      armLength: 18,
      child: panel,
    );
  }

  // ---------------------------------------------------------------------------
  // State routing
  // ---------------------------------------------------------------------------

  Widget _buildContent(PaymentGateway? gateway) {
    if (_hasSucceeded) return _buildSuccessState();
    if (_hasFailed) return _buildFailureState();
    return _buildNormalState(gateway);
  }

  // ---------------------------------------------------------------------------
  // Normal state
  // ---------------------------------------------------------------------------

  Widget _buildNormalState(PaymentGateway? gateway) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: AppDimens.space16),
        const HudDivider(),
        const SizedBox(height: AppDimens.space20),
        if (gateway != null) ...[
          _buildGatewaySelector(gateway),
          const SizedBox(height: AppDimens.space20),
        ],
        _buildGatewaySubform(gateway),
        if (gateway != null) ...[
          const SizedBox(height: AppDimens.space16),
          _buildHudCheckbox(),
        ],
        const SizedBox(height: AppDimens.space20),
        _buildFooter(showSaveButton: gateway != null),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIconRing(),
        const SizedBox(width: AppDimens.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'AÑADIR MÉTODO DE PAGO',
                  style: AppTextStyles.titleM,
                ),
              ),
              const SizedBox(height: AppDimens.space4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.lock_outline,
                      size: AppDimens.iconXS,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: AppDimens.space4),
                  Flexible(
                    child: Text(
                      'Tus datos se procesan de forma segura. '
                      'Nunca almacenamos el número completo.',
                      style: AppTextStyles.bodyS,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: AppDimens.space8),
        AppIconButton(
          icon: Icons.close,
          tooltip: 'Cerrar',
          onPressed: _isSaving ? null : _handleCancel,
          variant: AppButtonVariant.ghost,
          size: AppButtonSize.sm,
        ),
      ],
    );
  }

  Widget _buildIconRing() {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.surfaceHud,
        shape: BoxShape.circle,
        border: Border.fromBorderSide(
          BorderSide(color: AppColors.borderGold, width: 1.5),
        ),
        boxShadow: [
          BoxShadow(color: AppColors.goldGlow, blurRadius: 8),
        ],
      ),
      child: const Icon(
        Icons.credit_card_outlined,
        color: AppColors.gold,
        size: AppDimens.iconM,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Gateway selector (informational toggle — disabled when gateway is fixed)
  // ---------------------------------------------------------------------------

  Widget _buildGatewaySelector(PaymentGateway gateway) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PASARELA',
          style: AppTextStyles.labelSmall
              .copyWith(color: AppColors.textTertiary),
        ),
        const SizedBox(height: AppDimens.space8),
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surfaceHud,
            borderRadius: AppDimens.brS,
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildGatewaySegment(
                  'STRIPE',
                  Icons.credit_card_outlined,
                  PaymentGateway.stripe,
                  gateway,
                ),
              ),
              Container(width: 1, color: AppColors.borderDefault),
              Expanded(
                child: _buildGatewaySegment(
                  'MERCADO PAGO',
                  Icons.account_balance_wallet_outlined,
                  PaymentGateway.mp,
                  gateway,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGatewaySegment(
    String label,
    IconData icon,
    PaymentGateway value,
    PaymentGateway activeGateway,
  ) {
    final isActive = value == activeGateway;
    return AnimatedContainer(
      duration: AppMotion.durBase,
      curve: AppMotion.easeStandard,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.gold.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: AppDimens.brS,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: AppDimens.iconXS,
            color:
                isActive ? AppColors.gold : AppColors.textTertiary,
          ),
          const SizedBox(width: AppDimens.space4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall.copyWith(
                color: isActive ? AppColors.gold : AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Gateway subform routing
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space16,
        vertical: AppDimens.space20,
      ),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.06),
        borderRadius: AppDimens.brM,
        border: Border.all(
          color: AppColors.danger.withValues(alpha: 0.4),
          width: 1.5,
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
          const SizedBox(height: AppDimens.space12),
          Text(
            AppStrings.billingAddCardGatewayNotConfiguredTitle,
            style:
                AppTextStyles.label.copyWith(color: AppColors.danger),
          ),
          const SizedBox(height: AppDimens.space8),
          Text(
            AppStrings.billingAddCardGatewayNotConfiguredMsg,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyS,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HUD Checkbox
  // ---------------------------------------------------------------------------

  Widget _buildHudCheckbox() {
    return Semantics(
      label: 'Usar como tarjeta predeterminada para pagos',
      checked: _setAsDefault,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => setState(() => _setAsDefault = !_setAsDefault),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimens.space8,
              horizontal: AppDimens.space4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: AnimatedContainer(
                    duration: AppMotion.durFast,
                    curve: AppMotion.easeStandard,
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      borderRadius: AppDimens.brXS,
                      gradient: _setAsDefault ? AppColors.gradGold : null,
                      color:
                          _setAsDefault ? null : Colors.transparent,
                      border: Border.all(
                        color: _setAsDefault
                            ? AppColors.gold
                            : AppColors.borderStrong,
                        width: 1.5,
                      ),
                      boxShadow: _setAsDefault ? AppDimens.glowGold : null,
                    ),
                    child: _setAsDefault
                        ? const Icon(
                            Icons.check_rounded,
                            size: 13,
                            color: AppColors.textOnGold,
                          )
                            .animate()
                            .scale(
                              duration: AppMotion.durFast,
                              curve: Curves.elasticOut,
                            )
                        : null,
                  ),
                ),
                const SizedBox(width: AppDimens.space12),
                Text(
                  'Usar como tarjeta predeterminada',
                  style: AppTextStyles.bodyM,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Footer
  // ---------------------------------------------------------------------------

  Widget _buildFooter({required bool showSaveButton}) {
    if (!showSaveButton) {
      return AppButton.secondary(
        label: AppStrings.billingAddCardCancel,
        onPressed: _handleCancel,
        expand: true,
      );
    }

    final saveEnabled = _pendingToken != null && !_isSaving;

    return Row(
      children: [
        Expanded(
          child: AppButton.secondary(
            label: AppStrings.billingAddCardCancel,
            onPressed: _isSaving ? null : _handleCancel,
            expand: true,
          ),
        ),
        const SizedBox(width: AppDimens.space12),
        Expanded(
          child: Semantics(
            label: 'Agregar tarjeta de crédito/débito',
            button: true,
            enabled: saveEnabled,
            excludeSemantics: true,
            child: AppButton.primary(
              label: AppStrings.billingAddCardSave,
              onPressed: saveEnabled ? _onSave : null,
              loading: _isSaving,
              expand: true,
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
        const SizedBox(height: AppDimens.space8),
        _buildSuccessRing(),
        const SizedBox(height: AppDimens.space20),
        Text(
          'MÉTODO AGREGADO',
          style: AppTextStyles.titleM.copyWith(
            color: AppColors.success,
            letterSpacing: 2.0,
          ),
        ).animate().fadeIn().moveY(begin: 8, end: 0),
        const SizedBox(height: AppDimens.space8),
        Text(
          AppStrings.billingAddCardSuccessMsg,
          textAlign: TextAlign.center,
          style:
              AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: AppDimens.space16),
        _buildCountdownText(),
        const SizedBox(height: AppDimens.space8),
      ],
    );
  }

  Widget _buildSuccessRing() {
    return AnimatedBuilder(
      animation: _successCtrl,
      builder: (_, child) {
        final remaining = (1.0 - _successCtrl.value).clamp(0.0, 1.0);
        return SizedBox(
          width: 84,
          height: 84,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.successGlow,
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 84,
                height: 84,
                child: CircularProgressIndicator(
                  value: remaining,
                  strokeWidth: 2,
                  color: AppColors.success,
                  backgroundColor: Colors.transparent,
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: const Icon(Icons.check_rounded, color: AppColors.success, size: 36)
          .animate()
          .scale(
            begin: const Offset(0, 0),
            end: const Offset(1, 1),
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
          ),
    );
  }

  Widget _buildCountdownText() {
    return AnimatedBuilder(
      animation: _successCtrl,
      builder: (_, __) {
        final count = _countdown.clamp(0, 2);
        return Text(
          'CERRANDO EN $count...',
          style: AppTextStyles.mono.copyWith(
            color: AppColors.success.withValues(alpha: 0.6),
            letterSpacing: 2.0,
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Failure state
  // ---------------------------------------------------------------------------

  Widget _buildFailureState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppDimens.space8),
        _buildFailureRing(),
        const SizedBox(height: AppDimens.space20),
        Text(
          _failureTitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.titleM.copyWith(
            color: AppColors.danger,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: AppDimens.space12),
        Semantics(
          liveRegion: true,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimens.space16),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.06),
              borderRadius: AppDimens.brM,
              border: Border.all(
                color: AppColors.danger.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              _failureMessage,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyM,
            ),
          ),
        ),
        const SizedBox(height: AppDimens.space24),
        Row(
          children: [
            Expanded(
              child: AppButton.secondary(
                label: AppStrings.billingCheckoutClose,
                onPressed: () => Navigator.of(context).pop(),
                expand: true,
              ),
            ),
            const SizedBox(width: AppDimens.space12),
            Expanded(
              child: AppButton.primary(
                label: 'REINTENTAR',
                onPressed: () => setState(() {
                  _hasFailed = false;
                  _failureTitle = '';
                  _failureMessage = '';
                  _pendingToken = null;
                }),
                expand: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFailureRing() {
    final reduced = AppMotion.reduced(context);
    Widget ring = Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color.fromRGBO(255, 45, 85, 0.1),
        border: Border.fromBorderSide(
          BorderSide(color: AppColors.danger, width: 2),
        ),
        boxShadow: [
          BoxShadow(color: AppColors.dangerGlow, blurRadius: 16, spreadRadius: 1),
        ],
      ),
      child: const Icon(
        Icons.gpp_bad_rounded,
        color: AppColors.danger,
        size: 36,
      ),
    );

    if (!reduced) {
      ring = ring.animate().shake(
        hz: 4,
        offset: const Offset(4, 0),
        duration: AppMotion.durFast,
      );
    }

    return ring;
  }
}

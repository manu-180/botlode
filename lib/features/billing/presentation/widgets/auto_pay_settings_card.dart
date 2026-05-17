// Archivo: lib/features/billing/presentation/widgets/auto_pay_settings_card.dart
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/hud/hud_divider.dart';
import 'package:botslode/core/ui/panels/holo_panel.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/widgets/manage_cards_modal.dart';
import 'package:botslode/l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Banner variant
// ---------------------------------------------------------------------------

enum _BannerVariant { card, warning, info }

// ---------------------------------------------------------------------------
// Root widget
// ---------------------------------------------------------------------------

class AutoPaySettingsCard extends ConsumerStatefulWidget {
  const AutoPaySettingsCard({super.key});

  @override
  ConsumerState<AutoPaySettingsCard> createState() =>
      _AutoPaySettingsCardState();
}

class _AutoPaySettingsCardState extends ConsumerState<AutoPaySettingsCard> {
  bool _isMutating = false;

  Future<void> _onToggle(bool enableAutoRenew) async {
    if (_isMutating) return;
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
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.danger,
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.billingAutoPayUpdateError)),
      );
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
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

        final defaultPm =
            state.paymentMethods.where((pm) => pm.isDefault).firstOrNull;
        final hasDefaultPm = defaultPm != null;
        final autoRenew = !subscription.cancelAtPeriodEnd;
        final activeState = autoRenew && hasDefaultPm;

        // Determine banner variant
        final _BannerVariant bannerVariant;
        if (!autoRenew) {
          bannerVariant = _BannerVariant.info;
        } else if (!hasDefaultPm) {
          bannerVariant = _BannerVariant.warning;
        } else {
          bannerVariant = _BannerVariant.card;
        }

        return Container(
          margin: const EdgeInsets.only(top: AppDimens.space20),
          child: HoloPanel(
            borderColor:
                activeState ? AppColors.borderGold : AppColors.borderDefault,
            glowAccent: activeState ? AppColors.gold : null,
            cornerBrackets: activeState,
            padding: const EdgeInsets.all(AppDimens.space20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header row ──────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'COBRO AUTOMÁTICO',
                            style: AppTextStyles.titleM
                                .copyWith(color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: AppDimens.space4),
                          Text(
                            'Se renueva al final de cada período de facturación.',
                            style: AppTextStyles.bodyS
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppDimens.space16),
                    _HudToggle(
                      value: autoRenew,
                      disabled: !hasDefaultPm,
                      loading: _isMutating,
                      onChanged: (hasDefaultPm && !_isMutating)
                          ? _onToggle
                          : null,
                    ),
                  ],
                ),

                const SizedBox(height: AppDimens.space16),

                // ── Retry policy ────────────────────────────────────────────
                const HudDivider(label: 'POLÍTICA DE REINTENTOS'),

                const SizedBox(height: AppDimens.space12),

                Text(
                  'Ante un cobro fallido, reintentamos automáticamente. '
                  'Si los reintentos se agotan, la suscripción pasa a estado pendiente.',
                  style: AppTextStyles.bodyS
                      .copyWith(color: AppColors.textSecondary),
                ),

                const SizedBox(height: AppDimens.space8),

                const Row(
                  children: [
                    _RetryChip('24H'),
                    SizedBox(width: AppDimens.space8),
                    _RetryChip('72H'),
                    SizedBox(width: AppDimens.space8),
                    _RetryChip('7D'),
                  ],
                ),

                const SizedBox(height: AppDimens.space16),

                // ── Animated banner ─────────────────────────────────────────
                AnimatedSwitcher(
                  duration: AppMotion.durBase,
                  switchInCurve: AppMotion.easeEntrance,
                  switchOutCurve: AppMotion.easeExit,
                  child: _InlineBanner(
                    key: ValueKey(bannerVariant),
                    variant: bannerVariant,
                    cardBrand: defaultPm?.brand,
                    cardLast4: defaultPm?.last4,
                    onManageCards: () => ManageCardsModal.show(context),
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

// ---------------------------------------------------------------------------
// _HudToggle
// ---------------------------------------------------------------------------

class _HudToggle extends StatefulWidget {
  final bool value;
  final bool disabled;
  final bool loading;
  final ValueChanged<bool>? onChanged;

  const _HudToggle({
    required this.value,
    required this.disabled,
    required this.loading,
    this.onChanged,
  });

  @override
  State<_HudToggle> createState() => _HudToggleState();
}

class _HudToggleState extends State<_HudToggle>
    with TickerProviderStateMixin {
  // Dimensions
  static const double _railW = 52;
  static const double _railH = 28;
  static const double _knobD = 22;
  static const double _knobPad = 3;

  bool _hovered = false;
  bool _focused = false;

  late final AnimationController _slideCtrl;
  late final AnimationController _pressCtrl;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();

    _slideCtrl = AnimationController(
      vsync: this,
      value: widget.value ? 1.0 : 0.0,
      duration: AppMotion.durFast,
    );

    _pressCtrl = AnimationController(
      vsync: this,
      duration: AppMotion.durInstant,
      reverseDuration: AppMotion.durFast,
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: AppMotion.durHeartbeat,
    );

    if (widget.loading) {
      _pulseCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_HudToggle oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value) {
      final reduced = AppMotion.reduced(context);
      if (reduced) {
        _slideCtrl.value = widget.value ? 1.0 : 0.0;
      } else {
        _slideCtrl.animateTo(
          widget.value ? 1.0 : 0.0,
          duration: AppMotion.durFast,
          curve: AppMotion.easeEntrance,
        );
      }
    }

    if (oldWidget.loading != widget.loading) {
      if (widget.loading) {
        _pulseCtrl.repeat(reverse: true);
      } else {
        _pulseCtrl.stop();
        _pulseCtrl.value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _pressCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  bool get _isInteractive =>
      !widget.disabled && !widget.loading && widget.onChanged != null;

  void _onTap() {
    if (!_isInteractive) return;
    widget.onChanged?.call(!widget.value);
  }

  void _onTapDown(TapDownDetails _) {
    if (!_isInteractive) return;
    _pressCtrl.forward();
  }

  void _onTapUp(TapUpDetails _) {
    if (!_isInteractive) return;
    _pressCtrl.reverse();
  }

  void _onTapCancel() {
    if (!_isInteractive) return;
    _pressCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isOn = widget.value;

    // Hit target wrapper
    return Semantics(
      label: 'Cobro automático ${widget.value ? "activado" : "desactivado"}',
      toggled: widget.value,
      enabled: !widget.disabled && !widget.loading,
      button: true,
      excludeSemantics: true,
      child: SizedBox(
        width: _railW + AppDimens.space8,
        height: _railH + AppDimens.space8,
        child: Center(
          child: MouseRegion(
            cursor: _isInteractive
                ? SystemMouseCursors.click
                : MouseCursor.defer,
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: Focus(
              onFocusChange: (f) => setState(() => _focused = f),
              child: GestureDetector(
                onTap: _onTap,
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                child: _buildToggleContent(isOn),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleContent(bool isOn) {
    // Disabled opacity wrapper (only when disabled and not loading)
    Widget toggle = _buildAnimatedToggle(isOn);
    if (widget.disabled && !widget.loading) {
      toggle = Opacity(opacity: 0.4, child: toggle);
    }
    return toggle;
  }

  Widget _buildAnimatedToggle(bool isOn) {
    return AnimatedBuilder(
      animation: Listenable.merge([_slideCtrl, _pressCtrl, _pulseCtrl]),
      builder: (context, _) {
        final knobLeft =
            _knobPad + _slideCtrl.value * (_railW - _knobD - _knobPad * 2);
        final knobColor = isOn ? AppColors.goldBright : AppColors.textTertiary;

        // Rail decoration
        final railDecoration = isOn
            ? BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color.fromRGBO(200, 147, 10, 0.8),  // goldDeep @ 0.8
                    Color.fromRGBO(255, 192, 0, 0.6),   // gold @ 0.6
                  ],
                ),
                borderRadius: AppDimens.brPill,
                border: Border.all(
                  color: _hovered
                      ? AppColors.gold.withValues(alpha: 0.7)
                      : AppColors.borderGold,
                ),
                boxShadow: _hovered
                    ? AppDimens.glowGold
                    : [
                        BoxShadow(
                          color: AppColors.goldGlow.withValues(alpha: 0.18),
                          blurRadius: 10,
                        ),
                      ],
              )
            : BoxDecoration(
                color: AppColors.surfaceHud,
                borderRadius: AppDimens.brPill,
                border: Border.all(
                  color: _hovered
                      ? AppColors.borderStrong
                      : AppColors.borderDefault,
                ),
              );

        // Knob
        Widget knob = Container(
          width: _knobD,
          height: _knobD,
          decoration: BoxDecoration(
            color: knobColor,
            shape: BoxShape.circle,
            boxShadow: isOn
                ? [
                    const BoxShadow(
                      color: AppColors.goldGlow,
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: widget.loading
              ? Center(
                  child: SizedBox(
                    width: _knobD - 8,
                    height: _knobD - 8,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: isOn
                          ? AppColors.goldDeep
                          : AppColors.textSecondary,
                    ),
                  ),
                )
              : null,
        );

        // Press scale on knob
        knob = Transform.scale(
          scale: 1.0 - _pressCtrl.value * 0.06,
          child: knob,
        );

        // Loading pulse opacity on knob
        if (widget.loading) {
          knob = Opacity(
            opacity: 0.6 + _pulseCtrl.value * 0.4,
            child: knob,
          );
        }

        Widget rail = SizedBox(
          width: _railW,
          height: _railH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Rail background
              AnimatedContainer(
                duration: AppMotion.durFast,
                curve: AppMotion.easeStandard,
                width: _railW,
                height: _railH,
                decoration: railDecoration,
              ),
              // "O" marker (OFF side)
              Positioned(
                left: 4,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Text(
                    'O',
                    style: AppTextStyles.mono.copyWith(
                      fontSize: 7,
                      color: AppColors.textTertiary,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
              // "I" marker (ON side)
              Positioned(
                right: 4,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Text(
                    'I',
                    style: AppTextStyles.mono.copyWith(
                      fontSize: 7,
                      color: AppColors.textTertiary,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
              // Knob
              Positioned(
                left: knobLeft,
                top: _knobPad,
                child: knob,
              ),
            ],
          ),
        );

        // Focus ring
        if (_focused) {
          rail = Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: _railW + 6,
                height: _railH + 6,
                decoration: BoxDecoration(
                  borderRadius: AppDimens.brPill,
                  border: Border.all(color: AppColors.gold, width: 2),
                ),
              ),
              rail,
            ],
          );
        }

        return rail;
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _RetryChip
// ---------------------------------------------------------------------------

class _RetryChip extends StatelessWidget {
  final String label;

  const _RetryChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space8,
        vertical: AppDimens.space4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceHud,
        borderRadius: AppDimens.brPill,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall
            .copyWith(color: AppColors.textTertiary),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _InlineBanner
// ---------------------------------------------------------------------------

class _InlineBanner extends StatelessWidget {
  final _BannerVariant variant;
  final String? cardBrand;
  final String? cardLast4;
  final VoidCallback? onManageCards;

  const _InlineBanner({
    super.key,
    required this.variant,
    this.cardBrand,
    this.cardLast4,
    this.onManageCards,
  });

  String get _cardLabel {
    final brand = (cardBrand?.isNotEmpty == true)
        ? '${cardBrand!.toUpperCase()} '
        : '';
    return '$brand•••• ${cardLast4 ?? '—'}';
  }

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case _BannerVariant.card:
        return _buildCardBanner(context);
      case _BannerVariant.warning:
        return _buildWarningBanner();
      case _BannerVariant.info:
        return _buildInfoBanner();
    }
  }

  Widget _buildCardBanner(BuildContext context) {
    return Semantics(
      label:
          'Tarjeta para pago automático: $_cardLabel. Toca para administrar tarjetas.',
      button: true,
      child: GestureDetector(
        onTap: onManageCards,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.space12,
              vertical: AppDimens.space8,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppDimens.brS,
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ExcludeSemantics(
                  child: Icon(
                    Icons.credit_card_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppDimens.space8),
                Text.rich(
                  TextSpan(
                    text: 'Se cobrará a ',
                    style: AppTextStyles.bodyS
                        .copyWith(color: AppColors.textSecondary),
                    children: [
                      TextSpan(
                        text: _cardLabel,
                        style: AppTextStyles.mono.copyWith(
                          color: AppColors.gold,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Semantics(
      liveRegion: true,
      label:
          'Advertencia: Agregá un método de pago para activar el cobro automático.',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space12,
          vertical: AppDimens.space8,
        ),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.10),
          borderRadius: AppDimens.brS,
          border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            const ExcludeSemantics(
              child: Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: AppDimens.space8),
            Expanded(
              child: Text(
                'Agregá un método de pago para activar el cobro automático.',
                style: AppTextStyles.bodyS
                    .copyWith(color: AppColors.warning),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Semantics(
      liveRegion: true,
      label: 'Tu suscripción se cancelará al final del período actual.',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space12,
          vertical: AppDimens.space8,
        ),
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.08),
          borderRadius: AppDimens.brS,
          border: Border.all(
            color: AppColors.info.withValues(alpha: 0.20),
          ),
        ),
        child: Row(
          children: [
            const ExcludeSemantics(
              child: Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: AppDimens.space8),
            Expanded(
              child: Text(
                'Tu suscripción se cancelará al final del período actual.',
                style: AppTextStyles.bodyS.copyWith(color: AppColors.info),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

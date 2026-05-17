// Archivo: lib/features/billing/presentation/widgets/digital_card.dart
//
// T4·12 — DigitalCard · Hangar OS design system.
// Displays the default PaymentMethod with brand icon, masked PAN and expiry.
//
// 4 visual states:
//   1. empty        — no method provided
//   2. valid        — active, not expiring within 30 days
//   3. expiringSoon — ≤30 days until expiry
//   4. expired      — expiry date is in the past
//
// Security: never displays gatewayToken or full PAN — only last4.

import 'dart:math' as math;

import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/hud/hud_corner_brackets.dart';
import 'package:botslode/core/ui/hud/hud_grid_texture.dart';
import 'package:botslode/core/ui/hud/hud_id_tag.dart';
import 'package:botslode/core/ui/hud/hud_status_dot.dart';
import 'package:botslode/core/ui/widgets/app_button.dart';
import 'package:botslode/features/billing/domain/models/payment_method.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';

// ---------------------------------------------------------------------------
// Internal card state
// ---------------------------------------------------------------------------

enum _CardState { empty, valid, expiringSoon, expired }

// ---------------------------------------------------------------------------
// DigitalCard
// ---------------------------------------------------------------------------

class DigitalCard extends StatefulWidget {
  const DigitalCard({super.key, this.method, this.now, this.onAddCard});

  /// The PaymentMethod to display. If null, shows the empty/add-card state.
  final PaymentMethod? method;

  /// Injectable clock for deterministic golden/unit tests.
  /// Production code always leaves this null and uses [DateTime.now()].
  final DateTime? now;

  /// Optional callback fired when the user taps "Agregar tarjeta" in the
  /// empty state. If null the button is rendered but does nothing.
  final VoidCallback? onAddCard;

  @override
  State<DigitalCard> createState() => _DigitalCardState();
}

class _DigitalCardState extends State<DigitalCard>
    with TickerProviderStateMixin {
  // ── Interaction state ──────────────────────────────────────────────────────
  bool _isHovered = false;
  bool _isPressed = false;
  Size _cardSize = Size.zero;
  Offset _mouseFraction = Offset.zero;

  // ── Animation controllers ──────────────────────────────────────────────────
  /// 3D tilt on hover
  late final AnimationController _tiltCtrl;

  /// Periodic gold sheen sweep (valid state, resting)
  late final AnimationController _shimmerCtrl;

  /// One-shot sheen on hover enter
  late final AnimationController _hoverSheenCtrl;

  // ── Expiry helpers ─────────────────────────────────────────────────────────

  /// First moment of the month AFTER expMonth/expYear — the card is valid
  /// through the last day of expMonth; after that it is expired.
  DateTime? _expiryDate() {
    final m = widget.method?.expMonth;
    final y = widget.method?.expYear;
    if (m == null || y == null) return null;
    return DateTime(y, m + 1, 1);
  }

  DateTime get _now => widget.now ?? DateTime.now();

  bool get _isExpired {
    final exp = _expiryDate();
    return exp != null && !_now.isBefore(exp);
  }

  bool get _isExpiringSoon {
    final exp = _expiryDate();
    if (exp == null || _isExpired) return false;
    return exp.difference(_now).inDays <= 30;
  }

  _CardState get _state {
    if (widget.method == null) return _CardState.empty;
    if (_isExpired) return _CardState.expired;
    if (_isExpiringSoon) return _CardState.expiringSoon;
    return _CardState.valid;
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _tiltCtrl = AnimationController(
      vsync: this,
      duration: AppMotion.durFast,
    );

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: AppMotion.durShimmer, // 3100 ms
    );

    _hoverSheenCtrl = AnimationController(
      vsync: this,
      duration: AppMotion.durDeliberate,
    );

    // Delay the first sweep so it doesn't conflict with the entry animation.
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) _updateShimmer();
    });
  }

  @override
  void didUpdateWidget(DigitalCard old) {
    super.didUpdateWidget(old);
    // Re-evaluate shimmer when state changes (e.g. method added/removed)
    if (old.method != widget.method || old.now != widget.now) {
      _updateShimmer();
    }
  }

  @override
  void dispose() {
    _tiltCtrl.dispose();
    _shimmerCtrl.dispose();
    _hoverSheenCtrl.dispose();
    super.dispose();
  }

  void _updateShimmer() {
    if (_state == _CardState.valid && mounted) {
      _shimmerCtrl.repeat();
    } else {
      _shimmerCtrl.stop();
      _shimmerCtrl.value = 0;
    }
  }

  // ── Mouse event handlers ───────────────────────────────────────────────────

  void _onEnter(PointerEnterEvent _) {
    if (!mounted) return;
    setState(() => _isHovered = true);
    if (!AppMotion.isReduced(context)) {
      _tiltCtrl.forward();
    }
    if (_state != _CardState.expired && !AppMotion.isReduced(context)) {
      _hoverSheenCtrl.forward(from: 0).then((_) {
        if (mounted) _hoverSheenCtrl.reset();
      });
    }
  }

  void _onHover(PointerHoverEvent e) {
    if (_cardSize == Size.zero) return;
    setState(() {
      _mouseFraction = Offset(
        (e.localPosition.dx / _cardSize.width - 0.5).clamp(-0.5, 0.5),
        (e.localPosition.dy / _cardSize.height - 0.5).clamp(-0.5, 0.5),
      );
    });
  }

  void _onExit(PointerExitEvent _) {
    if (!mounted) return;
    if (AppMotion.isReduced(context)) {
      _tiltCtrl.value = 0;
    } else {
      _tiltCtrl.reverse();
    }
    setState(() {
      _isHovered = false;
      _mouseFraction = Offset.zero;
    });
  }

  // ── State-dependent design tokens ──────────────────────────────────────────

  Color get _borderColor => switch (_state) {
        _CardState.empty => AppColors.borderSubtle,
        _CardState.valid => AppColors.borderGold,
        _CardState.expiringSoon => AppColors.warning,
        _CardState.expired => AppColors.danger,
      };

  double get _borderWidth => switch (_state) {
        _CardState.empty => 1.0,
        _CardState.valid => 1.0,
        _CardState.expiringSoon => 2.0,
        _CardState.expired => 2.0,
      };

  Color get _bracketColor => switch (_state) {
        _CardState.empty => AppColors.borderSubtle,
        _CardState.valid => AppColors.borderGold,
        _CardState.expiringSoon => AppColors.warning,
        _CardState.expired => AppColors.danger,
      };

  List<BoxShadow> get _shadows => switch (_state) {
        _CardState.empty => [...AppDimens.elev1],
        _CardState.valid => [
            ...AppDimens.elev2,
            BoxShadow(
              color: AppColors.goldGlow,
              blurRadius: _isHovered ? 28 : 18,
              spreadRadius: _isHovered ? 2 : 1,
            ),
          ],
        _CardState.expiringSoon => [
            ...AppDimens.elev2,
            const BoxShadow(
              color: AppColors.warningGlow,
              blurRadius: 18,
            ),
          ],
        _CardState.expired => [...AppDimens.elev2],
      };

  HudStatus get _dotStatus => switch (_state) {
        _CardState.empty => HudStatus.offline,
        _CardState.valid => HudStatus.online,
        _CardState.expiringSoon => HudStatus.suspended,
        _CardState.expired => HudStatus.offline,
      };

  // ── Expiry display string "MM/YY" ──────────────────────────────────────────

  String get _expiryLabel {
    final m = widget.method?.expMonth;
    final y = widget.method?.expYear;
    if (m == null || y == null) return '--/--';
    final mm = m.toString().padLeft(2, '0');
    final yy = (y % 100).toString().padLeft(2, '0');
    return '$mm/$yy';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.isReduced(context);
    final state = _state;

    Widget card;

    if (state == _CardState.empty) {
      card = _buildEmptyCard(reduced);
    } else {
      card = _buildDataCard(context, reduced, state);
    }

    // Entry animation
    if (!reduced) {
      card = card
          .animate()
          .fadeIn(
            duration: AppMotion.durBase,
            curve: AppMotion.easeEntrance,
          )
          .scale(
            begin: const Offset(0.96, 0.96),
            end: const Offset(1.0, 1.0),
            duration: AppMotion.durBase,
            curve: AppMotion.easeEntrance,
          );
    } else {
      card = card
          .animate()
          .fadeIn(duration: AppMotion.durCrossfadeReduced);
    }

    return card;
  }

  // ── State 1 — Empty card ───────────────────────────────────────────────────

  Widget _buildEmptyCard(bool reduced) {
    return AspectRatio(
      aspectRatio: 1.586,
      child: AnimatedContainer(
        duration: AppMotion.durFast,
        curve: AppMotion.easeStandard,
        decoration: BoxDecoration(
          borderRadius: AppDimens.brXL,
          border: Border.all(
            color: AppColors.borderSubtle,
            width: 1.0,
          ),
          boxShadow: AppDimens.elev1,
        ),
        child: ClipRRect(
          borderRadius: AppDimens.brXL,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Layer 1 — metallic background (dimmer, no voidBlack)
              ExcludeSemantics(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-0.5, -1.0),
                      end: Alignment(0.5, 1.0),
                      colors: [
                        AppColors.surfaceRaised,
                        AppColors.surface,
                      ],
                    ),
                  ),
                ),
              ),

              // Layer 2 — grid texture
              const ExcludeSemantics(
                child: HudGridTexture(
                  opacity: 0.04,
                  color: AppColors.cyan,
                ),
              ),

              // Layer 3 — HUD corner brackets
              const Positioned.fill(
                child: HudCornerBrackets(
                  color: AppColors.borderSubtle,
                  armLength: 14,
                  thickness: 1.5,
                  child: SizedBox.expand(),
                ),
              ),

              // Layer 4 — centered empty-state content
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimens.space24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.borderGold.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                          color: AppColors.surfaceHud.withValues(alpha: 0.7),
                        ),
                        child: Icon(
                          Icons.add_card,
                          size: AppDimens.iconL,
                          color: AppColors.gold.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: AppDimens.space12),
                      Text(
                        'Sin método de pago',
                        style: AppTextStyles.titleM,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppDimens.space8 - 2),
                      Text(
                        'Agregá una tarjeta para habilitar el cobro automático',
                        style: AppTextStyles.bodyS.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppDimens.space16),
                      Semantics(
                        label: 'Agregar tarjeta de pago',
                        child: AppButton.secondary(
                          label: 'Agregar tarjeta',
                          onPressed: widget.onAddCard,
                          leadingIcon: Icons.add_card,
                          size: AppButtonSize.sm,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── States 2 / 3 / 4 — Card with data ─────────────────────────────────────

  Widget _buildDataCard(
    BuildContext context,
    bool reduced,
    _CardState state,
  ) {
    final isExpired = state == _CardState.expired;

    final last4Raw = widget.method?.last4;
    final last4 = (last4Raw != null && last4Raw.isNotEmpty) ? last4Raw : '••••';
    final brand = widget.method?.brand ?? '';
    final statusSuffix = isExpired
        ? ', vencida'
        : state == _CardState.expiringSoon
            ? ', vence pronto'
            : '';

    // Inner card stack (layers 1-6 — badge rendered separately below)
    Widget innerContent = _buildInnerCardStack(reduced, state);

    // Status badge sits OUTSIDE the ColorFiltered wrapper so it stays fully
    // saturated even in the expired state (spec §5.8).
    Widget clippedContent;
    if (isExpired) {
      clippedContent = Stack(
        fit: StackFit.expand,
        children: [
          ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              0.4882, 0.4649, 0.0469, 0, 0,
              0.1382, 0.8149, 0.0469, 0, 0,
              0.1382, 0.4649, 0.3969, 0, 0,
              0,      0,      0,      1, 0,
            ]),
            child: innerContent,
          ),
          const Positioned(
            bottom: AppDimens.space16,
            left: AppDimens.space16,
            child: ExcludeSemantics(
              child: _CardStatusBadge(isExpired: true),
            ),
          ),
        ],
      );
    } else if (state == _CardState.expiringSoon) {
      clippedContent = Stack(
        fit: StackFit.expand,
        children: [
          innerContent,
          const Positioned(
            bottom: AppDimens.space16,
            left: AppDimens.space16,
            child: ExcludeSemantics(
              child: _CardStatusBadge(isExpired: false),
            ),
          ),
        ],
      );
    } else {
      clippedContent = innerContent;
    }

    Widget cardContent = AspectRatio(
      aspectRatio: 1.586,
      child: AnimatedContainer(
        duration: AppMotion.durFast,
        curve: AppMotion.easeStandard,
        decoration: BoxDecoration(
          borderRadius: AppDimens.brXL,
          border: Border.all(
            color: _borderColor,
            width: _borderWidth,
          ),
          boxShadow: _shadows,
        ),
        child: ClipRRect(
          borderRadius: AppDimens.brXL,
          child: clippedContent,
        ),
      ),
    );

    // 3D tilt + scale wrapper (skip for expired)
    Widget interactiveCard = LayoutBuilder(
      builder: (context, constraints) {
        _cardSize = constraints.biggest;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: _onEnter,
          onHover: _onHover,
          onExit: _onExit,
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            child: AnimatedScale(
              scale: _isHovered && !isExpired
                  ? 1.015
                  : (_isPressed ? AppMotion.pressScale : 1.0),
              duration: AppMotion.durFast,
              curve: AppMotion.easeHover,
              child: isExpired || reduced
                  ? cardContent
                  : AnimatedBuilder(
                      animation: _tiltCtrl,
                      builder: (_, child) {
                        final t = _tiltCtrl.value;
                        const maxAngle = 4.0 * (math.pi / 180.0);
                        final rx = _mouseFraction.dy * maxAngle * -1.0 * t;
                        final ry = _mouseFraction.dx * maxAngle * t;
                        final m = Matrix4.identity()
                          ..setEntry(3, 2, 0.0012)
                          ..rotateX(rx)
                          ..rotateY(ry);
                        return Transform(
                          alignment: Alignment.center,
                          transform: m,
                          child: child,
                        );
                      },
                      child: cardContent,
                    ),
            ),
          ),
        );
      },
    );

    return Semantics(
      label: 'Tarjeta terminada en $last4, $brand, vence $_expiryLabel$statusSuffix',
      child: ExcludeSemantics(child: interactiveCard),
    );
  }

  Widget _buildInnerCardStack(bool reduced, _CardState state) {
    final isValidState = state == _CardState.valid;

    // Choose the active sheen animation
    final Animation<double> sheenAnim = _hoverSheenCtrl.isAnimating
        ? _hoverSheenCtrl
        : _shimmerCtrl;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Layer 1 — metallic background
        const ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-0.5, -1.0),
                end: Alignment(0.5, 1.0),
                colors: [
                  AppColors.surfaceRaised,
                  AppColors.surface,
                  AppColors.voidBlack,
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),

        // Layer 1b — diagonal glass highlight overlay
        ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.glassHighlightTop,
                  Colors.transparent,
                  AppColors.voidBlack.withValues(alpha: 0.6),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),

        // Layer 2 — grid texture
        const ExcludeSemantics(
          child: HudGridTexture(
            opacity: 0.04,
            color: AppColors.cyan,
          ),
        ),

        // Layer 3 — decorative hexagon
        Positioned(
          right: -50,
          top: -24,
          child: ExcludeSemantics(
            child: IgnorePointer(
              child: CustomPaint(
                size: const Size(300, 300),
                painter: _HexagonPainter(
                  color: AppColors.gold.withValues(alpha: 0.06),
                ),
              ),
            ),
          ),
        ),

        // Layer 4 — gold sheen sweep (valid only, reduced motion respected)
        if (!reduced && isValidState)
          Positioned.fill(
            child: ExcludeSemantics(
              child: RepaintBoundary(
                child: IgnorePointer(
                  child: _GoldSheenSweep(animation: sheenAnim),
                ),
              ),
            ),
          ),

        // Layer 5 — scanlines
        if (!reduced)
          const Positioned.fill(
            child: ExcludeSemantics(
              child: IgnorePointer(
                child: CustomPaint(painter: _ScanlinePainter()),
              ),
            ),
          ),

        // Layer 5b — main card content
        Positioned.fill(
          child: _buildCardContent(state),
        ),

        // HudIdTag (default badge) — top left, states 2/3/4
        if (widget.method?.isDefault == true)
          const Positioned(
            top: AppDimens.space16,
            left: AppDimens.space16,
            child: ExcludeSemantics(
              child: HudIdTag(
                text: 'CARD · DEFAULT',
                icon: Icons.verified_outlined,
                color: AppColors.borderGold,
              ),
            ),
          ),

        // Layer 6 — HUD corner brackets
        Positioned.fill(
          child: ExcludeSemantics(
            child: HudCornerBrackets(
              color: _bracketColor,
              armLength: 14,
              thickness: 1.5,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ],
    );
  }

  // ── Card content (padding + rows) ─────────────────────────────────────────

  Widget _buildCardContent(_CardState state) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ExcludeSemantics(child: _buildHeader()),
          ExcludeSemantics(child: _buildPan(state)),
          ExcludeSemantics(child: _buildFooter(state)),
        ],
      ),
    );
  }

  // Header row: EMV chip left, brand icon right
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // EMV chip with gradGold + goldGlow shadow
        Container(
          width: 46,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.radiusXS),
            gradient: AppColors.gradGold,
            boxShadow: const [
              BoxShadow(
                color: AppColors.goldGlow,
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
          ),
          child: CustomPaint(painter: _ChipPainter()),
        ),
        // Brand icon
        _BrandIcon(brand: widget.method?.brand),
      ],
    );
  }

  // Masked PAN: dots + last4 in gold
  Widget _buildPan(_CardState state) {
    final last4 = widget.method?.last4;
    final isExpired = state == _CardState.expired;
    final isValid = state == _CardState.valid;
    final isExpiringSoon = state == _CardState.expiringSoon;

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '•••• •••• •••• ',
              style: AppTextStyles.mono.copyWith(
                color: AppColors.textTertiary.withValues(alpha: 0.62),
                fontSize: 12,
                letterSpacing: 2.0,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              last4 ?? '••••',
              style: AppTextStyles.numericTicker.copyWith(
                color: isExpired ? AppColors.textSecondary : AppColors.gold,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 3.2,
                fontFeatures: const [FontFeature.tabularFigures()],
                shadows: (isValid || isExpiringSoon)
                    ? const [
                        Shadow(
                          color: AppColors.goldGlow,
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Footer row: status dot+label left, expiry date right
  Widget _buildFooter(_CardState state) {
    final Color statusColor = switch (state) {
      _CardState.valid => AppColors.success,
      _CardState.expiringSoon => AppColors.warning,
      _CardState.expired => AppColors.danger,
      _CardState.empty => AppColors.textTertiary,
    };

    final String statusLabel = switch (state) {
      _CardState.valid => 'ACTIVA',
      _CardState.expiringSoon => 'VENCE PRONTO',
      _CardState.expired => 'VENCIDA',
      _CardState.empty => '',
    };

    final Color expiryColor = switch (state) {
      _CardState.expiringSoon => AppColors.warning,
      _CardState.expired => AppColors.danger,
      _ => AppColors.textPrimary,
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Status dot + label
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HudStatusDot(status: _dotStatus, size: 7),
            const SizedBox(width: AppDimens.space8),
            Text(
              statusLabel,
              style: AppTextStyles.labelSmall.copyWith(
                color: statusColor,
                fontSize: 9,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        // Expiry date block
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'VENCE',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textTertiary,
                fontSize: 9,
              ),
            ),
            const SizedBox(height: AppDimens.space2),
            Text(
              _expiryLabel,
              style: AppTextStyles.hudReadout.copyWith(
                color: expiryColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _CardStatusBadge — pill badge for expiringSoon / expired states
// ---------------------------------------------------------------------------

class _CardStatusBadge extends StatelessWidget {
  const _CardStatusBadge({required this.isExpired});

  final bool isExpired;

  @override
  Widget build(BuildContext context) {
    final Color color = isExpired ? AppColors.danger : AppColors.warning;
    final IconData icon =
        isExpired ? Icons.error_outline : Icons.schedule;
    final String label = isExpired ? 'VENCIDA' : 'VENCE PRONTO';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space12,
        vertical: AppDimens.space4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(
          color: color.withValues(alpha: 0.32),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: AppDimens.space4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _GoldSheenSweep — subtle golden diagonal sweep across valid card
// ---------------------------------------------------------------------------

class _GoldSheenSweep extends StatelessWidget {
  final Animation<double> animation;
  const _GoldSheenSweep({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final t = animation.value;
        // Sweep center travels from -1.8 to 2.8 (off-screen left → right)
        final sweep = -1.8 + t * 4.6;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(sweep - 0.65, -0.6),
              end: Alignment(sweep + 0.65, 0.6),
              colors: [
                Colors.transparent,
                AppColors.goldBright.withValues(alpha: 0.068),
                AppColors.glassHighlightTop,
                Colors.transparent,
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _BrandIcon — renders brand SVG from assets/billing/brands/.
// Normalises gateway strings via alias map. Falls back to generic.svg.
// ---------------------------------------------------------------------------

class _BrandIcon extends StatelessWidget {
  const _BrandIcon({this.brand});
  final String? brand;

  static const _kAliases = <String, String>{
    'visa': 'visa',
    'mastercard': 'mastercard',
    'master': 'mastercard',
    'mc': 'mastercard',
    'amex': 'amex',
    'americanexpress': 'amex',
    'american_express': 'amex', // Stripe returns this
  };

  String get _assetPath {
    final raw = (brand ?? '').toLowerCase().replaceAll(RegExp(r'[\s\-_]'), '');
    final name = _kAliases[raw] ?? 'generic';
    return 'assets/billing/brands/$name.svg';
  }

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      _assetPath,
      width: 52,
      height: 34,
      placeholderBuilder: (_) => const SizedBox(width: 52, height: 34),
      semanticsLabel: '', // outer Semantics widget already provides the label
    );
  }
}

// ---------------------------------------------------------------------------
// _ChipPainter — EMV chip contact grid (3×2 pads + center vertical slot)
// ---------------------------------------------------------------------------

class _ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final padPaint = Paint()
      ..color = AppColors.voidBlack.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = AppColors.voidBlack.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const cols = 3;
    const rows = 2;
    const hPad = 4.0;
    const vPad = 3.0;
    const gap = 2.0;
    const rounding = 1.5;

    final padW = (size.width - hPad * 2 - gap * (cols - 1)) / cols;
    final padH = (size.height - vPad * 2 - gap * (rows - 1)) / rows;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final left = hPad + col * (padW + gap);
        final top = vPad + row * (padH + gap);
        final rect = Rect.fromLTWH(left, top, padW, padH);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(rounding)),
          padPaint,
        );
      }
    }

    // Center vertical slot line
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// _HexagonPainter — decorative hexagon stroke (PRESERVED)
// ---------------------------------------------------------------------------

class _HexagonPainter extends CustomPainter {
  final Color color;
  const _HexagonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28;
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    for (int i = 0; i < 6; i++) {
      final angle = (60 * i - 30) * (math.pi / 180);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HexagonPainter old) => old.color != color;
}

// ---------------------------------------------------------------------------
// _ScanlinePainter — lightweight horizontal scanlines (PRESERVED)
// ---------------------------------------------------------------------------

class _ScanlinePainter extends CustomPainter {
  const _ScanlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: 0.032)
      ..strokeWidth = 1;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      y += 3;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

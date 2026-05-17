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
<<<<<<< Updated upstream
// Security: never displays gatewayToken or full PAN — only last4.
=======
// Security: never displays gatewayToken or full PAN.
// Only last4 (4 digits max) is shown.
//
// CONTRAST ANALYSIS (T4·27 a11y audit):
//   - White text (Colors.white, #FFFFFF) on dark gradient bottom (#050505 → black 80%).
//     Approximate background at text positions: ~#0A0A0A (near-black).
//     Contrast ratio: ~19.9:1 — passes WCAG AA and AAA for both normal and large text.
//   - Primary color text (AppColors.primary, gold ~#D4AF37 approx) on #050505:
//     Approximate contrast: ~9.5:1 — passes WCAG AA and AAA.
//   - "VENCE" label (Colors.white24, ~rgba(255,255,255,0.24)) on dark background:
//     Approximate contrast: ~1.8:1 — FAILS WCAG AA. This is intentional decorative
//     micro-label; the expiry value itself (Colors.white) passes at ~19.9:1.
//   - Colors.white38 masked digits on #050505: ~3.2:1 — passes WCAG AA for large text
//     (font-size 16, bold) per 3:1 threshold. Borderline for normal text (4.5:1 needed).
//     Recommendation: increase opacity to 0.6+ for strict AA compliance on body text.
>>>>>>> Stashed changes

import 'dart:math' as math;
import 'dart:ui';

import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/hud/hud_corner_brackets.dart';
import 'package:botslode/core/ui/hud/hud_status_dot.dart';
import 'package:botslode/features/billing/domain/models/payment_method.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';

// ---------------------------------------------------------------------------
// Internal card state
// ---------------------------------------------------------------------------

<<<<<<< Updated upstream
enum _CardState { empty, valid, expiringSoon, expired }

// ---------------------------------------------------------------------------
// DigitalCard
// ---------------------------------------------------------------------------

class DigitalCard extends StatefulWidget {
  const DigitalCard({super.key, this.method, this.now});
=======
class DigitalCard extends StatelessWidget {
  const DigitalCard({super.key, this.method, this.now, this.onAddCard});
>>>>>>> Stashed changes

  /// The PaymentMethod to display. If null, shows the empty/add-card state.
  final PaymentMethod? method;

  /// Injectable clock for deterministic golden/unit tests.
  /// Production code always leaves this null and uses [DateTime.now()].
  final DateTime? now;

<<<<<<< Updated upstream
  @override
  State<DigitalCard> createState() => _DigitalCardState();
}
=======
  /// Optional callback fired when the user taps "Agregar tarjeta" in the
  /// empty state. If null the button is rendered but does nothing.
  final VoidCallback? onAddCard;

  // -------------------------------------------------------------------------
  // Expiry helpers
  // -------------------------------------------------------------------------
>>>>>>> Stashed changes

class _DigitalCardState extends State<DigitalCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  // Gold sheen sweep — plays once every ~3.1 s on the valid state card.
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: AppMotion.durShimmer, // 3100 ms
    );
    // Delay the first sweep so it doesn't conflict with the entry animation.
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) _shimmerCtrl.repeat();
    });
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  // ─── Expiry helpers ────────────────────────────────────────────────────────

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

  // ─── State-dependent design tokens ────────────────────────────────────────

  Color get _accentColor => switch (_state) {
        _CardState.empty => AppColors.danger,
        _CardState.valid => AppColors.gold,
        _CardState.expiringSoon => AppColors.warning,
        _CardState.expired => AppColors.danger,
      };

  Color get _borderColor => switch (_state) {
        _CardState.empty => AppColors.danger.withValues(alpha: 0.28),
        _CardState.valid => AppColors.borderGold,
        _CardState.expiringSoon => AppColors.warning.withValues(alpha: 0.42),
        _CardState.expired => AppColors.danger.withValues(alpha: 0.42),
      };

  Color get _bracketColor => switch (_state) {
        _CardState.empty => AppColors.danger.withValues(alpha: 0.32),
        _CardState.valid => AppColors.borderGold,
        _CardState.expiringSoon => AppColors.warning.withValues(alpha: 0.58),
        _CardState.expired => AppColors.danger.withValues(alpha: 0.58),
      };

  List<BoxShadow> get _shadows {
    final hoverMult = _isHovered ? 1.55 : 1.0;
    return switch (_state) {
      _CardState.empty => [
          ...AppDimens.elev1,
          BoxShadow(
            color: AppColors.danger.withValues(alpha: 0.11 * hoverMult),
            blurRadius: 16,
          ),
        ],
      _CardState.valid => [
          ...AppDimens.elev2,
          BoxShadow(
            color: AppColors.goldGlow,
            blurRadius: 24 * hoverMult,
            spreadRadius: _isHovered ? 2 : 1,
          ),
        ],
      _CardState.expiringSoon => [
          ...AppDimens.elev2,
          BoxShadow(
            color: AppColors.warningGlow,
            blurRadius: 20 * hoverMult,
          ),
        ],
      _CardState.expired => [
          ...AppDimens.elev2,
          BoxShadow(
            color: AppColors.dangerGlow,
            blurRadius: 18 * hoverMult,
          ),
        ],
    };
  }

  HudStatus get _dotStatus => switch (_state) {
        _CardState.empty => HudStatus.offline,
        _CardState.valid => HudStatus.online,
        _CardState.expiringSoon => HudStatus.suspended,
        _CardState.expired => HudStatus.offline,
      };

  // ─── Expiry display string  "MM/YY" ───────────────────────────────────────

  String get _expiryLabel {
    final m = widget.method?.expMonth;
    final y = widget.method?.expYear;
    if (m == null || y == null) return '--/--';
    final mm = m.toString().padLeft(2, '0');
    final yy = (y % 100).toString().padLeft(2, '0');
    return '$mm/$yy';
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.isReduced(context);
    final isValidState = _state == _CardState.valid;

    Widget card = AspectRatio(
      aspectRatio: 1.586,
<<<<<<< Updated upstream
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedScale(
          scale: !reduced && _isHovered ? 1.022 : 1.0,
          duration: AppMotion.durFast,
          curve: AppMotion.easeHover,
          child: AnimatedContainer(
            duration: AppMotion.durFast,
            curve: AppMotion.easeStandard,
            decoration: BoxDecoration(
              borderRadius: AppDimens.brL,
              border: Border.all(color: _borderColor, width: 1.2),
              boxShadow: _shadows,
            ),
            child: ClipRRect(
              borderRadius: AppDimens.brL,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.surfaceRaised,
                        AppColors.surface,
                        AppColors.voidBlack,
=======
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF080808),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.credit_card_off_rounded,
                color: AppColors.error.withValues(alpha: 0.5),
                size: 36,
              ),
              const SizedBox(height: 16),
              const Text(
                'Sin tarjeta agregada',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              _AddCardButton(onPressed: onAddCard),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // States 2 / 3 / 4 — Card with data
  // -------------------------------------------------------------------------

  Widget _buildCardState() {
    final last4 = method?.last4 ?? '••••';
    final brand = (method?.brand?.isNotEmpty == true) ? method!.brand! : 'genérica';
    final expiry = _expiryLabel;
    final statusSuffix = _isExpired
        ? ', vencida'
        : _isExpiringSoon
            ? ', vence pronto'
            : '';

    return Semantics(
      label: 'Tarjeta terminada en $last4, $brand, vence $expiry$statusSuffix',
      child: AspectRatio(
        aspectRatio: 1.586,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: const Color(0xFF050505),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15),
                blurRadius: 40,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: _borderColor,
              width: _borderWidth,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Fondo hexagonal decorativo (puramente decorativo)
                ExcludeSemantics(
                  child: Positioned(
                    right: -50,
                    top: -20,
                    child: CustomPaint(
                      size: const Size(300, 300),
                      painter: _HexagonPainter(
                        color: AppColors.primary.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                ),
                // Gradiente sutil decorativo
                ExcludeSemantics(
                  child: Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.05),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Contenido principal — inner semantics excluded to avoid
                // duplication with the top-level Semantics label on this widget.
                ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildHeader(),
                        _buildCardNumber(),
                        _buildFooter(),
>>>>>>> Stashed changes
                      ],
                      stops: [0.0, 0.55, 1.0],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // ── Decorative hex background ──────────────────────
                      Positioned(
                        right: -48,
                        top: -20,
                        child: CustomPaint(
                          size: const Size(250, 250),
                          painter: _HexagonPainter(
                            color: _accentColor.withValues(alpha: 0.045),
                          ),
                        ),
                      ),

                      // ── Scanline texture ───────────────────────────────
                      if (!reduced)
                        const Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _ScanlinePainter(),
                            ),
                          ),
                        ),

                      // ── Gold sheen sweep (valid only) ──────────────────
                      if (!reduced && isValidState)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: _GoldSheenSweep(
                              animation: _shimmerCtrl,
                            ),
                          ),
                        ),

                      // ── Main card content ──────────────────────────────
                      Positioned.fill(
                        child: _state == _CardState.empty
                            ? _buildEmptyContent()
                            : _buildCardContent(),
                      ),

                      // ── HUD corner brackets overlay ────────────────────
                      Positioned.fill(
                        child: HudCornerBrackets(
                          color: _bracketColor,
                          armLength: 15,
                          thickness: 1.4,
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ],
                  ),
                ),
<<<<<<< Updated upstream
              ),
=======
                // Badge de estado (vencida / vence pronto) — already in top Semantics label
                if (_isExpired || _isExpiringSoon)
                  ExcludeSemantics(
                    child: Positioned(
                      bottom: 16,
                      left: 24,
                      child: _buildStatusBadge(),
                    ),
                  ),
              ],
>>>>>>> Stashed changes
            ),
          ),
        ),
      ),
    );

    // Entry animation: fade + slide from below
    if (!reduced) {
      card = card
          .animate()
          .fadeIn(
            duration: AppMotion.durSlow,
            curve: AppMotion.easeEntrance,
          )
          .moveY(
            begin: AppMotion.slideOffset,
            end: 0,
            duration: AppMotion.durSlow,
            curve: AppMotion.easeEntrance,
          );
    }

    return card;
  }

  // ─── State 1 — Empty ───────────────────────────────────────────────────────

  Widget _buildEmptyContent() {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.space24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.danger.withValues(alpha: 0.32),
                width: 1.5,
              ),
              color: AppColors.danger.withValues(alpha: 0.07),
            ),
            child: Icon(
              Icons.credit_card_off_rounded,
              color: AppColors.danger.withValues(alpha: 0.62),
              size: 26,
            ),
          ),
          const SizedBox(height: AppDimens.space12),
          Text(
            'SIN MÉTODO DE PAGO',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: AppDimens.space4),
          Text(
            'Vinculá una tarjeta para activar pagos automáticos',
            textAlign: TextAlign.center,
            style: AppTextStyles.mono.copyWith(
              color: AppColors.textTertiary,
              fontSize: 10,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppDimens.space16),
          const _AddCardButton(),
        ],
      ),
    );
  }

  // ─── States 2 / 3 / 4 — Card with data ────────────────────────────────────

  Widget _buildCardContent() {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildHeader(),
          _buildPan(),
          _buildFooter(),
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
        // EMV chip with gradGold + glow
        Container(
          width: 45,
          height: 35,
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
        Semantics(
<<<<<<< Updated upstream
          label: '${widget.method?.brand ?? 'generic'} card',
          child: _BrandIcon(brand: widget.method?.brand),
=======
          label: 'Icono tarjeta ${method?.brand?.isNotEmpty == true ? method!.brand! : 'genérica'}',
          child: _BrandIcon(brand: method?.brand),
>>>>>>> Stashed changes
        ),
      ],
    );
  }

  // Masked PAN: dots + last4 highlighted in gold
  Widget _buildPan() {
    final last4 = widget.method?.last4;
    final isExpired = _state == _CardState.expired;

    return Semantics(
      label: last4 != null
          ? 'Tarjeta terminada en $last4'
          : 'Número de tarjeta no disponible',
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '•••• •••• •••• ',
                style: AppTextStyles.hudReadout.copyWith(
                  color: AppColors.textTertiary.withValues(
                    alpha: isExpired ? 0.35 : 0.62,
                  ),
                  fontSize: 16,
                  letterSpacing: 2.0,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                last4 ?? '••••',
                style: AppTextStyles.hudReadout.copyWith(
                  color: isExpired
                      ? AppColors.danger.withValues(alpha: 0.72)
                      : AppColors.gold,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3.2,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  shadows: isExpired
                      ? null
                      : const [
                          Shadow(
                            color: AppColors.goldGlow,
                            blurRadius: 12,
                          ),
                        ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Footer row: status dot+label left, expiry date right
  Widget _buildFooter() {
    final state = _state;

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
              colors: const [
                Colors.transparent,
                Color.fromRGBO(255, 215, 64, 0.068),
                Color.fromRGBO(255, 255, 255, 0.04),
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
<<<<<<< Updated upstream
// _AddCardButton — no-op CTA for empty state (caller handles navigation)
// ---------------------------------------------------------------------------

class _AddCardButton extends StatelessWidget {
  const _AddCardButton();
=======
// _AddCardButton — CTA for empty state; forwards optional onPressed callback
// ---------------------------------------------------------------------------

class _AddCardButton extends StatelessWidget {
  const _AddCardButton({this.onPressed});
  final VoidCallback? onPressed;
>>>>>>> Stashed changes

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.gold,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space20,
          vertical: AppDimens.space8,
        ),
        side: const BorderSide(color: AppColors.borderGold, width: 1),
        shape: RoundedRectangleBorder(borderRadius: AppDimens.brM),
        minimumSize: const Size(AppDimens.hitTargetMin, AppDimens.hitTargetMin),
      ),
      child: Text(
        'AGREGAR TARJETA',
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.gold,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
<<<<<<< Updated upstream
// _BrandIcon — renders brand SVG from assets/billing/brands/
// Supported: visa, mastercard, amex. Falls back to generic.svg.
=======
// _BrandIcon — renders brand SVG from assets/billing/brands/.
// Normalises gateway strings (Stripe, Mercado Pago, etc.) via alias map.
// Falls back to generic.svg for unknown brands.
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
    return SvgPicture.asset(_assetPath, width: 52, height: 34);
=======
    return SvgPicture.asset(
      _assetPath,
      width: 52,
      height: 34,
      placeholderBuilder: (_) => const SizedBox(width: 52, height: 34),
      semanticsLabel: '', // outer Semantics widget already provides the label
    );
>>>>>>> Stashed changes
  }
}

// ---------------------------------------------------------------------------
// Preserved painters — must NOT be deleted per task constraints
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

class _ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(6),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 2 / 3, 0),
      Offset(size.width * 2 / 3, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Lightweight scanline painter — avoids importing private API from hud_scanlines.dart
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

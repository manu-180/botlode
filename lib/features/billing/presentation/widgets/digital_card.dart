// Archivo: lib/features/billing/presentation/widgets/digital_card.dart
//
// T4·12 — DigitalCard refactored to display PaymentMethod domain model.
//
// Displays the default PaymentMethod with brand icon (SVG placeholder),
// masked card number and expiry. Implements 4 visual states:
//   1. Empty  — no method provided
//   2. Valid  — card is active (not expired, not expiring soon)
//   3. Expiring soon — ≤30 days until expiry
//   4. Expired — expiry date is in the past
//
// Security: never displays gatewayToken or full PAN.
// Only last4 (4 digits max) is shown.

import 'dart:math' as math;

import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/billing/domain/models/payment_method.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// ---------------------------------------------------------------------------
// Public widget
// ---------------------------------------------------------------------------

class DigitalCard extends StatelessWidget {
  const DigitalCard({super.key, this.method, this.now});

  /// The PaymentMethod to display. If null, shows the empty/add-card state.
  final PaymentMethod? method;

  /// Injectable clock for deterministic golden/unit tests.
  /// Production code always leaves this null and uses [DateTime.now()].
  final DateTime? now;

  // -------------------------------------------------------------------------
  // Expiry helpers
  // -------------------------------------------------------------------------

  /// Returns the first moment of the month AFTER expMonth/expYear.
  /// A card is valid through the last day of expMonth; once that month ends
  /// the card is expired.
  DateTime? _expiryDate() {
    if (method?.expMonth == null || method?.expYear == null) return null;
    final m = method!.expMonth!;
    final y = method!.expYear!;
    return DateTime(y, m + 1, 1);
  }

  DateTime get _now => now ?? DateTime.now();

  bool get _isExpired {
    final exp = _expiryDate();
    return exp != null && _now.isAfter(exp);
  }

  bool get _isExpiringSoon {
    final exp = _expiryDate();
    if (exp == null || _isExpired) return false;
    return exp.difference(_now).inDays <= 30;
  }

  // -------------------------------------------------------------------------
  // Border color based on state
  // -------------------------------------------------------------------------

  Color get _borderColor {
    if (_isExpired) return AppColors.error;
    if (_isExpiringSoon) return AppColors.warning;
    return AppColors.borderHighlight;
  }

  double get _borderWidth {
    if (_isExpired || _isExpiringSoon) return 2.0;
    return 1.0;
  }

  // -------------------------------------------------------------------------
  // Expiry display string  "MM/YY"
  // -------------------------------------------------------------------------

  String get _expiryLabel {
    final m = method?.expMonth;
    final y = method?.expYear;
    if (m == null || y == null) return '--/--';
    final mm = m.toString().padLeft(2, '0');
    final yy = (y % 100).toString().padLeft(2, '0');
    return '$mm/$yy';
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (method == null) return _buildEmptyState();
    return _buildCardState();
  }

  // -------------------------------------------------------------------------
  // State 1 — Empty
  // -------------------------------------------------------------------------

  Widget _buildEmptyState() {
    return AspectRatio(
      aspectRatio: 1.586,
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
              _AddCardButton(),
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
    return AspectRatio(
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
              // Fondo hexagonal decorativo
              Positioned(
                right: -50,
                top: -20,
                child: CustomPaint(
                  size: const Size(300, 300),
                  painter: _HexagonPainter(
                    color: AppColors.primary.withValues(alpha: 0.05),
                  ),
                ),
              ),
              // Gradiente sutil de arriba-izquierda a abajo-derecha
              Positioned.fill(
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
              // Contenido principal
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildHeader(),
                    _buildCardNumber(),
                    _buildFooter(),
                  ],
                ),
              ),
              // Badge de estado (vencida / vence pronto)
              if (_isExpired || _isExpiringSoon)
                Positioned(
                  bottom: 16,
                  left: 24,
                  child: _buildStatusBadge(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Header row: chip left, brand icon right
  // -------------------------------------------------------------------------

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chip EMV
        Container(
          width: 45,
          height: 35,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: const LinearGradient(
              colors: [Color(0xFFE0AA3E), Color(0xFFB88A2D), Color(0xFFF9E496)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 2,
                offset: const Offset(1, 1),
              ),
            ],
          ),
          child: CustomPaint(painter: _ChipPainter()),
        ),
        // Icono de marca
        Semantics(
          label: '${method?.brand ?? 'generic'} card icon',
          child: _BrandIcon(brand: method?.brand),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Card number (masked)
  // -------------------------------------------------------------------------

  Widget _buildCardNumber() {
    final last4 = method?.last4;
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
              const Text(
                '•••• •••• •••• ',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 16,
                  letterSpacing: 2.0,
                  fontFamily: 'Courier',
                ),
              ),
              Text(
                last4 ?? '••••',
                style: TextStyle(
                  color: AppColors.primary,
                  fontFamily: 'Oxanium',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3.0,
                  shadows: [
                    Shadow(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      blurRadius: 15,
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

  // -------------------------------------------------------------------------
  // Footer row: expiry date right-aligned
  // -------------------------------------------------------------------------

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'VENCE',
              style: TextStyle(
                color: Colors.white24,
                fontSize: 9,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _expiryLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Status badge (VENCIDA / VENCE PRONTO)
  // -------------------------------------------------------------------------

  Widget _buildStatusBadge() {
    final isExpired = _isExpired;
    final bgColor = isExpired ? AppColors.error : AppColors.warning;
    final textColor = isExpired ? Colors.white : const Color(0xFF1A1200);
    final label = isExpired ? 'VENCIDA' : 'VENCE PRONTO';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _AddCardButton — no-op CTA for empty state
// ---------------------------------------------------------------------------

class _AddCardButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        // no-op: caller is responsible for navigation/modal
      },
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        side: const BorderSide(color: AppColors.primary, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text(
        'Agregar tarjeta',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _BrandIcon — renders brand SVG from assets/billing/brands/.
// Supported: visa, mastercard, amex. Falls back to generic.svg.
// ---------------------------------------------------------------------------

class _BrandIcon extends StatelessWidget {
  const _BrandIcon({this.brand});
  final String? brand;

  static const _kSupported = {'visa', 'mastercard', 'amex'};

  String get _assetPath {
    final b = brand?.toLowerCase() ?? '';
    final name = _kSupported.contains(b) ? b : 'generic';
    return 'assets/billing/brands/$name.svg';
  }

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      _assetPath,
      width: 52,
      height: 34,
    );
  }
}

// ---------------------------------------------------------------------------
// Preserved painters (must NOT be deleted per task constraints)
// ---------------------------------------------------------------------------

class _HexagonPainter extends CustomPainter {
  final Color color;
  const _HexagonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30;
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
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

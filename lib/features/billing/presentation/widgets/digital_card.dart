// Archivo: lib/features/billing/presentation/widgets/digital_card.dart
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/billing/domain/models/card_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

class DigitalCard extends ConsumerWidget {
  final CardInfo? card;
  const DigitalCard({super.key, this.card});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (card == null) return _buildEmptyState();

    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF050505), // Negro puro
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 40,
            offset: const Offset(0, 10),
          )
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Fondo Hexagonal
            Positioned(
              right: -50, top: -20,
              child: CustomPaint(
                size: const Size(300, 300),
                painter: _HexagonPainter(color: AppColors.primary.withValues(alpha: 0.05)),
              ),
            ),
            // Gradiente
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.05),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
            ),
            // Contenido
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Header: Chip (Icono derecho eliminado como se pidió)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 45, height: 35,
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
                              offset: const Offset(1,1)
                            )
                          ]
                        ),
                        child: CustomPaint(painter: _ChipPainter()),
                      ),
                      // AQUÍ ANTES ESTABA EL ICONO, YA NO ESTÁ.
                    ],
                  ),

                  // Número
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text("•••• •••• •••• ", 
                            style: TextStyle(color: Colors.white38, fontSize: 18, letterSpacing: 2.0, fontFamily: 'Courier')
                          ),
                          Text(
                            card!.lastFour,
                            style: TextStyle(
                              color: AppColors.primary, 
                              fontFamily: 'Oxanium',
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3.0,
                              shadows: [
                                Shadow(
                                  color: AppColors.primary.withValues(alpha: 0.5), 
                                  blurRadius: 15
                                )
                              ]
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("TITULAR", style: TextStyle(color: Colors.white24, fontSize: 9, letterSpacing: 1.5)),
                          const SizedBox(height: 4),
                          Text(
                            card!.holderName.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text("VENCE", style: TextStyle(color: Colors.white24, fontSize: 9, letterSpacing: 1.5)),
                          const SizedBox(height: 4),
                          Text(
                            card!.expiryDate,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity, height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF080808),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3), width: 1),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Image.network("https://www.transparenttextures.com/patterns/diagmonds-light.png", repeat: ImageRepeat.repeat),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.credit_card_off_rounded, color: AppColors.error.withValues(alpha: 0.5), size: 40)
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text("SIN MÉTODO DE PAGO", style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontFamily: 'Oxanium')),
                const SizedBox(height: 8),
                Text("Vincule una tarjeta para operar", style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Painters
class _HexagonPainter extends CustomPainter {
  final Color color;
  _HexagonPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 30;
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    for (int i = 0; i < 6; i++) {
      final angle = (60 * i - 30) * (math.pi / 180);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
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
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.2)..style = PaintingStyle.stroke..strokeWidth = 1;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(6)), paint);
    canvas.drawLine(Offset(0, size.height/2), Offset(size.width, size.height/2), paint);
    canvas.drawLine(Offset(size.width/3, 0), Offset(size.width/3, size.height), paint);
    canvas.drawLine(Offset(size.width*2/3, 0), Offset(size.width*2/3, size.height), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
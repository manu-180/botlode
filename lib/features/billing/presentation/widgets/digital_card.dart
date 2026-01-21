// Archivo: lib/features/billing/presentation/widgets/digital_card.dart
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:flutter/material.dart';

class DigitalCard extends StatelessWidget {
  const DigitalCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos AspectRatio para mantener la proporción de tarjeta de crédito (1.58)
    // sin importar el ancho de la pantalla.
    return AspectRatio(
      aspectRatio: 1.586, // Proporción estándar ID-1 (85.60 × 53.98 mm)
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF1a1a1a), Color(0xFF000000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: AppColors.borderGlass),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 30,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 1. Fondo Decorativo
            Positioned(
              right: -50,
              top: -50,
              child: Icon(
                Icons.hexagon_outlined,
                size: 300,
                color: AppColors.primary.withOpacity(0.05),
              ),
            ),
            
            // 2. Brillo Holográfico
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [Colors.white.withOpacity(0.05), Colors.transparent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),

            // 3. CONTENIDO AUTO-AJUSTABLE (La Magia)
            // LayoutBuilder nos dice cuánto espacio tenemos disponible
            LayoutBuilder(
              builder: (context, constraints) {
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    // FittedBox escala todo hacia abajo si no cabe
                    child: FittedBox(
                      fit: BoxFit.scaleDown, 
                      child: SizedBox(
                        // Definimos un "Lienzo Virtual" interno. 
                        // Diseñamos pensando que tenemos este espacio.
                        // Si la tarjeta real es más chica, FittedBox lo reduce.
                        width: 380, 
                        height: 220, 
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // --- HEADER ---
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: 50,
                                  height: 35,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD4AF37),
                                    borderRadius: BorderRadius.circular(6),
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFD4AF37), Color(0xFFF7E7CE)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: CustomPaint(painter: _ChipPainter()),
                                ),
                                const Icon(Icons.wifi, color: Colors.white54, size: 30),
                              ],
                            ),

                            // --- NÚMERO ---
                            const Text(
                              "•••• •••• •••• 8842",
                              style: TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 28, // Fuente grande, total se achica sola
                                color: Colors.white,
                                letterSpacing: 4.0,
                                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                              ),
                            ),

                            // --- FOOTER ---
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "TITULAR DE CUENTA",
                                      style: TextStyle(color: Colors.white54, fontSize: 10),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "APEX CORP.",
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "VÁLIDA HASTA",
                                      style: TextStyle(color: Colors.white54, fontSize: 10),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "12/30",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(6)), paint);
    canvas.drawLine(Offset(size.width * 0.3, 0), Offset(size.width * 0.3, size.height), paint);
    canvas.drawLine(Offset(size.width * 0.7, 0), Offset(size.width * 0.7, size.height), paint);
    canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.5), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
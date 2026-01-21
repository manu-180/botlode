// Archivo: lib/features/bots_library/presentation/widgets/blueprint_card.dart
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/bots_library/domain/models/blueprint.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BlueprintCard extends StatefulWidget {
  final BotBlueprint blueprint;
  final VoidCallback onTap;

  const BlueprintCard({
    super.key,
    required this.blueprint,
    required this.onTap,
  });

  @override
  State<BlueprintCard> createState() => _BlueprintCardState();
}

class _BlueprintCardState extends State<BlueprintCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.blueprint.techColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: _isHovered ? 0.8 : 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered ? color.withValues(alpha: 0.8) : AppColors.borderGlass,
              width: 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // FONDO: Cuadrícula técnica (Grid)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _GridPainter(
                      color: color.withValues(alpha: _isHovered ? 0.1 : 0.03),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // HEADER: Icono y Categoría
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: color.withValues(alpha: 0.3)),
                            ),
                            // CAMBIO: FaIcon para iconos de FontAwesome
                            child: FaIcon(widget.blueprint.icon, color: color, size: 24),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.3)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.blueprint.id,
                              style: const TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 10,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // BODY: Título y Categoría
                      Text(
                        widget.blueprint.category,
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.blueprint.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _isHovered ? Colors.white : AppColors.textPrimary,
                          letterSpacing: 1.0,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.blueprint.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Marca de agua "PROTOTIPO"
                Positioned(
                  top: 15,
                  right: -25,
                  child: Transform.rotate(
                    angle: 0.785, // 45 grados
                    child: Container(
                      width: 100,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      color: color.withValues(alpha: 0.15),
                      child: Text(
                        "PROTOTIPO",
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: color,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    const step = 20.0;
    
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
}

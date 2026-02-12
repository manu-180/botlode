// Archivo: lib/features/store/presentation/widgets/product_card.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/store/domain/models/store_product.dart';
import 'package:botslode/features/hunter_bot/presentation/views/hunter_view.dart';

/// Card de producto en la tienda
class ProductCard extends StatefulWidget {
  final StoreProduct product;

  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()
          ..translate(0.0, _isHovered ? -4.0 : 0.0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered 
                ? product.accentColor.withOpacity(0.4) 
                : AppColors.borderGlass,
            width: _isHovered ? 1.5 : 1,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: product.accentColor.withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header con icono
            _buildHeader(product),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Categoría
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: product.category.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.category.displayName,
                        style: TextStyle(
                          color: product.category.color,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          fontFamily: 'Oxanium',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Nombre
                    Text(
                      product.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Oxanium',
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Descripción
                    Text(
                      product.description,
                      style: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.7),
                        fontSize: 12,
                        fontFamily: 'Oxanium',
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const Spacer(),
                    
                    // Features (mostrar solo 3)
                    ...product.features.take(3).map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: product.accentColor.withOpacity(0.6),
                            size: 12,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              feature,
                              style: TextStyle(
                                color: AppColors.textSecondary.withOpacity(0.6),
                                fontSize: 10,
                                fontFamily: 'Oxanium',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
            
            // Footer con precio y botón
            _buildFooter(product),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(StoreProduct product) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            product.accentColor.withOpacity(0.1),
            product.accentColor.withOpacity(0.05),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
      ),
      child: Stack(
        children: [
          // Patrón de fondo
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPatternPainter(product.accentColor),
            ),
          ),
          
          // Icono central
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.9),
                shape: BoxShape.circle,
                border: Border.all(
                  color: product.accentColor.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: product.accentColor.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: FaIcon(
                product.icon,
                color: product.accentColor,
                size: 28,
              ),
            ),
          ),
          
          // Badge de "Próximamente" si no está disponible
          if (!product.isAvailable)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'PRÓXIMAMENTE',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Oxanium',
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          
          // Badge de "Adquirido" si ya lo tiene
          if (product.isOwned)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, color: Colors.black, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'ACTIVO',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Oxanium',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooter(StoreProduct product) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.5),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
        border: Border(
          top: BorderSide(color: AppColors.borderGlass),
        ),
      ),
      child: Row(
        children: [
          // Precio
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.formattedPrice,
                style: TextStyle(
                  color: !product.priceDefined
                      ? AppColors.textSecondary.withOpacity(0.8)
                      : product.price == 0
                          ? AppColors.success
                          : AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Oxanium',
                ),
              ),
              if (product.priceDefined && product.price > 0)
                Text(
                  'pago único',
                  style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.5),
                    fontSize: 10,
                    fontFamily: 'Oxanium',
                  ),
                ),
            ],
          ),
          
          const Spacer(),
          
          // Botón
          ElevatedButton(
            onPressed: product.isAvailable && !product.isOwned
                ? () => _handleAction(product)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: product.isOwned 
                  ? AppColors.success.withOpacity(0.2)
                  : product.accentColor,
              foregroundColor: product.isOwned 
                  ? AppColors.success 
                  : Colors.black,
              disabledBackgroundColor: AppColors.textSecondary.withOpacity(0.1),
              disabledForegroundColor: AppColors.textSecondary.withOpacity(0.4),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              product.isOwned 
                  ? 'ABRIR'
                  : product.isAvailable 
                      ? 'OBTENER'
                      : 'NOTIFICAR',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Oxanium',
                letterSpacing: 1,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(StoreProduct product) {
    if (product.id == 'HUNTER-BOT') {
      // Navegar a HunterBot
      context.goNamed(HunterView.routeName);
    } else {
      // Mostrar modal de compra (TODO)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Compra de ${product.name} próximamente',
            style: const TextStyle(fontFamily: 'Oxanium'),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// Painter para el patrón de grid en el header
class _GridPatternPainter extends CustomPainter {
  final Color color;

  _GridPatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.05)
      ..strokeWidth = 1;

    const spacing = 20.0;

    // Líneas verticales
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Líneas horizontales
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

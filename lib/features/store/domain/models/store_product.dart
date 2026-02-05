// Archivo: lib/features/store/domain/models/store_product.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:botslode/core/config/theme/app_colors.dart';

/// Categorías de productos en la tienda
enum ProductCategory {
  automation,
  marketing,
  analytics,
  integration;

  String get displayName {
    switch (this) {
      case ProductCategory.automation:
        return 'AUTOMATIZACIÓN';
      case ProductCategory.marketing:
        return 'MARKETING';
      case ProductCategory.analytics:
        return 'ANALÍTICAS';
      case ProductCategory.integration:
        return 'INTEGRACIONES';
    }
  }

  Color get color {
    switch (this) {
      case ProductCategory.automation:
        return AppColors.primary;
      case ProductCategory.marketing:
        return AppColors.success;
      case ProductCategory.analytics:
        return AppColors.secondary;
      case ProductCategory.integration:
        return const Color(0xFFB026FF);
    }
  }
}

/// Modelo de un producto en la tienda
class StoreProduct {
  final String id;
  final String name;
  final String description;
  final ProductCategory category;
  final double price;
  final String? riveAsset;
  final IconData icon;
  final Color accentColor;
  final bool isOwned;
  final bool isAvailable;
  final List<String> features;

  const StoreProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    this.riveAsset,
    required this.icon,
    required this.accentColor,
    this.isOwned = false,
    this.isAvailable = true,
    required this.features,
  });

  /// Precio formateado para mostrar
  String get formattedPrice => price == 0 ? 'GRATIS' : '\$${price.toStringAsFixed(2)} USD';

  /// Catálogo de productos disponibles
  static List<StoreProduct> get catalog => [
    const StoreProduct(
      id: 'HUNTER-BOT',
      name: 'HUNTER BOT',
      description: 'Encuentra emails de contacto en cualquier sitio web y envía campañas de outreach automatizadas.',
      category: ProductCategory.marketing,
      price: 29.99,
      riveAsset: null, // TODO: Agregar animación Rive
      icon: FontAwesomeIcons.crosshairs,
      accentColor: AppColors.success,
      features: [
        'Scraping inteligente de sitios web',
        'Detección automática de emails',
        'Integración con Resend',
        'Logs en tiempo real',
        'Templates de email personalizables',
        'Estadísticas de campañas',
      ],
    ),
    const StoreProduct(
      id: 'ANALYTICS-PRO',
      name: 'ANALYTICS PRO',
      description: 'Dashboard avanzado con métricas detalladas de tus bots y conversaciones.',
      category: ProductCategory.analytics,
      price: 0,
      riveAsset: null,
      icon: FontAwesomeIcons.chartLine,
      accentColor: AppColors.secondary,
      isAvailable: false, // Próximamente
      features: [
        'Métricas de conversación',
        'Análisis de sentimiento',
        'Reportes exportables',
        'Alertas personalizadas',
      ],
    ),
    const StoreProduct(
      id: 'WHATSAPP-BRIDGE',
      name: 'WHATSAPP BRIDGE',
      description: 'Conecta tus bots directamente a WhatsApp Business para atender clientes 24/7.',
      category: ProductCategory.integration,
      price: 49.99,
      riveAsset: null,
      icon: FontAwesomeIcons.whatsapp,
      accentColor: Color(0xFF25D366),
      isAvailable: false, // Próximamente
      features: [
        'Conexión API oficial',
        'Mensajes ilimitados',
        'Multimedia soportado',
        'Respuestas automáticas',
      ],
    ),
  ];

  /// Crea una copia con isOwned modificado
  StoreProduct copyWith({
    bool? isOwned,
    bool? isAvailable,
  }) {
    return StoreProduct(
      id: id,
      name: name,
      description: description,
      category: category,
      price: price,
      riveAsset: riveAsset,
      icon: icon,
      accentColor: accentColor,
      isOwned: isOwned ?? this.isOwned,
      isAvailable: isAvailable ?? this.isAvailable,
      features: features,
    );
  }

  @override
  String toString() => 'StoreProduct(id: $id, name: $name, price: $formattedPrice)';
}

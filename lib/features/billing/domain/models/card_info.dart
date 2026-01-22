// Archivo: lib/features/billing/domain/models/card_info.dart
class CardInfo {
  final String id; // UUID de la tabla
  final String lastFour;
  final String brand;
  final String holderName;
  final String expiryDate;
  final bool isPrimary; // Nuevo campo

  CardInfo({
    required this.id,
    required this.lastFour,
    required this.brand,
    required this.holderName,
    required this.expiryDate,
    required this.isPrimary,
  });

  factory CardInfo.fromMap(Map<String, dynamic> map) {
    return CardInfo(
      id: map['id']?.toString() ?? '',
      lastFour: map['card_last_four'] ?? '****',
      brand: map['card_brand'] ?? 'UNKNOWN',
      holderName: map['card_holder'] ?? 'OPERADOR',
      expiryDate: map['card_expiry'] ?? 'MM/AA',
      isPrimary: map['is_primary'] ?? false,
    );
  }
}
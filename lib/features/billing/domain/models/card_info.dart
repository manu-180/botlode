// Archivo: lib/features/billing/domain/models/card_info.dart

class CardInfo {
  final String id;
  final String lastFour;
  final String brand;
  final String holderName;
  final String expiryDate;
  final bool isPrimary;
  final String mpCustomerId; // ID interno de MP
  final String cardTokenId;  // ID interno de la tarjeta en MP
  final double autoPayThreshold; // <--- NUEVO CAMPO

  CardInfo({
    required this.id,
    required this.lastFour,
    required this.brand,
    required this.holderName,
    required this.expiryDate,
    required this.isPrimary,
    required this.mpCustomerId,
    required this.cardTokenId,
    this.autoPayThreshold = 0.0, // Default apagado
  });

  factory CardInfo.fromMap(Map<String, dynamic> map) {
    return CardInfo(
      id: map['id']?.toString() ?? '',
      lastFour: map['card_last_four'] ?? '****',
      brand: map['card_brand'] ?? 'Unknown',
      holderName: map['card_holder'] ?? '',
      expiryDate: map['card_expiry'] ?? '',
      isPrimary: map['is_primary'] ?? false,
      mpCustomerId: map['mp_customer_id'] ?? '',
      cardTokenId: map['card_token_id'] ?? '',
      autoPayThreshold: (map['auto_pay_threshold'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'card_last_four': lastFour,
      'card_brand': brand,
      'card_holder': holderName,
      'card_expiry': expiryDate,
      'is_primary': isPrimary,
      'mp_customer_id': mpCustomerId,
      'card_token_id': cardTokenId,
      'auto_pay_threshold': autoPayThreshold,
    };
  }

  CardInfo copyWith({
    String? id,
    String? lastFour,
    String? brand,
    String? holderName,
    String? expiryDate,
    bool? isPrimary,
    String? mpCustomerId,
    String? cardTokenId,
    double? autoPayThreshold,
  }) {
    return CardInfo(
      id: id ?? this.id,
      lastFour: lastFour ?? this.lastFour,
      brand: brand ?? this.brand,
      holderName: holderName ?? this.holderName,
      expiryDate: expiryDate ?? this.expiryDate,
      isPrimary: isPrimary ?? this.isPrimary,
      mpCustomerId: mpCustomerId ?? this.mpCustomerId,
      cardTokenId: cardTokenId ?? this.cardTokenId,
      autoPayThreshold: autoPayThreshold ?? this.autoPayThreshold,
    );
  }
}
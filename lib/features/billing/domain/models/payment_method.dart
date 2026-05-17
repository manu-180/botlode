// lib/features/billing/domain/models/payment_method.dart

class PaymentMethod {
  final String id;
  final bool isDefault;
  final String? last4;
  final String? brand;
  final int? expMonth;
  final int? expYear;
  final String? gatewayToken;

  const PaymentMethod({
    required this.id,
    required this.isDefault,
    this.last4,
    this.brand,
    this.expMonth,
    this.expYear,
    this.gatewayToken,
  });

  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      id: map['id']?.toString() ?? '',
      isDefault: map['is_default'] as bool? ?? false,
      last4: map['last4']?.toString() ?? map['card_last_four']?.toString(),
      brand: map['brand']?.toString() ?? map['card_brand']?.toString(),
      expMonth: (map['exp_month'] as num?)?.toInt(),
      expYear: (map['exp_year'] as num?)?.toInt(),
      gatewayToken: map['gateway_token']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'is_default': isDefault,
        'last4': last4,
        'brand': brand,
        'exp_month': expMonth,
        'exp_year': expYear,
      };

  PaymentMethod copyWith({
    String? id,
    bool? isDefault,
    String? last4,
    String? brand,
    int? expMonth,
    int? expYear,
    String? gatewayToken,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      isDefault: isDefault ?? this.isDefault,
      last4: last4 ?? this.last4,
      brand: brand ?? this.brand,
      expMonth: expMonth ?? this.expMonth,
      expYear: expYear ?? this.expYear,
      gatewayToken: gatewayToken ?? this.gatewayToken,
    );
  }
}

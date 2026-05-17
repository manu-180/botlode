// lib/features/billing/domain/models/plan.dart

class Plan {
  final String id;
  final String name;
  final double priceMonthly;
  final String currency;
  final String? description;
  final bool isPublic;

  const Plan({
    required this.id,
    required this.name,
    required this.priceMonthly,
    required this.currency,
    this.description,
    this.isPublic = true,
  });

  factory Plan.fromMap(Map<String, dynamic> map) {
    return Plan(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      priceMonthly: (map['price_monthly'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency']?.toString() ?? 'usd',
      description: map['description']?.toString(),
      isPublic: map['is_public'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'price_monthly': priceMonthly,
        'currency': currency,
        'description': description,
        'is_public': isPublic,
      };
}

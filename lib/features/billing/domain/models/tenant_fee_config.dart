// Archivo: lib/features/billing/domain/models/tenant_fee_config.dart

/// Configuración de comisión de marketplace por tenant.
///
/// Un solo registro por tenant (PK: tenant_id). Se crea automáticamente
/// con `marketplace_fee_percent = 0` vía trigger al insertar en `tenants`.
///
/// [marketplaceFeePercent] usa el rango [0, 100]. Ejemplo: 10.00 = 10%.
/// La comisión sólo se aplica cuando la pasarela soporta marketplace
/// (Stripe Connect / MP Marketplace). Esa lógica reside en T5 (edge).
///
/// [appliedUntil] permite comisiones temporales (promo). `null` = sin expiración.
class TenantFeeConfig {
  final String tenantId;

  /// Porcentaje de comisión, en el rango [0, 100]. Default: 0.
  final double marketplaceFeePercent;

  /// Si no es null, la comisión sólo aplica hasta esta fecha (UTC).
  final DateTime? appliedUntil;

  final DateTime createdAt;
  final DateTime updatedAt;

  const TenantFeeConfig({
    required this.tenantId,
    required this.marketplaceFeePercent,
    this.appliedUntil,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TenantFeeConfig.fromJson(Map<String, dynamic> json) {
    return TenantFeeConfig(
      tenantId: json['tenant_id'] as String,
      marketplaceFeePercent:
          (json['marketplace_fee_percent'] as num).toDouble(),
      appliedUntil: json['applied_until'] != null
          ? DateTime.parse(json['applied_until'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'tenant_id': tenantId,
        'marketplace_fee_percent': marketplaceFeePercent,
        'applied_until': appliedUntil?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  /// Devuelve `true` si la comisión está vigente (no ha expirado).
  bool get isActive =>
      appliedUntil == null || DateTime.now().toUtc().isBefore(appliedUntil!);
}

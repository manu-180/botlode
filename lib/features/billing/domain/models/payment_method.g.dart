// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_method.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PaymentMethodImpl _$$PaymentMethodImplFromJson(Map<String, dynamic> json) =>
    _$PaymentMethodImpl(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      gateway: $enumDecode(_$PaymentGatewayEnumMap, json['gateway']),
      gatewayToken: json['gateway_token'] as String,
      brand: json['brand'] as String?,
      last4: json['last4'] as String?,
      expMonth: (json['exp_month'] as num?)?.toInt(),
      expYear: (json['exp_year'] as num?)?.toInt(),
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
    );

Map<String, dynamic> _$$PaymentMethodImplToJson(_$PaymentMethodImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tenant_id': instance.tenantId,
      'gateway': _$PaymentGatewayEnumMap[instance.gateway]!,
      'gateway_token': instance.gatewayToken,
      'brand': instance.brand,
      'last4': instance.last4,
      'exp_month': instance.expMonth,
      'exp_year': instance.expYear,
      'is_default': instance.isDefault,
      'created_at': instance.createdAt.toIso8601String(),
      'deleted_at': instance.deletedAt?.toIso8601String(),
    };

const _$PaymentGatewayEnumMap = {
  PaymentGateway.stripe: 'stripe',
  PaymentGateway.mp: 'mp',
};

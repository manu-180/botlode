// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'billing_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BillingEventImpl _$$BillingEventImplFromJson(Map<String, dynamic> json) =>
    _$BillingEventImpl(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      subscriptionId: json['subscription_id'] as String?,
      type: json['type'] as String,
      gateway: $enumDecodeNullable(_$PaymentGatewayEnumMap, json['gateway']),
      gatewayEventId: json['gateway_event_id'] as String?,
      idempotencyKey: json['idempotency_key'] as String?,
      payload:
          json['payload'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      occurredAt: DateTime.parse(json['occurred_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$BillingEventImplToJson(_$BillingEventImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tenant_id': instance.tenantId,
      'subscription_id': instance.subscriptionId,
      'type': instance.type,
      'gateway': _$PaymentGatewayEnumMap[instance.gateway],
      'gateway_event_id': instance.gatewayEventId,
      'idempotency_key': instance.idempotencyKey,
      'payload': instance.payload,
      'occurred_at': instance.occurredAt.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$PaymentGatewayEnumMap = {
  PaymentGateway.stripe: 'stripe',
  PaymentGateway.mp: 'mp',
};

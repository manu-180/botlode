// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SubscriptionImpl _$$SubscriptionImplFromJson(Map<String, dynamic> json) =>
    _$SubscriptionImpl(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      planId: json['plan_id'] as String,
      status: $enumDecode(_$SubscriptionStatusEnumMap, json['status']),
      currentPeriodStart: json['current_period_start'] == null
          ? null
          : DateTime.parse(json['current_period_start'] as String),
      currentPeriodEnd: json['current_period_end'] == null
          ? null
          : DateTime.parse(json['current_period_end'] as String),
      trialEnd: json['trial_end'] == null
          ? null
          : DateTime.parse(json['trial_end'] as String),
      cancelAtPeriodEnd: json['cancel_at_period_end'] as bool? ?? false,
      canceledAt: json['canceled_at'] == null
          ? null
          : DateTime.parse(json['canceled_at'] as String),
      gateway: $enumDecodeNullable(_$PaymentGatewayEnumMap, json['gateway']),
      gatewaySubscriptionId: json['gateway_subscription_id'] as String?,
      gatewayCustomerId: json['gateway_customer_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$SubscriptionImplToJson(_$SubscriptionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tenant_id': instance.tenantId,
      'plan_id': instance.planId,
      'status': _$SubscriptionStatusEnumMap[instance.status]!,
      'current_period_start': instance.currentPeriodStart?.toIso8601String(),
      'current_period_end': instance.currentPeriodEnd?.toIso8601String(),
      'trial_end': instance.trialEnd?.toIso8601String(),
      'cancel_at_period_end': instance.cancelAtPeriodEnd,
      'canceled_at': instance.canceledAt?.toIso8601String(),
      'gateway': _$PaymentGatewayEnumMap[instance.gateway],
      'gateway_subscription_id': instance.gatewaySubscriptionId,
      'gateway_customer_id': instance.gatewayCustomerId,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$SubscriptionStatusEnumMap = {
  SubscriptionStatus.trialing: 'trialing',
  SubscriptionStatus.active: 'active',
  SubscriptionStatus.pastDue: 'past_due',
  SubscriptionStatus.canceled: 'canceled',
  SubscriptionStatus.incomplete: 'incomplete',
};

const _$PaymentGatewayEnumMap = {
  PaymentGateway.stripe: 'stripe',
  PaymentGateway.mp: 'mp',
};

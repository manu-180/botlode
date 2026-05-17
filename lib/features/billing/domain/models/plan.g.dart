// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlanImpl _$$PlanImplFromJson(Map<String, dynamic> json) => _$PlanImpl(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      priceCents: (json['price_cents'] as num).toInt(),
      currency: json['currency'] as String? ?? 'USD',
      interval: $enumDecode(_$BillingIntervalEnumMap, json['interval']),
      maxBots: (json['max_bots'] as num).toInt(),
      maxConversations: (json['max_conversations'] as num).toInt(),
      features: json['features'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
      public: json['public'] as bool? ?? true,
      archivedAt: json['archived_at'] == null
          ? null
          : DateTime.parse(json['archived_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$PlanImplToJson(_$PlanImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'price_cents': instance.priceCents,
      'currency': instance.currency,
      'interval': _$BillingIntervalEnumMap[instance.interval]!,
      'max_bots': instance.maxBots,
      'max_conversations': instance.maxConversations,
      'features': instance.features,
      'public': instance.public,
      'archived_at': instance.archivedAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$BillingIntervalEnumMap = {
  BillingInterval.month: 'month',
  BillingInterval.year: 'year',
};

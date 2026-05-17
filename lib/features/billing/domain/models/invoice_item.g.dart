// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$InvoiceItemImpl _$$InvoiceItemImplFromJson(Map<String, dynamic> json) =>
    _$InvoiceItemImpl(
      id: json['id'] as String,
      invoiceId: json['invoice_id'] as String,
      description: json['description'] as String,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPriceCents: (json['unit_price_cents'] as num).toInt(),
      amountCents: (json['amount_cents'] as num).toInt(),
      currency: json['currency'] as String? ?? 'USD',
      proration: json['proration'] as bool? ?? false,
      periodStart: json['period_start'] == null
          ? null
          : DateTime.parse(json['period_start'] as String),
      periodEnd: json['period_end'] == null
          ? null
          : DateTime.parse(json['period_end'] as String),
      planId: json['plan_id'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$InvoiceItemImplToJson(_$InvoiceItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'invoice_id': instance.invoiceId,
      'description': instance.description,
      'quantity': instance.quantity,
      'unit_price_cents': instance.unitPriceCents,
      'amount_cents': instance.amountCents,
      'currency': instance.currency,
      'proration': instance.proration,
      'period_start': instance.periodStart?.toIso8601String(),
      'period_end': instance.periodEnd?.toIso8601String(),
      'plan_id': instance.planId,
      'metadata': instance.metadata,
      'created_at': instance.createdAt.toIso8601String(),
    };

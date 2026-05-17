// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$InvoiceImpl _$$InvoiceImplFromJson(Map<String, dynamic> json) =>
    _$InvoiceImpl(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      subscriptionId: json['subscription_id'] as String?,
      number: json['number'] as String,
      totalCents: (json['total_cents'] as num).toInt(),
      subtotalCents: (json['subtotal_cents'] as num?)?.toInt() ?? 0,
      taxCents: (json['tax_cents'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'USD',
      status: $enumDecode(_$InvoiceStatusEnumMap, json['status']),
      periodStart: json['period_start'] == null
          ? null
          : DateTime.parse(json['period_start'] as String),
      periodEnd: json['period_end'] == null
          ? null
          : DateTime.parse(json['period_end'] as String),
      dueAt: json['due_at'] == null
          ? null
          : DateTime.parse(json['due_at'] as String),
      paidAt: json['paid_at'] == null
          ? null
          : DateTime.parse(json['paid_at'] as String),
      pdfUrl: json['pdf_url'] as String?,
      gateway: $enumDecodeNullable(_$PaymentGatewayEnumMap, json['gateway']),
      gatewayInvoiceId: json['gateway_invoice_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$InvoiceImplToJson(_$InvoiceImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tenant_id': instance.tenantId,
      'subscription_id': instance.subscriptionId,
      'number': instance.number,
      'total_cents': instance.totalCents,
      'subtotal_cents': instance.subtotalCents,
      'tax_cents': instance.taxCents,
      'currency': instance.currency,
      'status': _$InvoiceStatusEnumMap[instance.status]!,
      'period_start': instance.periodStart?.toIso8601String(),
      'period_end': instance.periodEnd?.toIso8601String(),
      'due_at': instance.dueAt?.toIso8601String(),
      'paid_at': instance.paidAt?.toIso8601String(),
      'pdf_url': instance.pdfUrl,
      'gateway': _$PaymentGatewayEnumMap[instance.gateway],
      'gateway_invoice_id': instance.gatewayInvoiceId,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$InvoiceStatusEnumMap = {
  InvoiceStatus.draft: 'draft',
  InvoiceStatus.open: 'open',
  InvoiceStatus.paid: 'paid',
  InvoiceStatus.uncollectible: 'uncollectible',
  InvoiceStatus.voided: 'void',
};

const _$PaymentGatewayEnumMap = {
  PaymentGateway.stripe: 'stripe',
  PaymentGateway.mp: 'mp',
};

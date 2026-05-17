// Archivo: lib/features/billing/domain/models/billing_event.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'subscription.dart';

part 'billing_event.freezed.dart';
part 'billing_event.g.dart';

@freezed
class BillingEvent with _$BillingEvent {
  const factory BillingEvent({
    required String id,
    required String tenantId,
    String? subscriptionId,
    required String type,
    PaymentGateway? gateway,
    String? gatewayEventId,
    String? idempotencyKey,
    @Default(<String, dynamic>{}) Map<String, dynamic> payload,
    required DateTime occurredAt,
    required DateTime createdAt,
  }) = _BillingEvent;

  factory BillingEvent.fromJson(Map<String, dynamic> json) =>
      _$BillingEventFromJson(json);
}

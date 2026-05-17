// Archivo: lib/features/billing/domain/models/invoice_item.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'invoice_item.freezed.dart';
part 'invoice_item.g.dart';

@freezed
class InvoiceItem with _$InvoiceItem {
  const factory InvoiceItem({
    required String id,
    required String invoiceId,
    required String description,
    @Default(1) int quantity,
    required int unitPriceCents,
    required int amountCents,
    @Default('USD') String currency,
    @Default(false) bool proration,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? planId,
    @Default(<String, dynamic>{}) Map<String, dynamic> metadata,
    required DateTime createdAt,
  }) = _InvoiceItem;

  factory InvoiceItem.fromJson(Map<String, dynamic> json) =>
      _$InvoiceItemFromJson(json);
}

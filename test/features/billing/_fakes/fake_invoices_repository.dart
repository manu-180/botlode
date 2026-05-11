import 'package:botslode/features/billing/domain/models/invoice.dart';
import 'package:botslode/features/billing/domain/models/invoice_item.dart';
import 'package:botslode/features/billing/domain/models/invoice_page.dart';
import 'package:botslode/features/billing/domain/repositories/invoices_repository.dart';

class FakeInvoicesRepository implements InvoicesRepository {
  final List<Invoice> _invoices;

  FakeInvoicesRepository([List<Invoice>? invoices])
      : _invoices = List.of(invoices ?? []);

  void addInvoice(Invoice invoice) => _invoices.add(invoice);

  @override
  Future<InvoicePage> listForTenant(
    String tenantId, {
    String? cursor,
    int limit = 20,
  }) async {
    final items = _invoices
        .where((i) => i.tenantId == tenantId)
        .take(limit)
        .toList();
    return InvoicePage(items: items, nextCursor: null);
  }

  @override
  Future<Invoice?> getById(String id) async =>
      _invoices.where((i) => i.id == id).firstOrNull;

  @override
  Future<List<InvoiceItem>> itemsForInvoice(String invoiceId) async => [];
}

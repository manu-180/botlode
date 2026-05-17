// lib/features/billing/domain/repositories/invoices_repository.dart

import 'package:botslode/features/billing/domain/models/invoice_page.dart';

import 'package:botslode/features/billing/domain/models/invoice.dart';

abstract class InvoicesRepository {
  /// Returns a page of invoices for [tenantId] ordered by date descending.
  Future<InvoicePage> listForTenant(String tenantId, {int limit = 20});

  /// Returns a single invoice by [id], or null if not found.
  Future<Invoice?> getById(String id);
}

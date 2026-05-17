// lib/features/billing/domain/models/invoice_page.dart

import 'package:botslode/features/billing/domain/models/invoice.dart';

class InvoicePage {
  final List<Invoice> items;
  final bool hasMore;
  final String? nextCursor;

  const InvoicePage({
    required this.items,
    this.hasMore = false,
    this.nextCursor,
  });

  const InvoicePage.empty()
      : items = const [],
        hasMore = false,
        nextCursor = null;
}

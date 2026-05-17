// lib/features/billing/data/repositories/invoices_repository_impl.dart

import 'package:botslode/features/billing/domain/models/invoice.dart';
import 'package:botslode/features/billing/domain/models/invoice_page.dart';
import 'package:botslode/features/billing/domain/repositories/invoices_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InvoicesRepositoryImpl implements InvoicesRepository {
  final SupabaseClient _supabase;

  InvoicesRepositoryImpl(this._supabase);

  @override
  Future<InvoicePage> listForTenant(String tenantId, {int limit = 20}) async {
    final data = await _supabase
        .from('invoices')
        .select()
        .eq('tenant_id', tenantId)
        .order('created_at', ascending: false)
        .limit(limit + 1);

    final rows = data as List;
    final hasMore = rows.length > limit;
    final items = rows
        .take(limit)
        .map((m) => Invoice.fromMap(m as Map<String, dynamic>))
        .toList();

    return InvoicePage(items: items, hasMore: hasMore);
  }

  @override
  Future<Invoice?> getById(String id) async {
    final data = await _supabase
        .from('invoices')
        .select()
        .eq('id', id)
        .maybeSingle();

    return data != null ? Invoice.fromMap(data) : null;
  }
}

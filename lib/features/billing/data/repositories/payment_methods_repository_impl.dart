// lib/features/billing/data/repositories/payment_methods_repository_impl.dart

import 'package:botslode/features/billing/domain/models/payment_method.dart';
import 'package:botslode/features/billing/domain/repositories/payment_methods_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentMethodsRepositoryImpl implements PaymentMethodsRepository {
  final SupabaseClient _supabase;

  PaymentMethodsRepositoryImpl(this._supabase);

  @override
  Future<List<PaymentMethod>> listForTenant(String tenantId) async {
    final data = await _supabase
        .from('payment_methods')
        .select()
        .eq('tenant_id', tenantId)
        .eq('deleted', false)
        .order('created_at', ascending: true);

    return (data as List)
        .map((m) => PaymentMethod.fromMap(m as Map<String, dynamic>))
        .toList();
  }
}

// lib/features/billing/data/repositories/subscriptions_repository_impl.dart

import 'package:botslode/features/billing/domain/models/subscription.dart';
import 'package:botslode/features/billing/domain/repositories/subscriptions_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionsRepositoryImpl implements SubscriptionsRepository {
  final SupabaseClient _supabase;

  SubscriptionsRepositoryImpl(this._supabase);

  @override
  Future<Subscription?> getActiveForTenant(String tenantId) async {
    final data = await _supabase
        .from('subscriptions')
        .select()
        .eq('tenant_id', tenantId)
        .inFilter('status', ['active', 'trialing', 'past_due'])
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return data != null ? Subscription.fromMap(data) : null;
  }

  @override
  Stream<Subscription?> watchActiveForTenant(String tenantId) {
    return _supabase
        .from('subscriptions')
        .stream(primaryKey: ['id'])
        .eq('tenant_id', tenantId)
        .map((rows) {
          final active = rows.where((r) {
            final s = r['status']?.toString() ?? '';
            return s == 'active' || s == 'trialing' || s == 'past_due';
          });
          return active.isEmpty ? null : Subscription.fromMap(active.first);
        });
  }
}

// lib/features/billing/data/repositories/plans_repository_impl.dart

import 'package:botslode/features/billing/domain/models/plan.dart';
import 'package:botslode/features/billing/domain/repositories/plans_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlansRepositoryImpl implements PlansRepository {
  final SupabaseClient _supabase;

  PlansRepositoryImpl(this._supabase);

  @override
  Future<List<Plan>> listPublic() async {
    final data = await _supabase
        .from('plans')
        .select()
        .eq('is_public', true)
        .order('price_monthly', ascending: true);

    return (data as List).map((m) => Plan.fromMap(m as Map<String, dynamic>)).toList();
  }
}

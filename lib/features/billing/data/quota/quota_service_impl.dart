// lib/features/billing/data/quota/quota_service_impl.dart

import 'package:botslode/features/billing/domain/quota/quota_action.dart';
import 'package:botslode/features/billing/domain/quota/quota_service.dart';
import 'package:botslode/features/billing/domain/repositories/plans_repository.dart';
import 'package:botslode/features/billing/domain/repositories/subscriptions_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuotaServiceImpl implements QuotaService {
  final SupabaseClient client;
  final SubscriptionsRepository subscriptionsRepo;
  final PlansRepository plansRepo;

  QuotaServiceImpl({
    required this.client,
    required this.subscriptionsRepo,
    required this.plansRepo,
  });

  @override
  Future<QuotaResult> check(String tenantId, QuotaAction action) async {
    // Default: allow all actions. Actual enforcement via Edge Functions (T5).
    // `limit: -1` indica ilimitado en el modelo enriquecido de QuotaResult.
    return QuotaResult.allowed(used: 0, limit: -1);
  }
}

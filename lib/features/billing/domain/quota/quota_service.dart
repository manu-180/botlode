// lib/features/billing/domain/quota/quota_service.dart

import 'package:botslode/features/billing/domain/quota/quota_action.dart';

class QuotaResult {
  final bool allow;
  final int? used;
  final int? limit;
  final String? reason;

  const QuotaResult({
    required this.allow,
    this.used,
    this.limit,
    this.reason,
  });

  const QuotaResult.allowed() : allow = true, used = null, limit = null, reason = null;
}

abstract class QuotaService {
  Future<QuotaResult> check(String tenantId, QuotaAction action);
}

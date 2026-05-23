// lib/features/billing/domain/quota/quota_service.dart

import 'package:botslode/features/billing/domain/quota/quota_action.dart';
import 'package:botslode/features/billing/domain/quota/quota_result.dart';

export 'package:botslode/features/billing/domain/quota/quota_result.dart';

abstract class QuotaService {
  Future<QuotaResult> check(String tenantId, QuotaAction action);
}

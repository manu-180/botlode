// lib/features/billing/domain/repositories/subscriptions_repository.dart

import 'package:botslode/features/billing/domain/models/subscription.dart';

abstract class SubscriptionsRepository {
  /// Returns the active subscription for [tenantId], or null if none.
  Future<Subscription?> getActiveForTenant(String tenantId);

  /// Emits the active subscription whenever it changes (realtime).
  Stream<Subscription?> watchActiveForTenant(String tenantId);
}

import 'package:botslode/features/billing/domain/models/subscription.dart';
import 'package:botslode/features/billing/domain/repositories/subscriptions_repository.dart';

class FakeSubscriptionsRepository implements SubscriptionsRepository {
  Subscription? _active;

  FakeSubscriptionsRepository([this._active]);

  void setActive(Subscription? sub) => _active = sub;

  @override
  Future<Subscription?> getActiveForTenant(String tenantId) async => _active;

  @override
  Future<List<Subscription>> listForTenant(String tenantId, {int limit = 20}) async =>
      _active != null ? [_active!] : [];

  @override
  Future<Subscription?> getById(String id) async =>
      _active?.id == id ? _active : null;

  @override
  Stream<Subscription?> watchActiveForTenant(String tenantId) =>
      Stream.value(_active);
}

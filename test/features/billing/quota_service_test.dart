import 'package:flutter_test/flutter_test.dart';
import 'package:botslode/features/billing/domain/models/plan.dart';
import 'package:botslode/features/billing/domain/models/subscription.dart';
import 'package:botslode/features/billing/domain/quota/quota_action.dart';
import 'package:botslode/features/billing/domain/quota/quota_result.dart';
import 'package:botslode/features/billing/domain/quota/quota_service.dart';

import '_fakes/fake_plans_repository.dart';
import '_fakes/fake_subscriptions_repository.dart';

// ---------------------------------------------------------------------------
// Fake QuotaService for testing without SupabaseClient
// ---------------------------------------------------------------------------
/// Fake implementation of [QuotaService] that uses in-memory bot/conversation counts.
class FakeQuotaService implements QuotaService {
  final FakeSubscriptionsRepository _subsRepo;
  final FakePlansRepository _plansRepo;
  final Map<String, int> _botCounts; // tenantId → bot count
  final Map<String, int> _convCounts; // tenantId → conversation count

  static const String _freePlanCode = 'free';

  FakeQuotaService({
    required FakeSubscriptionsRepository subsRepo,
    required FakePlansRepository plansRepo,
    Map<String, int>? botCounts,
    Map<String, int>? convCounts,
  })  : _subsRepo = subsRepo,
        _plansRepo = plansRepo,
        _botCounts = botCounts ?? {},
        _convCounts = convCounts ?? {};

  @override
  Future<QuotaResult> check(String tenantId, QuotaAction action) async {
    final sub = await _subsRepo.getActiveForTenant(tenantId);

    Plan? plan;
    if (sub != null) {
      plan = await _plansRepo.getById(sub.planId);
    }
    plan ??= await _plansRepo.getByCode(_freePlanCode);

    if (plan == null) return QuotaResult.noSubscription();

    switch (action) {
      case QuotaAction.createBot:
        final used = _botCounts[tenantId] ?? 0;
        final limit = plan.maxBots;
        return used >= limit
            ? QuotaResult.exceeded(used: used, limit: limit)
            : QuotaResult.allowed(used: used, limit: limit);

      case QuotaAction.recordConversation:
        final used = _convCounts[tenantId] ?? 0;
        final limit = plan.maxConversations;
        return used >= limit
            ? QuotaResult.exceeded(used: used, limit: limit)
            : QuotaResult.allowed(used: used, limit: limit);
    }
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  Plan makePlan({
    required String id,
    required String code,
    required int maxBots,
    required int maxConversations,
  }) =>
      Plan(
        id: id,
        code: code,
        name: code,
        priceCents: 0,
        currency: 'USD',
        interval: BillingInterval.month,
        maxBots: maxBots,
        maxConversations: maxConversations,
        createdAt: DateTime(2026),
      );

  final freePlan = makePlan(
    id: 'plan-free',
    code: 'free',
    maxBots: 1,
    maxConversations: 100,
  );
  final starterPlan = makePlan(
    id: 'plan-starter',
    code: 'starter',
    maxBots: 5,
    maxConversations: 1000,
  );

  Subscription makeActiveSub(String planId) => Subscription(
        id: 'sub-1',
        tenantId: 'tenant-1',
        planId: planId,
        status: SubscriptionStatus.active,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );

  group('QuotaService', () {
    test('tenant without subscription falls back to free plan limits', () async {
      final subsRepo = FakeSubscriptionsRepository(); // no active sub
      final plansRepo = FakePlansRepository()..addPlan(freePlan);
      final service = FakeQuotaService(
        subsRepo: subsRepo,
        plansRepo: plansRepo,
        botCounts: {'tenant-1': 0},
      );

      final result = await service.check('tenant-1', QuotaAction.createBot);

      expect(result.allow, isTrue);
      expect(result.limit, freePlan.maxBots);
    });

    test('tenant with starter plan, 4 bots → createBot allowed, remaining=1', () async {
      final subsRepo = FakeSubscriptionsRepository(makeActiveSub(starterPlan.id));
      final plansRepo = FakePlansRepository()..addPlan(starterPlan);
      final service = FakeQuotaService(
        subsRepo: subsRepo,
        plansRepo: plansRepo,
        botCounts: {'tenant-1': 4},
      );

      final result = await service.check('tenant-1', QuotaAction.createBot);

      expect(result.allow, isTrue);
      expect(result.used, 4);
      expect(result.remaining, 1);
    });

    test('tenant with starter plan, 5 bots → createBot denied', () async {
      final subsRepo = FakeSubscriptionsRepository(makeActiveSub(starterPlan.id));
      final plansRepo = FakePlansRepository()..addPlan(starterPlan);
      final service = FakeQuotaService(
        subsRepo: subsRepo,
        plansRepo: plansRepo,
        botCounts: {'tenant-1': 5},
      );

      final result = await service.check('tenant-1', QuotaAction.createBot);

      expect(result.allow, isFalse);
      expect(result.reason, 'plan_limit_reached');
      expect(result.remaining, isZero);
    });

    test('tenant with exceeded conversations → recordConversation denied', () async {
      final subsRepo = FakeSubscriptionsRepository(makeActiveSub(starterPlan.id));
      final plansRepo = FakePlansRepository()..addPlan(starterPlan);
      final service = FakeQuotaService(
        subsRepo: subsRepo,
        plansRepo: plansRepo,
        convCounts: {'tenant-1': 1000}, // exactly at limit
      );

      final result = await service.check('tenant-1', QuotaAction.recordConversation);

      expect(result.allow, isFalse);
      expect(result.reason, 'plan_limit_reached');
    });

    test('no subscription and no free plan → noSubscription result', () async {
      final subsRepo = FakeSubscriptionsRepository(); // no sub
      final plansRepo = FakePlansRepository(); // no plans at all
      final service = FakeQuotaService(subsRepo: subsRepo, plansRepo: plansRepo);

      final result = await service.check('tenant-1', QuotaAction.createBot);

      expect(result.allow, isFalse);
      expect(result.reason, 'no_active_subscription');
    });

    test('tenant with free plan, 1 bot → createBot denied (at limit)', () async {
      final subsRepo = FakeSubscriptionsRepository(); // no sub → falls to free
      final plansRepo = FakePlansRepository()..addPlan(freePlan);
      final service = FakeQuotaService(
        subsRepo: subsRepo,
        plansRepo: plansRepo,
        botCounts: {'tenant-1': 1}, // at free limit
      );

      final result = await service.check('tenant-1', QuotaAction.createBot);

      expect(result.allow, isFalse);
      expect(result.limit, freePlan.maxBots);
    });

    test('QuotaResult.remaining is 0 when exceeded', () {
      final result = QuotaResult.exceeded(used: 5, limit: 5);
      expect(result.remaining, isZero);
    });

    test('QuotaResult.remaining computed correctly when allowed', () {
      final result = QuotaResult.allowed(used: 3, limit: 10);
      expect(result.remaining, 7);
    });
  });
}

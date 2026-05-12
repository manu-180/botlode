// Archivo: test/features/billing/presentation/widgets/subscription_summary_card_golden_test.dart
//
// T4·15 — Golden tests for SubscriptionSummaryCard.
//
// Five states rendered at 400×600 with a fixed `now` for deterministic output:
//   1. active          — normal active subscription.
//   2. trialing        — trial with 10 days remaining.
//   3. past_due        — overdue subscription.
//   4. canceled        — canceled subscription.
//   5. cancel_at_end   — active but cancelAtPeriodEnd=true (pending cancellation).
//
// Run once to generate / update the goldens:
//   flutter test --update-goldens \
//     test/features/billing/presentation/widgets/subscription_summary_card_golden_test.dart

import 'dart:async';

import 'package:botslode/features/billing/domain/models/plan.dart';
import 'package:botslode/features/billing/domain/models/subscription.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/providers/billing_state.dart';
import 'package:botslode/features/billing/presentation/widgets/subscription_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

final _kCreatedAt = DateTime.utc(2026, 1, 1);
final _kNow = DateTime.utc(2026, 1, 10);
final _kPeriodEnd = DateTime.utc(2026, 2, 10);
final _kTrialEnd = DateTime.utc(2026, 1, 20); // 10 days from _kNow

final _kPlan = Plan(
  id: 'plan-001',
  code: 'starter',
  name: 'Starter',
  priceCents: 999,
  interval: BillingInterval.month,
  maxBots: 5,
  maxConversations: 100,
  public: true,
  createdAt: _kCreatedAt,
);

Subscription _makeSub({
  SubscriptionStatus status = SubscriptionStatus.active,
  bool cancelAtPeriodEnd = false,
  DateTime? trialEnd,
}) =>
    Subscription(
      id: 'sub-golden',
      tenantId: 'tenant-golden',
      planId: 'plan-001',
      status: status,
      currentPeriodEnd: _kPeriodEnd,
      cancelAtPeriodEnd: cancelAtPeriodEnd,
      trialEnd: trialEnd,
      createdAt: _kCreatedAt,
      updatedAt: _kCreatedAt,
    );

// ---------------------------------------------------------------------------
// Stub notifiers
// ---------------------------------------------------------------------------

class _StubBillingV2 extends BillingV2 {
  _StubBillingV2(this._state);
  final BillingV2State _state;

  @override
  Future<BillingV2State> build() async => _state;
}

class _LoadingBillingV2 extends BillingV2 {
  @override
  FutureOr<BillingV2State> build() async {
    await Completer<void>().future;
    return const BillingV2State();
  }
}

// ---------------------------------------------------------------------------
// Pump helper
// ---------------------------------------------------------------------------

Future<void> _pumpCard(
  WidgetTester tester,
  BillingV2State state, {
  bool loading = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        billingV2Provider.overrideWith(
          loading ? _LoadingBillingV2.new : () => _StubBillingV2(state),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(400, 600)),
          child: Scaffold(
            backgroundColor: const Color(0xFF050A10),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: SubscriptionSummaryCard(
                now: _kNow,
                onChangePlan: () {},
                onCancel: () {},
                onReactivate: () {},
                onUpdatePayment: () {},
                onCompletePayment: () {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Golden tests
// ---------------------------------------------------------------------------

void main() {
  group('SubscriptionSummaryCard — golden', () {
    // -----------------------------------------------------------------------
    // 1. Active
    // -----------------------------------------------------------------------
    testWidgets('active', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpCard(
        tester,
        BillingV2State(
          subscription: _makeSub(),
          availablePlans: [_kPlan],
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(SubscriptionSummaryCard),
        matchesGoldenFile('goldens/subscription_summary_card_active.png'),
      );
    });

    // -----------------------------------------------------------------------
    // 2. Trialing
    // -----------------------------------------------------------------------
    testWidgets('trialing', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpCard(
        tester,
        BillingV2State(
          subscription: _makeSub(
            status: SubscriptionStatus.trialing,
            trialEnd: _kTrialEnd,
          ),
          availablePlans: [_kPlan],
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(SubscriptionSummaryCard),
        matchesGoldenFile('goldens/subscription_summary_card_trialing.png'),
      );
    });

    // -----------------------------------------------------------------------
    // 3. Past due
    // -----------------------------------------------------------------------
    testWidgets('past_due', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpCard(
        tester,
        BillingV2State(
          subscription: _makeSub(status: SubscriptionStatus.pastDue),
          availablePlans: [_kPlan],
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(SubscriptionSummaryCard),
        matchesGoldenFile('goldens/subscription_summary_card_past_due.png'),
      );
    });

    // -----------------------------------------------------------------------
    // 4. Canceled
    // -----------------------------------------------------------------------
    testWidgets('canceled', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpCard(
        tester,
        BillingV2State(
          subscription: _makeSub(status: SubscriptionStatus.canceled),
          availablePlans: [_kPlan],
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(SubscriptionSummaryCard),
        matchesGoldenFile('goldens/subscription_summary_card_canceled.png'),
      );
    });

    // -----------------------------------------------------------------------
    // 5. Active — cancelAtPeriodEnd=true
    // -----------------------------------------------------------------------
    testWidgets('cancel_at_end', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpCard(
        tester,
        BillingV2State(
          subscription: _makeSub(cancelAtPeriodEnd: true),
          availablePlans: [_kPlan],
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(SubscriptionSummaryCard),
        matchesGoldenFile(
            'goldens/subscription_summary_card_cancel_at_end.png'),
      );
    });
  });
}

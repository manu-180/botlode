// Archivo: test/features/billing/presentation/widgets/plan_picker_golden_test.dart
//
// T4·04 — Golden tests for PlanPicker.
//
// Strategy:
//   - Overrides billingV2Provider with lightweight stubs; no real Supabase
//     calls are made.
//   - Fixed surface size of 400×800 to simulate a mobile viewport so goldens
//     are deterministic across machines.
//   - Three scenarios: loading spinner, plans with an active subscription, and
//     plans with no subscription.
//
// Run once to generate / update the goldens:
//   flutter test --update-goldens \
//     test/features/billing/presentation/widgets/plan_picker_golden_test.dart

import 'dart:async';

import 'package:botslode/features/billing/domain/models/plan.dart';
import 'package:botslode/features/billing/domain/models/subscription.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/providers/billing_state.dart';
import 'package:botslode/features/billing/presentation/widgets/plan_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Stub notifiers
// ---------------------------------------------------------------------------

/// Returns a pre-defined [BillingV2State] immediately, skipping all
/// repository / Supabase calls.
class _StubBillingV2 extends BillingV2 {
  _StubBillingV2(this._state);

  final BillingV2State _state;

  @override
  Future<BillingV2State> build() async => _state;
}

/// Never resolves — keeps [billingV2Provider] in the loading state
/// indefinitely so the spinner can be captured.
class _LoadingBillingV2 extends BillingV2 {
  @override
  FutureOr<BillingV2State> build() async {
    await Completer<void>().future; // never completes
    return const BillingV2State();
  }
}

// ---------------------------------------------------------------------------
// Fixture helpers
// ---------------------------------------------------------------------------

final _kCreatedAt = DateTime.utc(2026, 1, 1);

Plan _makePlan({
  required String id,
  required String code,
  required String name,
  required int priceCents,
  Map<String, dynamic> features = const {},
}) =>
    Plan(
      id: id,
      code: code,
      name: name,
      priceCents: priceCents,
      interval: BillingInterval.month,
      maxBots: 5,
      maxConversations: 100,
      features: features,
      public: true,
      createdAt: _kCreatedAt,
    );

Subscription _makeSub(String planId) => Subscription(
      id: 'sub-golden',
      tenantId: 'tenant-golden',
      planId: planId,
      status: SubscriptionStatus.active,
      createdAt: _kCreatedAt,
      updatedAt: _kCreatedAt,
    );

// ---------------------------------------------------------------------------
// Helper: pump the widget under test
// ---------------------------------------------------------------------------

Future<void> _pumpPicker(
  WidgetTester tester, {
  required BillingV2 Function() notifierFactory,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        billingV2Provider.overrideWith(notifierFactory),
      ],
      child: MaterialApp(
        theme: ThemeData(useMaterial3: true),
        // Explicitly override MediaQuery so the widget always sees 400px
        // logical width regardless of the test binding's device pixel ratio.
        // This guarantees single-column layout (crossAxisCount=1) and avoids
        // GridView fixed-height constraints during golden capture.
        home: MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: PlanPicker(
                onPlanSelected: (_) {},
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
  group('PlanPicker — golden', () {
    // -----------------------------------------------------------------------
    // 1. Loading state
    // -----------------------------------------------------------------------
    testWidgets('loading state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpPicker(
        tester,
        notifierFactory: _LoadingBillingV2.new,
      );

      // Pump exactly one frame so the async build has started but the
      // Completer never resolves — provider stays in AsyncLoading.
      await tester.pump();

      await expectLater(
        find.byType(PlanPicker),
        matchesGoldenFile('goldens/plan_picker_loading.png'),
      );
    });

    // -----------------------------------------------------------------------
    // 2. With current plan (3 monthly plans; middle plan is active)
    // -----------------------------------------------------------------------
    testWidgets('with current plan', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final starter = _makePlan(
        id: 'plan-s',
        code: 'starter',
        name: 'Starter',
        priceCents: 900,
      );
      final starterPro = _makePlan(
        id: 'plan-sp',
        code: 'starter-pro',
        name: 'Starter Pro',
        priceCents: 2900,
        features: const {
          'feature_1': 'Soporte prioritario',
          'feature_2': 'Analíticas avanzadas',
        },
      );
      final enterprise = _makePlan(
        id: 'plan-e',
        code: 'enterprise',
        name: 'Enterprise',
        priceCents: 9900,
      );

      final state = BillingV2State(
        availablePlans: [starter, starterPro, enterprise],
        subscription: _makeSub('plan-sp'),
      );

      await _pumpPicker(
        tester,
        notifierFactory: () => _StubBillingV2(state),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(PlanPicker),
        matchesGoldenFile('goldens/plan_picker_with_current_plan.png'),
      );
    });

    // -----------------------------------------------------------------------
    // 3. No subscription (2 monthly plans, no active sub)
    // -----------------------------------------------------------------------
    testWidgets('no subscription', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final starter = _makePlan(
        id: 'plan-s',
        code: 'starter',
        name: 'Starter',
        priceCents: 900,
      );
      final pro = _makePlan(
        id: 'plan-p',
        code: 'pro',
        name: 'Pro',
        priceCents: 2900,
      );

      final state = BillingV2State(
        availablePlans: [starter, pro],
        subscription: null,
      );

      await _pumpPicker(
        tester,
        notifierFactory: () => _StubBillingV2(state),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(PlanPicker),
        matchesGoldenFile('goldens/plan_picker_no_subscription.png'),
      );
    });
  });
}

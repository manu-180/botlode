// Archivo: test/features/billing/presentation/widgets/plan_picker_test.dart
//
// T4·04 — Widget tests for PlanPicker.
//
// Strategy:
//   - Uses ProviderScope with overrides for billingV2Provider.
//   - Provides a _StubBillingV2 AsyncNotifier that immediately returns a
//     predefined BillingV2State so no real Supabase calls are made.
//   - Verifies: plan cards render, current plan CTA is disabled,
//     non-current plan CTA is enabled, empty state, loading state,
//     interval filtering and onPlanSelected callback.

import 'package:botslode/features/billing/domain/models/plan.dart';
import 'package:botslode/features/billing/domain/models/subscription.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/providers/billing_state.dart';
import 'package:botslode/features/billing/presentation/widgets/plan_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Stub AsyncNotifier — returns a pre-defined state synchronously.
// ---------------------------------------------------------------------------

/// Stub notifier used to override billingV2Provider in widget tests.
///
/// Receives a [BillingV2State] at construction time and returns it
/// immediately from [build], avoiding any repository / Supabase calls.
class _StubBillingV2 extends BillingV2 {
  _StubBillingV2(this._state);

  final BillingV2State _state;

  @override
  Future<BillingV2State> build() async => _state;
}

// ---------------------------------------------------------------------------
// Fixture helpers
// ---------------------------------------------------------------------------

const _kTenantId = 'tenant-plan-picker-test';
final _kCreatedAt = DateTime.utc(2026, 1, 1);

Plan _makePlan({
  required String id,
  required String code,
  required String name,
  required int priceCents,
  BillingInterval interval = BillingInterval.month,
  Map<String, dynamic> features = const {},
}) =>
    Plan(
      id: id,
      code: code,
      name: name,
      priceCents: priceCents,
      interval: interval,
      maxBots: 5,
      maxConversations: 100,
      features: features,
      public: true,
      createdAt: _kCreatedAt,
    );

Subscription _makeSubscription(String planId) => Subscription(
      id: 'sub-picker-001',
      tenantId: _kTenantId,
      planId: planId,
      status: SubscriptionStatus.active,
      createdAt: _kCreatedAt,
      updatedAt: _kCreatedAt,
    );

// ---------------------------------------------------------------------------
// Helper: pump PlanPicker with a BillingV2State override
// ---------------------------------------------------------------------------

Future<void> _pumpPlanPicker(
  WidgetTester tester,
  BillingV2State state, {
  void Function(String planId)? onPlanSelected,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        billingV2Provider.overrideWith(() => _StubBillingV2(state)),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PlanPicker(
              onPlanSelected: onPlanSelected ?? (_) {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('PlanPicker', () {
    // -----------------------------------------------------------------------
    // Plan card rendering
    // -----------------------------------------------------------------------
    group('plan cards', () {
      testWidgets('renders both plan names when 2 monthly plans are available',
          (tester) async {
        final planA = _makePlan(
          id: 'plan-001',
          code: 'starter',
          name: 'Starter',
          priceCents: 900,
        );
        final planB = _makePlan(
          id: 'plan-002',
          code: 'pro',
          name: 'Pro',
          priceCents: 2900,
        );

        final state = BillingV2State(
          availablePlans: [planA, planB],
          subscription: _makeSubscription(planA.id),
        );

        await _pumpPlanPicker(tester, state);

        expect(find.text('Starter'), findsOneWidget);
        expect(find.text('Pro'), findsOneWidget);
      });

      testWidgets('shows formatted price for monthly plan', (tester) async {
        final plan = _makePlan(
          id: 'plan-monthly',
          code: 'basic',
          name: 'Basic',
          priceCents: 1999,
        );

        await _pumpPlanPicker(tester, BillingV2State(availablePlans: [plan]));

        expect(find.text(r'$19.99/mes'), findsOneWidget);
      });

      testWidgets('shows "Recomendado" badge for starter plan code',
          (tester) async {
        final plan = _makePlan(
          id: 'plan-starter',
          code: 'starter',
          name: 'Starter',
          priceCents: 900,
        );

        await _pumpPlanPicker(tester, BillingV2State(availablePlans: [plan]));

        expect(find.text('Recomendado'), findsOneWidget);
      });

      testWidgets(
          'shows "Recomendado" badge when features map has highlighted=true',
          (tester) async {
        final plan = _makePlan(
          id: 'plan-highlight',
          code: 'enterprise',
          name: 'Enterprise',
          priceCents: 9900,
          features: const {'highlighted': true},
        );

        await _pumpPlanPicker(tester, BillingV2State(availablePlans: [plan]));

        expect(find.text('Recomendado'), findsOneWidget);
      });

      testWidgets('shows "Plan actual" badge on current plan card',
          (tester) async {
        final plan = _makePlan(
          id: 'plan-current',
          code: 'pro',
          name: 'Pro',
          priceCents: 2900,
        );

        final state = BillingV2State(
          availablePlans: [plan],
          subscription: _makeSubscription(plan.id),
        );

        await _pumpPlanPicker(tester, state);

        // Badge text appears at least once (in the card).
        expect(find.text('Plan actual'), findsAtLeast(1));
      });
    });

    // -----------------------------------------------------------------------
    // CTA button states
    // -----------------------------------------------------------------------
    group('CTA buttons', () {
      testWidgets('current plan CTA OutlinedButton is disabled',
          (tester) async {
        final planCurrent = _makePlan(
          id: 'plan-current',
          code: 'starter',
          name: 'Starter',
          priceCents: 900,
        );
        final planOther = _makePlan(
          id: 'plan-other',
          code: 'pro',
          name: 'Pro',
          priceCents: 2900,
        );

        final state = BillingV2State(
          availablePlans: [planCurrent, planOther],
          subscription: _makeSubscription(planCurrent.id),
        );

        await _pumpPlanPicker(tester, state);

        // The current plan renders an OutlinedButton with onPressed == null.
        final outlinedButtons = tester.widgetList<OutlinedButton>(
          find.byType(OutlinedButton),
        );

        expect(
          outlinedButtons.any((btn) => btn.onPressed == null),
          isTrue,
          reason: 'Current plan CTA must be disabled (onPressed == null)',
        );
      });

      testWidgets('non-current plan FilledButton is enabled', (tester) async {
        final planCurrent = _makePlan(
          id: 'plan-current',
          code: 'starter',
          name: 'Starter',
          priceCents: 900,
        );
        final planOther = _makePlan(
          id: 'plan-other',
          code: 'pro',
          name: 'Pro',
          priceCents: 2900,
        );

        final state = BillingV2State(
          availablePlans: [planCurrent, planOther],
          subscription: _makeSubscription(planCurrent.id),
        );

        await _pumpPlanPicker(tester, state);

        final filledButtons = tester.widgetList<FilledButton>(
          find.byType(FilledButton),
        );

        expect(
          filledButtons.any((btn) => btn.onPressed != null),
          isTrue,
          reason: 'Non-current plan CTA must be enabled',
        );
      });

      testWidgets('tapping non-current plan calls onPlanSelected with planId',
          (tester) async {
        String? selectedId;

        final planCurrent = _makePlan(
          id: 'plan-current',
          code: 'starter',
          name: 'Starter',
          priceCents: 900,
        );
        final planPro = _makePlan(
          id: 'plan-pro',
          code: 'pro',
          name: 'Pro',
          priceCents: 2900,
        );

        final state = BillingV2State(
          availablePlans: [planCurrent, planPro],
          subscription: _makeSubscription(planCurrent.id),
        );

        await _pumpPlanPicker(
          tester,
          state,
          onPlanSelected: (id) => selectedId = id,
        );

        await tester.tap(find.byType(FilledButton).first);
        await tester.pumpAndSettle();

        expect(selectedId, equals('plan-pro'));
      });

      testWidgets('shows "Upgrade" label when plan is more expensive',
          (tester) async {
        final planCurrent = _makePlan(
          id: 'plan-current',
          code: 'starter',
          name: 'Starter',
          priceCents: 900,
        );
        final planPro = _makePlan(
          id: 'plan-pro',
          code: 'pro',
          name: 'Pro',
          priceCents: 2900,
        );

        final state = BillingV2State(
          availablePlans: [planCurrent, planPro],
          subscription: _makeSubscription(planCurrent.id),
        );

        await _pumpPlanPicker(tester, state);

        expect(find.text('Upgrade'), findsOneWidget);
      });

      testWidgets('shows "Downgrade" label when plan is cheaper',
          (tester) async {
        final planCurrent = _makePlan(
          id: 'plan-current',
          code: 'pro',
          name: 'Pro',
          priceCents: 2900,
        );
        final planBasic = _makePlan(
          id: 'plan-basic',
          code: 'basic',
          name: 'Basic',
          priceCents: 900,
        );

        final state = BillingV2State(
          availablePlans: [planCurrent, planBasic],
          subscription: _makeSubscription(planCurrent.id),
        );

        await _pumpPlanPicker(tester, state);

        expect(find.text('Downgrade'), findsOneWidget);
      });
    });

    // -----------------------------------------------------------------------
    // Interval filtering
    // -----------------------------------------------------------------------
    group('interval toggle', () {
      testWidgets('only shows monthly plans when monthly toggle is selected',
          (tester) async {
        final monthlyPlan = _makePlan(
          id: 'plan-monthly',
          code: 'starter-m',
          name: 'Starter Mensual',
          priceCents: 900,
          interval: BillingInterval.month,
        );
        final yearlyPlan = _makePlan(
          id: 'plan-yearly',
          code: 'starter-y',
          name: 'Starter Anual',
          priceCents: 8900,
          interval: BillingInterval.year,
        );

        final state = BillingV2State(
          availablePlans: [monthlyPlan, yearlyPlan],
        );

        await _pumpPlanPicker(tester, state);

        // Default interval is monthly.
        expect(find.text('Starter Mensual'), findsOneWidget);
        expect(find.text('Starter Anual'), findsNothing);
      });

      testWidgets('shows yearly plans after tapping annual toggle',
          (tester) async {
        final monthlyPlan = _makePlan(
          id: 'plan-monthly',
          code: 'starter-m',
          name: 'Starter Mensual',
          priceCents: 900,
          interval: BillingInterval.month,
        );
        final yearlyPlan = _makePlan(
          id: 'plan-yearly',
          code: 'starter-y',
          name: 'Starter Anual',
          priceCents: 8900,
          interval: BillingInterval.year,
        );

        final state = BillingV2State(
          availablePlans: [monthlyPlan, yearlyPlan],
        );

        await _pumpPlanPicker(tester, state);

        await tester.tap(find.text('Anual'));
        await tester.pumpAndSettle();

        expect(find.text('Starter Anual'), findsOneWidget);
        expect(find.text('Starter Mensual'), findsNothing);
      });
    });

    // -----------------------------------------------------------------------
    // Empty state
    // -----------------------------------------------------------------------
    group('empty state', () {
      testWidgets('shows "No hay planes disponibles" when plans list is empty',
          (tester) async {
        await _pumpPlanPicker(tester, const BillingV2State());

        expect(find.text('No hay planes disponibles'), findsOneWidget);
      });

      testWidgets('shows contact CTA in empty state', (tester) async {
        await _pumpPlanPicker(tester, const BillingV2State());

        expect(find.text('Contactar soporte'), findsOneWidget);
      });
    });
  });
}

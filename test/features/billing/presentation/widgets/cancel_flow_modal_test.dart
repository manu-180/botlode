// Archivo: test/features/billing/presentation/widgets/cancel_flow_modal_test.dart
//
// T4·16 — Widget tests for CancelFlowModal.
//
// Strategy:
//   - Uses ProviderScope with overrides for billingV2Provider.
//   - _StubBillingV2 returns an active subscription and completes cancelSubscription
//     without throwing (success path).
//   - Tests drive the real production widget via the public showCancelFlowModal
//     entry point, wrapping a ConsumerWidget trigger inside a ProviderScope.
//   - Tests cover: step-1 render, radio enables Continuar, step-2 consequences,
//     success snackbar, and "Mantener" closes modal.

import 'package:botslode/features/billing/domain/models/subscription.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/providers/billing_state.dart';
import 'package:botslode/features/billing/presentation/widgets/cancel_flow_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fixture constants
// ---------------------------------------------------------------------------

const _kTenantId = 'tenant-cancel-test';
final _kNow = DateTime.utc(2026, 5, 12);
final _kPeriodEnd = DateTime.utc(2026, 6, 30);

final _kSubscription = Subscription(
  id: 'sub-cancel-001',
  tenantId: _kTenantId,
  planId: 'plan-starter-001',
  status: SubscriptionStatus.active,
  currentPeriodStart: _kNow,
  currentPeriodEnd: _kPeriodEnd,
  createdAt: _kNow,
  updatedAt: _kNow,
);

// ---------------------------------------------------------------------------
// Stub BillingV2 notifier — success path
// ---------------------------------------------------------------------------

/// Overrides [BillingV2] so no Supabase calls are made.
///
/// - [build] returns a state with an active subscription.
/// - [cancelSubscription] completes without throwing (success path).
class _StubBillingV2 extends BillingV2 {
  @override
  Future<BillingV2State> build() async {
    return BillingV2State(subscription: _kSubscription);
  }

  @override
  Future<void> cancelSubscription({String? reason}) async {
    // Success: does nothing, no exception thrown.
  }
}

// ---------------------------------------------------------------------------
// Pump helper
// ---------------------------------------------------------------------------

/// Pumps the app, opens the cancel flow modal via a trigger button that calls
/// [showCancelFlowModal] — the real public entry point — and waits for the
/// modal to settle.
///
/// The trigger is a [ConsumerWidget] so it has a [WidgetRef] to pass to
/// [showCancelFlowModal]. The [ProviderScope] container is shared with the
/// modal via [UncontrolledProviderScope] inside [showCancelFlowModal] itself.
Future<void> _pumpModal(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        billingV2Provider.overrideWith(() => _StubBillingV2()),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: _OpenModalButton(),
        ),
      ),
    ),
  );

  // Allow the async billingV2Provider to resolve before opening the modal,
  // so that ref.read inside the production widget sees the loaded state.
  await tester.pumpAndSettle();

  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

/// A [ConsumerWidget] trigger that calls [showCancelFlowModal] when tapped.
/// Defined at top level (not inline) to ensure a stable widget type across
/// pumps and to give [showCancelFlowModal] the required [WidgetRef].
class _OpenModalButton extends ConsumerWidget {
  const _OpenModalButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () => showCancelFlowModal(context, ref),
      child: const Text('Open'),
    );
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('CancelFlowModal', () {
    // -------------------------------------------------------------------------
    // Test 1 — Step 1 renders correctly
    // -------------------------------------------------------------------------
    testWidgets('step 1 renders with "Mantener mi suscripción" visible and '
        '"Continuar" disabled before selecting a reason', (tester) async {
      await _pumpModal(tester);

      // "Mantener mi suscripción" text button must be visible
      expect(
        find.text('Mantener mi suscripción'),
        findsOneWidget,
        reason: 'Keep-subscription button must be visible in step 1',
      );

      // "Continuar" button must exist but be disabled (onPressed == null)
      final continuar =
          tester.widget<FilledButton>(find.byKey(const Key('continuar_btn')));
      expect(
        continuar.onPressed,
        isNull,
        reason: 'Continuar must be disabled before selecting a reason',
      );
    });

    // -------------------------------------------------------------------------
    // Test 2 — Selecting a radio enables Continuar
    // -------------------------------------------------------------------------
    testWidgets('tapping "Muy caro" radio enables "Continuar"', (tester) async {
      await _pumpModal(tester);

      // Tap the "Muy caro" radio tile via its key added in production widget
      await tester.tap(find.byKey(const ValueKey('radio_Muy caro')));
      await tester.pump();

      final continuar =
          tester.widget<FilledButton>(find.byKey(const Key('continuar_btn')));
      expect(
        continuar.onPressed,
        isNotNull,
        reason: 'Continuar must be enabled after selecting a reason',
      );
    });

    // -------------------------------------------------------------------------
    // Test 3 — Cannot skip to step 2 without selecting a reason
    // -------------------------------------------------------------------------
    testWidgets(
        'Continuar is disabled before any radio is selected (acceptance criterion)',
        (tester) async {
      await _pumpModal(tester);

      // Verify step 2 is not visible yet
      expect(find.text('Confirmá la cancelación'), findsNothing,
          reason: 'Step 2 must not appear before a reason is selected');

      // Continuar disabled
      final continuar =
          tester.widget<FilledButton>(find.byKey(const Key('continuar_btn')));
      expect(continuar.onPressed, isNull,
          reason: 'Continuar must be disabled — user cannot skip to step 2');
    });

    // -------------------------------------------------------------------------
    // Test 4 — Step 2 shows consequences including the date
    // -------------------------------------------------------------------------
    testWidgets('step 2 shows all 3 consequence texts with date "30/06/2026"',
        (tester) async {
      await _pumpModal(tester);

      // Select a reason
      await tester.tap(find.byKey(const ValueKey('radio_Muy caro')));
      await tester.pump();

      // Navigate to step 2
      await tester.tap(find.byKey(const Key('continuar_btn')));
      await tester.pumpAndSettle();

      expect(find.textContaining('30/06/2026'), findsOneWidget,
          reason: 'Period-end date must appear in step 2');
      expect(
          find.text('Las conversaciones acumuladas se conservan'), findsOneWidget,
          reason: 'Second bullet must be visible');
      expect(
          find.text(
              'Podés reactivar en cualquier momento antes de esa fecha'),
          findsOneWidget,
          reason: 'Third bullet must be visible');
    });

    // -------------------------------------------------------------------------
    // Test 5 — Success path: snackbar appears after confirmation
    // -------------------------------------------------------------------------
    testWidgets(
        'tapping "Confirmar cancelación" shows success snackbar with date',
        (tester) async {
      await _pumpModal(tester);

      // Select reason and go to step 2
      await tester.tap(find.byKey(const ValueKey('radio_Muy caro')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('continuar_btn')));
      await tester.pumpAndSettle();

      // Tap confirm cancel
      await tester.tap(find.byKey(const Key('confirmar_cancel_btn')));
      await tester.pumpAndSettle();

      expect(
        find.text('Suscripción cancelada — activa hasta 30/06/2026'),
        findsOneWidget,
        reason: 'Success snackbar with period-end date must appear',
      );
    });

    // -------------------------------------------------------------------------
    // Test 6 — "Mantener mi suscripción" in step 2 closes modal
    // -------------------------------------------------------------------------
    testWidgets(
        '"Mantener mi suscripción" in step 2 dismisses the modal',
        (tester) async {
      await _pumpModal(tester);

      // Select reason and go to step 2
      await tester.tap(find.byKey(const ValueKey('radio_Muy caro')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('continuar_btn')));
      await tester.pumpAndSettle();

      // Tap the keep-subscription button in step 2
      await tester.tap(find.byKey(const Key('mantener_btn')));
      await tester.pumpAndSettle();

      // Modal should be dismissed — step 2 title no longer visible
      expect(find.text('Confirmá la cancelación'), findsNothing,
          reason: 'Modal must be dismissed after tapping Mantener in step 2');
    });
  });
}

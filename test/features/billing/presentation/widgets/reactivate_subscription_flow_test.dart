// Archivo: test/features/billing/presentation/widgets/reactivate_subscription_flow_test.dart
//
// T4·17 — Widget tests for showReactivateFlow.
//
// Strategy:
//   - Override billingV2Provider; no Supabase calls.
//   - Drive the production widget via the public showReactivateFlow entry point.
//   - Test 1 (success): state has default PM → tap Reactivar → snackbar shown.
//   - Test 2 (falta método): no default PM → blocked dialog with "Agregar método".

import 'package:botslode/features/billing/domain/models/payment_method.dart';
import 'package:botslode/features/billing/domain/models/subscription.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/providers/billing_state.dart';
import 'package:botslode/features/billing/presentation/widgets/reactivate_subscription_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

final _kNow = DateTime.utc(2026, 5, 12);
final _kPeriodEnd = DateTime.utc(2026, 6, 30);

final _kSubscription = Subscription(
  id: 'sub-react-001',
  tenantId: 'tenant-test',
  planId: 'plan-starter',
  status: SubscriptionStatus.active,
  currentPeriodStart: _kNow,
  currentPeriodEnd: _kPeriodEnd,
  cancelAtPeriodEnd: true,
  createdAt: _kNow,
  updatedAt: _kNow,
);

final _kDefaultPm = PaymentMethod(
  id: 'pm-001',
  tenantId: 'tenant-test',
  gateway: PaymentGateway.stripe,
  gatewayToken: 'tok_test',
  brand: 'visa',
  last4: '4242',
  expMonth: 12,
  expYear: 2027,
  isDefault: true,
  createdAt: _kNow,
);

// ---------------------------------------------------------------------------
// Stub notifiers
// ---------------------------------------------------------------------------

/// Success path: subscription with default PM; reactivation completes without error.
class _SuccessStub extends BillingV2 {
  @override
  Future<BillingV2State> build() async => BillingV2State(
        subscription: _kSubscription,
        paymentMethods: [_kDefaultPm],
        defaultPaymentMethodId: _kDefaultPm.id,
      );

  @override
  Future<void> reactivateSubscription() async {}
}

/// No payment method path: subscription exists but no payment methods registered.
class _NoPaymentStub extends BillingV2 {
  @override
  Future<BillingV2State> build() async => BillingV2State(
        subscription: _kSubscription,
      );
}

// ---------------------------------------------------------------------------
// Pump helper
// ---------------------------------------------------------------------------

Future<void> _pumpModal(
  WidgetTester tester, {
  required BillingV2 stub,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [billingV2Provider.overrideWith(() => stub)],
      child: const MaterialApp(
        home: Scaffold(body: _OpenButton()),
      ),
    ),
  );

  // Let the async provider resolve before opening the modal.
  await tester.pumpAndSettle();

  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

/// Trigger widget that calls [showReactivateFlow] when tapped.
class _OpenButton extends ConsumerWidget {
  const _OpenButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () => showReactivateFlow(context, ref),
      child: const Text('Open'),
    );
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('showReactivateFlow', () {
    testWidgets(
      'success — tap Reactivar calls reactivateSubscription and shows snackbar',
      (tester) async {
        await _pumpModal(tester, stub: _SuccessStub());

        expect(find.text('Reactivar suscripción'), findsOneWidget);
        expect(find.byKey(const Key('reactivar_btn')), findsOneWidget);

        await tester.tap(find.byKey(const Key('reactivar_btn')));
        await tester.pumpAndSettle();

        expect(find.text('Suscripción reactivada con éxito.'), findsOneWidget);
        // Dialog must be dismissed after success.
        expect(find.text('Reactivar suscripción'), findsNothing);
      },
    );

    testWidgets(
      'falta método — shows blocked dialog with "Agregar método" button '
      'and no Reactivar button',
      (tester) async {
        await _pumpModal(tester, stub: _NoPaymentStub());

        expect(find.text('Método de pago requerido'), findsOneWidget);
        expect(
          find.text(
            'Necesitás agregar un método de pago antes de reactivar tu suscripción.',
          ),
          findsOneWidget,
        );
        expect(find.byKey(const Key('agregar_metodo_btn')), findsOneWidget);
        // Confirm dialog must not be rendered when no PM.
        expect(find.byKey(const Key('reactivar_btn')), findsNothing);
      },
    );
  });
}

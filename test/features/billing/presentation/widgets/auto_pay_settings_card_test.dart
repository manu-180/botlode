// Archivo: test/features/billing/presentation/widgets/auto_pay_settings_card_test.dart
//
// T4·11 — Widget tests for AutoPaySettingsCard.
//
// Strategy:
//   - Override billingV2Provider with stub/tracking notifiers; no Supabase calls.
//   - Covered paths:
//     · No subscription → widget hidden.
//     · With subscription + default PM → switch enabled, shows card info.
//     · No default PM → switch disabled, shows warning message.
//     · Toggle ON (cancelAtPeriodEnd=true) → calls reactivateSubscription.
//     · Toggle OFF (cancelAtPeriodEnd=false) → calls cancelSubscription.
//     · Mutation error → SnackBar shown, UI reverts.

import 'package:botslode/features/billing/domain/models/payment_method.dart';
import 'package:botslode/features/billing/domain/models/subscription.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/providers/billing_state.dart';
import 'package:botslode/features/billing/presentation/widgets/auto_pay_settings_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

final _kCreatedAt = DateTime.utc(2026, 1, 1);
final _kPeriodEnd = DateTime.utc(2026, 2, 1);

Subscription _makeSub({bool cancelAtPeriodEnd = false}) => Subscription(
      id: 'sub-001',
      tenantId: 'tenant-test',
      planId: 'plan-starter',
      status: SubscriptionStatus.active,
      currentPeriodEnd: _kPeriodEnd,
      cancelAtPeriodEnd: cancelAtPeriodEnd,
      createdAt: _kCreatedAt,
      updatedAt: _kCreatedAt,
    );

PaymentMethod _makePm({bool isDefault = true}) => PaymentMethod(
      id: 'pm-001',
      tenantId: 'tenant-test',
      gateway: PaymentGateway.stripe,
      gatewayToken: 'tok_test',
      brand: 'visa',
      last4: '4242',
      expMonth: 12,
      expYear: 2027,
      isDefault: isDefault,
      createdAt: _kCreatedAt,
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

class _CallTracker {
  bool reactivateCalled = false;
  bool cancelCalled = false;
  bool shouldThrow = false;
}

class _TrackingBillingV2 extends BillingV2 {
  _TrackingBillingV2(this._state, this._tracker);
  final BillingV2State _state;
  final _CallTracker _tracker;

  @override
  Future<BillingV2State> build() async => _state;

  @override
  Future<void> reactivateSubscription() async {
    _tracker.reactivateCalled = true;
    if (_tracker.shouldThrow) {
      throw const BillingException(
        code: 'not_implemented',
        message: 'No implementado aún.',
      );
    }
  }

  @override
  Future<void> cancelSubscription({String? reason}) async {
    _tracker.cancelCalled = true;
    if (_tracker.shouldThrow) {
      throw const BillingException(
        code: 'not_implemented',
        message: 'No implementado aún.',
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Pump helper
// ---------------------------------------------------------------------------

Future<void> _pump(
  WidgetTester tester,
  BillingV2State state, {
  _CallTracker? tracker,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        billingV2Provider.overrideWith(
          () => tracker != null
              ? _TrackingBillingV2(state, tracker)
              : _StubBillingV2(state),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AutoPaySettingsCard(),
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
  group('AutoPaySettingsCard', () {
    // -----------------------------------------------------------------------
    // Visibility
    // -----------------------------------------------------------------------
    group('visibilidad', () {
      testWidgets('oculto cuando no hay suscripción', (tester) async {
        await _pump(tester, const BillingV2State());

        expect(find.text('Cobro automático'), findsNothing);
      });

      testWidgets('visible cuando hay suscripción activa', (tester) async {
        await _pump(
          tester,
          BillingV2State(subscription: _makeSub()),
        );

        expect(find.text('Cobro automático'), findsOneWidget);
      });
    });

    // -----------------------------------------------------------------------
    // Switch state — with default PM
    // -----------------------------------------------------------------------
    group('con método de pago predeterminado', () {
      testWidgets('switch ON cuando autoRenew=true (cancelAtPeriodEnd=false)', (tester) async {
        await _pump(
          tester,
          BillingV2State(
            subscription: _makeSub(cancelAtPeriodEnd: false),
            paymentMethods: [_makePm()],
            defaultPaymentMethodId: 'pm-001',
          ),
        );

        final sw = tester.widget<Switch>(find.byType(Switch));
        expect(sw.value, isTrue);
        expect(sw.onChanged, isNotNull);
      });

      testWidgets('switch OFF cuando autoRenew=false (cancelAtPeriodEnd=true)', (tester) async {
        await _pump(
          tester,
          BillingV2State(
            subscription: _makeSub(cancelAtPeriodEnd: true),
            paymentMethods: [_makePm()],
            defaultPaymentMethodId: 'pm-001',
          ),
        );

        final sw = tester.widget<Switch>(find.byType(Switch));
        expect(sw.value, isFalse);
        expect(sw.onChanged, isNotNull);
      });

      testWidgets('muestra brand y últimos 4 dígitos del método default', (tester) async {
        await _pump(
          tester,
          BillingV2State(
            subscription: _makeSub(),
            paymentMethods: [_makePm()],
            defaultPaymentMethodId: 'pm-001',
          ),
        );

        expect(find.textContaining('4242'), findsOneWidget);
        expect(find.textContaining('visa'), findsOneWidget);
        expect(find.textContaining('Se cobrará a'), findsOneWidget);
      });
    });

    // -----------------------------------------------------------------------
    // Switch state — without default PM
    // -----------------------------------------------------------------------
    group('sin método de pago predeterminado', () {
      testWidgets('switch deshabilitado cuando no hay PM', (tester) async {
        await _pump(
          tester,
          BillingV2State(subscription: _makeSub()),
        );

        final sw = tester.widget<Switch>(find.byType(Switch));
        expect(sw.onChanged, isNull);
      });

      testWidgets('muestra mensaje para agregar método de pago', (tester) async {
        await _pump(
          tester,
          BillingV2State(subscription: _makeSub()),
        );

        expect(
          find.text('Agregá un método de pago para activar.'),
          findsOneWidget,
        );
      });
    });

    // -----------------------------------------------------------------------
    // Toggle dispatches mutations
    // -----------------------------------------------------------------------
    group('toggle dispara mutation', () {
      testWidgets('tap switch OFF→ON llama reactivateSubscription', (tester) async {
        final tracker = _CallTracker();

        await _pump(
          tester,
          BillingV2State(
            subscription: _makeSub(cancelAtPeriodEnd: true),
            paymentMethods: [_makePm()],
            defaultPaymentMethodId: 'pm-001',
          ),
          tracker: tracker,
        );

        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();

        expect(tracker.reactivateCalled, isTrue);
        expect(tracker.cancelCalled, isFalse);
      });

      testWidgets('tap switch ON→OFF llama cancelSubscription', (tester) async {
        final tracker = _CallTracker();

        await _pump(
          tester,
          BillingV2State(
            subscription: _makeSub(cancelAtPeriodEnd: false),
            paymentMethods: [_makePm()],
            defaultPaymentMethodId: 'pm-001',
          ),
          tracker: tracker,
        );

        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();

        expect(tracker.cancelCalled, isTrue);
        expect(tracker.reactivateCalled, isFalse);
      });
    });

    // -----------------------------------------------------------------------
    // Error handling — mutation throws → SnackBar shown
    // -----------------------------------------------------------------------
    group('manejo de error', () {
      testWidgets('muestra SnackBar cuando la mutation falla', (tester) async {
        final tracker = _CallTracker()..shouldThrow = true;

        await _pump(
          tester,
          BillingV2State(
            subscription: _makeSub(cancelAtPeriodEnd: true),
            paymentMethods: [_makePm()],
            defaultPaymentMethodId: 'pm-001',
          ),
          tracker: tracker,
        );

        await tester.tap(find.byType(Switch));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('No implementado aún.'), findsOneWidget);
      });
    });
  });
}

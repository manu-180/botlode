// Archivo: test/features/billing/presentation/widgets/add_card_modal_test.dart
//
// T4·09 — Smoke tests for AddCardModal.
//
// Strategy:
//   - billingV2Provider overridden with lightweight stub notifiers; no Supabase.
//   - Token is injected directly via stripeForm.onToken() to simulate tokenization
//     without invoking the Stripe SDK (which requires platform init).
//   - Tests cover: gateway routing, GUARDAR gating, default checkbox, success
//     path, and backend error path.
//
// Run:
//   flutter test test/features/billing/presentation/widgets/add_card_modal_test.dart

import 'package:botslode/features/billing/domain/models/subscription.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/providers/billing_state.dart';
import 'package:botslode/features/billing/presentation/widgets/add_card_modal.dart';
import 'package:botslode/features/billing/presentation/widgets/mercadopago_brick_form.dart';
import 'package:botslode/features/billing/presentation/widgets/stripe_elements_card_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Stub notifiers
// ---------------------------------------------------------------------------

class _SuccessStub extends BillingV2 {
  _SuccessStub(this._state);
  final BillingV2State _state;

  @override
  Future<BillingV2State> build() async => _state;

  @override
  Future<void> addPaymentMethod(
    String token, {
    bool setAsDefault = false,
  }) async {
    // Success — no throw.
  }
}

class _ThrowingStub extends BillingV2 {
  _ThrowingStub(this._state);
  final BillingV2State _state;

  @override
  Future<BillingV2State> build() async => _state;

  @override
  Future<void> addPaymentMethod(
    String token, {
    bool setAsDefault = false,
  }) async {
    throw const BillingException(
      code: 'card_declined',
      message: 'Tarjeta rechazada',
    );
  }
}

// ---------------------------------------------------------------------------
// Fixture helpers
// ---------------------------------------------------------------------------

final _kCreatedAt = DateTime.utc(2026, 1, 1);

Subscription _sub(PaymentGateway gw) => Subscription(
      id: 'sub-test',
      tenantId: 'tenant-test',
      planId: 'plan-starter',
      status: SubscriptionStatus.active,
      gateway: gw,
      createdAt: _kCreatedAt,
      updatedAt: _kCreatedAt,
    );

Subscription _subNullGw() => Subscription(
      id: 'sub-no-gw',
      tenantId: 'tenant-test',
      planId: 'plan-starter',
      status: SubscriptionStatus.active,
      gateway: null,
      createdAt: _kCreatedAt,
      updatedAt: _kCreatedAt,
    );

// ---------------------------------------------------------------------------
// Helper: pump AddCardModal with fixed surface
// ---------------------------------------------------------------------------

Future<void> _pump(
  WidgetTester tester, {
  required BillingV2 Function() notifierFactory,
}) async {
  await tester.binding.setSurfaceSize(const Size(600, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        billingV2Provider.overrideWith(notifierFactory),
      ],
      child: MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: const Scaffold(
          body: Center(child: AddCardModal()),
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
  group('AddCardModal', () {
    // -------------------------------------------------------------------------
    // 1. Gateway routing
    // -------------------------------------------------------------------------
    group('gateway routing', () {
      testWidgets('stripe → StripeElementsCardForm only', (tester) async {
        await _pump(
          tester,
          notifierFactory: () =>
              _SuccessStub(BillingV2State(subscription: _sub(PaymentGateway.stripe))),
        );
        expect(find.byType(StripeElementsCardForm), findsOneWidget);
        expect(find.byType(MercadoPagoBrickForm), findsNothing);
      });

      testWidgets('mp → MercadoPagoBrickForm only', (tester) async {
        await _pump(
          tester,
          notifierFactory: () =>
              _SuccessStub(BillingV2State(subscription: _sub(PaymentGateway.mp))),
        );
        expect(find.byType(MercadoPagoBrickForm), findsOneWidget);
        expect(find.byType(StripeElementsCardForm), findsNothing);
      });

      testWidgets('null gateway → PASARELA NO CONFIGURADA, no subforms',
          (tester) async {
        await _pump(
          tester,
          notifierFactory: () =>
              _SuccessStub(BillingV2State(subscription: _subNullGw())),
        );
        expect(find.text('PASARELA NO CONFIGURADA'), findsOneWidget);
        expect(find.byType(StripeElementsCardForm), findsNothing);
        expect(find.byType(MercadoPagoBrickForm), findsNothing);
      });
    });

    // -------------------------------------------------------------------------
    // 2. GUARDAR button gating
    // -------------------------------------------------------------------------
    group('GUARDAR gating', () {
      testWidgets('GUARDAR disabled before token', (tester) async {
        await _pump(
          tester,
          notifierFactory: () =>
              _SuccessStub(BillingV2State(subscription: _sub(PaymentGateway.stripe))),
        );
        final btn = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'GUARDAR'),
        );
        expect(
          btn.onPressed,
          isNull,
          reason: 'GUARDAR must be disabled until a token is received',
        );
      });

      testWidgets('GUARDAR absent when gateway is null', (tester) async {
        await _pump(
          tester,
          notifierFactory: () =>
              _SuccessStub(BillingV2State(subscription: _subNullGw())),
        );
        expect(find.widgetWithText(ElevatedButton, 'GUARDAR'), findsNothing);
      });

      testWidgets('GUARDAR enabled after token injected', (tester) async {
        await _pump(
          tester,
          notifierFactory: () =>
              _SuccessStub(BillingV2State(subscription: _sub(PaymentGateway.stripe))),
        );

        final stripeForm = tester.widget<StripeElementsCardForm>(
          find.byType(StripeElementsCardForm),
        );
        stripeForm.onToken('pm_test_enable');
        await tester.pump();

        final btn = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'GUARDAR'),
        );
        expect(
          btn.onPressed,
          isNotNull,
          reason: 'GUARDAR must be enabled once a token is available',
        );
      });
    });

    // -------------------------------------------------------------------------
    // 3. Success path
    // -------------------------------------------------------------------------
    group('success path', () {
      testWidgets('success state shown after token + GUARDAR tap', (tester) async {
        await tester.binding.setSurfaceSize(const Size(600, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              billingV2Provider.overrideWith(
                () => _SuccessStub(
                  BillingV2State(subscription: _sub(PaymentGateway.stripe)),
                ),
              ),
            ],
            child: MaterialApp(
              theme: ThemeData(useMaterial3: true),
              home: const Scaffold(body: Center(child: AddCardModal())),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Inject token directly to bypass Stripe SDK platform dependency.
        final stripeForm = tester.widget<StripeElementsCardForm>(
          find.byType(StripeElementsCardForm),
        );
        stripeForm.onToken('pm_test_success');
        await tester.pump();

        // GUARDAR now enabled — tap it.
        await tester.tap(
          find.widgetWithText(ElevatedButton, 'GUARDAR'),
          warnIfMissed: false,
        );
        // pump twice: one for setState, one for async completion.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          find.text('MÉTODO DE PAGO AGREGADO'),
          findsOneWidget,
          reason: 'Success title must be shown after addPaymentMethod succeeds',
        );
      });
    });

    // -------------------------------------------------------------------------
    // 4. Error path
    // -------------------------------------------------------------------------
    group('error path', () {
      testWidgets(
          'failure state shown when addPaymentMethod throws BillingException',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(600, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              billingV2Provider.overrideWith(
                () => _ThrowingStub(
                  BillingV2State(subscription: _sub(PaymentGateway.stripe)),
                ),
              ),
            ],
            child: MaterialApp(
              theme: ThemeData(useMaterial3: true),
              home: const Scaffold(body: Center(child: AddCardModal())),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final stripeForm = tester.widget<StripeElementsCardForm>(
          find.byType(StripeElementsCardForm),
        );
        stripeForm.onToken('pm_test_fail');
        await tester.pump();

        await tester.tap(
          find.widgetWithText(ElevatedButton, 'GUARDAR'),
          warnIfMissed: false,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // PaymentErrorService maps generic error → TRANSACCIÓN RECHAZADA.
        expect(
          find.text('TRANSACCIÓN RECHAZADA'),
          findsOneWidget,
          reason: 'Failure title from PaymentErrorService must appear',
        );
      });

      testWidgets('REINTENTAR resets failure state', (tester) async {
        await tester.binding.setSurfaceSize(const Size(600, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              billingV2Provider.overrideWith(
                () => _ThrowingStub(
                  BillingV2State(subscription: _sub(PaymentGateway.stripe)),
                ),
              ),
            ],
            child: MaterialApp(
              theme: ThemeData(useMaterial3: true),
              home: const Scaffold(body: Center(child: AddCardModal())),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final stripeForm = tester.widget<StripeElementsCardForm>(
          find.byType(StripeElementsCardForm),
        );
        stripeForm.onToken('pm_test_retry');
        await tester.pump();

        await tester.tap(
          find.widgetWithText(ElevatedButton, 'GUARDAR'),
          warnIfMissed: false,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Failure state shown; now tap REINTENTAR.
        await tester.tap(
          find.widgetWithText(ElevatedButton, 'REINTENTAR'),
          warnIfMissed: false,
        );
        await tester.pump();

        // Normal state restored — subform visible again.
        expect(find.byType(StripeElementsCardForm), findsOneWidget);
        expect(find.text('TRANSACCIÓN RECHAZADA'), findsNothing);
      });
    });

    // -------------------------------------------------------------------------
    // 5. Default checkbox
    // -------------------------------------------------------------------------
    group('default checkbox', () {
      testWidgets('checkbox visible for configured gateway', (tester) async {
        await _pump(
          tester,
          notifierFactory: () =>
              _SuccessStub(BillingV2State(subscription: _sub(PaymentGateway.stripe))),
        );
        expect(find.text('Establecer como predeterminado'), findsOneWidget);
        expect(find.byType(Checkbox), findsOneWidget);
      });

      testWidgets('checkbox absent when gateway is null', (tester) async {
        await _pump(
          tester,
          notifierFactory: () =>
              _SuccessStub(BillingV2State(subscription: _subNullGw())),
        );
        expect(find.byType(Checkbox), findsNothing);
      });

      testWidgets('checkbox starts unchecked and toggles on tap', (tester) async {
        await _pump(
          tester,
          notifierFactory: () =>
              _SuccessStub(BillingV2State(subscription: _sub(PaymentGateway.stripe))),
        );

        final before = tester.widget<Checkbox>(find.byType(Checkbox));
        expect(before.value, isFalse, reason: 'Checkbox must be unchecked by default');

        await tester.tap(find.byType(Checkbox));
        await tester.pump();

        final after = tester.widget<Checkbox>(find.byType(Checkbox));
        expect(after.value, isTrue, reason: 'Checkbox must toggle to checked on tap');
      });
    });

    // -------------------------------------------------------------------------
    // 6. CANCELAR always present
    // -------------------------------------------------------------------------
    group('cancel button', () {
      testWidgets('CANCELAR present for stripe gateway', (tester) async {
        await _pump(
          tester,
          notifierFactory: () =>
              _SuccessStub(BillingV2State(subscription: _sub(PaymentGateway.stripe))),
        );
        expect(find.text('CANCELAR'), findsOneWidget);
      });

      testWidgets('CANCELAR present when gateway is null', (tester) async {
        await _pump(
          tester,
          notifierFactory: () =>
              _SuccessStub(BillingV2State(subscription: _subNullGw())),
        );
        expect(find.text('CANCELAR'), findsOneWidget);
      });
    });

    // -------------------------------------------------------------------------
    // 7. Header content
    // -------------------------------------------------------------------------
    group('header', () {
      testWidgets('shows title and PCI-DSS compliance text', (tester) async {
        await _pump(
          tester,
          notifierFactory: () =>
              _SuccessStub(BillingV2State(subscription: _sub(PaymentGateway.stripe))),
        );
        expect(find.text('Agregar método de pago'), findsOneWidget);
        expect(find.textContaining('PCI-DSS'), findsOneWidget);
      });
    });
  });
}

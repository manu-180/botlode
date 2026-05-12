// Archivo: test/features/billing/presentation/widgets/payment_checkout_modal_golden_test.dart
//
// T4·06 — Golden tests for PaymentCheckoutModal.
//
// Strategy:
//   - Overrides billingV2Provider with _StubBillingV2; no real Supabase calls.
//   - Fixed surface size of 480×800.
//   - Two scenarios: stripe gateway and mp gateway.
//
// Run once to generate / update the goldens:
//   flutter test --update-goldens \
//     test/features/billing/presentation/widgets/payment_checkout_modal_golden_test.dart

import 'package:botslode/features/billing/domain/models/subscription.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/providers/billing_state.dart';
import 'package:botslode/features/billing/presentation/widgets/payment_checkout_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Stub notifier
// ---------------------------------------------------------------------------

class _StubBillingV2 extends BillingV2 {
  _StubBillingV2(this._state);

  final BillingV2State _state;

  @override
  Future<BillingV2State> build() async => _state;

  @override
  Future<void> addPaymentMethod(
    String token, {
    bool setAsDefault = false,
  }) async {
    // No-op for golden tests.
  }
}

// ---------------------------------------------------------------------------
// Fixture helpers
// ---------------------------------------------------------------------------

final _kCreatedAt = DateTime.utc(2026, 1, 1);

Subscription _makeSubWithGateway(PaymentGateway gateway) => Subscription(
      id: 'sub-golden',
      tenantId: 'tenant-golden',
      planId: 'plan-starter',
      status: SubscriptionStatus.active,
      gateway: gateway,
      createdAt: _kCreatedAt,
      updatedAt: _kCreatedAt,
    );

// ---------------------------------------------------------------------------
// Helper: pump the modal
// ---------------------------------------------------------------------------

Future<void> _pumpModal(
  WidgetTester tester, {
  required BillingV2 Function() notifierFactory,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        billingV2Provider.overrideWith(notifierFactory),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFFC000),
            brightness: Brightness.dark,
          ),
        ),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(480, 800)),
          child: Scaffold(
            backgroundColor: const Color(0xFF050A10),
            body: Center(
              child: PaymentCheckoutModal(
                amount: 9.00,
                exchangeRate: 1200.0,
                planName: 'Starter',
                frequency: BillingInterval.month,
                idempotencyKey: 'idem-golden-key',
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
  group('PaymentCheckoutModal — golden', () {
    // -----------------------------------------------------------------------
    // 1. Stripe gateway
    // -----------------------------------------------------------------------
    testWidgets(
      'stripe gateway',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(480, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final state = BillingV2State(
          subscription: _makeSubWithGateway(PaymentGateway.stripe),
        );

        await _pumpModal(
          tester,
          notifierFactory: () => _StubBillingV2(state),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(PaymentCheckoutModal),
          matchesGoldenFile('goldens/checkout_modal_stripe.png'),
        );
      },
      // Use Windows platform variant so StripeElementsCardForm renders
      // the desktop fallback (avoids MobileStub overflow in test env).
      variant: TargetPlatformVariant.only(TargetPlatform.windows),
    );

    // -----------------------------------------------------------------------
    // 2. MercadoPago gateway
    // -----------------------------------------------------------------------
    testWidgets(
      'mp gateway',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(480, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final state = BillingV2State(
          subscription: _makeSubWithGateway(PaymentGateway.mp),
        );

        await _pumpModal(
          tester,
          notifierFactory: () => _StubBillingV2(state),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(PaymentCheckoutModal),
          matchesGoldenFile('goldens/checkout_modal_mp.png'),
        );
      },
      variant: TargetPlatformVariant.only(TargetPlatform.windows),
    );

    // -----------------------------------------------------------------------
    // 3. Null gateway (error state)
    // -----------------------------------------------------------------------
    testWidgets(
      'null gateway — error block',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(480, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        const state = BillingV2State(
          subscription: null, // no gateway
        );

        await _pumpModal(
          tester,
          notifierFactory: () => _StubBillingV2(state),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(PaymentCheckoutModal),
          matchesGoldenFile('goldens/checkout_modal_no_gateway.png'),
        );
      },
      variant: TargetPlatformVariant.only(TargetPlatform.windows),
    );
  });
}

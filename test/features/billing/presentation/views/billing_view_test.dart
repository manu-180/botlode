// Archivo: test/features/billing/presentation/views/billing_view_test.dart
//
// T4·03 — Widget tests for BillingView tab-based layout.
//
// Strategy:
//   - Uses ProviderScope with overrides for billingV2Provider.
//   - Does NOT require Supabase or real providers.
//   - Verifies: 4-tab rendering, loading state, error state, dunning banner.

import 'package:botslode/features/billing/domain/models/invoice.dart';
import 'package:botslode/features/billing/domain/models/payment_method.dart';
import 'package:botslode/features/billing/domain/models/plan.dart';
import 'package:botslode/features/billing/domain/models/subscription.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/providers/billing_state.dart';
import 'package:botslode/features/billing/presentation/views/billing_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fixture helpers
// ---------------------------------------------------------------------------

const _kTenantId = 'tenant-view-test';

Subscription _makeSubscription({
  SubscriptionStatus status = SubscriptionStatus.active,
  DateTime? trialEnd,
}) =>
    Subscription(
      id: 'sub-view-001',
      tenantId: _kTenantId,
      planId: 'plan-starter',
      status: status,
      trialEnd: trialEnd,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

PaymentMethod _makePm(String id) => PaymentMethod(
      id: id,
      tenantId: _kTenantId,
      gateway: PaymentGateway.stripe,
      gatewayToken: 'tok_$id',
      brand: 'visa',
      last4: '4242',
      expMonth: 12,
      expYear: 2028,
      isDefault: true,
      createdAt: DateTime.utc(2026),
    );

Invoice _makeInvoice(String id) => Invoice(
      id: id,
      tenantId: _kTenantId,
      number: 'INV-$id',
      totalCents: 2900,
      status: InvoiceStatus.paid,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

// ---------------------------------------------------------------------------
// Helper: pump BillingView with an AsyncValue override
// ---------------------------------------------------------------------------

Future<void> _pumpBillingView(
  WidgetTester tester,
  AsyncValue<BillingV2State> asyncValue,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        billingV2Provider.overrideWith((_) => asyncValue),
      ],
      child: const MaterialApp(
        home: BillingView(),
      ),
    ),
  );
  // Let animations settle.
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('BillingView', () {
    // -------------------------------------------------------------------------
    // Tab rendering
    // -------------------------------------------------------------------------
    group('tabs', () {
      testWidgets('renders 4 tabs when data is available', (tester) async {
        final state = BillingV2State(
          subscription: _makeSubscription(),
          paymentMethods: [_makePm('pm-001')],
          invoices: [_makeInvoice('inv-001')],
        );

        await _pumpBillingView(tester, AsyncData(state));

        expect(find.text('Plan'), findsOneWidget);
        expect(find.text('Métodos de pago'), findsOneWidget);
        expect(find.text('Facturas'), findsOneWidget);
        expect(find.text('Historial'), findsOneWidget);
      });

      testWidgets('Tab 0 — shows "Plan actual" heading', (tester) async {
        final state = BillingV2State(
          subscription: _makeSubscription(),
        );

        await _pumpBillingView(tester, AsyncData(state));

        expect(find.text('Plan actual'), findsOneWidget);
      });

      testWidgets('Tab 1 — shows payment methods count after tap',
          (tester) async {
        final state = BillingV2State(
          subscription: _makeSubscription(),
          paymentMethods: [_makePm('pm-001'), _makePm('pm-002')],
        );

        await _pumpBillingView(tester, AsyncData(state));

        // Tap "Métodos de pago" tab.
        await tester.tap(find.text('Métodos de pago'));
        await tester.pumpAndSettle();

        expect(find.text('2 métodos de pago registrados'), findsOneWidget);
      });

      testWidgets('Tab 2 — shows "Sin facturas" when invoices is empty',
          (tester) async {
        final state = const BillingV2State();

        await _pumpBillingView(tester, AsyncData(state));

        await tester.tap(find.text('Facturas'));
        await tester.pumpAndSettle();

        expect(find.text('Sin facturas'), findsOneWidget);
      });

      testWidgets('Tab 2 — shows invoice count when invoices exist',
          (tester) async {
        final state = BillingV2State(
          invoices: [_makeInvoice('i1'), _makeInvoice('i2')],
        );

        await _pumpBillingView(tester, AsyncData(state));

        await tester.tap(find.text('Facturas'));
        await tester.pumpAndSettle();

        expect(find.text('2 facturas'), findsOneWidget);
      });

      testWidgets('Tab 3 — shows historial placeholder after tap',
          (tester) async {
        final state = const BillingV2State();

        await _pumpBillingView(tester, AsyncData(state));

        await tester.tap(find.text('Historial'));
        await tester.pumpAndSettle();

        expect(
          find.text('Historial de eventos de billing próximamente.'),
          findsOneWidget,
        );
      });
    });

    // -------------------------------------------------------------------------
    // Loading state
    // -------------------------------------------------------------------------
    group('loading', () {
      testWidgets('shows CircularProgressIndicator while loading',
          (tester) async {
        await _pumpBillingView(
          tester,
          const AsyncLoading<BillingV2State>(),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        // Tabs should NOT be visible while loading.
        expect(find.text('Plan'), findsNothing);
      });
    });

    // -------------------------------------------------------------------------
    // Error state
    // -------------------------------------------------------------------------
    group('error', () {
      testWidgets('shows error text when provider has error', (tester) async {
        await _pumpBillingView(
          tester,
          AsyncError<BillingV2State>(
            Exception('network failure'),
            StackTrace.empty,
          ),
        );

        expect(find.text('Error al cargar billing'), findsOneWidget);
        expect(find.text('Reintentar'), findsOneWidget);
      });
    });

    // -------------------------------------------------------------------------
    // Dunning banner
    // -------------------------------------------------------------------------
    group('banners', () {
      testWidgets('shows dunning banner when subscription is pastDue',
          (tester) async {
        final state = BillingV2State(
          subscription: _makeSubscription(status: SubscriptionStatus.pastDue),
        );

        await _pumpBillingView(tester, AsyncData(state));

        expect(
          find.text(
            'Tu pago está pendiente. Actualiza tu método de pago para evitar interrupciones.',
          ),
          findsOneWidget,
        );
      });

      testWidgets(
          'shows trial countdown banner when subscription is trialing with trialEnd',
          (tester) async {
        final trialEnd = DateTime.now().add(const Duration(days: 7));
        final state = BillingV2State(
          subscription: _makeSubscription(
            status: SubscriptionStatus.trialing,
            trialEnd: trialEnd,
          ),
        );

        await _pumpBillingView(tester, AsyncData(state));

        // Banner should contain "7 días" or similar text.
        expect(find.textContaining('período de prueba'), findsOneWidget);
      });

      testWidgets('does NOT show dunning banner for active subscription',
          (tester) async {
        final state = BillingV2State(
          subscription: _makeSubscription(status: SubscriptionStatus.active),
        );

        await _pumpBillingView(tester, AsyncData(state));

        expect(
          find.text(
            'Tu pago está pendiente. Actualiza tu método de pago para evitar interrupciones.',
          ),
          findsNothing,
        );
      });

      testWidgets('does NOT show trial banner when trialEnd is null',
          (tester) async {
        final state = BillingV2State(
          subscription: _makeSubscription(
            status: SubscriptionStatus.trialing,
            // trialEnd intentionally null
          ),
        );

        await _pumpBillingView(tester, AsyncData(state));

        expect(find.textContaining('período de prueba'), findsNothing);
      });
    });

    // -------------------------------------------------------------------------
    // No subscription
    // -------------------------------------------------------------------------
    group('empty state', () {
      testWidgets('shows "Sin suscripción activa" chip when no subscription',
          (tester) async {
        final state = const BillingV2State();

        await _pumpBillingView(tester, AsyncData(state));

        expect(find.text('Sin suscripción activa'), findsOneWidget);
      });
    });
  });
}

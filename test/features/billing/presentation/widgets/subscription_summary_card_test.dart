// Archivo: test/features/billing/presentation/widgets/subscription_summary_card_test.dart
//
// T4·15 — Widget tests for SubscriptionSummaryCard.
//
// Strategy:
//   - Override billingV2Provider with stub notifiers; no real Supabase calls.
//   - All tests pass `now: _kNow` for deterministic trial-day counts.
//   - Covered paths:
//     · No subscription → widget hidden.
//     · Chip label and icon per status.
//     · Plan name and price rendered.
//     · Trial days remaining displayed.
//     · cancelAtPeriodEnd shows end date + Reactivar, hides Cancelar.
//     · past_due shows warning + Actualizar pago.
//     · incomplete shows Completar pago.
//     · Cambiar plan visible only for active/trialing.
//     · Cancelar only when active/trialing and not cancelAtPeriodEnd.
//     · All visible buttons have minHeight ≥ 48 dp (touch target).
//     · Callbacks invoked on tap.

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
final _kTrialEnd = DateTime.utc(2026, 1, 20); // 10 días desde _kNow

Plan _makePlan({String id = 'plan-001'}) => Plan(
      id: id,
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
      id: 'sub-test',
      tenantId: 'tenant-test',
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

// ---------------------------------------------------------------------------
// Pump helper
// ---------------------------------------------------------------------------

Future<void> _pump(
  WidgetTester tester,
  BillingV2State state, {
  VoidCallback? onChangePlan,
  VoidCallback? onCancel,
  VoidCallback? onReactivate,
  VoidCallback? onUpdatePayment,
  VoidCallback? onCompletePayment,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        billingV2Provider.overrideWith(() => _StubBillingV2(state)),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SubscriptionSummaryCard(
              now: _kNow,
              onChangePlan: onChangePlan,
              onCancel: onCancel,
              onReactivate: onReactivate,
              onUpdatePayment: onUpdatePayment,
              onCompletePayment: onCompletePayment,
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
  group('SubscriptionSummaryCard', () {
    // -----------------------------------------------------------------------
    // Visibility
    // -----------------------------------------------------------------------
    group('visibilidad', () {
      testWidgets('oculto cuando no hay suscripción', (tester) async {
        await _pump(tester, const BillingV2State());
        expect(find.text('Tu suscripción'), findsNothing);
      });

      testWidgets('visible cuando hay suscripción activa', (tester) async {
        await _pump(
          tester,
          BillingV2State(
            subscription: _makeSub(),
            availablePlans: [_makePlan()],
          ),
        );
        expect(find.text('Tu suscripción'), findsOneWidget);
      });
    });

    // -----------------------------------------------------------------------
    // Status chip
    // -----------------------------------------------------------------------
    group('chip de status', () {
      for (final (status, label) in [
        (SubscriptionStatus.active, 'ACTIVA'),
        (SubscriptionStatus.trialing, 'TRIAL'),
        (SubscriptionStatus.pastDue, 'VENCIDA'),
        (SubscriptionStatus.canceled, 'CANCELADA'),
        (SubscriptionStatus.incomplete, 'INCOMPLETA'),
      ]) {
        testWidgets('muestra "$label" para status=$status', (tester) async {
          await _pump(
            tester,
            BillingV2State(
              subscription: _makeSub(status: status),
              availablePlans: [_makePlan()],
            ),
          );
          expect(find.text(label), findsOneWidget);
        });
      }
    });

    // -----------------------------------------------------------------------
    // Plan info
    // -----------------------------------------------------------------------
    group('información del plan', () {
      testWidgets('muestra nombre del plan', (tester) async {
        await _pump(
          tester,
          BillingV2State(
            subscription: _makeSub(),
            availablePlans: [_makePlan()],
          ),
        );
        expect(find.text('Starter'), findsOneWidget);
      });

      testWidgets('muestra precio mensual formateado', (tester) async {
        await _pump(
          tester,
          BillingV2State(
            subscription: _makeSub(),
            availablePlans: [_makePlan()],
          ),
        );
        expect(find.text(r'$9.99/mes'), findsOneWidget);
      });

      testWidgets('muestra precio anual con sufijo /año', (tester) async {
        final yearlyPlan = Plan(
          id: 'plan-001',
          code: 'starter-y',
          name: 'Starter Anual',
          priceCents: 9900,
          interval: BillingInterval.year,
          maxBots: 5,
          maxConversations: 100,
          public: true,
          createdAt: _kCreatedAt,
        );
        await _pump(
          tester,
          BillingV2State(
            subscription: _makeSub(),
            availablePlans: [yearlyPlan],
          ),
        );
        expect(find.text(r'$99.00/año'), findsOneWidget);
      });

      testWidgets('usa planId como fallback si el plan no está en el catálogo',
          (tester) async {
        await _pump(
          tester,
          BillingV2State(subscription: _makeSub()),
        );
        expect(find.text('plan-001'), findsOneWidget);
      });
    });

    // -----------------------------------------------------------------------
    // Trial days
    // -----------------------------------------------------------------------
    group('días de trial', () {
      testWidgets('muestra "10 días restantes" cuando trialEnd es 10d desde now',
          (tester) async {
        await _pump(
          tester,
          BillingV2State(
            subscription: _makeSub(
              status: SubscriptionStatus.trialing,
              trialEnd: _kTrialEnd,
            ),
            availablePlans: [_makePlan()],
          ),
        );
        expect(find.textContaining('10 días restantes'), findsOneWidget);
      });
    });

    // -----------------------------------------------------------------------
    // Cancel at period end
    // -----------------------------------------------------------------------
    group('cancelAtPeriodEnd', () {
      testWidgets('muestra fecha de finalización cuando cancelAtPeriodEnd=true',
          (tester) async {
        await _pump(
          tester,
          BillingV2State(
            subscription: _makeSub(cancelAtPeriodEnd: true),
            availablePlans: [_makePlan()],
          ),
        );
        expect(find.textContaining('finaliza el'), findsOneWidget);
      });

      testWidgets('muestra "Reactivar" cuando cancelAtPeriodEnd=true',
          (tester) async {
        await _pump(
          tester,
          BillingV2State(
            subscription: _makeSub(cancelAtPeriodEnd: true),
            availablePlans: [_makePlan()],
          ),
        );
        expect(find.text('Reactivar'), findsOneWidget);
      });

      testWidgets('oculta "Cancelar" cuando cancelAtPeriodEnd=true',
          (tester) async {
        await _pump(
          tester,
          BillingV2State(
            subscription: _makeSub(cancelAtPeriodEnd: true),
            availablePlans: [_makePlan()],
          ),
        );
        expect(find.text('Cancelar'), findsNothing);
      });
    });

    // -----------------------------------------------------------------------
    // Past due
    // -----------------------------------------------------------------------
    group('status past_due', () {
      testWidgets('muestra texto "Cobro pendiente"', (tester) async {
        await _pump(
          tester,
          BillingV2State(
            subscription: _makeSub(status: SubscriptionStatus.pastDue),
            availablePlans: [_makePlan()],
          ),
        );
        expect(find.text('Cobro pendiente'), findsOneWidget);
      });

      testWidgets('muestra botón "Actualizar pago"', (tester) async {
        await _pump(
          tester,
          BillingV2State(
            subscription: _makeSub(status: SubscriptionStatus.pastDue),
            availablePlans: [_makePlan()],
          ),
        );
        expect(find.text('Actualizar pago'), findsOneWidget);
      });

      testWidgets('oculta "Cambiar plan" y "Cancelar" cuando past_due',
          (tester) async {
        await _pump(
          tester,
          BillingV2State(
            subscription: _makeSub(status: SubscriptionStatus.pastDue),
            availablePlans: [_makePlan()],
          ),
        );
        expect(find.text('Cambiar plan'), findsNothing);
        expect(find.text('Cancelar'), findsNothing);
      });
    });

    // -----------------------------------------------------------------------
    // Incomplete
    // -----------------------------------------------------------------------
    group('status incomplete', () {
      testWidgets('muestra "Completar pago" y texto de autenticación',
          (tester) async {
        await _pump(
          tester,
          BillingV2State(
            subscription: _makeSub(status: SubscriptionStatus.incomplete),
            availablePlans: [_makePlan()],
          ),
        );
        expect(find.text('Completar pago'), findsOneWidget);
        expect(
          find.textContaining('autenticación'),
          findsOneWidget,
        );
      });
    });

    // -----------------------------------------------------------------------
    // Action visibility per status
    // -----------------------------------------------------------------------
    group('acciones contextuales', () {
      testWidgets('"Cambiar plan" visible para active', (tester) async {
        await _pump(
          tester,
          BillingV2State(
            subscription: _makeSub(),
            availablePlans: [_makePlan()],
          ),
        );
        expect(find.text('Cambiar plan'), findsOneWidget);
      });

      testWidgets('"Cambiar plan" visible para trialing', (tester) async {
        await _pump(
          tester,
          BillingV2State(
            subscription: _makeSub(status: SubscriptionStatus.trialing),
            availablePlans: [_makePlan()],
          ),
        );
        expect(find.text('Cambiar plan'), findsOneWidget);
      });

      testWidgets('"Cambiar plan" oculto para canceled', (tester) async {
        await _pump(
          tester,
          BillingV2State(
            subscription: _makeSub(status: SubscriptionStatus.canceled),
            availablePlans: [_makePlan()],
          ),
        );
        expect(find.text('Cambiar plan'), findsNothing);
      });

      testWidgets('"Cancelar" visible cuando active y no cancelAtPeriodEnd',
          (tester) async {
        await _pump(
          tester,
          BillingV2State(
            subscription: _makeSub(),
            availablePlans: [_makePlan()],
          ),
        );
        expect(find.text('Cancelar'), findsOneWidget);
      });

      testWidgets('"Cancelar" visible cuando trialing y no cancelAtPeriodEnd',
          (tester) async {
        await _pump(
          tester,
          BillingV2State(
            subscription: _makeSub(status: SubscriptionStatus.trialing),
            availablePlans: [_makePlan()],
          ),
        );
        expect(find.text('Cancelar'), findsOneWidget);
      });
    });

    // -----------------------------------------------------------------------
    // Callbacks
    // -----------------------------------------------------------------------
    group('callbacks', () {
      testWidgets('onChangePlan invocado al tocar "Cambiar plan"',
          (tester) async {
        var called = false;
        await _pump(
          tester,
          BillingV2State(
            subscription: _makeSub(),
            availablePlans: [_makePlan()],
          ),
          onChangePlan: () => called = true,
        );
        await tester.tap(find.text('Cambiar plan'));
        await tester.pumpAndSettle();
        expect(called, isTrue);
      });

      testWidgets('onCancel invocado al tocar "Cancelar"', (tester) async {
        var called = false;
        await _pump(
          tester,
          BillingV2State(
            subscription: _makeSub(),
            availablePlans: [_makePlan()],
          ),
          onCancel: () => called = true,
        );
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
        expect(called, isTrue);
      });

      testWidgets('onReactivate invocado al tocar "Reactivar"', (tester) async {
        var called = false;
        await _pump(
          tester,
          BillingV2State(
            subscription: _makeSub(cancelAtPeriodEnd: true),
            availablePlans: [_makePlan()],
          ),
          onReactivate: () => called = true,
        );
        await tester.tap(find.text('Reactivar'));
        await tester.pumpAndSettle();
        expect(called, isTrue);
      });

      testWidgets('onUpdatePayment invocado al tocar "Actualizar pago"',
          (tester) async {
        var called = false;
        await _pump(
          tester,
          BillingV2State(
            subscription: _makeSub(status: SubscriptionStatus.pastDue),
            availablePlans: [_makePlan()],
          ),
          onUpdatePayment: () => called = true,
        );
        await tester.tap(find.text('Actualizar pago'));
        await tester.pumpAndSettle();
        expect(called, isTrue);
      });

      testWidgets('onCompletePayment invocado al tocar "Completar pago"',
          (tester) async {
        var called = false;
        await _pump(
          tester,
          BillingV2State(
            subscription: _makeSub(status: SubscriptionStatus.incomplete),
            availablePlans: [_makePlan()],
          ),
          onCompletePayment: () => called = true,
        );
        await tester.tap(find.text('Completar pago'));
        await tester.pumpAndSettle();
        expect(called, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // Touch targets ≥ 48dp
    // -----------------------------------------------------------------------
    group('touch targets', () {
      testWidgets('todos los botones visibles tienen altura ≥ 48dp',
          (tester) async {
        await _pump(
          tester,
          BillingV2State(
            subscription: _makeSub(),
            availablePlans: [_makePlan()],
          ),
          onChangePlan: () {},
          onCancel: () {},
        );

        final buttons = tester.widgetList<SizedBox>(
          find.ancestor(
            of: find.byType(ButtonStyleButton),
            matching: find.byType(SizedBox),
          ),
        );

        for (final box in buttons) {
          if (box.height != null) {
            expect(
              box.height,
              greaterThanOrEqualTo(48),
              reason:
                  'Botón con SizedBox tiene altura ${box.height}, mínimo 48dp',
            );
          }
        }
      });
    });
  });
}

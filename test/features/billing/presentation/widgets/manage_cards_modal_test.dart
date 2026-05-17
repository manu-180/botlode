// Archivo: test/features/billing/presentation/widgets/manage_cards_modal_test.dart
//
// T4·10 — Widget tests for ManageCardsModal.
//
// Strategy:
//   - Override billingV2Provider with stub/tracking notifiers; no Supabase calls.
//   - _StubBillingV2: returns a fixed BillingV2State.
//   - _TrackingBillingV2: records setDefaultPaymentMethod / removePaymentMethod calls.
//   - Covered paths: list renders, set-default success, delete-only-card blocked.

import 'package:botslode/features/billing/domain/models/payment_method.dart';
import 'package:botslode/features/billing/domain/models/subscription.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/providers/billing_state.dart';
import 'package:botslode/features/billing/presentation/widgets/manage_cards_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
  String? setDefaultCalledWith;
  String? removeCalledWith;
}

class _TrackingBillingV2 extends BillingV2 {
  _TrackingBillingV2(this._state, this._tracker);
  final BillingV2State _state;
  final _CallTracker _tracker;

  @override
  Future<BillingV2State> build() async => _state;

  @override
  Future<void> setDefaultPaymentMethod(String id) async {
    _tracker.setDefaultCalledWith = id;
  }

  @override
  Future<void> removePaymentMethod(String id) async {
    _tracker.removeCalledWith = id;
  }
}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

final _kCreatedAt = DateTime.utc(2026, 1, 1);

PaymentMethod _makeCard({
  required String id,
  required String last4,
  bool isDefault = false,
  String brand = 'visa',
}) =>
    PaymentMethod(
      id: id,
      tenantId: 'tenant-test',
      gateway: PaymentGateway.stripe,
      gatewayToken: 'tok_$id',
      brand: brand,
      last4: last4,
      expMonth: 12,
      expYear: 2027,
      isDefault: isDefault,
      createdAt: _kCreatedAt,
    );

Subscription _makeActiveSub() => Subscription(
      id: 'sub-001',
      tenantId: 'tenant-test',
      planId: 'plan-starter',
      status: SubscriptionStatus.active,
      createdAt: _kCreatedAt,
      updatedAt: _kCreatedAt,
    );

// ---------------------------------------------------------------------------
// Pump helper
// ---------------------------------------------------------------------------

Future<void> _pumpModal(
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
            child: ManageCardsModal(),
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
  group('ManageCardsModal', () {
    // -----------------------------------------------------------------------
    // List rendering
    // -----------------------------------------------------------------------
    group('lista', () {
      testWidgets('muestra los últimos 4 dígitos de cada tarjeta', (tester) async {
        final cardA = _makeCard(id: 'pm-001', last4: '1234', isDefault: true);
        final cardB = _makeCard(id: 'pm-002', last4: '5678');

        await _pumpModal(
          tester,
          BillingV2State(
            paymentMethods: [cardA, cardB],
            defaultPaymentMethodId: cardA.id,
          ),
        );

        expect(find.text('•••• 1234'), findsOneWidget);
        expect(find.text('•••• 5678'), findsOneWidget);
      });

      testWidgets('muestra badge PREDETERMINADA para la tarjeta default', (tester) async {
        final card = _makeCard(id: 'pm-001', last4: '0001', isDefault: true);

        await _pumpModal(
          tester,
          BillingV2State(
            paymentMethods: [card],
            defaultPaymentMethodId: card.id,
          ),
        );

        expect(find.text('PREDETERMINADA'), findsOneWidget);
      });

      testWidgets('muestra empty state cuando no hay métodos de pago', (tester) async {
        await _pumpModal(tester, const BillingV2State());

        expect(find.text('Aún no agregaste métodos de pago'), findsOneWidget);
      });
    });

    // -----------------------------------------------------------------------
    // Set default
    // -----------------------------------------------------------------------
    group('set default', () {
      testWidgets('llama setDefaultPaymentMethod con el id correcto', (tester) async {
        final defaultCard = _makeCard(id: 'pm-default', last4: '1111', isDefault: true);
        final otherCard = _makeCard(id: 'pm-other', last4: '2222');
        final tracker = _CallTracker();

        await _pumpModal(
          tester,
          BillingV2State(
            paymentMethods: [defaultCard, otherCard],
            defaultPaymentMethodId: defaultCard.id,
          ),
          tracker: tracker,
        );

        // Tap el menú del segundo ítem (la tarjeta no-default).
        final menus = find.byIcon(Icons.more_vert);
        await tester.tap(menus.at(1));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Establecer como predeterminada'));
        await tester.pumpAndSettle();

        expect(tracker.setDefaultCalledWith, equals('pm-other'));
      });
    });

    // -----------------------------------------------------------------------
    // Delete — única tarjeta con suscripción activa
    // -----------------------------------------------------------------------
    group('eliminar', () {
      testWidgets(
        'bloquea eliminar cuando es la única tarjeta y hay suscripción activa',
        (tester) async {
          final onlyCard = _makeCard(id: 'pm-only', last4: '9999', isDefault: true);
          final tracker = _CallTracker();

          await _pumpModal(
            tester,
            BillingV2State(
              paymentMethods: [onlyCard],
              defaultPaymentMethodId: onlyCard.id,
              subscription: _makeActiveSub(),
            ),
            tracker: tracker,
          );

          // Abrir menú de la única tarjeta.
          await tester.tap(find.byIcon(Icons.more_vert).first);
          await tester.pumpAndSettle();

          await tester.tap(find.text('Eliminar'));
          await tester.pumpAndSettle();

          // No debe mostrar el AlertDialog de confirmación.
          expect(find.byType(AlertDialog), findsNothing);

          // Debe mostrar el mensaje bloqueante en un SnackBar.
          expect(
            find.textContaining('No podés eliminar tu único método'),
            findsOneWidget,
          );

          // No debe llamar al notifier.
          expect(tracker.removeCalledWith, isNull);
        },
      );
    });
  });
}

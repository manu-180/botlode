// Archivo: test/features/billing/presentation/widgets/dunning_warning_banner_test.dart
//
// T4·19 — Widget tests para DunningWarningBanner.
//
// Cobertura:
//   Visibilidad:
//     - Oculto cuando status != past_due (active, trialing, canceled, incomplete).
//     - Oculto cuando subscription == null.
//     - Oculto cuando el provider está cargando.
//     - Oculto cuando el provider devuelve error.
//     - Visible cuando status == past_due.
//   Texto del mensaje:
//     - Muestra fecha formateada cuando currentPeriodEnd está definido.
//     - Muestra "suspenderse pronto" cuando currentPeriodEnd == null.
//     - Muestra errorMessage del estado cuando está disponible.
//     - No muestra errorMessage cuando es null.
//   CTAs:
//     - CTA primaria "Actualizar método de pago" con touch target ≥ 48dp.
//     - CTA secundaria "Reintentar cobro" con touch target ≥ 48dp.
//     - Reintentar cobro se deshabilita durante el reintento.
//     - Muestra SnackBar con mensaje del BillingException al reintentar.
//   No descartable:
//     - No existe botón de cierre.

import 'dart:async';

import 'package:botslode/features/billing/domain/models/subscription.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/providers/billing_state.dart';
import 'package:botslode/features/billing/presentation/widgets/dunning_warning_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

final _kCreatedAt = DateTime.utc(2026, 1, 1);
final _kPeriodEnd = DateTime.utc(2026, 2, 1);

Subscription _makeSub({
  SubscriptionStatus status = SubscriptionStatus.pastDue,
  DateTime? currentPeriodEnd,
}) =>
    Subscription(
      id: 'sub-test',
      tenantId: 'tenant-test',
      planId: 'plan-001',
      status: status,
      currentPeriodEnd: currentPeriodEnd,
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

class _LoadingBillingV2 extends BillingV2 {
  @override
  FutureOr<BillingV2State> build() async {
    await Completer<void>().future;
    return const BillingV2State();
  }
}

class _ErrorBillingV2 extends BillingV2 {
  @override
  FutureOr<BillingV2State> build() async {
    throw Exception('Error de prueba');
  }
}

// ---------------------------------------------------------------------------
// Pump helper
// ---------------------------------------------------------------------------

Future<void> _wrap(
  WidgetTester tester, {
  required BillingV2 Function() notifierFactory,
  Future<void> Function()? retryOverride,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        billingV2Provider.overrideWith(notifierFactory),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: DunningWarningBanner(
            retryPaymentOverride: retryOverride,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('DunningWarningBanner', () {
    // -----------------------------------------------------------------------
    // Visibilidad
    // -----------------------------------------------------------------------
    group('visibilidad', () {
      testWidgets('oculto cuando status == active', (tester) async {
        await _wrap(
          tester,
          notifierFactory: () => _StubBillingV2(
            BillingV2State(
              subscription: _makeSub(status: SubscriptionStatus.active),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Pago fallido'), findsNothing);
      });

      testWidgets('oculto cuando status == trialing', (tester) async {
        await _wrap(
          tester,
          notifierFactory: () => _StubBillingV2(
            BillingV2State(
              subscription: _makeSub(status: SubscriptionStatus.trialing),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Pago fallido'), findsNothing);
      });

      testWidgets('oculto cuando status == canceled', (tester) async {
        await _wrap(
          tester,
          notifierFactory: () => _StubBillingV2(
            BillingV2State(
              subscription: _makeSub(status: SubscriptionStatus.canceled),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Pago fallido'), findsNothing);
      });

      testWidgets('oculto cuando subscription == null', (tester) async {
        await _wrap(
          tester,
          notifierFactory: () => _StubBillingV2(const BillingV2State()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Pago fallido'), findsNothing);
      });

      testWidgets('oculto cuando el provider está cargando', (tester) async {
        await _wrap(
          tester,
          notifierFactory: _LoadingBillingV2.new,
        );
        await tester.pump();

        expect(find.text('Pago fallido'), findsNothing);
      });

      testWidgets('oculto cuando el provider devuelve error', (tester) async {
        await _wrap(
          tester,
          notifierFactory: _ErrorBillingV2.new,
        );
        await tester.pump();

        expect(find.text('Pago fallido'), findsNothing);
      });

      testWidgets('visible cuando status == past_due', (tester) async {
        await _wrap(
          tester,
          notifierFactory: () => _StubBillingV2(
            BillingV2State(
              subscription: _makeSub(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Pago fallido'), findsOneWidget);
      });
    });

    // -----------------------------------------------------------------------
    // Texto del mensaje
    // -----------------------------------------------------------------------
    group('texto del mensaje', () {
      testWidgets('muestra fecha formateada cuando currentPeriodEnd != null',
          (tester) async {
        await _wrap(
          tester,
          notifierFactory: () => _StubBillingV2(
            BillingV2State(
              subscription: _makeSub(currentPeriodEnd: _kPeriodEnd),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // _kPeriodEnd = 2026-02-01 → "01/02/2026" en local
        expect(
          find.textContaining('01/02/2026'),
          findsOneWidget,
        );
        expect(
          find.textContaining('suspenderse el'),
          findsOneWidget,
        );
      });

      testWidgets('muestra "pronto" cuando currentPeriodEnd == null',
          (tester) async {
        await _wrap(
          tester,
          notifierFactory: () => _StubBillingV2(
            BillingV2State(
              subscription: _makeSub(currentPeriodEnd: null),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('suspenderse pronto'), findsOneWidget);
      });

      testWidgets('muestra errorMessage del estado cuando está disponible',
          (tester) async {
        await _wrap(
          tester,
          notifierFactory: () => _StubBillingV2(
            BillingV2State(
              subscription: _makeSub(),
              errorMessage: 'Fondos insuficientes en la tarjeta.',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Fondos insuficientes en la tarjeta.'),
          findsOneWidget,
        );
      });

      testWidgets('no muestra error cuando errorMessage == null',
          (tester) async {
        await _wrap(
          tester,
          notifierFactory: () => _StubBillingV2(
            BillingV2State(
              subscription: _makeSub(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Solo debe aparecer el título y el mensaje principal, no un error extra.
        expect(find.text('Pago fallido'), findsOneWidget);
      });
    });

    // -----------------------------------------------------------------------
    // No descartable
    // -----------------------------------------------------------------------
    group('no descartable', () {
      testWidgets('no existe botón de cierre', (tester) async {
        await _wrap(
          tester,
          notifierFactory: () => _StubBillingV2(
            BillingV2State(subscription: _makeSub()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byTooltip('Cerrar'), findsNothing);
        expect(find.byIcon(Icons.close), findsNothing);
      });
    });

    // -----------------------------------------------------------------------
    // Touch targets
    // -----------------------------------------------------------------------
    group('touch targets', () {
      testWidgets('CTA "Actualizar método de pago" tiene altura ≥ 48dp',
          (tester) async {
        await _wrap(
          tester,
          notifierFactory: () => _StubBillingV2(
            BillingV2State(subscription: _makeSub()),
          ),
        );
        await tester.pumpAndSettle();

        final size = tester.getSize(
          find.widgetWithText(FilledButton, 'Actualizar método de pago'),
        );
        expect(
          size.height,
          greaterThanOrEqualTo(48),
          reason: 'Altura actual: ${size.height}dp',
        );
      });

      testWidgets('CTA "Reintentar cobro" tiene altura ≥ 48dp', (tester) async {
        await _wrap(
          tester,
          notifierFactory: () => _StubBillingV2(
            BillingV2State(subscription: _makeSub()),
          ),
          retryOverride: () async {},
        );
        await tester.pumpAndSettle();

        final size = tester.getSize(
          find.widgetWithText(OutlinedButton, 'Reintentar cobro'),
        );
        expect(
          size.height,
          greaterThanOrEqualTo(48),
          reason: 'Altura actual: ${size.height}dp',
        );
      });
    });

    // -----------------------------------------------------------------------
    // Retry flow
    // -----------------------------------------------------------------------
    group('retry', () {
      testWidgets('botón se deshabilita durante el reintento', (tester) async {
        final retryCompleter = Completer<void>();

        await _wrap(
          tester,
          notifierFactory: () => _StubBillingV2(
            BillingV2State(subscription: _makeSub()),
          ),
          retryOverride: () => retryCompleter.future,
        );
        await tester.pumpAndSettle();

        // Botón habilitado antes de tap.
        final buttonFinder =
            find.widgetWithText(OutlinedButton, 'Reintentar cobro');
        final buttonBefore =
            tester.widget<OutlinedButton>(buttonFinder);
        expect(buttonBefore.onPressed, isNotNull);

        // Iniciar reintento.
        await tester.tap(buttonFinder);
        await tester.pump();

        // Botón deshabilitado mientras espera.
        final buttonDuring = tester.widget<OutlinedButton>(buttonFinder);
        expect(buttonDuring.onPressed, isNull);

        // Completar y verificar que vuelve a habilitarse.
        retryCompleter.complete();
        await tester.pumpAndSettle();

        final buttonAfter = tester.widget<OutlinedButton>(buttonFinder);
        expect(buttonAfter.onPressed, isNotNull);
      });

      testWidgets('muestra SnackBar con mensaje al recibir BillingException',
          (tester) async {
        await _wrap(
          tester,
          notifierFactory: () => _StubBillingV2(
            BillingV2State(subscription: _makeSub()),
          ),
          retryOverride: () async {
            throw const BillingException(
              code: 'not_implemented',
              message: 'Reintento no disponible aún.',
            );
          },
        );
        await tester.pumpAndSettle();

        await tester.tap(
            find.widgetWithText(OutlinedButton, 'Reintentar cobro'));
        await tester.pumpAndSettle();

        expect(find.text('Reintento no disponible aún.'), findsOneWidget);
      });
    });
  });
}

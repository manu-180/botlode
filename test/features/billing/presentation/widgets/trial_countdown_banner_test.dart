// Archivo: test/features/billing/presentation/widgets/trial_countdown_banner_test.dart
//
// T4·18 — Widget tests para TrialCountdownBanner.
//
// Cobertura:
//   Visibilidad:
//     - Oculto cuando status != trialing.
//     - Oculto cuando trialEnd == null.
//     - Oculto cuando subscription == null.
//     - Oculto cuando el provider está cargando.
//   Cálculo de días:
//     - Muestra "10 días restantes" correctamente.
//     - Forma singular: "1 día restante".
//     - Clamps a 0 cuando trialEnd ya pasó.
//   Visibilidad del CTA:
//     - Muestra "Agregar método" cuando no hay método predeterminado.
//     - Oculta "Agregar método" cuando defaultPaymentMethodId != null.
//   Dismiss:
//     - Al tocar el botón de cierre (tooltip 'Cerrar') el banner desaparece.
//   Touch target:
//     - El botón CTA tiene altura ≥ 48dp.

import 'dart:async';

import 'package:botslode/features/billing/domain/models/subscription.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/providers/billing_state.dart';
import 'package:botslode/features/billing/presentation/widgets/trial_countdown_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

final _kNow = DateTime.utc(2026, 1, 10, 12, 0);
final _kCreatedAt = DateTime.utc(2026, 1, 1);

Subscription _makeSub({
  SubscriptionStatus status = SubscriptionStatus.trialing,
  DateTime? trialEnd,
}) =>
    Subscription(
      id: 'sub-test',
      tenantId: 'tenant-test',
      planId: 'plan-001',
      status: status,
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

class _LoadingBillingV2 extends BillingV2 {
  @override
  FutureOr<BillingV2State> build() async {
    // Nunca completa: simula estado de carga infinita.
    await Completer<void>().future;
    return const BillingV2State();
  }
}

// ---------------------------------------------------------------------------
// Pump helper
// ---------------------------------------------------------------------------

Future<void> _wrap(
  WidgetTester tester, {
  required BillingV2 Function() notifierFactory,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        billingV2Provider.overrideWith(notifierFactory),
      ],
      child: MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF050A10),
          body: TrialCountdownBanner(now: _kNow),
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
  group('TrialCountdownBanner', () {
    // -----------------------------------------------------------------------
    // Visibilidad
    // -----------------------------------------------------------------------
    group('visibilidad', () {
      testWidgets('oculto cuando status != trialing (active)', (tester) async {
        await _wrap(
          tester,
          notifierFactory: () => _StubBillingV2(
            BillingV2State(
              subscription: _makeSub(
                status: SubscriptionStatus.active,
                trialEnd: DateTime.utc(2026, 1, 20),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Agregar método'), findsNothing);
        expect(find.byTooltip('Cerrar'), findsNothing);
      });

      testWidgets('oculto cuando trialEnd == null', (tester) async {
        await _wrap(
          tester,
          notifierFactory: () => _StubBillingV2(
            BillingV2State(
              // status == trialing pero sin trialEnd
              subscription: _makeSub(trialEnd: null),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byTooltip('Cerrar'), findsNothing);
      });

      testWidgets('oculto cuando subscription == null', (tester) async {
        await _wrap(
          tester,
          notifierFactory: () => _StubBillingV2(const BillingV2State()),
        );
        await tester.pumpAndSettle();

        expect(find.byTooltip('Cerrar'), findsNothing);
      });

      testWidgets('oculto cuando el provider está cargando', (tester) async {
        await _wrap(
          tester,
          notifierFactory: _LoadingBillingV2.new,
        );
        // No pumpAndSettle: el provider nunca completa.
        await tester.pump();

        expect(find.byTooltip('Cerrar'), findsNothing);
      });

      testWidgets('visible cuando status == trialing con trialEnd', (tester) async {
        await _wrap(
          tester,
          notifierFactory: () => _StubBillingV2(
            BillingV2State(
              subscription: _makeSub(
                trialEnd: DateTime.utc(2026, 1, 20),
              ),
              defaultPaymentMethodId: null,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byTooltip('Cerrar'), findsOneWidget);
      });
    });

    // -----------------------------------------------------------------------
    // Cálculo de días
    // -----------------------------------------------------------------------
    group('cálculo de días', () {
      testWidgets('muestra "10 días restantes" cuando trialEnd es 10d adelante',
          (tester) async {
        // _kNow = 2026-01-10, trialEnd = 2026-01-20 → 10 días
        await _wrap(
          tester,
          notifierFactory: () => _StubBillingV2(
            BillingV2State(
              subscription: _makeSub(
                trialEnd: DateTime.utc(2026, 1, 20),
              ),
              defaultPaymentMethodId: 'pm-existing',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('10 días restantes'), findsOneWidget);
      });

      testWidgets('forma singular: "1 día restante"', (tester) async {
        // _kNow = 2026-01-10, trialEnd = 2026-01-11 → 1 día
        await _wrap(
          tester,
          notifierFactory: () => _StubBillingV2(
            BillingV2State(
              subscription: _makeSub(
                trialEnd: DateTime.utc(2026, 1, 11),
              ),
              defaultPaymentMethodId: 'pm-existing',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('1 día restante'), findsOneWidget);
        // Verifica que NO aparezca la forma plural con 1 día.
        expect(find.text('Trial: 1 días restantes'), findsNothing);
      });

      testWidgets('clamps a 0 días cuando trialEnd ya pasó', (tester) async {
        // _kNow = 2026-01-10, trialEnd = 2026-01-05 → pasado → 0
        await _wrap(
          tester,
          notifierFactory: () => _StubBillingV2(
            BillingV2State(
              subscription: _makeSub(
                trialEnd: DateTime.utc(2026, 1, 5),
              ),
              defaultPaymentMethodId: 'pm-existing',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('0 días restantes'), findsOneWidget);
      });
    });

    // -----------------------------------------------------------------------
    // Visibilidad del CTA
    // -----------------------------------------------------------------------
    group('CTA de método de pago', () {
      testWidgets(
          'muestra "Agregar método" cuando no hay método predeterminado',
          (tester) async {
        await _wrap(
          tester,
          notifierFactory: () => _StubBillingV2(
            BillingV2State(
              subscription: _makeSub(
                trialEnd: DateTime.utc(2026, 1, 20),
              ),
              defaultPaymentMethodId: null,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Agregar método'), findsOneWidget);
      });

      testWidgets(
          'oculta "Agregar método" cuando defaultPaymentMethodId != null',
          (tester) async {
        await _wrap(
          tester,
          notifierFactory: () => _StubBillingV2(
            BillingV2State(
              subscription: _makeSub(
                trialEnd: DateTime.utc(2026, 1, 20),
              ),
              defaultPaymentMethodId: 'pm-xyz-123',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Agregar método'), findsNothing);
      });
    });

    // -----------------------------------------------------------------------
    // Dismiss
    // -----------------------------------------------------------------------
    group('dismiss', () {
      testWidgets('al tocar Cerrar el banner desaparece', (tester) async {
        await _wrap(
          tester,
          notifierFactory: () => _StubBillingV2(
            BillingV2State(
              subscription: _makeSub(
                trialEnd: DateTime.utc(2026, 1, 20),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Banner visible antes de descartar.
        expect(find.byTooltip('Cerrar'), findsOneWidget);

        await tester.tap(find.byTooltip('Cerrar'));
        await tester.pumpAndSettle();

        // Banner oculto tras el dismiss.
        expect(find.byTooltip('Cerrar'), findsNothing);
        expect(find.text('Agregar método'), findsNothing);
      });
    });

    // -----------------------------------------------------------------------
    // Touch target
    // -----------------------------------------------------------------------
    group('touch target', () {
      testWidgets('el botón CTA tiene altura ≥ 48dp', (tester) async {
        await _wrap(
          tester,
          notifierFactory: () => _StubBillingV2(
            BillingV2State(
              subscription: _makeSub(
                trialEnd: DateTime.utc(2026, 1, 20),
              ),
              defaultPaymentMethodId: null,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final buttonSize =
            tester.getSize(find.widgetWithText(FilledButton, 'Agregar método'));
        expect(
          buttonSize.height,
          greaterThanOrEqualTo(48),
          reason: 'El botón CTA tiene altura ${buttonSize.height}, mínimo 48dp',
        );
      });
    });
  });
}

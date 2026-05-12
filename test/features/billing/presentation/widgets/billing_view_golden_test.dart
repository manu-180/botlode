// Archivo: test/features/billing/presentation/widgets/billing_view_golden_test.dart
//
// T4·25 — Golden tests para BillingView (Task 2/5).
//
// Tres escenarios capturados a viewport de escritorio 1280×800:
//   1. trialing  — suscripción en prueba con trialEnd 7 días en el futuro.
//   2. active    — suscripción activa, sin trialEnd.
//   3. past_due  — suscripción con pago pendiente, sin trialEnd.
//
// NOTA SOBRE DETERMINISMO EN `trialing`:
//   BillingView instancia `TrialCountdownBanner` como `const TrialCountdownBanner()`
//   sin reenviar un parámetro `now`, por lo que el banner internamente llama a
//   `DateTime.now()`. El golden de trialing mostrará el número de días calculado
//   en el momento en que se ejecute `--update-goldens`. Para regenerar:
//
//     flutter test --update-goldens \
//       test/features/billing/presentation/widgets/billing_view_golden_test.dart
//
//   Si BillingView se actualiza en el futuro para aceptar y reenviar `now` al
//   banner, reemplazar la fixture y eliminar esta nota.
//
// Generar/actualizar todos los goldens de este archivo:
//   flutter test --update-goldens \
//     test/features/billing/presentation/widgets/billing_view_golden_test.dart

import 'package:botslode/features/billing/domain/models/plan.dart';
import 'package:botslode/features/billing/domain/models/subscription.dart';
import 'package:botslode/features/billing/presentation/providers/billing_provider.dart';
import 'package:botslode/features/billing/presentation/providers/billing_state.dart';
import 'package:botslode/features/billing/presentation/views/billing_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Stub notifier
// ---------------------------------------------------------------------------

/// Devuelve un [BillingV2State] predefinido de inmediato, sin llamadas a
/// Supabase ni repositorios reales.
class _StubBillingV2 extends BillingV2 {
  _StubBillingV2(this._state);

  final BillingV2State _state;

  @override
  Future<BillingV2State> build() async => _state;
}

// ---------------------------------------------------------------------------
// Fixture helpers
// ---------------------------------------------------------------------------

final _kCreatedAt = DateTime.utc(2026, 1, 1);

/// Plan de ejemplo liviano para poblar `availablePlans` sin lógica extra.
Plan _makePlan({
  required String id,
  required String code,
  required String name,
  required int priceCents,
}) =>
    Plan(
      id: id,
      code: code,
      name: name,
      priceCents: priceCents,
      interval: BillingInterval.month,
      maxBots: 5,
      maxConversations: 100,
      features: const {},
      public: true,
      createdAt: _kCreatedAt,
    );

/// Lista mínima de planes para que `PlanPicker` (embebido en Tab 0) tenga
/// datos y no lance errores por lista vacía.
final _kPlans = [
  _makePlan(id: 'plan-s', code: 'starter', name: 'Starter', priceCents: 900),
  _makePlan(id: 'plan-p', code: 'pro', name: 'Pro', priceCents: 2900),
];

// ---------------------------------------------------------------------------
// Helper: pump BillingView
// ---------------------------------------------------------------------------

Future<void> _pumpView(
  WidgetTester tester, {
  required BillingV2 Function() notifierFactory,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        billingV2Provider.overrideWith(notifierFactory),
      ],
      child: MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: const BillingView(),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Golden tests
// ---------------------------------------------------------------------------

void main() {
  group('BillingView — golden', () {
    // -----------------------------------------------------------------------
    // 1. Trialing — banner de cuenta regresiva visible
    // -----------------------------------------------------------------------
    testWidgets('trialing state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // trialEnd fijo 7 días después de una fecha de referencia conocida.
      // El conteo de días visualizado en el banner depende de DateTime.now()
      // en TrialCountdownBanner (ver nota en el encabezado del archivo).
      final trialEnd = DateTime.utc(2026, 6, 8);

      final state = BillingV2State(
        availablePlans: _kPlans,
        subscription: Subscription(
          id: 'sub-trialing',
          tenantId: 'tenant-golden',
          planId: 'plan-s',
          status: SubscriptionStatus.trialing,
          trialEnd: trialEnd,
          createdAt: _kCreatedAt,
          updatedAt: _kCreatedAt,
        ),
      );

      await _pumpView(
        tester,
        notifierFactory: () => _StubBillingV2(state),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(BillingView),
        matchesGoldenFile('goldens/billing_view_trialing.png'),
      );
    });

    // -----------------------------------------------------------------------
    // 2. Active — sin banners; chip "Activa" visible en Tab 0
    // -----------------------------------------------------------------------
    testWidgets('active state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = BillingV2State(
        availablePlans: _kPlans,
        subscription: Subscription(
          id: 'sub-active',
          tenantId: 'tenant-golden',
          planId: 'plan-p',
          status: SubscriptionStatus.active,
          createdAt: _kCreatedAt,
          updatedAt: _kCreatedAt,
        ),
      );

      await _pumpView(
        tester,
        notifierFactory: () => _StubBillingV2(state),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(BillingView),
        matchesGoldenFile('goldens/billing_view_active.png'),
      );
    });

    // -----------------------------------------------------------------------
    // 3. Past due — DunningWarningBanner visible
    // -----------------------------------------------------------------------
    testWidgets('past_due state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = BillingV2State(
        availablePlans: _kPlans,
        subscription: Subscription(
          id: 'sub-pastdue',
          tenantId: 'tenant-golden',
          planId: 'plan-s',
          status: SubscriptionStatus.pastDue,
          createdAt: _kCreatedAt,
          updatedAt: _kCreatedAt,
        ),
      );

      await _pumpView(
        tester,
        notifierFactory: () => _StubBillingV2(state),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(BillingView),
        matchesGoldenFile('goldens/billing_view_past_due.png'),
      );
    });
  });
}

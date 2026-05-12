// Archivo: test/features/billing/presentation/widgets/quota_paywall_modal_test.dart
//
// T4·20 — Widget tests for QuotaPaywallModal.
//
// Strategy:
//   - showQuotaPaywallModal es una función plain que recibe los datos como
//     parámetros; no necesita ProviderScope ni stub de BillingV2.
//   - Los tests usan MaterialApp directo con un Builder para el BuildContext.
//   - Test 3 (navegación) usa un MaterialApp+GoRouter para verificar que el
//     modal se descarta (la navegación real a /billing se comprueba como dismiss).

import 'package:botslode/features/billing/domain/models/plan.dart';
import 'package:botslode/features/billing/domain/models/subscription.dart';
import 'package:botslode/features/billing/domain/quota/quota_result.dart';
import 'package:botslode/features/billing/presentation/widgets/quota_paywall_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

final _kNow = DateTime.utc(2026, 5, 12);

final _freePlan = Plan(
  id: 'plan-free',
  code: 'free',
  name: 'Free',
  priceCents: 0,
  interval: BillingInterval.month,
  maxBots: 1,
  maxConversations: 50,
  createdAt: _kNow,
);

final _starterPlan = Plan(
  id: 'plan-starter',
  code: 'starter',
  name: 'Starter',
  priceCents: 999,
  interval: BillingInterval.month,
  maxBots: 5,
  maxConversations: 500,
  createdAt: _kNow,
);

final _proPlan = Plan(
  id: 'plan-pro',
  code: 'pro',
  name: 'Pro',
  priceCents: 2999,
  interval: BillingInterval.month,
  maxBots: 20,
  maxConversations: 2000,
  createdAt: _kNow,
);

final _botsQuota = QuotaResult.exceeded(used: 1, limit: 1);
final _convsQuota = QuotaResult.exceeded(used: 50, limit: 50);

// ---------------------------------------------------------------------------
// Pump helpers
// ---------------------------------------------------------------------------

/// Bombea la app con MaterialApp simple (sin GoRouter) para tests que no
/// requieren navegación real.
Future<void> _pumpModal(
  WidgetTester tester, {
  required QuotaResult quota,
  required String resource,
  required List<Plan> plans,
  String? currentPlanId,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => showQuotaPaywallModal(
              ctx,
              quota: quota,
              resource: resource,
              plans: plans,
              currentPlanId: currentPlanId,
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}


// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('QuotaPaywallModal', () {
    // -------------------------------------------------------------------------
    // Test 1 — Smoke test bots quota exceeded
    // -------------------------------------------------------------------------
    testWidgets(
        'muestra "Límite alcanzado", nombre del plan y los botones de acción',
        (tester) async {
      await _pumpModal(
        tester,
        quota: _botsQuota,
        resource: 'bots',
        plans: [_freePlan, _starterPlan],
        currentPlanId: _freePlan.id,
      );

      expect(
        find.text('Límite alcanzado'),
        findsOneWidget,
        reason: 'El título del modal debe estar visible',
      );

      expect(
        find.text(_freePlan.name),
        findsOneWidget,
        reason: 'El nombre del plan actual debe aparecer en la tabla',
      );

      expect(
        find.byKey(const Key('ver_planes_btn')),
        findsOneWidget,
        reason: 'El botón "Ver planes" debe estar visible',
      );

      expect(
        find.byKey(const Key('mas_tarde_btn')),
        findsOneWidget,
        reason: 'El botón "Más tarde" debe estar visible',
      );
    });

    // -------------------------------------------------------------------------
    // Test 2 — "Más tarde" cierra el modal sin navegar
    // -------------------------------------------------------------------------
    testWidgets('"Más tarde" cierra el modal', (tester) async {
      await _pumpModal(
        tester,
        quota: _botsQuota,
        resource: 'bots',
        plans: [_freePlan, _starterPlan],
        currentPlanId: _freePlan.id,
      );

      expect(find.text('Límite alcanzado'), findsOneWidget);

      await tester.tap(find.byKey(const Key('mas_tarde_btn')));
      await tester.pumpAndSettle();

      expect(
        find.text('Límite alcanzado'),
        findsNothing,
        reason: 'El modal debe cerrarse al tocar "Más tarde"',
      );
    });

    // -------------------------------------------------------------------------
    // Test 3 — "Ver planes" cierra el modal y navega a /billing
    //
    // Dialogs opened via showDialog are Navigator overlay entries that persist
    // through GoRouter.go() page changes. So finding 'Límite alcanzado' gone
    // after the tap PROVES Navigator.pop() was called — it did not disappear
    // merely from the route replacement.
    // -------------------------------------------------------------------------
    testWidgets('"Ver planes" cierra el modal y navega a /billing',
        (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => showQuotaPaywallModal(
                    ctx,
                    quota: _botsQuota,
                    resource: 'bots',
                    plans: [_freePlan, _starterPlan],
                    currentPlanId: _freePlan.id,
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/billing',
            builder: (context, state) =>
                const Scaffold(body: Text('BillingPage')),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Límite alcanzado'), findsOneWidget);

      await tester.tap(find.byKey(const Key('ver_planes_btn')));
      await tester.pumpAndSettle();

      // Dialogs survive GoRouter.go() since they live in the Navigator overlay.
      // 'Límite alcanzado' being absent proves Navigator.pop() was called.
      expect(
        find.text('Límite alcanzado'),
        findsNothing,
        reason: 'El modal debe haber sido popeado del Navigator',
      );

      // La navegación a /billing ocurrió
      expect(
        find.text('BillingPage'),
        findsOneWidget,
        reason: 'Debe navegar a la ruta /billing',
      );
    });

    // -------------------------------------------------------------------------
    // Test 4 — Tabla comparativa muestra plan actual y siguiente
    // -------------------------------------------------------------------------
    testWidgets('la tabla muestra el plan actual y el siguiente con badge "Recomendado"',
        (tester) async {
      await _pumpModal(
        tester,
        quota: _botsQuota,
        resource: 'bots',
        plans: [_freePlan, _starterPlan, _proPlan],
        currentPlanId: _freePlan.id,
      );

      expect(
        find.text(_freePlan.name),
        findsOneWidget,
        reason: 'El plan actual (Free) debe estar en la tabla',
      );

      expect(
        find.text(_starterPlan.name),
        findsOneWidget,
        reason: 'El siguiente plan (Starter) debe estar en la tabla',
      );

      expect(
        find.text('Recomendado'),
        findsOneWidget,
        reason: 'El plan siguiente debe tener el badge "Recomendado"',
      );

      // El plan superior (Pro) no debe aparecer en la tabla comparativa
      expect(
        find.text(_proPlan.name),
        findsNothing,
        reason: 'Solo debe aparecer el siguiente plan, no todos los superiores',
      );
    });

    // -------------------------------------------------------------------------
    // Test 5 — Copy correcto para bots
    // -------------------------------------------------------------------------
    testWidgets('muestra copy correcto para resource bots', (tester) async {
      await _pumpModal(
        tester,
        quota: _botsQuota,
        resource: 'bots',
        plans: [_freePlan, _starterPlan],
        currentPlanId: _freePlan.id,
      );

      expect(
        find.textContaining('bot(s)'),
        findsOneWidget,
        reason: 'El copy para bots debe mencionar "bot(s)"',
      );
      expect(
        find.textContaining('${_botsQuota.limit}'),
        findsWidgets,
        reason: 'El límite del plan debe aparecer en el copy',
      );
    });

    // -------------------------------------------------------------------------
    // Test 6 — Copy correcto para conversaciones
    // -------------------------------------------------------------------------
    testWidgets('muestra copy correcto para resource conversations',
        (tester) async {
      await _pumpModal(
        tester,
        quota: _convsQuota,
        resource: 'conversations',
        plans: [_freePlan, _starterPlan],
        currentPlanId: _freePlan.id,
      );

      expect(
        find.textContaining('conversación(es)'),
        findsOneWidget,
        reason: 'El copy para conversations debe mencionar "conversación(es)"',
      );
    });

    // -------------------------------------------------------------------------
    // Test 7 — Plan en el tier máximo muestra "Contactar soporte"
    // -------------------------------------------------------------------------
    testWidgets(
        'cuando el plan actual es el más caro muestra "Contactar soporte"',
        (tester) async {
      await _pumpModal(
        tester,
        quota: _botsQuota,
        resource: 'bots',
        plans: [_freePlan, _starterPlan, _proPlan],
        currentPlanId: _proPlan.id, // ya está en el tier máximo
      );

      expect(
        find.text('Contactar soporte'),
        findsOneWidget,
        reason: 'En el tier máximo se debe mostrar "Contactar soporte"',
      );

      expect(
        find.text('Recomendado'),
        findsNothing,
        reason: 'No debe haber badge "Recomendado" si no hay plan superior',
      );
    });
  });
}

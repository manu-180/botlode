// Archivo: test/features/billing/presentation/widgets/trial_countdown_banner_golden_test.dart
//
// T4·18 — Golden tests para TrialCountdownBanner.
//
// Tres estados renderizados a 400×350 con `now` fijo para output determinista:
//   1. info  (>7 días)  — trialEnd 10 días desde _kNow → cyan
//   2. amber (3–7 días) — trialEnd  5 días desde _kNow → naranja
//   3. red   (≤2 días)  — trialEnd  1 día  desde _kNow → rojo (singular)
//
// Todos los estados son sin método de pago predeterminado para mostrar el
// banner completo incluyendo el CTA "Agregar método".
//
// Generar/actualizar goldens:
//   flutter test --update-goldens \
//     test/features/billing/presentation/widgets/trial_countdown_banner_golden_test.dart

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

final _kNow = DateTime.utc(2026, 1, 10, 12, 0); // mediodía UTC
final _kCreatedAt = DateTime.utc(2026, 1, 1);

Subscription _makeSub(DateTime trialEnd) => Subscription(
      id: 'sub-golden',
      tenantId: 'tenant-golden',
      planId: 'plan-001',
      status: SubscriptionStatus.trialing,
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

Future<void> _pumpBanner(
  WidgetTester tester, {
  required DateTime trialEnd,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        billingV2Provider.overrideWith(
          () => _StubBillingV2(
            BillingV2State(
              subscription: _makeSub(trialEnd),
              defaultPaymentMethodId: null,
            ),
          ),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(400, 350)),
          child: Scaffold(
            backgroundColor: const Color(0xFF050A10),
            body: TrialCountdownBanner(now: _kNow),
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
  group('TrialCountdownBanner — golden', () {
    // -----------------------------------------------------------------------
    // 1. Info (>7 días, cyan)
    // -----------------------------------------------------------------------
    testWidgets('info (>7 días, sin método de pago)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 350));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // trialEnd = 2026-01-20 → 10 días desde _kNow (2026-01-10) → cyan
      await _pumpBanner(tester, trialEnd: DateTime.utc(2026, 1, 20));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(TrialCountdownBanner),
        matchesGoldenFile('goldens/trial_countdown_banner_info.png'),
      );
    });

    // -----------------------------------------------------------------------
    // 2. Amber (3–7 días, naranja)
    // -----------------------------------------------------------------------
    testWidgets('amber (3–7 días, sin método de pago)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 350));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // trialEnd = 2026-01-15 → 5 días desde _kNow → naranja
      await _pumpBanner(tester, trialEnd: DateTime.utc(2026, 1, 15));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(TrialCountdownBanner),
        matchesGoldenFile('goldens/trial_countdown_banner_amber.png'),
      );
    });

    // -----------------------------------------------------------------------
    // 3. Red (≤2 días, rojo — singular)
    // -----------------------------------------------------------------------
    testWidgets('red (≤2 días, sin método de pago, singular)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 350));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // trialEnd = 2026-01-11 → 1 día desde _kNow → rojo, forma singular
      await _pumpBanner(tester, trialEnd: DateTime.utc(2026, 1, 11));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(TrialCountdownBanner),
        matchesGoldenFile('goldens/trial_countdown_banner_red.png'),
      );
    });
  });
}

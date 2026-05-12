// Archivo: test/features/billing/presentation/widgets/dunning_warning_banner_golden_test.dart
//
// T4·19 — Golden tests para DunningWarningBanner.
//
// Dos estados renderizados a 400×300:
//   1. past_due con fecha (currentPeriodEnd = 2026-02-01) + errorMessage.
//   2. past_due sin fecha (currentPeriodEnd = null), sin errorMessage.
//
// Generar/actualizar goldens:
//   flutter test --update-goldens \
//     test/features/billing/presentation/widgets/dunning_warning_banner_golden_test.dart

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

Subscription _makeSub({DateTime? currentPeriodEnd}) => Subscription(
      id: 'sub-golden',
      tenantId: 'tenant-golden',
      planId: 'plan-001',
      status: SubscriptionStatus.pastDue,
      currentPeriodEnd: currentPeriodEnd,
      createdAt: _kCreatedAt,
      updatedAt: _kCreatedAt,
    );

// ---------------------------------------------------------------------------
// Stub notifier
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
  required BillingV2State state,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        billingV2Provider.overrideWith(() => _StubBillingV2(state)),
      ],
      child: MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: const MediaQuery(
          data: MediaQueryData(size: Size(400, 300)),
          child: Scaffold(
            backgroundColor: Color(0xFF050A10),
            body: DunningWarningBanner(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Golden tests
// ---------------------------------------------------------------------------

void main() {
  group('DunningWarningBanner — golden', () {
    // -----------------------------------------------------------------------
    // 1. past_due con fecha + error message
    // -----------------------------------------------------------------------
    testWidgets('past_due con fecha y errorMessage', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 300));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpBanner(
        tester,
        state: BillingV2State(
          subscription: _makeSub(
            currentPeriodEnd: DateTime.utc(2026, 2, 1),
          ),
          errorMessage: 'Tu banco rechazó la operación.',
        ),
      );

      await expectLater(
        find.byType(DunningWarningBanner),
        matchesGoldenFile('goldens/dunning_warning_banner_with_date.png'),
      );
    });

    // -----------------------------------------------------------------------
    // 2. past_due sin fecha ni error message
    // -----------------------------------------------------------------------
    testWidgets('past_due sin fecha ni errorMessage', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 300));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpBanner(
        tester,
        state: BillingV2State(
          subscription: _makeSub(currentPeriodEnd: null),
        ),
      );

      await expectLater(
        find.byType(DunningWarningBanner),
        matchesGoldenFile('goldens/dunning_warning_banner_no_date.png'),
      );
    });
  });
}

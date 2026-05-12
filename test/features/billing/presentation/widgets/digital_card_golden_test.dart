// Archivo: test/features/billing/presentation/widgets/digital_card_golden_test.dart
//
// T4·12 — Golden tests for DigitalCard.
//
// Four scenarios at 400×252 (standard credit-card aspect ratio 1.586).
// The [DigitalCard.now] parameter is used as an injectable clock so goldens
// are fully deterministic regardless of when they are run.
//
// Run once to generate / regenerate the reference images:
//   flutter test --update-goldens \
//     test/features/billing/presentation/widgets/digital_card_golden_test.dart

import 'package:botslode/features/billing/domain/models/payment_method.dart';
import 'package:botslode/features/billing/domain/models/subscription.dart'
    show PaymentGateway;
import 'package:botslode/features/billing/presentation/widgets/digital_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fixture helpers
// ---------------------------------------------------------------------------

final _kCreatedAt = DateTime.utc(2026, 1, 1);

PaymentMethod _makeMethod({
  required String brand,
  required String last4,
  required int expMonth,
  required int expYear,
}) =>
    PaymentMethod(
      id: 'pm-test',
      tenantId: 'tenant-test',
      gateway: PaymentGateway.stripe,
      gatewayToken: 'tok_NEVER_DISPLAY',
      brand: brand,
      last4: last4,
      expMonth: expMonth,
      expYear: expYear,
      isDefault: true,
      createdAt: _kCreatedAt,
    );

// ---------------------------------------------------------------------------
// Test harness helper
// ---------------------------------------------------------------------------

Future<void> _pumpCard(
  WidgetTester tester, {
  required DigitalCard card,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        backgroundColor: const Color(0xFF050A10),
        body: Center(
          child: SizedBox(
            width: 400,
            child: card,
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
  // Surface size: 400 wide × 252 high (≈ 400 / 1.586)
  const surfaceSize = Size(400, 252);

  group('DigitalCard — goldens', () {
    // -----------------------------------------------------------------------
    // 1. Visa valid (never expires in tests: expYear=2099, expMonth=12)
    // -----------------------------------------------------------------------
    testWidgets('visa_valid', (tester) async {
      await tester.binding.setSurfaceSize(surfaceSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpCard(
        tester,
        card: DigitalCard(
          method: _makeMethod(
            brand: 'visa',
            last4: '4242',
            expMonth: 12,
            expYear: 2099,
          ),
          // Inject a fixed clock well before expiry — card is always valid
          now: DateTime(2026, 1, 1),
        ),
      );

      await expectLater(
        find.byType(DigitalCard),
        matchesGoldenFile('goldens/visa_valid.png'),
      );
    });

    // -----------------------------------------------------------------------
    // 2. Mastercard expired (expMonth=1, expYear=2020 — always in the past)
    // -----------------------------------------------------------------------
    testWidgets('mastercard_expired', (tester) async {
      await tester.binding.setSurfaceSize(surfaceSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpCard(
        tester,
        card: DigitalCard(
          method: _makeMethod(
            brand: 'mastercard',
            last4: '5555',
            expMonth: 1,
            expYear: 2020,
          ),
          now: DateTime(2026, 1, 1),
        ),
      );

      await expectLater(
        find.byType(DigitalCard),
        matchesGoldenFile('goldens/mastercard_expired.png'),
      );
    });

    // -----------------------------------------------------------------------
    // 3. Amex expiring soon — inject now=2099-11-20, card expires 2099-12
    //    Difference = ~10 days → "VENCE PRONTO" badge
    // -----------------------------------------------------------------------
    testWidgets('amex_expiring_soon', (tester) async {
      await tester.binding.setSurfaceSize(surfaceSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpCard(
        tester,
        card: DigitalCard(
          method: _makeMethod(
            brand: 'amex',
            last4: '0005',
            expMonth: 12,
            expYear: 2099,
          ),
          // 20 Nov 2099 → expires 1 Jan 2100 → 42 days away → NOT expiring yet
          // Use 1 Dec 2099 → expires 1 Jan 2100 → 31 days away → still not ≤30
          // Use 2 Dec 2099 → expires 1 Jan 2100 → 30 days → exactly ≤30
          now: DateTime(2099, 12, 2),
        ),
      );

      await expectLater(
        find.byType(DigitalCard),
        matchesGoldenFile('goldens/amex_expiring_soon.png'),
      );
    });

    // -----------------------------------------------------------------------
    // 4. Empty state — no method
    // -----------------------------------------------------------------------
    testWidgets('empty', (tester) async {
      await tester.binding.setSurfaceSize(surfaceSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpCard(
        tester,
        card: const DigitalCard(method: null),
      );

      await expectLater(
        find.byType(DigitalCard),
        matchesGoldenFile('goldens/empty.png'),
      );
    });
  });
}

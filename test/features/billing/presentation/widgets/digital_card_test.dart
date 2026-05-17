// Archivo: test/features/billing/presentation/widgets/digital_card_test.dart
//
// T4·12 — Unit/widget tests for DigitalCard.
//
// Tests cover:
//   1. Empty state renders "Sin tarjeta agregada" when method is null
//   2. Valid card shows last4, no expired/expiring badges
//   3. Expired card shows "VENCIDA" badge
//   4. Expiring-soon card shows "VENCE PRONTO" badge
//   5. Only last4 (≤4 digits) is displayed — never full PAN
//   6. Brand semantics label is correct

import 'package:botslode/features/billing/domain/models/payment_method.dart';
import 'package:botslode/features/billing/domain/models/subscription.dart'
    show PaymentGateway;
import 'package:botslode/features/billing/presentation/widgets/digital_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fixture helper
// ---------------------------------------------------------------------------

final _kCreatedAt = DateTime.utc(2026, 1, 1);

PaymentMethod _makeMethod({
  String brand = 'visa',
  String last4 = '4242',
  int expMonth = 12,
  int expYear = 2099,
  bool isDefault = true,
}) =>
    PaymentMethod(
      id: 'pm-test',
      tenantId: 'tenant-test',
      gateway: PaymentGateway.stripe,
      // PCI: never displayed — widget must not show this
      gatewayToken: 'tok_test_NEVER_DISPLAY_SECRET',
      brand: brand,
      last4: last4,
      expMonth: expMonth,
      expYear: expYear,
      isDefault: isDefault,
      createdAt: _kCreatedAt,
    );

// ---------------------------------------------------------------------------
// Pump helper
// ---------------------------------------------------------------------------

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        body: SizedBox(width: 400, child: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('DigitalCard', () {
    // -----------------------------------------------------------------------
    // 1. Empty state
    // -----------------------------------------------------------------------
    testWidgets('renders empty state when method is null', (tester) async {
      await _pump(tester, const DigitalCard(method: null));

      expect(find.text('Sin tarjeta agregada'), findsOneWidget);
      expect(find.text('Agregar tarjeta'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // 2. Valid card — shows last4, no status badges
    // -----------------------------------------------------------------------
    testWidgets('valid card shows last4 and no status badge', (tester) async {
      await _pump(
        tester,
        DigitalCard(
          method: _makeMethod(last4: '4242', expMonth: 12, expYear: 2099),
          now: DateTime(2026, 1, 1),
        ),
      );

      // last4 is visible
      expect(find.text('4242'), findsOneWidget);

      // no expired or expiring-soon badge
      expect(find.text('VENCIDA'), findsNothing);
      expect(find.text('VENCE PRONTO'), findsNothing);

      // empty state is not shown
      expect(find.text('Sin tarjeta agregada'), findsNothing);
    });

    // -----------------------------------------------------------------------
    // 3. Expired card — shows "VENCIDA" badge
    // -----------------------------------------------------------------------
    testWidgets('expired card renders VENCIDA badge', (tester) async {
      await _pump(
        tester,
        DigitalCard(
          method: _makeMethod(last4: '5555', expMonth: 1, expYear: 2020),
          now: DateTime(2026, 1, 1), // well after Jan 2020
        ),
      );

      expect(find.text('VENCIDA'), findsOneWidget);
      expect(find.text('VENCE PRONTO'), findsNothing);
    });

    // -----------------------------------------------------------------------
    // 4. Expiring soon — shows "VENCE PRONTO" badge
    // -----------------------------------------------------------------------
    testWidgets('expiring-soon card renders VENCE PRONTO badge', (tester) async {
      // Card expires end of Dec 2099; inject clock at Dec 2 2099 (30 days until Jan 1 2100)
      await _pump(
        tester,
        DigitalCard(
          method: _makeMethod(last4: '0005', expMonth: 12, expYear: 2099),
          now: DateTime(2099, 12, 2),
        ),
      );

      expect(find.text('VENCE PRONTO'), findsOneWidget);
      expect(find.text('VENCIDA'), findsNothing);
    });

    // -----------------------------------------------------------------------
    // 5. Only last4 is shown — never full PAN or gatewayToken
    // -----------------------------------------------------------------------
    testWidgets('does not display more than 4 consecutive digits', (tester) async {
      await _pump(
        tester,
        DigitalCard(
          method: _makeMethod(
            last4: '4242',
            // gatewayToken contains 'tok_test_NEVER_DISPLAY_SECRET' (no long digit sequence)
          ),
          now: DateTime(2026, 1, 1),
        ),
      );

      final allTexts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? (t.textSpan?.toPlainText() ?? ''))
          .toList();

      // Check each widget individually — a widget with ≥5 consecutive digits could be PAN leak
      final panPattern = RegExp(r'\d{5,}');
      for (final text in allTexts) {
        expect(
          panPattern.hasMatch(text),
          isFalse,
          reason: 'Widget text "$text" contains 5+ consecutive digits — possible PAN leak',
        );
      }

      // Also join all texts to catch split-across-widget leakage
      final joined = allTexts.join('');
      expect(
        panPattern.hasMatch(joined),
        isFalse,
        reason: 'Joined text "$joined" contains 5+ consecutive digits — possible PAN leak',
      );

      // gatewayToken must not appear verbatim
      expect(find.textContaining('NEVER_DISPLAY_SECRET'), findsNothing);
      expect(find.textContaining('tok_test'), findsNothing);
    });

    // -----------------------------------------------------------------------
    // 6. Brand semantics label
    // -----------------------------------------------------------------------
    testWidgets('brand semantics label matches brand value', (tester) async {
      await _pump(
        tester,
        DigitalCard(
          method: _makeMethod(brand: 'visa'),
          now: DateTime(2026, 1, 1),
        ),
      );

      // Locate the Semantics node that wraps the brand icon
      final semanticsWidgets = tester.widgetList<Semantics>(find.byType(Semantics));
      final labels = semanticsWidgets
          .where((s) => s.properties.label != null)
          .map((s) => s.properties.label!)
          .toList();

      expect(
        labels.any((l) => l.contains('visa')),
        isTrue,
        reason: 'Expected a Semantics widget with label containing "visa"',
      );
    });

    // -----------------------------------------------------------------------
    // 7. Null last4 shows placeholder bullets
    // -----------------------------------------------------------------------
    testWidgets('null last4 shows bullet placeholder', (tester) async {
      await _pump(
        tester,
        DigitalCard(
          method: _makeMethod(last4: '').copyWith(last4: null),
          now: DateTime(2026, 1, 1),
        ),
      );

      // The masked-number section should fall back to ••••
      expect(find.textContaining('••••'), findsWidgets);
    });

    // -----------------------------------------------------------------------
    // 8. Unknown brand falls back gracefully (no exception)
    // -----------------------------------------------------------------------
    testWidgets('unknown brand renders without throwing', (tester) async {
      await _pump(
        tester,
        DigitalCard(
          method: _makeMethod(brand: 'discover'),
          now: DateTime(2026, 1, 1),
        ),
      );

      // Should not throw and card should still be rendered
      expect(find.byType(DigitalCard), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Expiry boundary tests
    // -----------------------------------------------------------------------
    testWidgets('card is expired at the exact flip moment (first of next month)', (tester) async {
      await _pump(
        tester,
        DigitalCard(
          method: _makeMethod(expMonth: 12, expYear: 2099),
          now: DateTime(2100, 1, 1), // exactly when card expires
        ),
      );
      expect(find.text('VENCIDA'), findsOneWidget);
      expect(find.text('VENCE PRONTO'), findsNothing);
    });

    testWidgets('card is expiring-soon exactly 30 days before flip', (tester) async {
      await _pump(
        tester,
        DigitalCard(
          method: _makeMethod(expMonth: 12, expYear: 2099),
          now: DateTime(2099, 12, 2), // 30 days to Jan 1 2100
        ),
      );
      expect(find.text('VENCE PRONTO'), findsOneWidget);
      expect(find.text('VENCIDA'), findsNothing);
    });

    testWidgets('card is NOT expiring-soon when 31 days before flip', (tester) async {
      await _pump(
        tester,
        DigitalCard(
          method: _makeMethod(expMonth: 12, expYear: 2099),
          now: DateTime(2099, 12, 1), // 31 days to Jan 1 2100
        ),
      );
      expect(find.text('VENCE PRONTO'), findsNothing);
      expect(find.text('VENCIDA'), findsNothing);
    });
  });
}

// Archivo: test/features/billing/presentation/widgets/empty_state_test.dart
//
// T4·29 — Unit/widget tests for BillingEmptyState.
// Pure widget — no providers, no mocks needed.

import 'package:botslode/features/billing/presentation/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('BillingEmptyState', () {
    testWidgets('shows title and subtitle text', (tester) async {
      await tester.pumpWidget(_wrap(
        const BillingEmptyState(
          title: 'Test Title',
          subtitle: 'Test Subtitle',
        ),
      ));

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Subtitle'), findsOneWidget);
    });

    testWidgets('shows illustration when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        const BillingEmptyState(
          illustration: Icon(Icons.receipt_long, key: Key('illus')),
          title: 'Title',
          subtitle: 'Subtitle',
        ),
      ));

      expect(find.byKey(const Key('illus')), findsOneWidget);
    });

    testWidgets('does NOT show CTA button when ctaLabel is null', (tester) async {
      await tester.pumpWidget(_wrap(
        const BillingEmptyState(
          title: 'Title',
          subtitle: 'Subtitle',
        ),
      ));

      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('shows CTA button when ctaLabel is provided', (tester) async {
      await tester.pumpWidget(_wrap(
        const BillingEmptyState(
          title: 'Title',
          subtitle: 'Subtitle',
          ctaLabel: 'Tap me',
        ),
      ));

      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.text('Tap me'), findsOneWidget);
    });

    testWidgets('CTA button has minimum 48dp height', (tester) async {
      await tester.pumpWidget(_wrap(
        const BillingEmptyState(
          title: 'Title',
          subtitle: 'Subtitle',
          ctaLabel: 'Action',
        ),
      ));

      final size = tester.getSize(find.byType(OutlinedButton));
      expect(size.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('calls onCta when CTA button is tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(_wrap(
        BillingEmptyState(
          title: 'Title',
          subtitle: 'Subtitle',
          ctaLabel: 'Do it',
          onCta: () => tapped = true,
        ),
      ));

      await tester.tap(find.byType(OutlinedButton));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('semantics label without CTA', (tester) async {
      await tester.pumpWidget(_wrap(
        const BillingEmptyState(
          title: 'No hay datos',
          subtitle: 'Volvé más tarde.',
        ),
      ));

      final semantics = tester.getSemantics(find.byType(BillingEmptyState));
      expect(semantics.label, contains('No hay datos'));
      expect(semantics.label, contains('Volvé más tarde.'));
      expect(semantics.label, isNot(contains('Botón:')));
    });

    testWidgets('semantics label with CTA includes button hint', (tester) async {
      await tester.pumpWidget(_wrap(
        const BillingEmptyState(
          title: 'Sin suscripción',
          subtitle: 'Elegí un plan.',
          ctaLabel: 'Ver planes',
        ),
      ));

      final semantics = tester.getSemantics(find.byType(BillingEmptyState));
      expect(semantics.label, contains('Sin suscripción'));
      expect(semantics.label, contains('Elegí un plan.'));
      expect(semantics.label, contains('Ver planes'));
    });

    testWidgets('does NOT show illustration section when illustration is null',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const BillingEmptyState(
          title: 'Title',
          subtitle: 'Subtitle',
        ),
      ));

      expect(
        find.descendant(
          of: find.byType(BillingEmptyState),
          matching: find.byType(Icon),
        ),
        findsNothing,
      );
    });
  });
}

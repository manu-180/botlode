// Archivo: test/features/billing/presentation/widgets/empty_state_golden_test.dart
//
// T4·29 — Golden tests for BillingEmptyState (3 states).
//
// Run once to generate / regenerate the reference images:
//   flutter test --update-goldens \
//     test/features/billing/presentation/widgets/empty_state_golden_test.dart

import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/billing/presentation/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, {required BillingEmptyState widget}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: SizedBox(width: 400, child: widget),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  const surfaceSize = Size(400, 300);

  group('BillingEmptyState — goldens', () {
    testWidgets('empty_cards', (tester) async {
      await tester.binding.setSurfaceSize(surfaceSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pump(
        tester,
        widget: const BillingEmptyState(
          illustration: Icon(Icons.credit_card_off_rounded, size: 48, color: Colors.white24),
          title: 'Aún no agregaste métodos de pago',
          subtitle: 'Agregá una tarjeta para habilitar el cobro automático.',
          ctaLabel: 'Agregar tarjeta',
        ),
      );

      await expectLater(
        find.byType(BillingEmptyState),
        matchesGoldenFile('goldens/billing_empty_cards.png'),
      );
    });

    testWidgets('empty_invoices', (tester) async {
      await tester.binding.setSurfaceSize(surfaceSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pump(
        tester,
        widget: const BillingEmptyState(
          illustration: Icon(Icons.receipt_long, size: 48, color: Colors.white38),
          title: 'Sin facturas todavía',
          subtitle: 'Aparecerán acá cuando se emita la primera.',
        ),
      );

      await expectLater(
        find.byType(BillingEmptyState),
        matchesGoldenFile('goldens/billing_empty_invoices.png'),
      );
    });

    testWidgets('empty_subscription', (tester) async {
      await tester.binding.setSurfaceSize(surfaceSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pump(
        tester,
        widget: const BillingEmptyState(
          illustration: Icon(Icons.workspace_premium_rounded, size: 48, color: Colors.white24),
          title: 'No tenés una suscripción activa',
          subtitle: 'Elegí un plan para comenzar a usar BotLode.',
          ctaLabel: 'Ver planes',
        ),
      );

      await expectLater(
        find.byType(BillingEmptyState),
        matchesGoldenFile('goldens/billing_empty_subscription.png'),
      );
    });
  });
}

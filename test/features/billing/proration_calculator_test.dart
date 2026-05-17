import 'package:flutter_test/flutter_test.dart';
import 'package:botslode/features/billing/domain/models/plan.dart';
import 'package:botslode/features/billing/domain/models/subscription.dart';
import 'package:botslode/features/billing/domain/proration/proration_calculator.dart';
import 'package:botslode/features/billing/domain/proration/proration_input.dart';
import 'package:botslode/features/billing/domain/proration/proration_output.dart';

void main() {
  const calculator = ProrationCalculator();

  // Helper to build a plan
  Plan makePlan({
    required String id,
    required String code,
    required int priceCents,
    String currency = 'USD',
  }) =>
      Plan(
        id: id,
        code: code,
        name: code,
        priceCents: priceCents,
        currency: currency,
        interval: BillingInterval.month,
        maxBots: 5,
        maxConversations: 1000,
        createdAt: DateTime(2026),
      );

  final starter = makePlan(id: 'plan-starter', code: 'starter', priceCents: 2900);
  final agency = makePlan(id: 'plan-agency', code: 'agency', priceCents: 9900);
  final agencyEur = makePlan(id: 'plan-agency-eur', code: 'agency', priceCents: 9900, currency: 'EUR');

  final periodStart = DateTime.utc(2026, 1, 1);
  final periodEnd = DateTime.utc(2026, 1, 31); // 30 days

  ProrationInput makeInput({
    required Plan current,
    required Plan newPlan,
    required DateTime changeAt,
    String currency = 'USD',
  }) =>
      ProrationInput(
        currentPlan: current,
        newPlan: newPlan,
        currentPeriodStart: periodStart,
        currentPeriodEnd: periodEnd,
        changeAt: changeAt,
        currency: currency,
      );

  group('ProrationCalculator', () {
    test('upgrade mid-period produces 2 lines, net charge positive', () {
      // 15 days remaining out of 30
      final input = makeInput(
        current: starter,
        newPlan: agency,
        changeAt: DateTime.utc(2026, 1, 16), // 15 days remaining
      );

      final output = calculator.compute(input);

      expect(output.lines.length, 2);
      final credit = output.lines.first; // unused time on starter
      final charge = output.lines.last;  // remaining time on agency

      expect(credit.amountCents, isNegative, reason: 'Credit should be negative');
      expect(charge.amountCents, isPositive, reason: 'Charge should be positive');
      expect(output.netAmountCents, isPositive, reason: 'Net should be positive for upgrade');
      expect(credit.proration, isTrue);
      expect(charge.proration, isTrue);
    });

    test('downgrade mid-period: credit magnitude > charge', () {
      final input = makeInput(
        current: agency,
        newPlan: starter,
        changeAt: DateTime.utc(2026, 1, 16),
      );

      final output = calculator.compute(input);

      expect(output.lines.length, 2);
      final credit = output.lines.first.amountCents.abs();
      final charge = output.lines.last.amountCents;
      expect(credit, greaterThan(charge), reason: 'Downgrade: credit > charge');
      expect(output.netAmountCents, isNegative);
    });

    test('same plan returns empty output', () {
      final input = makeInput(
        current: starter,
        newPlan: starter,
        changeAt: DateTime.utc(2026, 1, 16),
      );

      final output = calculator.compute(input);
      expect(output.isEmpty, isTrue);
    });

    test('currency mismatch throws ProrationCurrencyMismatch', () {
      expect(
        () => calculator.compute(makeInput(
          current: starter,
          newPlan: agencyEur,
          changeAt: DateTime.utc(2026, 1, 16),
          currency: 'USD',
        )),
        throwsA(isA<ProrationCurrencyMismatch>()),
      );
    });

    test('changeAt before period start throws ProrationOutOfWindowException', () {
      expect(
        () => calculator.compute(makeInput(
          current: starter,
          newPlan: agency,
          changeAt: DateTime.utc(2025, 12, 31),
        )),
        throwsA(isA<ProrationOutOfWindowException>()),
      );
    });

    test('changeAt after period end throws ProrationOutOfWindowException', () {
      expect(
        () => calculator.compute(makeInput(
          current: starter,
          newPlan: agency,
          changeAt: DateTime.utc(2026, 2, 1),
        )),
        throwsA(isA<ProrationOutOfWindowException>()),
      );
    });

    test('change at exact period start: 30 days remaining → full charge', () {
      final input = makeInput(
        current: starter,
        newPlan: agency,
        changeAt: periodStart,
      );

      final output = calculator.compute(input);
      expect(output.lines.length, 2);
      // Full credit for starter (30/30), full charge for agency (30/30)
      expect(output.lines.first.amountCents, equals(-starter.priceCents));
      expect(output.lines.last.amountCents, equals(agency.priceCents));
    });

    test('change at exact period end: 0 days remaining → zero amounts', () {
      final input = makeInput(
        current: starter,
        newPlan: agency,
        changeAt: periodEnd,
      );

      final output = calculator.compute(input);
      expect(output.lines.length, 2);
      expect(output.lines.first.amountCents, isZero);
      expect(output.lines.last.amountCents, isZero);
    });
  });
}

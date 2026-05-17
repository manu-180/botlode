// lib/features/billing/domain/proration/proration_calculator.dart

import 'package:botslode/features/billing/domain/exceptions/billing_exception.dart';
import 'package:botslode/features/billing/domain/proration/proration_input.dart';
import 'package:botslode/features/billing/domain/proration/proration_output.dart';

class ProrationCalculator {
  const ProrationCalculator();

  ProrationOutput compute(ProrationInput input) {
    final totalDays = input.currentPeriodEnd
        .difference(input.currentPeriodStart)
        .inDays;

    if (totalDays <= 0) {
      throw const BillingRepositoryException(
        code: 'invalid_period',
        message: 'El período de facturación tiene duración cero o negativa.',
      );
    }

    final changeAt = input.changeAt.isBefore(input.currentPeriodStart)
        ? input.currentPeriodStart
        : input.changeAt.isAfter(input.currentPeriodEnd)
            ? input.currentPeriodEnd
            : input.changeAt;

    final daysRemaining =
        input.currentPeriodEnd.difference(changeAt).inDays;

    final dailyRateCurrent = input.currentPlan.priceMonthly / totalDays;
    final dailyRateNew = input.newPlan.priceMonthly / totalDays;

    final creditAmount =
        double.parse((dailyRateCurrent * daysRemaining).toStringAsFixed(2));
    final chargeAmount =
        double.parse((dailyRateNew * daysRemaining).toStringAsFixed(2));
    final netAmount =
        double.parse((chargeAmount - creditAmount).toStringAsFixed(2));

    return ProrationOutput(
      creditAmount: creditAmount,
      chargeAmount: chargeAmount,
      netAmount: netAmount,
      currency: input.currency,
      daysRemaining: daysRemaining,
      totalDays: totalDays,
    );
  }
}

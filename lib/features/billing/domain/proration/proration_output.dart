// lib/features/billing/domain/proration/proration_output.dart

class ProrationOutput {
  /// Credit for unused days on the current plan.
  final double creditAmount;

  /// Charge for remaining days on the new plan.
  final double chargeAmount;

  /// Net amount due (chargeAmount - creditAmount). Negative means a refund.
  final double netAmount;

  final String currency;

  /// Days remaining in the billing period from [changeAt].
  final int daysRemaining;

  /// Total days in the billing period.
  final int totalDays;

  const ProrationOutput({
    required this.creditAmount,
    required this.chargeAmount,
    required this.netAmount,
    required this.currency,
    required this.daysRemaining,
    required this.totalDays,
  });
}

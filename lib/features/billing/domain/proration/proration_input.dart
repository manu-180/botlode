// lib/features/billing/domain/proration/proration_input.dart

import 'package:botslode/features/billing/domain/models/plan.dart';

class ProrationInput {
  final Plan currentPlan;
  final Plan newPlan;
  final DateTime currentPeriodStart;
  final DateTime currentPeriodEnd;
  final DateTime changeAt;
  final String currency;

  const ProrationInput({
    required this.currentPlan,
    required this.newPlan,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    required this.changeAt,
    required this.currency,
  });
}

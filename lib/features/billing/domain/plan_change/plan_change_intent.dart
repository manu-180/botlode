// Archivo: lib/features/billing/domain/plan_change/plan_change_intent.dart

import 'package:botslode/features/billing/domain/models/plan.dart';
import 'package:botslode/features/billing/domain/models/subscription.dart';
import 'package:botslode/features/billing/domain/proration/proration_output.dart';

/// Clasifica el tipo de cambio de plan.
enum PlanChangeKind {
  /// Plan destino más caro (mismo o distinto intervalo). Se aplica inmediatamente.
  upgrade,

  /// Plan destino más barato. Se aplica al fin del período actual.
  downgrade,

  /// Mismo plan: no hay cambio.
  sameTier,
}

/// Payload producido por [PlanChangeService.decide] para enviar a la Edge Function.
///
/// El cliente envía este intent como body de la Edge Function junto con el
/// header `X-Idempotency-Key`. La edge re-valida el intent antes de ejecutar.
///
/// Trial → paid: si la suscripción está en `trialing`, el upgrade cobra
/// inmediatamente y termina el período de trial. Documentado aquí porque
/// la edge function implementa esta regla con la misma semántica.
class PlanChangeIntent {
  final Subscription currentSub;
  final Plan targetPlan;

  /// Para upgrade: `now`. Para downgrade: `currentSub.currentPeriodEnd`.
  final DateTime effectiveAt;

  /// Líneas de prorrateo calculadas. Vacío para downgrade (no hay prorrateo).
  final List<ProrationLine> prorationLines;

  final PlanChangeKind kind;

  /// `true` si el cambio es inmediato (upgrade); `false` si es al fin del período.
  final bool immediate;

  const PlanChangeIntent({
    required this.currentSub,
    required this.targetPlan,
    required this.effectiveAt,
    required this.prorationLines,
    required this.kind,
    required this.immediate,
  });
}

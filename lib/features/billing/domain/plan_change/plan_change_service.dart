// Archivo: lib/features/billing/domain/plan_change/plan_change_service.dart

import 'package:botslode/features/billing/domain/models/plan.dart';
import 'package:botslode/features/billing/domain/models/subscription.dart';
import 'package:botslode/features/billing/domain/proration/proration_calculator.dart';
import 'package:botslode/features/billing/domain/proration/proration_input.dart';
import 'package:botslode/features/billing/domain/proration/proration_output.dart';
import 'plan_change_intent.dart';

/// Excepción cuando el estado de la suscripción impide el cambio de plan.
class PlanChangeBlockedException implements Exception {
  final String message;
  const PlanChangeBlockedException(this.message);
  @override
  String toString() => 'PlanChangeBlockedException: $message';
}

/// Excepción cuando los planes tienen monedas incompatibles.
class PlanChangeCurrencyMismatch implements Exception {
  final String message;
  const PlanChangeCurrencyMismatch(this.message);
  @override
  String toString() => 'PlanChangeCurrencyMismatch: $message';
}

/// Servicio puro que decide la política de cambio de plan (upgrade/downgrade).
///
/// Reglas de negocio:
/// - **Upgrade** (targetPlan.priceCents > currentPlan.priceCents, o cambio de
///   intervalo): inmediato con prorrateo. Trial → paid también aplica aquí.
/// - **Downgrade** (targetPlan.priceCents < currentPlan.priceCents): programado
///   para el fin del período; sin prorrateo.
/// - **Same tier**: no-op (intent vacío).
/// - **past_due**: bloqueado hasta resolver el dunning.
///
/// Esta función es pura: no escribe en DB. El caller envía el [PlanChangeIntent]
/// a la Edge Function que re-valida y ejecuta.
class PlanChangeService {
  final ProrationCalculator _prorationCalculator;

  const PlanChangeService({
    ProrationCalculator prorationCalculator = const ProrationCalculator(),
  }) : _prorationCalculator = prorationCalculator;

  /// Decide la política de cambio de plan.
  ///
  /// [now] debe ser UTC. Se usa como `effectiveAt` para upgrades y como fecha
  /// de referencia para el cálculo de prorrateo.
  PlanChangeIntent decide({
    required Subscription currentSub,
    required Plan currentPlan,
    required Plan targetPlan,
    required DateTime now,
  }) {
    _validateStatus(currentSub);
    _validateCurrency(currentPlan, targetPlan);

    if (targetPlan.id == currentSub.planId) {
      return PlanChangeIntent(
        currentSub: currentSub,
        targetPlan: targetPlan,
        effectiveAt: now,
        prorationLines: const [],
        kind: PlanChangeKind.sameTier,
        immediate: false,
      );
    }

    // Cambio de intervalo (mensual ↔ anual) se trata como upgrade.
    final isIntervalChange = targetPlan.interval != currentPlan.interval;
    final isUpgrade = targetPlan.priceCents > currentPlan.priceCents;

    if (isUpgrade || isIntervalChange) {
      return _buildUpgradeIntent(
        currentSub: currentSub,
        currentPlan: currentPlan,
        targetPlan: targetPlan,
        now: now,
      );
    }

    return _buildDowngradeIntent(
      currentSub: currentSub,
      targetPlan: targetPlan,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers privados
  // ---------------------------------------------------------------------------

  PlanChangeIntent _buildUpgradeIntent({
    required Subscription currentSub,
    required Plan currentPlan,
    required Plan targetPlan,
    required DateTime now,
  }) {
    List<ProrationLine> prorationLines = const [];

    if (currentSub.currentPeriodStart != null &&
        currentSub.currentPeriodEnd != null) {
      final input = ProrationInput(
        currentPlan: currentPlan,
        newPlan: targetPlan,
        currentPeriodStart: currentSub.currentPeriodStart!,
        currentPeriodEnd: currentSub.currentPeriodEnd!,
        changeAt: now,
        currency: currentPlan.currency,
      );
      try {
        prorationLines = _prorationCalculator.compute(input).lines;
      } catch (_) {
        // Si el cálculo falla (p.ej. fuera de ventana), el intent igualmente
        // procede sin líneas de prorrateo; la edge function recalcula.
        prorationLines = const [];
      }
    }

    return PlanChangeIntent(
      currentSub: currentSub,
      targetPlan: targetPlan,
      effectiveAt: now,
      prorationLines: prorationLines,
      kind: PlanChangeKind.upgrade,
      immediate: true,
    );
  }

  PlanChangeIntent _buildDowngradeIntent({
    required Subscription currentSub,
    required Plan targetPlan,
  }) {
    return PlanChangeIntent(
      currentSub: currentSub,
      targetPlan: targetPlan,
      effectiveAt: currentSub.currentPeriodEnd ?? DateTime.now().toUtc(),
      prorationLines: const [],
      kind: PlanChangeKind.downgrade,
      immediate: false,
    );
  }

  void _validateStatus(Subscription sub) {
    if (sub.status == SubscriptionStatus.pastDue) {
      throw const PlanChangeBlockedException(
        'resolve dunning first — subscription is past_due',
      );
    }
    if (sub.status == SubscriptionStatus.canceled ||
        sub.status == SubscriptionStatus.incomplete) {
      throw PlanChangeBlockedException(
        'subscription is ${sub.status.name}; cannot change plan',
      );
    }
  }

  void _validateCurrency(Plan currentPlan, Plan targetPlan) {
    if (currentPlan.currency != targetPlan.currency) {
      throw PlanChangeCurrencyMismatch(
        'Current plan currency "${currentPlan.currency}" differs from '
        'target plan currency "${targetPlan.currency}"',
      );
    }
  }
}

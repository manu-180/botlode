// Archivo: lib/features/billing/domain/dunning/dunning_state_machine.dart

import 'dunning_state.dart';

/// Máquina de estados pura para el flujo de dunning (cobros fallidos).
///
/// Política 7-14-21-35 días (fuente: GLOSSARY "Convenciones de cobro"):
/// - Intento 0 → retry en `firstFailedAt + 7 días`.
/// - Intento 1 fallido → retry en `firstFailedAt + 14 días`.
/// - Intento 2 fallido → retry en `firstFailedAt + 21 días` + notificación.
/// - Intento 3 fallido → suspend (past_due, sin acceso).
/// - 35+ días desde primer fallo → soft_delete (cancelación).
///
/// IMPORTANTE: Todos los [DateTime] en [DunningContext] deben estar en UTC.
/// Esta función es pura: no escribe en la base de datos. El caller (Edge T5)
/// es responsable de insertar en `dunning_attempts` con la decisión producida.
///
/// Si la política cambia, actualizar GLOSSARY primero y luego este código.
class DunningStateMachine {
  static const int _retryDay1 = 7;
  static const int _retryDay2 = 14;
  static const int _retryDay3 = 21;
  static const int _softDeleteDay = 35;

  const DunningStateMachine();

  /// Decide la próxima acción dado el [ctx].
  ///
  /// Determinstico: el mismo [ctx] siempre produce la misma [DunningDecision].
  DunningDecision decide(DunningContext ctx) {
    final daysSinceFirstFail =
        ctx.now.difference(ctx.firstFailedAt).inDays;

    // Soft-delete tiene prioridad sobre suspend si ya pasaron 35 días.
    if (ctx.attempts.length >= 3 && daysSinceFirstFail >= _softDeleteDay) {
      return DunningDecision(
        action: DunningAction.softDelete,
        reason:
            '$daysSinceFirstFail days since first failure (>= $_softDeleteDay); '
            'canceling subscription',
      );
    }

    switch (ctx.attempts.length) {
      case 0:
        return DunningDecision(
          action: DunningAction.retry,
          nextRetryAt:
              ctx.firstFailedAt.add(const Duration(days: _retryDay1)),
          reason: 'First attempt scheduled at +$_retryDay1 days',
        );

      case 1:
        return DunningDecision(
          action: DunningAction.retry,
          nextRetryAt:
              ctx.firstFailedAt.add(const Duration(days: _retryDay2)),
          reason: 'Second attempt scheduled at +$_retryDay2 days',
        );

      case 2:
        // Tercer intento: reintentar + notificar al tenant.
        return DunningDecision(
          action: DunningAction.notifyAndRetry,
          nextRetryAt:
              ctx.firstFailedAt.add(const Duration(days: _retryDay3)),
          reason:
              'Third attempt scheduled at +$_retryDay3 days; warning email sent',
        );

      default:
        // 3+ intentos fallidos → suspend.
        assert(
          ctx.attempts.last.succeeded == false,
          'DunningStateMachine.decide called with a succeeded attempt — '
          'should not reach dunning flow on success.',
        );
        return DunningDecision(
          action: DunningAction.suspend,
          reason:
              '${ctx.attempts.length} failed attempts; suspending subscription',
        );
    }
  }
}

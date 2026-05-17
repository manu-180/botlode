// Archivo: lib/features/billing/domain/dunning/dunning_state.dart

/// Resultado de un intento de cobro en el flujo de dunning.
class DunningAttempt {
  /// Fecha UTC del intento (deben pasarse en UTC siempre).
  final DateTime attemptedAt;

  /// `true` si el cobro fue exitoso; `false` si falló.
  final bool succeeded;

  final String? failureReason;

  const DunningAttempt({
    required this.attemptedAt,
    required this.succeeded,
    this.failureReason,
  });
}

/// Contexto completo para que la state machine tome una decisión.
///
/// Todos los [DateTime] deben estar en UTC.
class DunningContext {
  /// Fecha UTC del primer fallo de cobro que inició el flujo de dunning.
  final DateTime firstFailedAt;

  /// Historial de intentos ordenados ascendentemente por [DunningAttempt.attemptedAt].
  final List<DunningAttempt> attempts;

  /// Momento actual en UTC usado para calcular `soft_delete` a los 35 días.
  final DateTime now;

  const DunningContext({
    required this.firstFailedAt,
    required this.attempts,
    required this.now,
  });
}

/// Acciones que la state machine puede ordenar.
enum DunningAction {
  /// Reintentar cobro en [DunningDecision.nextRetryAt].
  retry,

  /// Notificar al tenant (email de advertencia) + reintentar.
  notifyAndRetry,

  /// Suspender el servicio; suscripción pasa a `past_due` sin acceso.
  suspend,

  /// Cancelar la suscripción de forma suave (datos preservados N días).
  softDelete,
}

/// Decisión producida por [DunningStateMachine.decide].
class DunningDecision {
  final DunningAction action;

  /// Fecha UTC del próximo intento. `null` para [DunningAction.suspend] y
  /// [DunningAction.softDelete].
  final DateTime? nextRetryAt;

  /// Razón legible para logs y auditoría.
  final String reason;

  const DunningDecision({
    required this.action,
    required this.reason,
    this.nextRetryAt,
  });
}

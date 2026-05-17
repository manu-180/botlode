// Archivo: lib/features/billing/domain/quota/quota_result.dart

/// Resultado de la verificación de cuota para una acción.
class QuotaResult {
  /// `true` si la acción está permitida; `false` si supera el límite del plan.
  final bool allow;

  /// Cantidad actualmente usada (bots activos, conversaciones en el período, etc.).
  final int used;

  /// Límite máximo del plan activo. `-1` significa ilimitado.
  final int limit;

  /// Cuántos usos quedan. `0` cuando [allow] es `false`.
  int get remaining => limit < 0 ? -1 : (limit - used).clamp(0, limit);

  /// Razón legible cuando [allow] es `false`. `null` cuando [allow] es `true`.
  final String? reason;

  const QuotaResult({
    required this.allow,
    required this.used,
    required this.limit,
    this.reason,
  });

  /// Acceso permitido.
  factory QuotaResult.allowed({required int used, required int limit}) =>
      QuotaResult(allow: true, used: used, limit: limit);

  /// Acceso denegado por límite del plan.
  factory QuotaResult.exceeded({required int used, required int limit}) =>
      QuotaResult(
        allow: false,
        used: used,
        limit: limit,
        reason: 'plan_limit_reached',
      );

  /// Acceso denegado por ausencia de suscripción activa y sin plan free.
  factory QuotaResult.noSubscription() => const QuotaResult(
        allow: false,
        used: 0,
        limit: 0,
        reason: 'no_active_subscription',
      );
}

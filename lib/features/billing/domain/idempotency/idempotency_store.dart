// Archivo: lib/features/billing/domain/idempotency/idempotency_store.dart

import 'idempotency_key.dart';

/// Contrato para persistir claves de idempotencia entre reinicios de la app.
///
/// Uso previsto:
/// ```dart
/// final key = await store.getOrCreate('checkout-${planId}-${tenantId}');
/// await edgeFn.invoke('billing-create-subscription',
///   headers: {'X-Idempotency-Key': key.value},
///   body: {...});
/// await store.markCompleted('checkout-${planId}-${tenantId}');
/// ```
///
/// Si la app se cierra antes de `markCompleted`, el próximo `getOrCreate`
/// devuelve la MISMA key — la edge function detecta el duplicado en
/// `billing_events.idempotency_key` y retorna el resultado original.
abstract class IdempotencyStore {
  /// Devuelve la clave existente para [operationId] o crea y persiste una nueva.
  ///
  /// El [operationId] debe ser determinístico por intent (no aleatorio):
  /// p. ej. `'checkout-${planCode}-${tenantId}'`.
  Future<IdempotencyKey> getOrCreate(String operationId);

  /// Marca la operación como completada y elimina la clave almacenada.
  ///
  /// El próximo [getOrCreate] con el mismo [operationId] generará un UUID nuevo.
  Future<void> markCompleted(String operationId);

  /// Devuelve `true` si hay una clave pendiente para [operationId].
  Future<bool> isPending(String operationId);
}

// Archivo: lib/features/billing/data/idempotency/idempotency_store_impl.dart

import 'package:shared_preferences/shared_preferences.dart';

import 'package:botslode/features/billing/domain/idempotency/idempotency_key.dart';
import 'package:botslode/features/billing/domain/idempotency/idempotency_store.dart';

/// Implementación de [IdempotencyStore] con [SharedPreferences].
///
/// Clave de almacenamiento: `idempotency:<operationId>` → UUID string.
/// Al llamar [markCompleted] la clave se elimina; el próximo [getOrCreate]
/// con el mismo operationId generará un UUID nuevo.
///
/// Riesgo documentado: si el usuario desinstala la app entre el intent y la
/// confirmación, se pierde la clave. La edge function también valida por
/// `gateway_event_id` para mitigar cobros dobles.
class IdempotencyStoreImpl implements IdempotencyStore {
  static const String _prefix = 'idempotency:';

  String _prefixedKey(String operationId) => '$_prefix$operationId';

  @override
  Future<IdempotencyKey> getOrCreate(String operationId) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefixedKey(operationId));
    if (stored != null) return IdempotencyKey.fromString(stored);

    final key = IdempotencyKey.generate();
    await prefs.setString(_prefixedKey(operationId), key.value);
    return key;
  }

  @override
  Future<void> markCompleted(String operationId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefixedKey(operationId));
  }

  @override
  Future<bool> isPending(String operationId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_prefixedKey(operationId));
  }
}

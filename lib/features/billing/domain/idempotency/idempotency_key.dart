// Archivo: lib/features/billing/domain/idempotency/idempotency_key.dart

import 'package:uuid/uuid.dart';

/// Value object que envuelve un UUID v4 usado como clave de idempotencia.
///
/// Se pasa como header `X-Idempotency-Key` a las Edge Functions de billing.
/// La edge function consulta `billing_events.idempotency_key` para detectar
/// duplicados y devolver el resultado original en lugar de reprocesar.
class IdempotencyKey {
  final String value;

  IdempotencyKey._(this.value);

  /// Genera una nueva clave con UUID v4 aleatorio.
  factory IdempotencyKey.generate() =>
      IdempotencyKey._(const Uuid().v4());

  /// Reconstruye una clave desde un string persistido (p. ej. SharedPreferences).
  factory IdempotencyKey.fromString(String s) => IdempotencyKey._(s);

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) =>
      other is IdempotencyKey && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

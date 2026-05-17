// Restricciones de bots por usuario.
//
// ESTADO ACTUAL (post T0): todas las restricciones están desactivadas.
// La lista hardcodeada de `allowedUserIds` se eliminó por filtración de
// identidad personal.
//
// TODO T18 (auth-real-multitenant): mover a tabla `feature_flags` con
// RLS por tenant. Cada bot restringido se gobierna por una flag activable
// desde el dashboard del tenant.

class RestrictedBotsConfig {
  /// Lista de IDs de bots restringidos. Vacía hasta T18.
  static const List<String> restrictedBotIds = <String>[];

  /// Devuelve true si el usuario puede acceder a un bot dado.
  /// Hasta T18: siempre true (no hay restricciones aplicadas).
  static bool canAccess({required String userId, required String botId}) {
    return true;
  }
}

/// Configuración de bots restringidos a usuarios específicos.
///
/// Los bots listados en [restrictedBotIds] solo se muestran en el sidebar
/// a los usuarios cuyo ID está en [allowedUserIds].
///
/// Permite diseñar bots nuevos en privado y exponerlos gradualmente.
class RestrictedBotsConfig {
  RestrictedBotsConfig._();

  /// IDs de usuarios que pueden ver los bots restringidos.
  static const Set<String> allowedUserIds = {
    '38152119-7da4-442e-9826-20901c65f42e',
  };

  /// Identificadores de bots restringidos (route names).
  /// Solo visibles para usuarios en [allowedUserIds].
  static const Set<String> restrictedBotIds = {
    'hunter',
    'seeder',
  };

  /// Comprueba si un usuario puede ver los bots restringidos.
  static bool canUserSeeRestrictedBots(String? userId) {
    if (userId == null) return false;
    return allowedUserIds.contains(userId);
  }
}

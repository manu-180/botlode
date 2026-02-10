import 'package:botslode/features/seeder_bot/domain/models/seeder_config.dart';
import 'package:botslode/features/seeder_bot/domain/models/seeder_log_entry.dart';

/// Interfaz del repositorio para Seeder Bot.
abstract class SeederRepository {
  /// Obtiene la configuración global (una sola fila).
  Future<SeederConfig?> getConfig();

  /// Guarda o actualiza la configuración.
  Future<void> saveConfig(SeederConfig config);

  /// Activa o desactiva el bot (actualiza bot_enabled).
  Future<void> updateBotEnabled(bool enabled);

  /// Estadísticas: ok, error, total_logs, pending_targets, submitted_targets.
  Future<Map<String, int>> getStats();

  /// Últimos logs con nombre del target (join propagation_targets).
  Future<List<SeederLogEntry>> getLogs({int limit = 100});

  /// Stream de logs (Realtime propagation_logs + refetch con nombres).
  Stream<List<SeederLogEntry>> watchLogs();

  /// Emite cuando las stats pueden haber cambiado (p. ej. propagation_targets insert/update).
  Stream<void> watchStatsInvalidated();

  /// Opcional: verificar acceso (por ahora todos los autenticados).
  Future<bool> hasSeederBotAccess();

  /// Libera recursos (canales Realtime, streams).
  void dispose();
}

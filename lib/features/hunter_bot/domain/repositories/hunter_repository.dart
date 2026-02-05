// Archivo: lib/features/hunter_bot/domain/repositories/hunter_repository.dart
import 'package:botslode/features/hunter_bot/domain/models/hunter_config.dart';
import 'package:botslode/features/hunter_bot/domain/models/hunter_log.dart';
import 'package:botslode/features/hunter_bot/domain/models/lead.dart';

/// Interfaz del repositorio para HunterBot
/// Define las operaciones disponibles para gestionar leads, configs y logs
abstract class HunterRepository {
  // ============================================================
  // CONFIGURACIÓN
  // ============================================================
  
  /// Obtiene la configuración del usuario actual
  Future<HunterConfig?> getConfig();
  
  /// Guarda o actualiza la configuración del usuario
  Future<void> saveConfig(HunterConfig config);
  
  /// Verifica si el usuario tiene HunterBot activado (comprado)
  Future<bool> hasHunterBotAccess();
  
  // ============================================================
  // LEADS
  // ============================================================
  
  /// Obtiene todos los leads del usuario
  Future<List<Lead>> getLeads();
  
  /// Obtiene estadísticas de leads del usuario
  Future<Map<String, int>> getStats();
  
  /// Agrega nuevos dominios para scrapear
  Future<void> addDomains(List<String> domains);
  
  /// Elimina un lead
  Future<void> deleteLead(String leadId);
  
  /// Reinicia un lead fallido (lo pone en pending)
  Future<void> retryLead(String leadId);
  
  // ============================================================
  // STREAMS (REALTIME)
  // ============================================================
  
  /// Stream de logs en tiempo real
  Stream<List<HunterLog>> watchLogs();
  
  /// Stream de leads en tiempo real
  Stream<List<Lead>> watchLeads();
  
  // ============================================================
  // LOGS (LOCAL)
  // ============================================================
  
  /// Inserta un log local (para feedback inmediato antes de Supabase)
  Future<void> insertLocalLog(HunterLog log);
}

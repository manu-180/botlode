// Archivo: lib/features/hunter_bot/data/repositories/hunter_repository_impl.dart
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:botslode/features/hunter_bot/domain/models/hunter_config.dart';
import 'package:botslode/features/hunter_bot/domain/models/hunter_log.dart';
import 'package:botslode/features/hunter_bot/domain/models/lead.dart';
import 'package:botslode/features/hunter_bot/domain/repositories/hunter_repository.dart';

/// Implementación del repositorio de HunterBot usando Supabase
class HunterRepositoryImpl implements HunterRepository {
  final SupabaseClient _supabase;
  
  // Controllers para streams locales
  final _logsController = StreamController<List<HunterLog>>.broadcast();
  final _leadsController = StreamController<List<Lead>>.broadcast();
  
  // Cache local de logs para feedback inmediato
  final List<HunterLog> _localLogs = [];
  
  // Subscripciones de Realtime
  RealtimeChannel? _logsChannel;
  RealtimeChannel? _leadsChannel;
  
  HunterRepositoryImpl(this._supabase) {
    _initializeRealtimeSubscriptions();
  }
  
  /// ID del usuario actual
  String? get _userId => _supabase.auth.currentUser?.id;
  
  /// Inicializa las subscripciones de Realtime
  void _initializeRealtimeSubscriptions() {
    if (_userId == null) return;
    
    // Subscripción a hunter_logs
    _logsChannel = _supabase
        .channel('hunter_logs_$_userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'hunter_logs',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _userId!,
          ),
          callback: (payload) {
            final newLog = HunterLog.fromMap(payload.newRecord);
            _localLogs.insert(0, newLog);
            // Mantener solo los últimos 1000 logs
            if (_localLogs.length > 1000) {
              _localLogs.removeRange(1000, _localLogs.length);
            }
            _logsController.add(List.from(_localLogs));
          },
        )
        .subscribe();
    
    // Subscripción a leads
    _leadsChannel = _supabase
        .channel('leads_$_userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'leads',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _userId!,
          ),
          callback: (payload) async {
            // Recargar todos los leads cuando hay un cambio
            final leads = await getLeads();
            _leadsController.add(leads);
          },
        )
        .subscribe();
  }
  
  // ============================================================
  // CONFIGURACIÓN
  // ============================================================
  
  @override
  Future<HunterConfig?> getConfig() async {
    if (_userId == null) return null;
    
    final response = await _supabase
        .from('hunter_configs')
        .select()
        .eq('user_id', _userId!)
        .maybeSingle();
    
    if (response == null) {
      return HunterConfig.empty(_userId!);
    }
    
    return HunterConfig.fromMap(response);
  }
  
  @override
  Future<void> saveConfig(HunterConfig config) async {
    if (_userId == null) return;
    
    final data = config.toMap();
    data['user_id'] = _userId;
    
    await _supabase
        .from('hunter_configs')
        .upsert(data, onConflict: 'user_id');
  }
  
  @override
  Future<bool> hasHunterBotAccess() async {
    if (_userId == null) return false;
    
    final response = await _supabase
        .from('user_products')
        .select()
        .eq('user_id', _userId!)
        .eq('product_id', 'HUNTER-BOT')
        .eq('is_active', true)
        .maybeSingle();
    
    return response != null;
  }
  
  // ============================================================
  // LEADS
  // ============================================================
  
  @override
  Future<List<Lead>> getLeads() async {
    if (_userId == null) return [];
    
    final response = await _supabase
        .from('leads')
        .select()
        .eq('user_id', _userId!)
        .order('created_at', ascending: false)
        .limit(100000);
    
    return (response as List)
        .map((data) => Lead.fromMap(data))
        .toList();
  }
  
  @override
  Future<Map<String, int>> getStats() async {
    if (_userId == null) {
      return {
        'total': 0,
        'pending': 0,
        'sent': 0,
        'failed': 0,
        'emails_found': 0,
        'sent_today': 0,
      };
    }
    
    final statsFuture = _supabase.rpc('get_hunter_stats', params: {'p_user_id': _userId});
    final sentTodayFuture = _querySentToday();
    
    final response = await statsFuture;
    final sentToday = await sentTodayFuture;
    
    if (response == null) {
      return {
        'total': 0,
        'pending': 0,
        'sent': 0,
        'failed': 0,
        'emails_found': 0,
        'sent_today': sentToday,
      };
    }
    
    final stats = Map<String, int>.from(response as Map);
    stats['sent_today'] = sentToday;
    return stats;
  }

  /// Cuenta emails enviados hoy (hora Argentina, UTC-3).
  Future<int> _querySentToday() async {
    if (_userId == null) return 0;
    try {
      final todayStart = _argentinaToday();
      final response = await _supabase
          .from('leads')
          .select('id')
          .eq('user_id', _userId!)
          .eq('status', 'sent')
          .gte('sent_at', todayStart);
      return (response as List).length;
    } catch (_) {
      return 0;
    }
  }

  /// Inicio del día actual en hora Argentina (UTC-3) como ISO string UTC.
  static String _argentinaToday() {
    final nowUtc = DateTime.now().toUtc();
    final argentinaTime = nowUtc.subtract(const Duration(hours: 3));
    final todayStartUtc = DateTime.utc(
      argentinaTime.year,
      argentinaTime.month,
      argentinaTime.day,
      3, 0, 0,
    );
    return todayStartUtc.toIso8601String();
  }
  
  @override
  Future<void> addDomains(List<String> domains) async {
    if (_userId == null || domains.isEmpty) return;
    
    // Normalizar dominios y eliminar duplicados
    final normalizedDomains = domains
        .map((d) => _normalizeDomain(d))
        .where((d) => d.isNotEmpty)
        .toSet()
        .toList();
    
    if (normalizedDomains.isEmpty) return;
    
    // Insertar cada dominio
    final inserts = normalizedDomains.map((domain) => {
      'user_id': _userId,
      'domain': domain,
      'status': 'pending',
    }).toList();
    
    // Usar upsert para ignorar duplicados del mismo usuario
    // Constraint UNIQUE en (user_id, domain) permite que varios usuarios
    // puedan scrapear el mismo dominio, pero cada usuario no duplica sus propios dominios
    await _supabase
        .from('leads')
        .upsert(
          inserts,
          onConflict: 'user_id,domain',
          ignoreDuplicates: true,
        );
    
    // Insertar log local
    await insertLocalLog(HunterLog.local(
      userId: _userId!,
      domain: normalizedDomains.length == 1 
          ? normalizedDomains.first 
          : '${normalizedDomains.length} dominios',
      level: LogLevel.info,
      action: LogAction.domainAdded,
      message: normalizedDomains.length == 1
          ? 'Dominio agregado a la cola: ${normalizedDomains.first}'
          : '${normalizedDomains.length} dominios agregados a la cola',
    ));
  }
  
  @override
  Future<void> deleteLead(String leadId) async {
    await _supabase
        .from('leads')
        .delete()
        .eq('id', leadId);
  }
  
  @override
  Future<void> retryLead(String leadId) async {
    await _supabase
        .from('leads')
        .update({
          'status': 'pending',
          'error_message': null,
        })
        .eq('id', leadId);
  }
  
  // ============================================================
  // STREAMS (REALTIME)
  // ============================================================
  
  @override
  Stream<List<HunterLog>> watchLogs() async* {
    // Primero cargar logs existentes
    if (_userId != null) {
      final response = await _supabase
          .from('hunter_logs')
          .select()
          .eq('user_id', _userId!)
          .order('created_at', ascending: false)
          .limit(1000);
      
      _localLogs.clear();
      _localLogs.addAll(
        (response as List).map((data) => HunterLog.fromMap(data))
      );
      yield List.from(_localLogs);
    }
    
    // Luego emitir actualizaciones
    yield* _logsController.stream;
  }
  
  @override
  Stream<List<Lead>> watchLeads() async* {
    // Primero cargar leads existentes
    final leads = await getLeads();
    yield leads;
    
    // Luego emitir actualizaciones
    yield* _leadsController.stream;
  }
  
  // ============================================================
  // LOGS (LOCAL)
  // ============================================================
  
  @override
  Future<void> insertLocalLog(HunterLog log) async {
    _localLogs.insert(0, log);
    _logsController.add(List.from(_localLogs));
    
    // También insertar en Supabase para persistencia
    if (_userId != null) {
      await _supabase
          .from('hunter_logs')
          .insert(log.toMap());
    }
  }
  
  // ============================================================
  // HELPERS
  // ============================================================
  
  /// Normaliza un dominio (elimina protocolo, www, espacios, etc)
  String _normalizeDomain(String domain) {
    var normalized = domain.trim().toLowerCase();
    
    // Eliminar protocolo
    normalized = normalized.replaceAll(RegExp(r'^https?://'), '');
    
    // Eliminar www.
    normalized = normalized.replaceAll(RegExp(r'^www\.'), '');
    
    // Eliminar path
    final slashIndex = normalized.indexOf('/');
    if (slashIndex > 0) {
      normalized = normalized.substring(0, slashIndex);
    }
    
    // Eliminar query params
    final questionIndex = normalized.indexOf('?');
    if (questionIndex > 0) {
      normalized = normalized.substring(0, questionIndex);
    }
    
    return normalized;
  }
  
  /// Libera recursos
  void dispose() {
    _logsChannel?.unsubscribe();
    _leadsChannel?.unsubscribe();
    _logsController.close();
    _leadsController.close();
  }
}

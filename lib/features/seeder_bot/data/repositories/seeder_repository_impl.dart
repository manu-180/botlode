import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:botslode/features/seeder_bot/domain/models/seeder_config.dart';
import 'package:botslode/features/seeder_bot/domain/models/seeder_log_entry.dart';
import 'package:botslode/features/seeder_bot/domain/repositories/seeder_repository.dart';

/// Implementación del repositorio de Seeder Bot usando Supabase.
class SeederRepositoryImpl implements SeederRepository {
  final SupabaseClient _supabase;
  final _logsController = StreamController<List<SeederLogEntry>>.broadcast();
  RealtimeChannel? _logsChannel;

  SeederRepositoryImpl(this._supabase) {
    _initializeRealtimeSubscriptions();
  }

  void _initializeRealtimeSubscriptions() {
    _logsChannel = _supabase
        .channel('seeder_propagation_logs')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'propagation_logs',
          callback: (_) async {
            final logs = await getLogs(limit: 100);
            if (!_logsController.isClosed) {
              _logsController.add(logs);
            }
          },
        )
        .subscribe();
  }

  @override
  Future<SeederConfig?> getConfig() async {
    final response = await _supabase
        .from('seeder_config')
        .select()
        .limit(1)
        .maybeSingle();
    if (response == null) return null;
    return SeederConfig.fromMap(response);
  }

  @override
  Future<void> saveConfig(SeederConfig config) async {
    await _supabase.from('seeder_config').upsert(
          config.toMap(),
          onConflict: 'id',
        );
  }

  @override
  Future<void> updateBotEnabled(bool enabled) async {
    final config = await getConfig();
    if (config == null) return;
    await _supabase.from('seeder_config').update({
      'bot_enabled': enabled,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', config.id);
  }

  @override
  Future<Map<String, int>> getStats() async {
    final response = await _supabase.rpc('get_seeder_stats');
    if (response == null) {
      return {
        'ok': 0,
        'error': 0,
        'total_logs': 0,
        'pending_targets': 0,
        'submitted_targets': 0,
      };
    }
    final map = response is Map ? response as Map<String, dynamic> : {};
    return {
      'ok': (map['ok'] is int) ? map['ok'] as int : int.tryParse(map['ok']?.toString() ?? '0') ?? 0,
      'error': (map['error'] is int) ? map['error'] as int : int.tryParse(map['error']?.toString() ?? '0') ?? 0,
      'total_logs': (map['total_logs'] is int) ? map['total_logs'] as int : int.tryParse(map['total_logs']?.toString() ?? '0') ?? 0,
      'pending_targets': (map['pending_targets'] is int) ? map['pending_targets'] as int : int.tryParse(map['pending_targets']?.toString() ?? '0') ?? 0,
      'submitted_targets': (map['submitted_targets'] is int) ? map['submitted_targets'] as int : int.tryParse(map['submitted_targets']?.toString() ?? '0') ?? 0,
    };
  }

  @override
  Future<List<SeederLogEntry>> getLogs({int limit = 100}) async {
    final response = await _supabase
        .from('propagation_logs')
        .select('*, propagation_targets(name, url)')
        .order('submitted_at', ascending: false)
        .limit(limit);
    final list = response as List<dynamic>? ?? [];
    return list.map((e) => SeederLogEntry.fromMap(Map<String, dynamic>.from(e as Map))).toList();
  }

  @override
  Stream<List<SeederLogEntry>> watchLogs() async* {
    final initial = await getLogs(limit: 100);
    yield initial;
    yield* _logsController.stream;
  }

  @override
  Future<bool> hasSeederBotAccess() async {
    // Visible para todos los autenticados
    return _supabase.auth.currentUser != null;
  }

  void dispose() {
    _logsChannel?.unsubscribe();
    _logsController.close();
  }
}

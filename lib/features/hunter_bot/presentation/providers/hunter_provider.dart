// Archivo: lib/features/hunter_bot/presentation/providers/hunter_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botslode/features/hunter_bot/domain/models/hunter_config.dart';
import 'package:botslode/features/hunter_bot/domain/models/lead.dart';
import 'package:botslode/features/hunter_bot/presentation/providers/hunter_repository_provider.dart';

/// Estado del HunterBot
class HunterState {
  final bool isLoading;
  final HunterConfig? config;
  final List<Lead> leads;
  final Map<String, int> stats;
  final String? error;
  final bool hasAccess;

  const HunterState({
    this.isLoading = true,
    this.config,
    this.leads = const [],
    this.stats = const {},
    this.error,
    this.hasAccess = false,
  });

  HunterState copyWith({
    bool? isLoading,
    HunterConfig? config,
    List<Lead>? leads,
    Map<String, int>? stats,
    String? error,
    bool? hasAccess,
  }) {
    return HunterState(
      isLoading: isLoading ?? this.isLoading,
      config: config ?? this.config,
      leads: leads ?? this.leads,
      stats: stats ?? this.stats,
      error: error,
      hasAccess: hasAccess ?? this.hasAccess,
    );
  }

  /// Verifica si la configuración está lista para enviar
  bool get isConfigured => config?.isConfigured ?? false;
  
  /// Control del bot
  bool get botEnabled => config?.botEnabled ?? false;
  String get nicho => config?.nicho ?? 'inmobiliarias';
  List<String> get ciudades => config?.ciudades ?? ['Buenos Aires'];
  String get pais => config?.pais ?? 'Argentina';
  
  /// Conteo rápido de leads por estado
  int get pendingCount => stats['pending'] ?? 0;
  int get sentCount => stats['sent'] ?? 0;
  int get failedCount => stats['failed'] ?? 0;
  int get totalCount => stats['total'] ?? 0;
  int get emailsFoundCount => stats['emails_found'] ?? 0;
  /// Escaneados + en cola + enviando (para que TOTAL = PEND + ENVÍO + FAIL + otherCount)
  int get otherCount =>
      (stats['scraping'] ?? 0) +
      (stats['scraped'] ?? 0) +
      (stats['queued_for_send'] ?? 0) +
      (stats['sending'] ?? 0);
}

/// Notifier para manejar el estado del HunterBot
class HunterNotifier extends StateNotifier<HunterState> {
  final Ref _ref;
  DateTime? _lastStatsUpdate;
  
  HunterNotifier(this._ref) : super(const HunterState()) {
    _initialize();
  }
  
  /// Inicializa el estado cargando config, leads y stats
  Future<void> _initialize() async {
    try {
      final repo = _ref.read(hunterRepositoryProvider);
      
      // Cargar todo en paralelo
      final results = await Future.wait([
        repo.hasHunterBotAccess(),
        repo.getConfig(),
        repo.getLeads(),
        repo.getStats(),
      ]);
      
      state = state.copyWith(
        isLoading: false,
        hasAccess: results[0] as bool,
        config: results[1] as HunterConfig?,
        leads: results[2] as List<Lead>,
        stats: results[3] as Map<String, int>,
      );
      
      // Suscribirse a cambios de leads
      _subscribeToLeads();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar: $e',
      );
    }
  }
  
  /// Suscribe a cambios en tiempo real de leads
  void _subscribeToLeads() {
    final repo = _ref.read(hunterRepositoryProvider);
    
    repo.watchLeads().listen((leads) {
      state = state.copyWith(leads: leads);
      // Actualizar stats también
      _refreshStats();
    });
  }
  
  /// Refresca las estadísticas (con throttle de 3s).
  /// ENVÍO (sent) nunca baja en pantalla: si el servidor devuelve menos por
  /// un snapshot viejo o replicación, se mantiene el máximo para no confundir.
  Future<void> _refreshStats() async {
    // Throttle: no actualizar si se actualizó hace menos de 3 segundos
    final now = DateTime.now();
    if (_lastStatsUpdate != null) {
      final diff = now.difference(_lastStatsUpdate!);
      if (diff.inSeconds < 3) {
        return; // Skip update
      }
    }
    
    _lastStatsUpdate = now;
    
    final repo = _ref.read(hunterRepositoryProvider);
    final newStats = await repo.getStats();
    // Que ENVÍO nunca disminuya (evita flicker por snapshots/replicación atrasada)
    final currentSent = state.stats['sent'] ?? 0;
    final serverSent = newStats['sent'] ?? 0;
    final merged = Map<String, int>.from(newStats);
    if (serverSent < currentSent) {
      merged['sent'] = currentSent;
    }
    state = state.copyWith(stats: merged);
  }
  
  /// Guarda la configuración
  Future<void> saveConfig(HunterConfig config) async {
    try {
      final repo = _ref.read(hunterRepositoryProvider);
      await repo.saveConfig(config);
      state = state.copyWith(config: config, error: null);
    } catch (e) {
      state = state.copyWith(error: 'Error al guardar config: $e');
    }
  }
  
  /// Actualiza el estado bot_enabled (prender/apagar bot)
  Future<void> updateBotEnabled(bool enabled) async {
    if (state.config == null) return;
    
    try {
      final updatedConfig = state.config!.copyWith(botEnabled: enabled);
      await saveConfig(updatedConfig);
    } catch (e) {
      state = state.copyWith(error: 'Error al actualizar bot: $e');
    }
  }
  
  /// Actualiza el nicho del bot
  Future<void> updateNicho(String nicho, List<String> ciudades, String pais) async {
    if (state.config == null) return;
    
    try {
      final updatedConfig = state.config!.copyWith(
        nicho: nicho,
        ciudades: ciudades,
        pais: pais,
      );
      await saveConfig(updatedConfig);
    } catch (e) {
      state = state.copyWith(error: 'Error al actualizar nicho: $e');
    }
  }
  
  /// Agrega dominios para scrapear
  Future<void> addDomains(List<String> domains) async {
    if (domains.isEmpty) return;
    
    try {
      final repo = _ref.read(hunterRepositoryProvider);
      await repo.addDomains(domains);
      
      // Refrescar leads y stats
      final leads = await repo.getLeads();
      final stats = await repo.getStats();
      
      state = state.copyWith(
        leads: leads,
        stats: stats,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: 'Error al agregar dominios: $e');
    }
  }
  
  /// Elimina un lead
  Future<void> deleteLead(String leadId) async {
    try {
      final repo = _ref.read(hunterRepositoryProvider);
      await repo.deleteLead(leadId);
      
      // Actualizar lista local
      final updatedLeads = state.leads.where((l) => l.id != leadId).toList();
      state = state.copyWith(leads: updatedLeads);
      
      await _refreshStats();
    } catch (e) {
      state = state.copyWith(error: 'Error al eliminar lead: $e');
    }
  }
  
  /// Reintenta un lead fallido
  Future<void> retryLead(String leadId) async {
    try {
      final repo = _ref.read(hunterRepositoryProvider);
      await repo.retryLead(leadId);
      
      // Actualizar lead local
      final updatedLeads = state.leads.map((l) {
        if (l.id == leadId) {
          return l.copyWith(status: LeadStatus.pending, errorMessage: null);
        }
        return l;
      }).toList();
      
      state = state.copyWith(leads: updatedLeads);
      await _refreshStats();
    } catch (e) {
      state = state.copyWith(error: 'Error al reintentar lead: $e');
    }
  }
  
  /// Refresca todo el estado
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    await _initialize();
  }
  
  /// Limpia el error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider del estado de HunterBot
final hunterProvider = StateNotifierProvider<HunterNotifier, HunterState>((ref) {
  return HunterNotifier(ref);
});

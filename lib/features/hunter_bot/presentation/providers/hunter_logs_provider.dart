// Archivo: lib/features/hunter_bot/presentation/providers/hunter_logs_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botslode/features/hunter_bot/domain/models/hunter_log.dart';
import 'package:botslode/features/hunter_bot/presentation/providers/hunter_repository_provider.dart';

/// Estado de los logs
class HunterLogsState {
  final List<HunterLog> logs;
  final bool isLoading;
  final LogLevel? filterLevel;
  final bool autoScroll;

  const HunterLogsState({
    this.logs = const [],
    this.isLoading = true,
    this.filterLevel,
    this.autoScroll = true,
  });

  HunterLogsState copyWith({
    List<HunterLog>? logs,
    bool? isLoading,
    LogLevel? filterLevel,
    bool? autoScroll,
    bool clearFilter = false,
  }) {
    return HunterLogsState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      filterLevel: clearFilter ? null : (filterLevel ?? this.filterLevel),
      autoScroll: autoScroll ?? this.autoScroll,
    );
  }

  /// Logs filtrados por nivel
  List<HunterLog> get filteredLogs {
    if (filterLevel == null) return logs;
    return logs.where((log) => log.level == filterLevel).toList();
  }

  /// Conteo por nivel
  int countByLevel(LogLevel level) {
    return logs.where((log) => log.level == level).length;
  }
}

/// Notifier para manejar los logs en tiempo real
class HunterLogsNotifier extends StateNotifier<HunterLogsState> {
  final Ref _ref;
  StreamSubscription<List<HunterLog>>? _subscription;

  HunterLogsNotifier(this._ref) : super(const HunterLogsState()) {
    _initialize();
  }

  /// Inicializa la suscripción a logs
  void _initialize() {
    final repo = _ref.read(hunterRepositoryProvider);
    
    _subscription = repo.watchLogs().listen((logs) {
      state = state.copyWith(
        logs: logs,
        isLoading: false,
      );
    });
  }

  /// Establece el filtro por nivel
  void setFilter(LogLevel? level) {
    if (level == state.filterLevel) {
      // Si es el mismo, quitar filtro
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(filterLevel: level);
    }
  }

  /// Activa/desactiva auto-scroll
  void toggleAutoScroll() {
    state = state.copyWith(autoScroll: !state.autoScroll);
  }

  /// Limpia todos los logs (solo localmente, no de Supabase)
  void clearLogs() {
    state = state.copyWith(logs: []);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Provider de los logs de HunterBot
final hunterLogsProvider = StateNotifierProvider<HunterLogsNotifier, HunterLogsState>((ref) {
  return HunterLogsNotifier(ref);
});

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botslode/features/seeder_bot/domain/models/seeder_config.dart';
import 'package:botslode/features/seeder_bot/presentation/providers/seeder_repository_provider.dart';

/// Estado del Seeder Bot
class SeederState {
  final bool isLoading;
  final SeederConfig? config;
  final Map<String, int> stats;
  final String? error;
  final bool hasAccess;

  const SeederState({
    this.isLoading = true,
    this.config,
    this.stats = const {},
    this.error,
    this.hasAccess = false,
  });

  SeederState copyWith({
    bool? isLoading,
    SeederConfig? config,
    Map<String, int>? stats,
    String? error,
    bool? hasAccess,
  }) {
    return SeederState(
      isLoading: isLoading ?? this.isLoading,
      config: config ?? this.config,
      stats: stats ?? this.stats,
      error: error,
      hasAccess: hasAccess ?? this.hasAccess,
    );
  }

  bool get botEnabled => config?.botEnabled ?? false;
  int get okCount => stats['ok'] ?? 0;
  int get errorCount => stats['error'] ?? 0;
  int get totalLogs => stats['total_logs'] ?? 0;
  int get pendingTargets => stats['pending_targets'] ?? 0;
  int get submittedTargets => stats['submitted_targets'] ?? 0;
}

/// Notifier del Seeder Bot
class SeederNotifier extends StateNotifier<SeederState> {
  final Ref _ref;
  StreamSubscription<void>? _statsInvalidatedSub;

  SeederNotifier(this._ref) : super(const SeederState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final repo = _ref.read(seederRepositoryProvider);
      final results = await Future.wait([
        repo.hasSeederBotAccess(),
        repo.getConfig(),
        repo.getStats(),
      ]);
      state = state.copyWith(
        isLoading: false,
        hasAccess: results[0] as bool,
        config: results[1] as SeederConfig?,
        stats: results[2] as Map<String, int>,
      );
      _statsInvalidatedSub = repo.watchStatsInvalidated().listen((_) async {
        final stats = await repo.getStats();
        state = state.copyWith(stats: stats);
      });
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar: $e',
      );
    }
  }

  @override
  void dispose() {
    _statsInvalidatedSub?.cancel();
    super.dispose();
  }

  Future<void> updateBotEnabled(bool enabled) async {
    try {
      final repo = _ref.read(seederRepositoryProvider);
      await repo.updateBotEnabled(enabled);
      state = state.copyWith(
        config: state.config?.copyWith(botEnabled: enabled, updatedAt: DateTime.now()),
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: 'Error al actualizar bot: $e');
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    await _initialize();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final seederProvider = StateNotifierProvider<SeederNotifier, SeederState>((ref) {
  return SeederNotifier(ref);
});

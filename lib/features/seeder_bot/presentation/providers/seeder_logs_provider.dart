import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botslode/features/seeder_bot/domain/models/seeder_log_entry.dart';
import 'package:botslode/features/seeder_bot/presentation/providers/seeder_repository_provider.dart';

/// Filtro por status de log (ok, error, o todos)
enum SeederLogFilter { all, ok, error }

/// Estado de los logs del Seeder Bot
class SeederLogsState {
  final List<SeederLogEntry> logs;
  final bool isLoading;
  final SeederLogFilter filter;
  final bool autoScroll;

  const SeederLogsState({
    this.logs = const [],
    this.isLoading = true,
    this.filter = SeederLogFilter.all,
    this.autoScroll = true,
  });

  SeederLogsState copyWith({
    List<SeederLogEntry>? logs,
    bool? isLoading,
    SeederLogFilter? filter,
    bool? autoScroll,
  }) {
    return SeederLogsState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      filter: filter ?? this.filter,
      autoScroll: autoScroll ?? this.autoScroll,
    );
  }

  List<SeederLogEntry> get filteredLogs {
    switch (filter) {
      case SeederLogFilter.ok:
        return logs.where((e) => e.isOk).toList();
      case SeederLogFilter.error:
        return logs.where((e) => !e.isOk).toList();
      case SeederLogFilter.all:
        return logs;
    }
  }
}

/// Notifier para los logs del Seeder Bot
class SeederLogsNotifier extends StateNotifier<SeederLogsState> {
  final Ref _ref;
  StreamSubscription<List<SeederLogEntry>>? _subscription;

  SeederLogsNotifier(this._ref) : super(const SeederLogsState()) {
    _initialize();
  }

  void _initialize() {
    final repo = _ref.read(seederRepositoryProvider);
    _subscription = repo.watchLogs().listen((logs) {
      state = state.copyWith(logs: logs, isLoading: false);
    });
  }

  void setFilter(SeederLogFilter f) {
    state = state.copyWith(filter: f);
  }

  void toggleAutoScroll() {
    state = state.copyWith(autoScroll: !state.autoScroll);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final seederLogsProvider = StateNotifierProvider<SeederLogsNotifier, SeederLogsState>((ref) {
  return SeederLogsNotifier(ref);
});

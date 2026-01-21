// Archivo: lib/features/dashboard/presentation/providers/dashboard_controller.dart
import 'package:botslode/features/dashboard/domain/models/bot.dart';
import 'package:botslode/features/dashboard/presentation/providers/bots_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_controller.g.dart';

enum BotFilter { all, active, maintenance, disabled }

@riverpod
class DashboardFilter extends _$DashboardFilter {
  @override
  BotFilter build() => BotFilter.all;

  void setFilter(BotFilter filter) => state = filter;
}

@riverpod
class DashboardSearch extends _$DashboardSearch {
  @override
  String build() => "";

  void setSearch(String query) => state = query;
}

// --- ACTUALIZADO PARA MANEJAR ASYNCVALUE ---
@riverpod
AsyncValue<List<Bot>> filteredBots(FilteredBotsRef ref) {
  // Observamos el provider de bots (que ahora es asíncrono)
  final botsAsync = ref.watch(botsProvider);
  final filter = ref.watch(dashboardFilterProvider);
  final search = ref.watch(dashboardSearchProvider).toLowerCase();

  // Usamos .whenData para aplicar el filtro solo cuando los datos estén listos
  return botsAsync.whenData((bots) {
    return bots.where((bot) {
      // 1. Filtro de Estado
      bool matchesFilter = switch (filter) {
        BotFilter.all => true,
        BotFilter.active => bot.status == BotStatus.active,
        BotFilter.maintenance => bot.status == BotStatus.maintenance,
        BotFilter.disabled => bot.status == BotStatus.disabled,
      };

      // 2. Filtro de Búsqueda
      bool matchesSearch = bot.name.toLowerCase().contains(search) || 
                           bot.id.toLowerCase().contains(search);

      return matchesFilter && matchesSearch;
    }).toList();
  });
}
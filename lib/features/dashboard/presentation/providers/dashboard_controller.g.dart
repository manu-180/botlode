// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$filteredBotsHash() => r'5441c8742e9611c2f4f9136f21b99428d9968b5d';

/// See also [filteredBots].
@ProviderFor(filteredBots)
final filteredBotsProvider =
    AutoDisposeProvider<AsyncValue<List<Bot>>>.internal(
  filteredBots,
  name: r'filteredBotsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$filteredBotsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FilteredBotsRef = AutoDisposeProviderRef<AsyncValue<List<Bot>>>;
String _$dashboardFilterHash() => r'f0116d8361256ae4a3289e3e5f7dec6251385142';

/// See also [DashboardFilter].
@ProviderFor(DashboardFilter)
final dashboardFilterProvider =
    AutoDisposeNotifierProvider<DashboardFilter, BotFilter>.internal(
  DashboardFilter.new,
  name: r'dashboardFilterProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dashboardFilterHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DashboardFilter = AutoDisposeNotifier<BotFilter>;
String _$dashboardSearchHash() => r'a9cf215d30b5f685cb791bd65d25ad9938c2b03d';

/// See also [DashboardSearch].
@ProviderFor(DashboardSearch)
final dashboardSearchProvider =
    AutoDisposeNotifierProvider<DashboardSearch, String>.internal(
  DashboardSearch.new,
  name: r'dashboardSearchProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dashboardSearchHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DashboardSearch = AutoDisposeNotifier<String>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member

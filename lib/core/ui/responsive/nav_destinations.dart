// Archivo: lib/core/ui/responsive/nav_destinations.dart
//
// Catálogo único de destinos de navegación. Lo consumen tanto el Sidebar
// desktop como la bottom nav bar mobile, para garantizar que ambas
// experiencias están sincronizadas.

import 'package:botslode/core/config/theme/app_icons.dart';
import 'package:botslode/features/billing/presentation/views/billing_view.dart';
import 'package:botslode/features/bots_library/presentation/views/bots_library_view.dart';
import 'package:botslode/features/dashboard/presentation/views/dashboard_view.dart';
import 'package:botslode/features/settings/presentation/views/settings_view.dart';
import 'package:botslode/features/store/presentation/views/store_view.dart';
import 'package:flutter/widgets.dart';

class NavDestination {
  const NavDestination({
    required this.id,
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.routeName,
    required this.matches,
    this.showInBottomNav = true,
  });

  /// Identificador interno (para keys / tests).
  final String id;
  final IconData icon;
  final String label;
  final String tooltip;
  final String routeName;

  /// Función para decidir si una location del router activa este destino.
  final bool Function(String location) matches;

  /// Si false, el destino sólo aparece en el sidebar desktop (no en bottom nav).
  /// Útil para "Ajustes" que quedaría como overflow item en mobile.
  final bool showInBottomNav;
}

/// Catálogo ordenado de destinos.
const List<NavDestination> kAppNavDestinations = [
  NavDestination(
    id: 'bots',
    icon: AppIcons.bots,
    label: 'BOTS',
    tooltip: 'Bots',
    routeName: DashboardView.routeName,
    matches: _matchesDashboard,
  ),
  NavDestination(
    id: 'plantillas',
    icon: AppIcons.library,
    label: 'PLANTILLAS',
    tooltip: 'Plantillas',
    routeName: BotsLibraryView.routeName,
    matches: _matchesPlantillas,
  ),
  NavDestination(
    id: 'pagos',
    icon: AppIcons.billing,
    label: 'PAGOS',
    tooltip: 'Pagos',
    routeName: BillingView.routeName,
    matches: _matchesPagos,
  ),
  NavDestination(
    id: 'tienda',
    icon: AppIcons.store,
    label: 'TIENDA',
    tooltip: 'Tienda',
    routeName: StoreView.routeName,
    matches: _matchesTienda,
  ),
  NavDestination(
    id: 'ajustes',
    icon: AppIcons.settings,
    label: 'AJUSTES',
    tooltip: 'Ajustes',
    routeName: SettingsView.routeName,
    matches: _matchesAjustes,
    showInBottomNav: true,
  ),
];

bool _matchesDashboard(String loc) =>
    loc.startsWith('/dashboard') || loc == '/';
bool _matchesPlantillas(String loc) => loc.startsWith('/bots');
bool _matchesPagos(String loc) => loc == '/billing';
bool _matchesTienda(String loc) => loc == '/store';
bool _matchesAjustes(String loc) => loc == '/settings';

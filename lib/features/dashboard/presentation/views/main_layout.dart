// lib/features/dashboard/presentation/views/main_layout.dart
// Shell principal «Hangar OS»: sidebar + title bar + AppBackground + toasts de conectividad.
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/providers/connectivity_provider.dart';
import 'package:botslode/core/ui/app_background.dart';
import 'package:botslode/core/ui/hud/connectivity_hud.dart';
import 'package:botslode/core/ui/widgets/custom_title_bar.dart';
import 'package:botslode/features/dashboard/presentation/widgets/sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MainLayout extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const MainLayout({super.key, required this.navigationShell});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  bool _wasOffline = false;
  final _connectivityHud = ConnectivityHudController();

  @override
  void dispose() {
    _connectivityHud.dispose();
    super.dispose();
  }

  String _breadcrumbFor(String location) {
    if (location.contains('/dashboard/detail/')) {
      final botId =
          location.split('/dashboard/detail/').last.split('/').first;
      final shortId = botId.length > 8
          ? botId.substring(0, 8).toUpperCase()
          : botId.toUpperCase();
      return 'HANGAR / UNIT-$shortId';
    }
    if (location.startsWith('/dashboard') || location == '/') return 'HANGAR';
    if (location.startsWith('/bots')) return 'PLANOS';
    if (location.startsWith('/billing')) return 'FACTURACIÓN';
    if (location.startsWith('/settings')) return 'PROTOCOLO';
    if (location.startsWith('/store')) return 'TIENDA';
    return 'HANGAR';
  }

  @override
  Widget build(BuildContext context) {
    final connectivityAsync = ref.watch(connectivityProvider);

    ref.listen(connectivityProvider, (prev, next) {
      next.whenData((isOnline) {
        if (!isOnline && !_wasOffline) {
          _connectivityHud.show(context: context, isOnline: false);
          _wasOffline = true;
        } else if (isOnline && _wasOffline) {
          _connectivityHud.show(context: context, isOnline: true);
          _wasOffline = false;
        }
      });
    });

    final isOnline = connectivityAsync.valueOrNull ?? true;
    final systemStatus =
        isOnline ? SystemStatus.operational : SystemStatus.offline;
    final location = GoRouterState.of(context).uri.toString();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // ─── SIDEBAR (z: zSidebar=30) ────────────────────────────
          const Sidebar(),

          // ─── CONTENT AREA ────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // Title bar corona el área de contenido (z: zTitleBar=40)
                CustomTitleBar(
                  breadcrumb: _breadcrumbFor(location),
                  systemStatus: systemStatus,
                ),

                // Stack: AppBackground (z: zBase=0) + contenido (z: zContent=10)
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const ExcludeSemantics(
                        child: AppBackground(child: SizedBox.shrink()),
                      ),
                      _ShellTransitionSwitcher(
                        currentIndex: widget.navigationShell.currentIndex,
                        child: widget.navigationShell,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Crossfade puro (durBase) entre ramas hermanas del IndexedStack.
/// No desmonta el IndexedStack interno — sólo anima la opacidad al cambiar de índice.
class _ShellTransitionSwitcher extends StatefulWidget {
  final Widget child;
  final int currentIndex;

  const _ShellTransitionSwitcher({
    required this.child,
    required this.currentIndex,
  });

  @override
  State<_ShellTransitionSwitcher> createState() =>
      _ShellTransitionSwitcherState();
}

class _ShellTransitionSwitcherState extends State<_ShellTransitionSwitcher>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppMotion.durBase);
    _fade = CurvedAnimation(parent: _ctrl, curve: AppMotion.easeStandard);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_ShellTransitionSwitcher old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _ctrl.duration = AppMotion.reduced(context)
          ? AppMotion.durCrossfadeReduced
          : AppMotion.durBase;
      _ctrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _fade, child: widget.child);
  }
}

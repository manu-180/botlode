// lib/features/dashboard/presentation/views/main_layout.dart
// Shell principal «Hangar OS»: sidebar + title bar + AppBackground + toasts de conectividad.
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/providers/connectivity_provider.dart';
import 'package:botslode/core/ui/app_background.dart';
import 'package:botslode/core/ui/toasts/app_toast.dart';
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

class _MainLayoutState extends ConsumerState<MainLayout>
    with SingleTickerProviderStateMixin {
  bool _wasOffline = false;
  late final AnimationController _pageCtrl;
  late final Animation<double> _pageFade;
  late final Animation<Offset> _pageSlide;

  @override
  void initState() {
    super.initState();
    _pageCtrl = AnimationController(
      vsync: this,
      duration: AppMotion.durBase,
    );
    _pageFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pageCtrl, curve: AppMotion.easeEntrance),
    );
    _pageSlide = Tween<Offset>(
      begin: const Offset(0, 0.02),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _pageCtrl, curve: AppMotion.easeEntrance));
    _pageCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(connectivityProvider, (prev, next) {
      next.whenData((isOnline) {
        if (!isOnline && !_wasOffline) {
          showAppToast(
            context,
            type: ToastType.error,
            message: 'CONEXIÓN PERDIDA — Modo offline activado',
            duration: const Duration(days: 1),
          );
          _wasOffline = true;
        } else if (isOnline && _wasOffline) {
          showAppToast(
            context,
            type: ToastType.success,
            message: 'ENLACE RESTABLECIDO — Sistemas online',
          );
          _wasOffline = false;
        }
      });
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        variant: _variantForPath(GoRouterState.of(context).uri.path),
        child: Row(
          children: [
            // ─── SIDEBAR ────────────────────────────────────────────
            const Sidebar(),

            // ─── CONTENT AREA ────────────────────────────────────────
            Expanded(
              child: Column(
                children: [
                  // Title bar solo en el área de contenido
                  const CustomTitleBar(),

                  // Page content con fade/slide de entrada
                  Expanded(
                    child: FadeTransition(
                      opacity: _pageFade,
                      child: SlideTransition(
                        position: _pageSlide,
                        child: widget.navigationShell,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBackgroundVariant _variantForPath(String path) {
    if (path == '/billing') return AppBackgroundVariant.billing;
    if (path.contains('/dashboard')) return AppBackgroundVariant.dashboard;
    return AppBackgroundVariant.standard;
  }
}

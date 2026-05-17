// Archivo: lib/core/router/app_router.dart
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/logging/app_logger.dart';
import 'package:botslode/core/providers/auth_provider.dart';
import 'package:botslode/features/auth/presentation/views/login_view.dart';
import 'package:botslode/features/billing/presentation/views/billing_view.dart';
import 'package:botslode/features/bots_library/presentation/views/bots_library_view.dart';
import 'package:botslode/features/dashboard/presentation/views/bot_detail_view.dart';
import 'package:botslode/features/dashboard/presentation/views/dashboard_view.dart';
import 'package:botslode/features/dashboard/presentation/views/main_layout.dart';
import 'package:botslode/features/settings/presentation/views/settings_view.dart';
import 'package:botslode/features/store/presentation/views/store_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _log = AppLogger('AppRouter');

final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(authProvider.select((state) => state.session));
  final isLoggedIn = session != null;

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isGoingToLogin = state.uri.path == '/login';
      _log.debug(
          "🧭 ROUTER CHECK | Path: ${state.uri.path} | User: ${isLoggedIn ? 'LOGUEADO' : 'NULL'}");
      if (!isLoggedIn && !isGoingToLogin) return '/login';
      if (isLoggedIn && isGoingToLogin) return '/dashboard';
      if (state.uri.path == '/') return isLoggedIn ? '/dashboard' : '/login';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: LoginView.routeName,
        builder: (context, state) => const LoginView(),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainLayout(navigationShell: navigationShell);
        },
        branches: [
          // RAMA 1: HANGAR (Dashboard) + DETALLE DE BOT
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                name: DashboardView.routeName,
                // Sin transición primaria (corte seco); usa secondaryAnimation
                // para deslizarse -16px hacia la izquierda cuando el detalle entra.
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const DashboardView(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    if (AppMotion.reduced(context)) return child;
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset.zero,
                        end: const Offset(-0.04, 0),
                      ).animate(CurvedAnimation(
                        parent: secondaryAnimation,
                        curve: AppMotion.easeExit,
                      )),
                      child: FadeTransition(
                        opacity: Tween<double>(begin: 1.0, end: 0.7).animate(
                          CurvedAnimation(
                            parent: secondaryAnimation,
                            curve: AppMotion.easeExit,
                          ),
                        ),
                        child: child,
                      ),
                    );
                  },
                ),
                routes: [
                  // Detalle: slide desde derecha (16px) + fade al entrar; inverso al volver.
                  GoRoute(
                    path: 'detail/:botId',
                    name: BotDetailView.routeName,
                    pageBuilder: (context, state) {
                      final botId = state.pathParameters['botId']!;
                      final reduced = AppMotion.reduced(context);
                      return CustomTransitionPage(
                        key: state.pageKey,
                        child: BotDetailView(botId: botId),
                        transitionDuration: reduced
                            ? AppMotion.durCrossfadeReduced
                            : AppMotion.durSlow,
                        reverseTransitionDuration: reduced
                            ? AppMotion.durCrossfadeReduced
                            : AppMotion.durBase,
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          if (AppMotion.reduced(context)) {
                            return FadeTransition(
                              opacity: CurvedAnimation(
                                parent: animation,
                                curve: AppMotion.easeStandard,
                              ),
                              child: child,
                            );
                          }
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.04, 0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: animation,
                              curve: AppMotion.easeEntrance,
                            )),
                            child: FadeTransition(
                              opacity: CurvedAnimation(
                                parent: animation,
                                curve: AppMotion.easeEntrance,
                              ),
                              child: child,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // RAMA 2: PLANOS (Bots Library)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bots',
                name: BotsLibraryView.routeName,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: BotsLibraryView()),
              ),
            ],
          ),

          // RAMA 3: FACTURACIÓN
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/billing',
                name: BillingView.routeName,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: BillingView()),
              ),
            ],
          ),

          // RAMA 4: PROTOCOLO (Settings)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: SettingsView.routeName,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: SettingsView()),
              ),
            ],
          ),

          // RAMA 5: TIENDA (Store)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/store',
                name: StoreView.routeName,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: StoreView()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

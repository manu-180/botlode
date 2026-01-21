// Archivo: lib/core/router/app_router.dart
import 'package:botslode/core/providers/auth_provider.dart';
import 'package:botslode/features/auth/presentation/views/login_view.dart';
import 'package:botslode/features/billing/presentation/views/billing_view.dart';
import 'package:botslode/features/bots_library/presentation/views/bots_library_view.dart';
import 'package:botslode/features/dashboard/presentation/views/bot_detail_view.dart';
import 'package:botslode/features/dashboard/presentation/views/dashboard_view.dart';
import 'package:botslode/features/dashboard/presentation/views/main_layout.dart';
import 'package:botslode/features/settings/presentation/views/settings_view.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(authProvider.select((state) => state.session));
  final isLoggedIn = session != null;

  return GoRouter(
    initialLocation: '/login', 
    
    redirect: (context, state) {
      final isGoingToLogin = state.uri.path == '/login';
      
      if (kDebugMode) {
        print("🧭 ROUTER CHECK | Path: ${state.uri.path} | User: ${isLoggedIn ? 'LOGUEADO' : 'NULL'}");
      }

      if (!isLoggedIn && !isGoingToLogin) {
        return '/login';
      }

      if (isLoggedIn && isGoingToLogin) {
        return '/dashboard';
      }

      if (state.uri.path == '/') {
        return isLoggedIn ? '/dashboard' : '/login';
      }

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
                pageBuilder: (context, state) => const NoTransitionPage(child: DashboardView()),
                routes: [
                  // MOVIMIENTOS ESTRATÉGICO: El detalle ahora vive en el Dashboard
                  GoRoute(
                    path: 'detail/:botId', // ruta relativa: /dashboard/detail/:botId
                    name: BotDetailView.routeName,
                    builder: (context, state) => BotDetailView(botId: state.pathParameters['botId']!),
                  ),
                ],
              ),
            ],
          ),
          // RAMA 2: PLANTILLAS (Antes Bots Library)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bots',
                name: BotsLibraryView.routeName,
                pageBuilder: (context, state) => const NoTransitionPage(child: BotsLibraryView()),
              ),
            ],
          ),
          // RAMA 3: BILLING
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/billing',
                name: BillingView.routeName,
                pageBuilder: (context, state) => const NoTransitionPage(child: BillingView()),
              ),
            ],
          ),
          // RAMA 4: SETTINGS
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: SettingsView.routeName,
                pageBuilder: (context, state) => const NoTransitionPage(child: SettingsView()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
// Archivo: lib/main.dart
import 'dart:async';
import 'package:botslode/core/config/app_config.dart';
import 'package:botslode/core/config/theme/app_theme.dart';
import 'package:botslode/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:rive/rive.dart'; // IMPORTACIÓN CRÍTICA AÑADIDA
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';
import 'package:botslode/core/logging/app_logger.dart';

final _log = AppLogger('Main');

const String DEPLOY_VERSION = "v1.0.5 - STABLE_CORE";

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 0. CARGA DE SECRETOS (PROTOCOLO DE SEGURIDAD)
    try {
      await dotenv.load(fileName: ".env");
      _log.info("🔐 [SEGURIDAD] Variables de entorno cargadas correctamente.");
    } catch (e) {
      _log.error("🔥 [FALLO CRÍTICO] No se pudo leer .env", error: e);
    }

    // 1. INICIALIZACIÓN DE STRIPE
    const stripeKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
    if (stripeKey.isNotEmpty) {
      Stripe.publishableKey = stripeKey;
      await Stripe.instance.applySettings();
      _log.info("💳 [STRIPE] SDK inicializado.");
    }

    // 2. INICIALIZACIÓN DE SUPABASE
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,     
        anonKey: AppConfig.supabaseAnonKey, 
      );
      _log.info("🚀 [ENLACE ESTABLECIDO] Supabase conectado.");
    } catch (e) {
      _log.error("🔥 [FALLO CRÍTICO] Error de enlace Supabase", error: e);
    }

    // 3. INICIALIZACIÓN DE RIVE (CORRECCIÓN VISUAL)
    try {
      await RiveFile.initialize();
      _log.info("🎨 [MOTOR GRÁFICO] Rive Engine inicializado.");
    } catch (e) {
      _log.warn("⚠️ [ADVERTENCIA VISUAL] Fallo en Rive Init", error: e);
    }

    // 4. CONFIGURACIÓN DE VENTANA
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 720), 
      minimumSize: Size(1024, 600), 
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    runApp(const ProviderScope(child: MainApp()));

  }, (error, stack) {
    _log.error("💥 CRASH DE NÚCLEO", error: error);
  });
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'BotLode Factory Terminal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
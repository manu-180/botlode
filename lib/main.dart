// Archivo: lib/main.dart
import 'dart:async';
import 'package:botslode/core/config/app_config.dart';
import 'package:botslode/core/config/theme/app_theme.dart';
import 'package:botslode/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // NUEVA IMPORTACIÓN
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';

const String DEPLOY_VERSION = "v1.0.4 - SECURE_CORE";

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 0. CARGA DE SECRETOS (PROTOCOLO DE SEGURIDAD)
    try {
      await dotenv.load(fileName: ".env");
      print("🔐 [SEGURIDAD] Variables de entorno cargadas correctamente.");
    } catch (e) {
      print("🔥 [FALLO CRÍTICO] No se pudo leer el archivo .env: $e");
      // Sin .env la app no debe arrancar, dejamos que el error continúe o manejamos una UI de error.
    }

    // 1. INICIALIZACIÓN DE SUPABASE (CON DIAGNÓSTICO)
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,     // Ahora lee del .env a través de AppConfig
        anonKey: AppConfig.supabaseAnonKey, 
      );
      print("🚀 [ENLACE ESTABLECIDO] Supabase conectado.");
    } catch (e) {
      print("🔥 [FALLO CRÍTICO] Error de enlace Supabase: $e");
    }

    // 2. CONFIGURACIÓN DE VENTANA (AJUSTE DE ALTURA)
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      // Reducimos altura de 800 a 720 para compatibilidad total
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
    print("💥 CRASH DE NÚCLEO: $error");
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
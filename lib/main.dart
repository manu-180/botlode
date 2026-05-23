// Archivo: lib/main.dart
import 'dart:async';
import 'package:botslode/core/config/app_config.dart';
import 'package:botslode/core/config/theme/app_theme.dart';
import 'package:botslode/core/observability/breadcrumbs.dart';
import 'package:botslode/core/observability/posthog_client.dart';
import 'package:botslode/core/observability/sentry_init.dart';
import 'package:botslode/core/platform/platform_info.dart';
import 'package:botslode/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:rive/rive.dart'; // IMPORTACIÓN CRÍTICA AÑADIDA
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:botslode/core/logging/app_logger.dart';
import 'package:google_fonts/google_fonts.dart';

final _log = AppLogger('Main');

const String DEPLOY_VERSION = "v1.0.5 - STABLE_CORE";

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    // T15·06 — Sentry init temprano para capturar errores de arranque.
    // Si SENTRY_DSN_BOTSLODE no está definido, no inicializa (dev local OK).
    await initSentry(appRunner: () async {

    // 0. CARGA DE SECRETOS (PROTOCOLO DE SEGURIDAD)
    try {
      await dotenv.load(fileName: ".env");
      _log.info("🔐 [SEGURIDAD] Variables de entorno cargadas correctamente.");
    } catch (e) {
      _log.error("🔥 [FALLO CRÍTICO] No se pudo leer .env", error: e);
    }

    // 0.5 PRECARGA DE FUENTES (JetBrains Mono via google_fonts)
    try {
      await GoogleFonts.pendingFonts([GoogleFonts.jetBrainsMono()]);
    } catch (e) {
      _log.warn("🔤 [FONTS] JetBrains Mono no pudo precargarse, se usará el fallback del sistema", error: e);
    }

    // 1. INICIALIZACIÓN DE STRIPE
    // flutter_stripe sólo soporta Android/iOS de forma nativa. En web se usa
    // flutter_stripe_web (init implícito), y en desktop no se inicializa.
    const stripeKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
    if (stripeKey.isNotEmpty && PlatformInfo.supportsNativeStripe) {
      Stripe.publishableKey = stripeKey;
      await Stripe.instance.applySettings();
      _log.info("💳 [STRIPE] SDK inicializado.");
    } else if (stripeKey.isNotEmpty && PlatformInfo.isWeb) {
      Stripe.publishableKey = stripeKey;
      _log.info("💳 [STRIPE] Public key configurada (web).");
    } else if (stripeKey.isEmpty) {
      _log.info("💳 [STRIPE] STRIPE_PUBLISHABLE_KEY vacía, SDK no inicializado.");
    } else {
      _log.info("💳 [STRIPE] Plataforma desktop sin soporte nativo Stripe.");
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

    // 3.5 INIT POSTHOG (T15·07). No init si las vars están vacías.
    try {
      await PostHogClient.instance.init(
        apiKey: const String.fromEnvironment('POSTHOG_PROJECT_API_KEY'),
        host: const String.fromEnvironment('POSTHOG_HOST', defaultValue: 'https://app.posthog.com'),
      );
    } catch (e) {
      _log.warn("📈 [POSTHOG] init falló", error: e);
    }

    // 4. La app pivoteó a mobile-first; ya no se configura window_manager.
    // En desktop nativo se usa la barra de título estándar del SO.

      // T15·08 — SentryRiverpodObserver: emite breadcrumbs por provider lifecycle.
      runApp(
        ProviderScope(
          observers: [SentryRiverpodObserver()],
          child: const MainApp(),
        ),
      );
    });

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
// T15·06 — botslode Sentry init.
// Cablea sentry_flutter con DSN desde --dart-define=SENTRY_DSN_BOTSLODE.
// Sampling: errors 1.0, traces 0.1 (override por env).
// Aplica PII redactor (T15·05) antes de enviar cualquier evento o breadcrumb.
//
// Uso desde main.dart:
//   await initSentry(appRunner: () async {
//     runApp(const ProviderScope(child: MainApp()));
//   });
//
// Para builds productivos, pasar:
//   flutter run --release \
//     --dart-define=SENTRY_DSN_BOTSLODE=https://<key>@<org>.ingest.sentry.io/<proj> \
//     --dart-define=SENTRY_TRACES_SAMPLE_RATE=0.1 \
//     --dart-define=SENTRY_ENVIRONMENT=production \
//     --dart-define=APP_RELEASE=botslode@1.0.0+abc1234
// O bien: --dart-define-from-file=secrets.json

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'pii_redactor.dart';

const _envDsn = String.fromEnvironment('SENTRY_DSN_BOTSLODE');
const _envTraces =
    String.fromEnvironment('SENTRY_TRACES_SAMPLE_RATE', defaultValue: '0.1');
const _envEnvironmentOverride =
    String.fromEnvironment('SENTRY_ENVIRONMENT', defaultValue: '');
const _envRelease =
    String.fromEnvironment('APP_RELEASE', defaultValue: 'botslode@dev');

/// Inicializa Sentry y ejecuta [appRunner] dentro del zone capturado.
/// Si el DSN no está definido (dev local sin secrets), corre [appRunner]
/// directamente y no envía nada a Sentry — esto permite que `flutter test`
/// y `flutter run` funcionen sin configurar el SDK.
Future<void> initSentry({
  required Future<void> Function() appRunner,
}) async {
  if (_envDsn.isEmpty) {
    if (kDebugMode) {
      debugPrint(
        '[T15] SENTRY_DSN_BOTSLODE vacío — Sentry no inicializa (modo dev).',
      );
    }
    await appRunner();
    return;
  }

  final tracesSampleRate = double.tryParse(_envTraces) ?? 0.1;
  final environment = _envEnvironmentOverride.isNotEmpty
      ? _envEnvironmentOverride
      : (kReleaseMode ? 'production' : 'development');

  await SentryFlutter.init(
    (options) {
      options.dsn = _envDsn;
      options.environment = environment;
      options.release = _envRelease;
      options.tracesSampleRate = tracesSampleRate;
      options.profilesSampleRate = 0.0; // habilitar manualmente en investigación
      options.attachStacktrace = true;
      options.sendDefaultPii = false;
      options.beforeSend = redactEvent;
      options.beforeBreadcrumb = redactBreadcrumb;
      // Drop screenshots por default — pueden contener todo el panel admin.
      options.attachScreenshot = false;
      options.attachViewHierarchy = false;
    },
    appRunner: appRunner,
  );
}

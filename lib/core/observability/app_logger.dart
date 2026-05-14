// Archivo: lib/core/observability/app_logger.dart
//
// Logger ligero y estructurado para botslode.
//
// • En `kDebugMode` imprime con prefijo por nivel + contexto.
// • En `kReleaseMode` los `info`/`debug` no imprimen; los `warn`/`error` sí.
//
// Diseñado para reemplazar `print()` que estaba sembrado en repos/providers.
// Más adelante se puede plug-in Sentry breadcrumbs/captureException acá.

import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warn, error }

class AppLogger {
  AppLogger._();

  static void debug(String tag, {Map<String, Object?>? context}) =>
      _log(LogLevel.debug, tag, context: context);

  static void info(String tag, {Map<String, Object?>? context}) =>
      _log(LogLevel.info, tag, context: context);

  static void warn(String tag,
          {Map<String, Object?>? context, Object? error}) =>
      _log(LogLevel.warn, tag, context: context, error: error);

  static void error(
    String tag, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? context,
  }) {
    _log(LogLevel.error, tag, context: context, error: error);
    if (kDebugMode && stackTrace != null) {
      // ignore: avoid_print
      print(stackTrace.toString());
    }
  }

  static void _log(
    LogLevel level,
    String tag, {
    Map<String, Object?>? context,
    Object? error,
  }) {
    final shouldPrint = switch (level) {
      LogLevel.debug => kDebugMode,
      LogLevel.info => kDebugMode,
      LogLevel.warn => true,
      LogLevel.error => true,
    };
    if (!shouldPrint) return;

    final prefix = switch (level) {
      LogLevel.debug => '🟦',
      LogLevel.info => '🟩',
      LogLevel.warn => '🟧',
      LogLevel.error => '🟥',
    };

    final ctx = context == null || context.isEmpty
        ? ''
        : ' ${_renderContext(context)}';
    final err = error == null ? '' : ' error=$error';
    // ignore: avoid_print
    print('$prefix [$tag]$ctx$err');
  }

  static String _renderContext(Map<String, Object?> ctx) {
    final entries = ctx.entries.map((e) => '${e.key}=${e.value}').join(' ');
    return '{$entries}';
  }
}

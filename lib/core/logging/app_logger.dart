import 'package:flutter/foundation.dart';

/// Logger neutro. Pre-T15.
/// En T15 se reemplaza la implementación por Sentry breadcrumbs.
class AppLogger {
  const AppLogger._(this._tag);

  final String _tag;

  factory AppLogger(String tag) => AppLogger._(tag);

  void debug(String message, {Object? error, StackTrace? stack}) {
    if (!kDebugMode) return;
    // ignore: avoid_print
    print('[D][$_tag] $message${error != null ? ' err=$error' : ''}');
  }

  void info(String message) {
    if (!kDebugMode) return;
    // ignore: avoid_print
    print('[I][$_tag] $message');
  }

  void warn(String message, {Object? error, StackTrace? stack}) {
    if (!kDebugMode) return;
    // ignore: avoid_print
    print('[W][$_tag] $message${error != null ? ' err=$error' : ''}');
  }

  void error(String message, {Object? error, StackTrace? stack}) {
    // En release este log se silencia hasta T15 (donde irá a Sentry).
    if (!kDebugMode) return;
    // ignore: avoid_print
    print('[E][$_tag] $message${error != null ? ' err=$error' : ''}');
  }
}

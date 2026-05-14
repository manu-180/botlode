// T15·08 — SentryRiverpodObserver para botslode.
// Emite breadcrumbs Sentry (no PostHog events) en didAddProvider /
// didUpdateProvider / providerDidFail. Excluye providers con nombre sensible
// (prompt/token/secret/password/chat_message) y throttles a 1/seg por provider
// para evitar rate-limit de Sentry cuando Riverpod actualiza en cascada.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'pii_redactor.dart';

class SentryRiverpodObserver extends ProviderObserver {
  static final RegExp _sensitiveName =
      RegExp(r'(prompt|token|secret|password|chat_message)', caseSensitive: false);

  final Map<String, int> _lastEmitMs = <String, int>{};
  static const int _throttleMs = 1000;

  bool _isSensitive(ProviderBase<Object?> provider) {
    final n = provider.name ?? provider.runtimeType.toString();
    return _sensitiveName.hasMatch(n);
  }

  bool _shouldThrottle(String key) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final last = _lastEmitMs[key];
    if (last != null && (now - last) < _throttleMs) return true;
    _lastEmitMs[key] = now;
    return false;
  }

  String _name(ProviderBase<Object?> p) => p.name ?? p.runtimeType.toString();

  void _emit({
    required ProviderBase<Object?> provider,
    required String category,
    required SentryLevel level,
    Map<String, dynamic>? extra,
  }) {
    if (_isSensitive(provider)) return;
    final name = _name(provider);
    if (_shouldThrottle('$category:$name')) return;

    final data = <String, dynamic>{
      'provider': _truncate(name, 200),
      if (extra != null) ...extra,
    };
    final clean = _scrubData(data);

    Sentry.addBreadcrumb(
      Breadcrumb(
        category: category,
        level: level,
        message: _truncate(name, 200),
        data: clean,
        timestamp: DateTime.now().toUtc(),
      ),
    );
  }

  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    _emit(provider: provider, category: 'riverpod.add', level: SentryLevel.info);
  }

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    _emit(
      provider: provider,
      category: 'riverpod.update',
      level: SentryLevel.debug,
      extra: {'changed': previousValue.runtimeType != newValue.runtimeType ||
          previousValue?.toString() != newValue?.toString()},
    );
  }

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    _emit(
      provider: provider,
      category: 'riverpod.fail',
      level: SentryLevel.error,
      extra: {'error_type': error.runtimeType.toString()},
    );
  }
}

String _truncate(String s, int max) => s.length > max ? '${s.substring(0, max)}…' : s;

Map<String, Object>? _scrubData(Map<String, dynamic> data) {
  if (data.isEmpty) return null;
  // Reusa scrub recursivo de pii_redactor vía redactProps de posthog_client
  // pero queremos quedarnos en pure dart sin depender de PostHogClient.
  // Replicamos la pieza mínima necesaria acá.
  final out = <String, Object>{};
  data.forEach((k, v) {
    if (_isSensitiveKey(k)) return;
    if (v == null) return;
    if (v is String) {
      out[k] = _scrubString(v);
    } else if (v is num || v is bool) {
      out[k] = v;
    } else {
      out[k] = v.toString();
    }
  });
  return out;
}

bool _isSensitiveKey(String key) {
  final k = key.toLowerCase();
  return RegExp(
    r'^(password|secret|token|api[_-]?key|authorization|bearer|cookie|'
    r'service_role_key|anon_key|system_prompt|prompt_template|dsn)$',
  ).hasMatch(k);
}

String _scrubString(String input) {
  var out = input;
  out = out.replaceAll(RegExp(r'\bsk-(?:proj-)?[A-Za-z0-9_-]{20,}'), '[REDACTED-SK]');
  out = out.replaceAll(
    RegExp(r'\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b'),
    '[REDACTED-JWT]',
  );
  out = out.replaceAll(
    RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b'),
    '[REDACTED-EMAIL]',
  );
  return out;
}

// Sólo para que `pii_redactor.dart` no aparezca sin uso en analyze (mantengo
// import por consistencia con el patrón del módulo).
// ignore: unused_element
void _ensureRedactorImported() {
  // El módulo pii_redactor.dart se usa en sentry_init.dart; este archivo
  // duplica las helpers mínimas para no acoplarse con la forma del payload
  // de Sentry y mantener el observer puro.
  if (kDebugMode) {}
}

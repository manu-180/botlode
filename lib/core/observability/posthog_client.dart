// T15·07 — Wrapper PostHog para botslode.
// Singleton con consent gate, init perezoso por DSN y PII redactor de props.
// Usar siempre `capture(AnalyticsEvent.xxx, props: {...})` — no llamar SDK directo.

import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

import 'analytics_events.dart';

class PostHogClient {
  PostHogClient._();
  static final PostHogClient instance = PostHogClient._();

  bool _initialized = false;
  bool _consentGranted = false;
  Posthog get _posthog => Posthog();

  /// Inicializa PostHog si [apiKey] y [host] están presentes; no-op si vacíos.
  /// Por privacidad, el capture queda gateado por [setConsent] (default false).
  Future<void> init({required String apiKey, required String host}) async {
    if (_initialized) return;
    if (apiKey.isEmpty || host.isEmpty) {
      if (kDebugMode) {
        debugPrint('[T15] POSTHOG_PROJECT_API_KEY/HOST vacío — PostHog no inicializa.');
      }
      return;
    }
    // SDK ya recibe apiKey/host vía nativo (Android: AndroidManifest meta-data;
    // iOS: Info.plist). En runtime sólo aseguramos features del client.
    await _posthog.enable(); // habilita pero NO captura hasta consent
    await _posthog.disable(); // empieza pausado — consent lo despierta
    _initialized = true;
  }

  /// Activa/desactiva captura según consent del usuario (GDPR / opt-in).
  Future<void> setConsent(bool granted) async {
    _consentGranted = granted;
    if (!_initialized) return;
    if (granted) {
      await _posthog.enable();
    } else {
      await _posthog.disable();
    }
  }

  /// Captura un evento del catálogo tipado. Aplica PII scrub a props.
  /// No-op si no hay init o sin consent.
  void capture(AnalyticsEvent event, {Map<String, dynamic>? props}) {
    if (!_initialized || !_consentGranted) return;
    final clean = redactProps(props ?? const {});
    _posthog.capture(eventName: event.key, properties: clean);
  }

  /// Identifica al user. Solo con consent y tras init.
  void identify(String userId, {Map<String, dynamic>? props}) {
    if (!_initialized || !_consentGranted) return;
    if (userId.isEmpty) return;
    final clean = redactProps(props ?? const {});
    _posthog.identify(userId: userId, userProperties: clean);
  }

  /// Reset al hacer logout — desidentifica para evitar mezcla de usuarios.
  void reset() {
    if (!_initialized) return;
    _posthog.reset();
  }
}

// ─── PII scrub (T15·05) ───────────────────────────────────────────────────────

/// Visible para testing. Elimina Sensitive y enmascara PII.
@visibleForTesting
Map<String, Object> redactProps(Map<String, dynamic> props) {
  final out = <String, Object>{};
  props.forEach((k, v) {
    final key = k.toLowerCase();
    if (_isSensitiveKey(key)) return;
    if (v == null) return;
    if (v is String) {
      if (RegExp(r'email').hasMatch(key)) {
        out[k] = _maskEmail(v);
      } else if (RegExp(r'(phone|whatsapp|mobile|tel)').hasMatch(key)) {
        out[k] = _maskPhone(v);
      } else if (RegExp(r'ip_address|client_ip').hasMatch(key)) {
        out[k] = _truncateOctet(v);
      } else {
        out[k] = _scrubString(v);
      }
    } else if (v is num || v is bool) {
      out[k] = v;
    } else if (v is Map) {
      out[k] = redactProps(Map<String, dynamic>.from(v));
    } else if (v is List) {
      out[k] = v.map((e) => e is String ? _scrubString(e) : e).toList();
    } else {
      out[k] = v.toString();
    }
  });
  return out;
}

bool _isSensitiveKey(String key) => RegExp(
      r'^(password|secret|token|api[_-]?key|authorization|bearer|cookie|'
      r'service_role_key|anon_key|system_prompt|prompt_template|dsn)$',
    ).hasMatch(key);

String _scrubString(String input) {
  var out = input;
  out = out.replaceAll(RegExp(r'\bsk-(?:proj-)?[A-Za-z0-9_-]{20,}'), '[REDACTED-SK]');
  out = out.replaceAll(RegExp(r'\bsk-ant-[A-Za-z0-9_-]{20,}'), '[REDACTED-ANTHROPIC]');
  out = out.replaceAll(RegExp(r'\bAKIA[0-9A-Z]{16}\b'), '[REDACTED-AWS]');
  out = out.replaceAll(
    RegExp(r'\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b'),
    '[REDACTED-JWT]',
  );
  out = out.replaceAll(
    RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b'),
    '[REDACTED-EMAIL]',
  );
  out = out.replaceAll(RegExp(r'\+\d{1,3}[\s-]?\d{6,14}\b'), '[REDACTED-PHONE]');
  out = out.replaceAll(RegExp(r'\b\d{2}-\d{8}-\d\b'), '[REDACTED-CUIT]');
  return out;
}

String _maskEmail(String email) {
  final at = email.indexOf('@');
  if (at <= 0) return '[REDACTED-EMAIL]';
  final user = email.substring(0, at);
  final domain = email.substring(at + 1);
  final lastDot = domain.lastIndexOf('.');
  if (lastDot <= 0) return '[REDACTED-EMAIL]';
  final domainName = domain.substring(0, lastDot);
  final tld = domain.substring(lastDot + 1);
  final u = user.isNotEmpty ? user[0] : '*';
  final d = domainName.isNotEmpty ? domainName[0] : '*';
  return '$u***@$d***.$tld';
}

String _maskPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 4) return '[REDACTED-PHONE]';
  final keepStart = phone.substring(0, phone.length > 3 ? 3 : 1);
  final lastTwo = digits.substring(digits.length - 2);
  final maskLen = digits.length - 5;
  return '$keepStart${'*' * (maskLen > 0 ? maskLen : 0)}$lastTwo';
}

String _truncateOctet(String ip) {
  final v4 = RegExp(r'^(\d{1,3}\.\d{1,3}\.\d{1,3})\.\d{1,3}$').firstMatch(ip);
  if (v4 != null) return '${v4.group(1)}.0';
  if (ip.contains(':')) {
    final parts = ip.split(':');
    return '${parts.take(3).join(':')}::0';
  }
  return ip;
}

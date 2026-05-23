// T15·05 — PII redactor para Sentry events y breadcrumbs (botslode).
// Implementa la política canónica de docs/observability/pii-filtering-policy.md.
// Drop absoluto de Sensitive (system_prompt, tokens, keys), mask de PII (email, phone, IP),
// scrub regex de secretos en strings libres.

import 'package:sentry_flutter/sentry_flutter.dart';

/// Aplica políticas T15·05 sobre un [SentryEvent] antes de enviar.
/// Devuelve `null` solo si el evento entero debe descartarse (en general nunca).
SentryEvent? redactEvent(SentryEvent event, Hint hint) {
  // User: mask email + truncate IP
  if (event.user != null) {
    event = event.copyWith(
      user: event.user!.copyWith(
        email: event.user!.email != null ? _maskEmail(event.user!.email!) : null,
        ipAddress: event.user!.ipAddress != null
            ? _truncateOctet(event.user!.ipAddress!)
            : null,
      ),
    );
  }

  // Message: scrub
  final message = event.message?.formatted;
  if (message != null && message.isNotEmpty) {
    event = event.copyWith(
      message: SentryMessage(_scrubString(message)),
    );
  }

  // Exceptions: scrub value
  final exceptions = event.exceptions;
  if (exceptions != null) {
    final scrubbed = exceptions.map((e) {
      final value = e.value;
      if (value == null) return e;
      return e.copyWith(value: _scrubString(value));
    }).toList();
    event = event.copyWith(exceptions: scrubbed);
  }

  // Tags: drop si la key matchea Sensitive
  final tags = event.tags;
  if (tags != null) {
    final filtered = <String, String>{};
    tags.forEach((k, v) {
      if (_isSensitiveKey(k)) return;
      filtered[k] = _scrubString(v);
    });
    event = event.copyWith(tags: filtered);
  }

  // Extra: drop Sensitive, scrub strings
  final extra = event.extra;
  if (extra != null) {
    final filtered = <String, dynamic>{};
    extra.forEach((k, v) {
      if (_isSensitiveKey(k)) return;
      if (v is String) {
        filtered[k] = _scrubString(v);
      } else {
        filtered[k] = v;
      }
    });
    event = event.copyWith(extra: filtered);
  }

  return event;
}

/// Aplica políticas T15·05 sobre un [Breadcrumb] antes de adjuntarlo.
/// Devuelve `null` para descartar el breadcrumb.
///
/// La signature acepta `Breadcrumb?` para coincidir con `BeforeBreadcrumbCallback`
/// de sentry_flutter 8.x.
Breadcrumb? redactBreadcrumb(Breadcrumb? crumb, Hint hint) {
  if (crumb == null) return null;

  // Drop categorías sensibles enteras
  if (crumb.category == 'auth' || crumb.category == 'billing.secret') {
    return null;
  }

  final message = crumb.message;
  final data = crumb.data;

  return crumb.copyWith(
    message: message != null ? _scrubString(message) : null,
    data: data != null ? _scrubMap(data) : null,
  );
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

bool _isSensitiveKey(String key) {
  final k = key.toLowerCase();
  return RegExp(
    r'^(password|secret|token|api[_-]?key|authorization|bearer|cookie|'
    r'service_role_key|anon_key|system_prompt|prompt_template|dsn)$',
  ).hasMatch(k);
}

Map<String, dynamic> _scrubMap(Map<String, dynamic> input) {
  final out = <String, dynamic>{};
  input.forEach((k, v) {
    if (_isSensitiveKey(k)) return;
    final key = k.toLowerCase();
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
    } else if (v is Map) {
      out[k] = _scrubMap(Map<String, dynamic>.from(v));
    } else {
      out[k] = v;
    }
  });
  return out;
}

String _scrubString(String input) {
  var out = input;
  // OpenAI / generic SDK keys
  out = out.replaceAll(RegExp(r'\bsk-(?:proj-)?[A-Za-z0-9_-]{20,}'), '[REDACTED-SK]');
  out = out.replaceAll(RegExp(r'\bsk-ant-[A-Za-z0-9_-]{20,}'), '[REDACTED-ANTHROPIC]');
  // AWS access keys
  out = out.replaceAll(RegExp(r'\bAKIA[0-9A-Z]{16}\b'), '[REDACTED-AWS]');
  // JWT
  out = out.replaceAll(
    RegExp(r'\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b'),
    '[REDACTED-JWT]',
  );
  // Email
  out = out.replaceAll(
    RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b'),
    '[REDACTED-EMAIL]',
  );
  // Teléfono internacional E.164
  out = out.replaceAll(RegExp(r'\+\d{1,3}[\s-]?\d{6,14}\b'), '[REDACTED-PHONE]');
  // CUIT/CUIL
  out = out.replaceAll(RegExp(r'\b\d{2}-\d{8}-\d\b'), '[REDACTED-CUIT]');
  // password=value patterns
  out = out.replaceAllMapped(
    RegExp(r'\b(password|secret|token|api[_-]?key)["' "'" r'\s:=]+[^\s"' "'" r',]{6,}',
        caseSensitive: false),
    (m) => '${m.group(1)}=[REDACTED]',
  );
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

// T15·07 — Verifica que los strings de AnalyticsEvent matcheen 1:1 con el
// catálogo del GLOSSARY y que redactProps aplique PII policy correctamente.

import 'package:flutter_test/flutter_test.dart';
import 'package:botslode/core/observability/analytics_events.dart';
import 'package:botslode/core/observability/posthog_client.dart';

void main() {
  group('AnalyticsEvent.key', () {
    test('19 events tienen keys snake_case del GLOSSARY', () {
      // Lista canónica del GLOSSARY — si cambia ahí, también acá.
      const expected = <String>{
        'bot_created',
        'bot_published',
        'bot_paused',
        'bot_deleted',
        'chat_started',
        'chat_message_sent',
        'chat_message_received',
        'lead_scored_hot',
        'lead_alert_sent',
        'meeting_booked',
        'checkout_initiated',
        'checkout_completed',
        'subscription_created',
        'subscription_canceled',
        'plan_upgraded',
        'plan_downgraded',
        'widget_loaded',
        'widget_opened',
        'widget_closed',
      };
      final actual = AnalyticsEvent.values.map((e) => e.key).toSet();
      expect(actual, equals(expected));
      expect(AnalyticsEvent.values.length, equals(19));
    });

    test('todos los keys son snake_case (lowercase + underscores)', () {
      for (final e in AnalyticsEvent.values) {
        expect(
          RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(e.key),
          isTrue,
          reason: '"${e.key}" no es snake_case',
        );
      }
    });
  });

  group('redactProps', () {
    test('drop system_prompt y tokens', () {
      final out = redactProps({
        'system_prompt': 'IP del cliente bla bla',
        'token': 'eyJabc.def.ghi',
        'authorization': 'Bearer xxx',
        'tenant_id': 'abc-123',
      });
      expect(out.containsKey('system_prompt'), isFalse);
      expect(out.containsKey('token'), isFalse);
      expect(out.containsKey('authorization'), isFalse);
      expect(out['tenant_id'], equals('abc-123'));
    });

    test('mask email', () {
      final out = redactProps({'email': 'juan.perez@gmail.com'});
      expect(out['email'], equals('j***@g***.com'));
    });

    test('mask phone', () {
      final out = redactProps({'phone': '+541112345678'});
      expect(out['phone'] as String, contains('***'));
      expect(out['phone'] as String, endsWith('78'));
    });

    test('truncate IP octet', () {
      final out = redactProps({'ip_address': '192.168.1.42'});
      expect(out['ip_address'], equals('192.168.1.0'));
    });

    test('scrub OpenAI key en string libre', () {
      final out = redactProps({'note': 'la key es sk-proj-AAAABBBBCCCCDDDDEEEEFFFF'});
      expect(out['note'], contains('[REDACTED-SK]'));
      expect(out['note'], isNot(contains('AAAABBBBCCCC')));
    });

    test('preserva tenant_id, bot_id, user_id', () {
      final out = redactProps({
        'tenant_id': 'tenant-xyz',
        'bot_id': 'bot-abc',
        'user_id': 'user-123',
      });
      expect(out['tenant_id'], equals('tenant-xyz'));
      expect(out['bot_id'], equals('bot-abc'));
      expect(out['user_id'], equals('user-123'));
    });
  });

  group('PostHogClient capture gating', () {
    test('capture es no-op si nunca init', () {
      final c = PostHogClient.instance;
      // Sin init() previo no debe lanzar.
      expect(
        () => c.capture(AnalyticsEvent.chatStarted, props: {'foo': 'bar'}),
        returnsNormally,
      );
    });
  });
}

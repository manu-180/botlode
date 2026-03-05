import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:botslode/core/providers/supabase_provider.dart';
import 'package:botslode/features/wpp_inbox/domain/models/wpp_conversation.dart';
import 'package:botslode/features/wpp_inbox/domain/models/wpp_message.dart';

// ---------------------------------------------------------------------------
// Provider: lista de conversaciones (con Realtime)
// ---------------------------------------------------------------------------

class ConversationsNotifier extends StateNotifier<AsyncValue<List<WppConversation>>> {
  ConversationsNotifier(this._supabase) : super(const AsyncValue.loading()) {
    _load();
    _subscribeRealtime();
  }

  final SupabaseClient _supabase;
  RealtimeChannel? _channel;

  Future<void> _load() async {
    try {
      debugPrint('[WppInbox] ConversationsNotifier: cargando lista...');
      final rows = await _supabase
          .from('wpp_conversations')
          .select()
          .order('last_message_at', ascending: false);
      final list = (rows as List).map((r) => WppConversation.fromMap(r as Map<String, dynamic>)).toList();
      debugPrint('[WppInbox] ConversationsNotifier: cargadas ${list.length} conversaciones. IDs: ${list.map((c) => c.id).take(3).toList()}');
      state = AsyncValue.data(list);
    } catch (e, st) {
      debugPrint('[WppInbox] ConversationsNotifier: ERROR _load: $e\n$st');
      state = AsyncValue.error(e, st);
    }
  }

  void _subscribeRealtime() {
    debugPrint('[WppInbox] ConversationsNotifier: suscribiendo a Realtime wpp_conversations');
    _channel = _supabase
        .channel('wpp_conversations_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'wpp_conversations',
          callback: (payload) {
            debugPrint('[WppInbox] Realtime wpp_conversations: evento ${payload.eventType}');
            _load();
          },
        )
        .subscribe((status, [err]) {
          debugPrint('[WppInbox] Realtime wpp_conversations subscribe: status=$status err=$err');
        });
  }

  Future<void> refresh() => _load();

  /// Marca todos los mensajes de una conversación como leídos (unread_count = 0).
  Future<void> markAsRead(String conversationId) async {
    await _supabase
        .from('wpp_conversations')
        .update({'unread_count': 0})
        .eq('id', conversationId);
    // La actualización dispara el Realtime y refresca la lista automáticamente.
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

final wppConversationsProvider =
    StateNotifierProvider<ConversationsNotifier, AsyncValue<List<WppConversation>>>(
  (ref) => ConversationsNotifier(ref.watch(supabaseClientProvider)),
);

// ---------------------------------------------------------------------------
// Provider: mensajes de una conversación (con Realtime)
// ---------------------------------------------------------------------------

class MessagesNotifier extends StateNotifier<AsyncValue<List<WppMessage>>> {
  MessagesNotifier(this._supabase, this.conversationId)
      : super(const AsyncValue.loading()) {
    _load();
    _subscribeRealtime();
  }

  final SupabaseClient _supabase;
  final String conversationId;
  RealtimeChannel? _channel;

  Future<void> _load() async {
    try {
      debugPrint('[WppInbox] MessagesNotifier($conversationId): cargando mensajes...');
      final rows = await _supabase
          .from('wpp_messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);
      final list = (rows as List).map((r) => WppMessage.fromMap(r as Map<String, dynamic>)).toList();
      debugPrint('[WppInbox] MessagesNotifier($conversationId): cargados ${list.length} mensajes');
      state = AsyncValue.data(list);
    } catch (e, st) {
      debugPrint('[WppInbox] MessagesNotifier($conversationId): ERROR _load: $e\n$st');
      state = AsyncValue.error(e, st);
    }
  }

  void _subscribeRealtime() {
    debugPrint('[WppInbox] MessagesNotifier($conversationId): suscribiendo Realtime wpp_messages');
    _channel = _supabase
        .channel('wpp_messages_$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'wpp_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            debugPrint('[WppInbox] Realtime wpp_messages: evento ${payload.eventType} conversation=$conversationId');
            _load();
          },
        )
        .subscribe((status, [err]) {
          debugPrint('[WppInbox] Realtime wpp_messages subscribe: status=$status err=$err');
        });
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

// Provider con familia: un MessagesNotifier por conversación.
final wppMessagesProvider = StateNotifierProvider.family<
    MessagesNotifier, AsyncValue<List<WppMessage>>, String>(
  (ref, conversationId) => MessagesNotifier(
    ref.watch(supabaseClientProvider),
    conversationId,
  ),
);

// ---------------------------------------------------------------------------
// Provider: conversación activa seleccionada en la UI
// ---------------------------------------------------------------------------

final activeConversationProvider = StateProvider<WppConversation?>((ref) => null);

// ---------------------------------------------------------------------------
// Service: envío de respuesta de texto libre (dentro de ventana de 24h)
// ---------------------------------------------------------------------------

class WppReplyService {
  WppReplyService(this._supabase);
  final SupabaseClient _supabase;

  bool _envLoaded = false;

  Future<void> _ensureEnv() async {
    if (_envLoaded) return;
    await dotenv.load(fileName: '.env');
    _envLoaded = true;
  }

  /// Envía un mensaje de texto libre al número destino via Twilio y lo guarda
  /// en wpp_messages como outbound.
  Future<bool> sendReply({
    required String conversationId,
    required String toPhoneNumber, // "whatsapp:+549..."
    required String body,
  }) async {
    try {
      await _ensureEnv();
      final apiKeySid   = dotenv.env['API_KEY_SID']?.trim() ?? '';
      final apiSecret   = dotenv.env['API_KEY_SECRET']?.trim() ?? '';
      final accountSid  = dotenv.env['ACCOUNT_SID']?.trim() ?? '';

      if (apiKeySid.isEmpty || apiSecret.isEmpty || accountSid.isEmpty) {
        debugPrint('[WppReply] Faltan credenciales Twilio en .env');
        return false;
      }

      const fromNumber = 'whatsapp:+5491125303794';

      final uri = Uri.parse(
        'https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json',
      );

      final response = await http.Client()
          .post(
            uri,
            headers: {
              'Authorization':
                  'Basic ${base64Encode(utf8.encode('$apiKeySid:$apiSecret'))}',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'From': fromNumber,
              'To':   toPhoneNumber,
              'Body': body,
            },
          )
          .timeout(const Duration(seconds: 15));

      final success = response.statusCode == 201;
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final twilioSid = decoded['sid'] as String?;

      // Guardar en Supabase como outbound
      await _supabase.from('wpp_messages').insert({
        'conversation_id': conversationId,
        'twilio_sid':      twilioSid,
        'direction':       'outbound',
        'body':            body,
        'status':          success ? 'sent' : 'failed',
      });

      if (success) {
        // Actualizar último mensaje en la conversación
        await _supabase.from('wpp_conversations').update({
          'last_message_at':   DateTime.now().toUtc().toIso8601String(),
          'last_message_body': body.length > 200 ? '${body.substring(0, 200)}…' : body,
        }).eq('id', conversationId);
      }

      if (!success) debugPrint('[WppReply] Error Twilio: ${response.body}');
      return success;
    } on SocketException catch (e) {
      debugPrint('[WppReply] Sin conexión: $e');
      return false;
    } on TimeoutException catch (_) {
      debugPrint('[WppReply] Timeout');
      return false;
    } catch (e) {
      debugPrint('[WppReply] Error inesperado: $e');
      return false;
    }
  }
}

final wppReplyServiceProvider = Provider<WppReplyService>(
  (ref) => WppReplyService(ref.watch(supabaseClientProvider)),
);

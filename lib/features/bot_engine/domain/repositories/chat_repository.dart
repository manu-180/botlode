// Archivo: lib/features/bot_engine/domain/repositories/chat_repository.dart
import 'package:botslode/features/bot_engine/domain/models/bot_response.dart';

abstract class ChatRepository {
  /// Envía un mensaje al núcleo de IA (Edge Function) y retorna la respuesta procesada.
  Future<BotResponse> sendMessage({
    required String message,
    required String sessionId,
    required String botId,
  });
}
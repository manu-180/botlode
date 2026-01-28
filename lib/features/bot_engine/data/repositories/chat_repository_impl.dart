// Archivo: lib/features/bot_engine/data/repositories/chat_repository_impl.dart
import 'dart:convert';
import 'package:botslode/core/config/app_config.dart';
import 'package:botslode/features/bot_engine/domain/models/bot_response.dart';
import 'package:botslode/features/bot_engine/domain/repositories/chat_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ChatRepositoryImpl implements ChatRepository {
  
  @override
  Future<BotResponse> sendMessage({
    required String message,
    required String sessionId,
    required String botId,
  }) async {
    try {
      final urlString = AppConfig.brainFunctionUrl;
      if (urlString.isEmpty) throw Exception("Protocolo de enlace no configurado (URL vacía)");

      final uri = Uri.parse(urlString);
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        },
        body: jsonEncode({
          'sessionId': sessionId,
          'botId': botId,
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        // Decodificación UTF-8 explícita para tildes y ñ
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonMap = jsonDecode(decodedBody);
        return BotResponse.fromJson(jsonMap);
      } else {
        throw Exception('Fallo del Núcleo: Código ${response.statusCode}');
      }
    } catch (e) {
      // Error silenciado
      // En lugar de romper la app, devolvemos una respuesta de error táctica
      return const BotResponse(
        reply: 'FALLO DE ENLACE NEURAL: Verifica la conexión o el estado de la Edge Function.',
        mood: 'confused'
      );
    }
  }
}
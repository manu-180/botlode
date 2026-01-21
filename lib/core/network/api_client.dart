// Archivo: lib/core/network/api_client.dart
import 'dart:convert';
import 'package:botslode/core/config/app_config.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  /// Envía mensaje al cerebro (Edge Function: botlode-brain)
  Future<Map<String, dynamic>> sendMessage({
    required String message,
    required String sessionId,
    required String botId,
  }) async {
    try {
      final urlString = AppConfig.brainFunctionUrl;
      if (urlString.isEmpty) throw Exception("Protocolo de enlace no configurado");

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
        // Decodificamos con UTF-8 para soportar tildes y caracteres especiales
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Error del Núcleo: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("🔴 CRITICAL LINK ERROR: $e");
      return {
        'reply': 'FALLO DE ENLACE NEURAL: Verifica la conexión o el estado de la Edge Function.', 
        'mood': 'confused'
      };
    }
  }
}
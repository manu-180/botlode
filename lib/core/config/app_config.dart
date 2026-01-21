// Archivo: lib/core/config/app_config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Mantenemos esta URL aquí ya que no venía en tu .env, 
  // pero idealmente también debería ir a variables de entorno en el futuro.
  static const String playerBaseUrl = "https://botlode-player.vercel.app";

  // --- GETTERS SEGUROS CONECTADOS A .ENV ---
  
  static String get supabaseUrl {
    final url = dotenv.env['SUPABASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception("FATAL ERROR: 'SUPABASE_URL' no encontrada en .env");
    }
    return url;
  }

  static String get supabaseAnonKey {
    final key = dotenv.env['SUPABASE_ANON_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception("FATAL ERROR: 'SUPABASE_ANON_KEY' no encontrada en .env");
    }
    return key;
  }

  // Lógica derivada (se mantiene igual pero usa los getters seguros)
  static String get brainFunctionUrl {
    final baseUrl = supabaseUrl;
    if (baseUrl.isEmpty) return '';
    final cleanUrl = baseUrl.endsWith('/') 
        ? baseUrl.substring(0, baseUrl.length - 1) 
        : baseUrl;
    // CORRECCIÓN: Nombre exacto de la función desplegada
    return '$cleanUrl/functions/v1/botlode-brain'; 
  }

  static const String fallbackBotId = "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11"; 
}
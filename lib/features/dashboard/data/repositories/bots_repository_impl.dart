// Archivo: lib/features/dashboard/data/repositories/bots_repository_impl.dart
import 'dart:math';
import 'dart:ui';
import 'package:botslode/features/dashboard/domain/models/bot.dart';
import 'package:botslode/features/dashboard/domain/repositories/bots_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BotsRepositoryImpl implements BotsRepository {
  final SupabaseClient _supabase;

  BotsRepositoryImpl(this._supabase);

  /// Maneja errores de Supabase diferenciando entre conexión, auth y errores de DB.
  Never _handleSupabaseError(Object e, String fallbackMessage) {
    debugPrint('[BotsRepository] Error: $e');
    if (e is PostgrestException) {
      final code = e.code ?? '';
      if (code.contains('PGRST301') || e.message.toLowerCase().contains('jwt') || e.message.toLowerCase().contains('unauthorized')) {
        throw Exception('Tu sesión ha expirado. Por favor, inicia sesión nuevamente.');
      }
      throw Exception(e.message.isNotEmpty ? e.message : fallbackMessage);
    }
    final msg = e.toString().toLowerCase();
    if (msg.contains('socket') || msg.contains('connection') || msg.contains('timeout') || msg.contains('failed host') || msg.contains('network')) {
      throw Exception(fallbackMessage);
    }
    throw Exception(fallbackMessage);
  }

  @override
  Future<List<Bot>> getBots() async {
    try {
      final response = await _supabase
          .from('bots')
          .select()
          .order('created_at', ascending: false);
      
      return (response as List).map((m) => Bot.fromMap(m)).toList();
    } catch (e) {
      _handleSupabaseError(e, "No pudimos cargar tus bots. Verifica tu conexión a internet.");
    }
  }

  @override
  Future<Bot> createBot({
    required String userId,
    required String name,
    required String description,
    required String systemPrompt,
    required Color color,
  }) async {
    try {
      final hexColor = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
      final nowUtc = DateTime.now().toUtc();

      // ⬅️ NUEVO: Generar PIN automático de 4 dígitos (1000-9999)
      final random = Random();
      final pin = (1000 + random.nextInt(9000)).toString(); // Número aleatorio entre 1000-9999
      
      // ⬅️ NUEVO: Generar alias basado en el nombre (normalizado a minúsculas)
      // Remover caracteres especiales y espacios, convertir a minúsculas
      var alias = name
          .toLowerCase()
          .trim()
          .replaceAll(RegExp(r'[^a-z0-9\s-]'), '') // Remover caracteres especiales
          .replaceAll(RegExp(r'\s+'), '-') // Espacios a guiones
          .replaceAll(RegExp(r'-+'), '-') // Múltiples guiones a uno
          .replaceAll(RegExp(r'^-|-$'), ''); // Remover guiones al inicio/fin
      
      // Si el alias queda vacío, usar un alias por defecto
      if (alias.isEmpty) {
        alias = 'bot-${DateTime.now().millisecondsSinceEpoch % 10000}';
      }

      final newBotMap = {
        'user_id': userId,
        'name': name,
        'alias': alias, // ⬅️ Alias generado automáticamente
        'description': description,
        'system_prompt': systemPrompt,
        'status': 'active',
        'tech_color': hexColor,
        'current_balance': 0.0,
        'cycle_start_date': nowUtc.toIso8601String(),
        'created_at': nowUtc.toIso8601String(),
        'access_pin': pin, // ⬅️ PIN generado automáticamente
      };

      final response = await _supabase
          .from('bots')
          .insert(newBotMap)
          .select('*, access_pin, alias') // ⬅️ Incluir PIN y alias en la respuesta
          .single();

      // ⬅️ Guardar PIN y alias para mostrarlos al usuario
      final createdPin = response['access_pin'] as String? ?? pin;
      final createdAlias = response['alias'] as String? ?? alias;
      
      return Bot.fromMap(response);
    } catch (e) {
      _handleSupabaseError(e, "No pudimos crear el bot. Por favor, intenta nuevamente.");
    }
  }

  @override
  Future<void> updateBot(Bot bot) async {
    try {
      await _supabase.from('bots').update({
        'status': bot.status == BotStatus.creditSuspended ? 'credit_suspended' : bot.status.name,
        'current_balance': bot.currentBalance,
        'cycle_start_date': bot.cycleStartDate.toIso8601String(),
        'theme_mode': bot.themeMode,
        'show_offline_alert': bot.showOfflineAlert,
        // Agregamos mapeo inverso del color si cambia, para consistencia
        'tech_color': '#${bot.primaryColor.value.toRadixString(16).substring(2).toUpperCase()}',
      }).eq('id', bot.id);
    } catch (e) {
      _handleSupabaseError(e, "No pudimos actualizar el bot. Verifica tu conexión.");
    }
  }

  @override
  Future<void> patchBot(String botId, Map<String, dynamic> data) async {
    try {
      await _supabase.from('bots').update(data).eq('id', botId);
    } catch (e) {
      _handleSupabaseError(e, "No pudimos guardar los cambios. Verifica tu conexión.");
    }
  }

  @override
  Future<void> deleteBot(String botId) async {
    try {
      await _supabase.from('bots').delete().eq('id', botId);
    } catch (e) {
      _handleSupabaseError(e, "No pudimos eliminar el bot. Por favor, intenta nuevamente.");
    }
  }
}
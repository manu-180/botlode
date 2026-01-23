// Archivo: lib/features/dashboard/data/repositories/bots_repository_impl.dart
import 'dart:ui';
import 'package:botslode/features/dashboard/domain/models/bot.dart';
import 'package:botslode/features/dashboard/domain/repositories/bots_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BotsRepositoryImpl implements BotsRepository {
  final SupabaseClient _supabase;

  BotsRepositoryImpl(this._supabase);

  @override
  Future<List<Bot>> getBots() async {
    try {
      final response = await _supabase
          .from('bots')
          .select()
          .order('created_at', ascending: false);
      
      return (response as List).map((m) => Bot.fromMap(m)).toList();
    } catch (e) {
      debugPrint("🔴 Error fetching bots from Repo: $e");
      throw Exception("Error al obtener bots: $e");
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

      final newBotMap = {
        'user_id': userId,
        'name': name,
        'description': description,
        'system_prompt': systemPrompt,
        'status': 'active',
        'tech_color': hexColor,
        'current_balance': 0.0,
        'cycle_start_date': nowUtc.toIso8601String(),
        'created_at': nowUtc.toIso8601String(),
      };

      final response = await _supabase
          .from('bots')
          .insert(newBotMap)
          .select()
          .single();

      return Bot.fromMap(response);
    } catch (e) {
      debugPrint("🔴 Error creating bot in Repo: $e");
      throw Exception("Error al crear bot: $e");
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
      debugPrint("🔴 Error updating bot in Repo: $e");
      throw Exception("Error al actualizar bot: $e");
    }
  }

  @override
  Future<void> patchBot(String botId, Map<String, dynamic> data) async {
    try {
      await _supabase.from('bots').update(data).eq('id', botId);
    } catch (e) {
       debugPrint("🔴 Error patching bot in Repo: $e");
       throw Exception("Error al modificar bot: $e");
    }
  }

  @override
  Future<void> deleteBot(String botId) async {
    try {
      await _supabase.from('bots').delete().eq('id', botId);
    } catch (e) {
      debugPrint("🔴 Error deleting bot in Repo: $e");
      throw Exception("Error al eliminar bot: $e");
    }
  }
}
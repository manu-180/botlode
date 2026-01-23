// Archivo: lib/features/dashboard/domain/repositories/bots_repository.dart
import 'dart:ui';
import 'package:botslode/features/dashboard/domain/models/bot.dart';

abstract class BotsRepository {
  /// Obtiene la lista completa de bots ordenados por creación.
  Future<List<Bot>> getBots();

  /// Crea un nuevo bot en la base de datos.
  Future<Bot> createBot({
    required String userId,
    required String name,
    required String description,
    required String systemPrompt,
    required Color color,
  });

  /// Actualiza los campos de un bot existente.
  Future<void> updateBot(Bot bot);

  /// Actualiza campos específicos para evitar sobreescritura completa (ej: cambiar solo nombre).
  Future<void> patchBot(String botId, Map<String, dynamic> data);

  /// Elimina un bot permanentemente.
  Future<void> deleteBot(String botId);
}
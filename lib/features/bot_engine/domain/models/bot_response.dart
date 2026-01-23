// Archivo: lib/features/bot_engine/domain/models/bot_response.dart

class BotResponse {
  final String reply;
  final String mood;

  const BotResponse({
    required this.reply,
    required this.mood,
  });

  factory BotResponse.fromJson(Map<String, dynamic> json) {
    return BotResponse(
      reply: json['reply'] ?? "Sin respuesta del núcleo.",
      mood: json['mood'] ?? "neutral",
    );
  }
}
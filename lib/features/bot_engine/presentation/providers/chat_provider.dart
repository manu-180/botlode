// Archivo: lib/features/bot_engine/presentation/providers/chat_provider.dart
import 'package:botslode/features/bot_engine/presentation/providers/chat_repository_provider.dart';
import 'package:botslode/features/bot_engine/presentation/widgets/rive_bot_display.dart'; // Para actualizar el mood global
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

// --- ESTADO DEL CHAT ---
class ChatState {
  final List<Map<String, dynamic>> messages;
  final bool isTyping;
  final String sessionId;

  ChatState({
    required this.messages,
    required this.isTyping,
    required this.sessionId,
  });

  ChatState copyWith({
    List<Map<String, dynamic>>? messages,
    bool? isTyping,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      sessionId: sessionId,
    );
  }
}

// --- NOTIFIER (Lógica de Negocio) ---
class ChatNotifier extends AutoDisposeFamilyNotifier<ChatState, String> {
  late final String _botId;

  @override
  ChatState build(String arg) {
    _botId = arg; // Capturamos el ID del bot
    final sessionId = const Uuid().v4();
    
    // Estado inicial: Sistema listo
    return ChatState(
      sessionId: sessionId,
      isTyping: false,
      messages: [
        {
          'text': "ENLACE NEURAL ESTABLECIDO.\nESPERANDO INSTRUCCIONES...",
          'isUser': false,
          'isSystem': true,
        }
      ],
    );
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 1. Agregar mensaje del usuario (Optimistic UI)
    final userMsg = {'text': text, 'isUser': true};
    
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isTyping: true,
    );

    try {
      // 2. Llamada al Repositorio (Clean Architecture)
      final repository = ref.read(chatRepositoryProvider);
      
      final botResponse = await repository.sendMessage(
        message: text,
        sessionId: state.sessionId,
        botId: _botId,
      );

      // 3. Procesar Respuesta Tipada
      _updateGlobalMood(botResponse.mood);

      // 4. Actualizar estado
      state = state.copyWith(
        isTyping: false,
        messages: [
          ...state.messages,
          {'text': botResponse.reply, 'isUser': false}
        ],
      );

    } catch (e) {
      // 5. Manejo de Errores (Fallback de seguridad)
      final friendlyError = _mapErrorToMessage(e.toString());
      
      state = state.copyWith(
        isTyping: false,
        messages: [
          ...state.messages,
          {'text': friendlyError, 'isUser': false, 'isSystem': true}
        ],
      );
    }
  }

  void _updateGlobalMood(String moodRaw) {
    final mood = moodRaw.toLowerCase();
    int moodIndex = 0;
    
    if (mood.contains('angry')) moodIndex = 1;
    else if (mood.contains('happy') || mood.contains('funny')) moodIndex = 2;
    else if (mood.contains('sales') || mood.contains('offer')) moodIndex = 3;
    else if (mood.contains('confused') || mood.contains('error')) moodIndex = 4;
    else if (mood.contains('tech') || mood.contains('code')) moodIndex = 5;
    else moodIndex = 0; // Neutral por defecto

    // Actualizamos el provider global visual (Rive)
    ref.read(terminalBotMoodProvider.notifier).state = moodIndex;
  }

  String _mapErrorToMessage(String errorStr) {
    if (errorStr.contains('503') || errorStr.contains('502')) {
      return "⚠️ SATURACIÓN DE ENLACE: Tráfico neuronal elevado. Reintente en unos segundos.";
    }
    return "❌ ERROR CRÍTICO: Enlace interrumpido. Protocolo de seguridad activado.";
  }
}

// --- PROVIDER ---
final chatProvider = NotifierProvider.autoDispose.family<ChatNotifier, ChatState, String>(ChatNotifier.new);
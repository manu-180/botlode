// Archivo: lib/features/bot_engine/presentation/providers/chat_provider.dart
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/network/api_client.dart';
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
// Extendemos AutoDisposeFamilyNotifier para soportar parámetros (botId) y limpieza automática
class ChatNotifier extends AutoDisposeFamilyNotifier<ChatState, String> {
  late final String _botId;
  final _apiClient = ApiClient();

  @override
  ChatState build(String arg) {
    _botId = arg; // Capturamos el ID del bot pasado al provider
    final sessionId = const Uuid().v4();
    
    // Estado inicial
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

    // 1. Agregar mensaje del usuario inmediatamente (Optimistic UI)
    final userMsg = {'text': text, 'isUser': true};
    
    // En Riverpod 2.0 actualizamos el estado asignando a 'state'
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isTyping: true,
    );

    try {
      // 2. Llamada a la API
      final response = await _apiClient.sendMessage(
        message: text,
        sessionId: state.sessionId,
        botId: _botId,
      );

      // 3. Procesar Respuesta
      final replyText = response['reply'] ?? "Sin respuesta del núcleo.";
      final moodString = (response['mood'] ?? 'neutral').toString().toLowerCase();

      _updateGlobalMood(moodString);

      // 4. Actualizar estado con la respuesta del bot
      state = state.copyWith(
        isTyping: false,
        messages: [
          ...state.messages,
          {'text': replyText, 'isUser': false}
        ],
      );

    } catch (e) {
      // 5. Manejo de Errores
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

  void _updateGlobalMood(String mood) {
    int moodIndex = 0;
    switch (mood) {
      case 'angry': moodIndex = 1; break;
      case 'happy': moodIndex = 2; break;
      case 'sales': moodIndex = 3; break;
      case 'confused': moodIndex = 4; break;
      case 'tech': moodIndex = 5; break;
      default: moodIndex = 0;
    }
    // Actualizamos el provider global Rive
    ref.read(terminalBotMoodProvider.notifier).state = moodIndex;
  }

  String _mapErrorToMessage(String errorStr) {
    if (errorStr.contains('503') || errorStr.contains('502')) {
      return "⚠️ SATURACIÓN DE ENLACE: Tráfico neuronal elevado. Reintente en unos segundos.";
    }
    return "❌ ERROR CRÍTICO: Enlace interrumpido. Protocolo de seguridad activado.";
  }
}

// --- PROVIDER (CORREGIDO) ---
// Usamos NotifierProvider en lugar de StateNotifierProvider
final chatProvider = NotifierProvider.autoDispose.family<ChatNotifier, ChatState, String>(ChatNotifier.new);
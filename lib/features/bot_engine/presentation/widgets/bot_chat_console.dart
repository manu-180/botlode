// Archivo: lib/features/bot_engine/presentation/widgets/bot_chat_console.dart
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/network/api_client.dart'; 
import 'package:botslode/features/bot_engine/presentation/widgets/rive_bot_display.dart'; 
import 'package:botslode/features/bot_engine/presentation/widgets/status_indicator.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class BotChatConsole extends ConsumerStatefulWidget {
  final String botName;
  final Color botColor;
  final String botId;

  const BotChatConsole({
    super.key, 
    required this.botName, 
    required this.botColor,
    required this.botId,
  });

  @override
  ConsumerState<BotChatConsole> createState() => _BotChatConsoleState();
}

class _BotChatConsoleState extends ConsumerState<BotChatConsole> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // 1. CONTROLADOR DE FOCO
  final FocusNode _focusNode = FocusNode(); 

  final List<Map<String, dynamic>> _messages = [];
  
  bool _isTyping = false;
  late String _sessionId;

  @override
  void initState() {
    super.initState();
    _sessionId = const Uuid().v4();
    _messages.add({
      'text': "ENLACE NEURAL ESTABLECIDO CON UNIDAD ${widget.botName.toUpperCase()}.\nESPERANDO INSTRUCCIONES...",
      'isUser': false,
      'isSystem': true,
    });
    
    // Opcional: Dar foco al entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose(); // Limpieza de memoria
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    
    _controller.clear();
    
    // 2. RECUPERAR EL FOCO INMEDIATAMENTE (Mantiene el cursor activo)
    _focusNode.requestFocus(); 

    setState(() {
      _messages.add({'text': text, 'isUser': true});
      _isTyping = true;
    });
    
    _scrollToBottom();

    try {
      final response = await ApiClient().sendMessage(
        message: text,
        sessionId: _sessionId,
        botId: widget.botId,
      );

      if (mounted) {
        final String newMood = (response['mood'] ?? 'neutral').toString().toLowerCase();
        
        int moodIndex = 0;
        switch (newMood) {
          case 'angry': moodIndex = 1; break;
          case 'happy': moodIndex = 2; break;
          case 'sales': moodIndex = 3; break;
          case 'confused': moodIndex = 4; break;
          case 'tech': moodIndex = 5; break;
          default: moodIndex = 0;
        }

        ref.read(terminalBotMoodProvider.notifier).state = moodIndex;

        setState(() {
          _isTyping = false;
          _messages.add({
            'text': response['reply'] ?? "Sin respuesta del núcleo.",
            'isUser': false,
          });
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTyping = false);
        
        final String errorStr = e.toString();
        String friendlyError;
        
        if (errorStr.contains('503') || errorStr.contains('502')) {
          friendlyError = "⚠️ SATURACIÓN DE ENLACE: Tráfico neuronal elevado en el núcleo central. Por favor, reintente la transmisión en unos segundos.";
        } else {
          friendlyError = "❌ ERROR CRÍTICO DE SISTEMA: Conexión interrumpida ($errorStr).";
        }

        _messages.add({
          'text': friendlyError, 
          'isUser': false, 
          'isSystem': true
        });
        
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGlass),
      ),
      child: Column(
        children: [
          // BARRA SUPERIOR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.borderGlass)),
            ),
            child: Row(
              children: [
                Icon(Icons.terminal_rounded, size: 16, color: themeColor.withValues(alpha: 0.7)),
                const SizedBox(width: 8),
                Text("SESSION ID: ${_sessionId.substring(0, 8)}", 
                  style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5), fontSize: 10, fontFamily: 'Courier')),
                const Spacer(),
                if (_isTyping)
                  SizedBox(
                    width: 12, height: 12, 
                    child: CircularProgressIndicator(strokeWidth: 2, color: themeColor)
                  ),
              ],
            ),
          ),

          // CHAT AREA
          Expanded(
            child: GestureDetector(
              // UX: Si tocas el fondo del chat, también recupera el foco
              onTap: () => _focusNode.requestFocus(),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['isUser'] as bool;
                  final isSystem = msg['isSystem'] ?? false;

                  if (isSystem) {
                    return Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: msg['text'].toString().contains('⚠️') 
                              ? AppColors.secondary.withValues(alpha: 0.1) 
                              : AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: msg['text'].toString().contains('⚠️') 
                                ? AppColors.secondary.withValues(alpha: 0.3)
                                : AppColors.error.withValues(alpha: 0.3),
                          )
                        ),
                        child: Text(
                          msg['text'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: msg['text'].toString().contains('⚠️') 
                                ? AppColors.secondary 
                                : AppColors.error, 
                            fontFamily: 'Courier', 
                            fontSize: 11, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                    );
                  }

                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.5),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isUser 
                            ? themeColor.withValues(alpha: 0.15) 
                            : Colors.transparent, 
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(12),
                          topRight: const Radius.circular(12),
                          bottomLeft: isUser ? const Radius.circular(12) : Radius.zero,
                          bottomRight: isUser ? Radius.zero : const Radius.circular(12),
                        ),
                        border: Border.all(
                          color: isUser 
                              ? themeColor.withValues(alpha: 0.3) 
                              : AppColors.borderGlass,
                        ),
                      ),
                      child: Text(
                        msg['text'],
                        style: TextStyle(
                          color: isUser ? Colors.white : AppColors.textSecondary, 
                          height: 1.4,
                          fontSize: 14
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // INPUT AREA
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(">_", style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontFamily: 'Courier')),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode, // 3. ASIGNACIÓN DEL FOCO
                    style: const TextStyle(color: Colors.white, fontFamily: 'Courier'),
                    cursorColor: themeColor,
                    // submitted -> envía el mensaje
                    onSubmitted: _handleSubmitted,
                    decoration: InputDecoration(
                      hintText: "Ingresar comando...",
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send_rounded, color: themeColor),
                  onPressed: () => _handleSubmitted(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
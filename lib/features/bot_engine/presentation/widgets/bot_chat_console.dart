// Archivo: lib/features/bot_engine/presentation/widgets/bot_chat_console.dart
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/bot_engine/presentation/providers/chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final FocusNode _focusNode = FocusNode(); 

  @override
  void initState() {
    super.initState();
    // Foco automático al iniciar la consola
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleSubmitted() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    
    _controller.clear();
    _focusNode.requestFocus(); // Mantener el flujo de escritura

    // Delegamos la lógica al Provider
    ref.read(chatProvider(widget.botId).notifier).sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos el estado completo del chat específico para este botId
    final chatState = ref.watch(chatProvider(widget.botId));
    final messages = chatState.messages;
    final isTyping = chatState.isTyping;
    
    final themeColor = AppColors.primary;

    // Auto-scroll reactivo: Si la lista de mensajes cambia, bajamos el scroll
    ref.listen(chatProvider(widget.botId), (previous, next) {
      if (next.messages.length > (previous?.messages.length ?? 0)) {
        // Pequeño delay para permitir que el ListView renderice el nuevo ítem
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGlass),
      ),
      child: Column(
        children: [
          // BARRA SUPERIOR (HUD)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.borderGlass)),
            ),
            child: Row(
              children: [
                Icon(Icons.terminal_rounded, size: 16, color: themeColor.withValues(alpha: 0.7)),
                const SizedBox(width: 8),
                Text(
                  "SESSION ID: ${chatState.sessionId.substring(0, 8).toUpperCase()}", 
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.5), 
                    fontSize: 10, 
                    fontFamily: 'Courier'
                  )
                ),
                const SizedBox(width: 8),
                Text(
                   "// TARGET: ${widget.botName.toUpperCase()}",
                   style: TextStyle(
                    color: widget.botColor.withValues(alpha: 0.7), 
                    fontSize: 10, 
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold
                  )
                ),
                const Spacer(),
                if (isTyping)
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
              onTap: () => _focusNode.requestFocus(),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isUser = msg['isUser'] as bool;
                  final isSystem = msg['isSystem'] ?? false;

                  if (isSystem) {
                    return _SystemMessageBubble(text: msg['text']);
                  }

                  return _ChatMessageBubble(
                    text: msg['text'],
                    isUser: isUser,
                    themeColor: themeColor,
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
                    focusNode: _focusNode,
                    style: const TextStyle(color: Colors.white, fontFamily: 'Courier'),
                    cursorColor: themeColor,
                    onSubmitted: (_) => _handleSubmitted(),
                    decoration: InputDecoration(
                      hintText: "Ingresar comando...",
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send_rounded, color: themeColor),
                  onPressed: _handleSubmitted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- COMPONENTES VISUALES PRIVADOS (CLEAN CODE) ---

class _SystemMessageBubble extends StatelessWidget {
  final String text;
  const _SystemMessageBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    final isError = text.contains('⚠️') || text.contains('❌');
    final color = isError ? AppColors.error : AppColors.secondary;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color, 
            fontFamily: 'Courier', 
            fontSize: 11, 
            fontWeight: FontWeight.bold
          ),
        ),
      ),
    );
  }
}

class _ChatMessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final Color themeColor;

  const _ChatMessageBubble({
    required this.text,
    required this.isUser,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
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
          text,
          style: TextStyle(
            color: isUser ? Colors.white : AppColors.textSecondary, 
            height: 1.4,
            fontSize: 14,
            fontFamily: isUser ? null : 'Courier', // Fuente técnica para el bot
          ),
        ),
      ),
    );
  }
}
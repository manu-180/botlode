// Archivo: lib/features/bot_engine/presentation/widgets/chat_message_bubble.dart
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:flutter/material.dart';

class ChatMessageBubble extends StatelessWidget {
  final String text;
  final bool isUser; // true = Usuario, false = Bot
  final Color botColor;

  const ChatMessageBubble({
    super.key,
    required this.text,
    required this.isUser,
    required this.botColor,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: isUser 
              ? AppColors.textSecondary.withOpacity(0.2) // Gris para usuario
              : botColor.withOpacity(0.15), // Color del bot para el bot
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isUser ? 12 : 2), // Borde cuadrado para el "origen"
            bottomRight: Radius.circular(isUser ? 2 : 12),
          ),
          border: Border.all(
            color: isUser 
                ? Colors.transparent 
                : botColor.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label pequeño (Sistema / Operador)
            Text(
              isUser ? "OPERADOR" : "SISTEMA",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isUser ? AppColors.textSecondary : botColor,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            // El mensaje real
            Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                height: 1.4,
                fontFamily: isUser ? null : 'Courier', // Bot usa fuente terminal
              ),
            ),
          ],
        ),
      ),
    );
  }
}
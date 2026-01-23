import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ErrorFeedbackCard extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const ErrorFeedbackCard({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    // Limpiamos el mensaje técnico feo si viene del backend
    final cleanMessage = message.replaceAll('Exception:', '').replaceAll('Error Sync:', '').replaceAll('{', '').replaceAll('}', '').trim();
    
    // Mensaje amigable si es el error conocido
    final displayMessage = cleanMessage.contains("invalid parameters") 
        ? "No se pudo registrar la identidad del cliente. Verifique su conexión."
        : cleanMessage;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        border: Border.all(color: AppColors.error.withOpacity(0.5), width: 1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withOpacity(0.05),
            blurRadius: 15,
            spreadRadius: 2,
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono animado
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.error.withOpacity(0.3)),
            ),
            child: Icon(Icons.gpp_bad_rounded, color: AppColors.error, size: 20)
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.5)),
          ),
          const SizedBox(width: 16),
          
          // Textos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "ERROR DE ENLACE",
                  style: TextStyle(
                    color: AppColors.error,
                    fontFamily: 'Oxanium',
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayMessage,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          
          // Botón cerrar
          IconButton(
            onPressed: onDismiss,
            icon: Icon(Icons.close, color: Colors.white.withOpacity(0.3), size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 20,
          )
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOut);
  }
}
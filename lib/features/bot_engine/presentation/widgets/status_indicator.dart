// Archivo: lib/features/bot_engine/presentation/widgets/status_indicator.dart
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StatusIndicator extends StatelessWidget {
  final bool isLoading;
  final bool isOnline; 
  final int moodIndex; 

  const StatusIndicator({
    super.key,
    required this.isLoading,
    required this.isOnline,
    required this.moodIndex,
  });

  @override
  Widget build(BuildContext context) {
    String text;
    Color color;
    bool isAlert = false;

    // LÓGICA DE PRIORIDAD
    if (!isOnline) {
      text = "SIN CONEXIÓN";
      color = AppColors.error;
      isAlert = true;
    } else if (isLoading) {
      text = "ESCRIBIENDO...";
      color = AppColors.secondary;
    } else {
      switch (moodIndex) {
        case 1: text = "ENOJADO"; color = const Color(0xFFFF2A00); break;
        case 2: text = "FELIZ"; color = const Color(0xFFFF00D6); break;
        case 3: text = "VENDEDOR"; color = const Color(0xFFFFC000); break;
        case 4: text = "CONFUNDIDO"; color = const Color(0xFF7B00FF); break;
        case 5: text = "TÉCNICO"; color = const Color(0xFF00F0FF); break;
        case 0: default: text = "EN LÍNEA"; color = const Color(0xFF00FF94); break;
      }
    }

    // WIDGET REACTOR (Barra de luz)
    final Widget reactorBar = Container(
      width: 4, 
      height: 14,
      decoration: BoxDecoration(
        color: color, 
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(color: color, blurRadius: isAlert ? 8 : 6, spreadRadius: 1), 
          BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 12, spreadRadius: 4),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9), 
        border: Border.all(
          color: color.withValues(alpha: isAlert ? 0.8 : 0.3), 
          width: isAlert ? 1.5 : 1.0
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 4)),
          if (isAlert) 
             BoxShadow(color: AppColors.error.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ANIMACIÓN ESTABILIZADA
          isAlert 
            ? reactorBar.animate(onPlay: (c) => c.repeat(reverse: true))
                .fadeIn(duration: 800.ms, curve: Curves.easeInOut) // Más lento y suave
                .then(delay: 200.ms)
                .fadeOut(duration: 800.ms, curve: Curves.easeInOut)
            : reactorBar.animate(onPlay: (c) => c.repeat()) 
                .fadeIn(duration: 200.ms, curve: Curves.easeOut) 
                .then(delay: 1000.ms)        
                .fadeOut(duration: 800.ms, curve: Curves.easeIn) 
                .then(delay: 200.ms),

          const SizedBox(width: 10),

          Text(
            text,
            style: TextStyle(
              color: color,
              fontFamily: 'Courier', 
              fontWeight: FontWeight.w900, 
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
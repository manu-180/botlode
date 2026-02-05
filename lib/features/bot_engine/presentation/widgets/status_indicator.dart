// Archivo: lib/features/bot_engine/presentation/widgets/status_indicator.dart
// Diseño replicado del StatusIndicator de botlode_player (chat_panel_view).
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StatusIndicator extends StatelessWidget {
  final bool isLoading;
  final bool isOnline;
  final int moodIndex;
  final bool isDarkMode;

  const StatusIndicator({
    super.key,
    required this.isLoading,
    required this.isOnline,
    required this.moodIndex,
    this.isDarkMode = true,
  });

  @override
  Widget build(BuildContext context) {
    String text;
    Color color;

    if (!isOnline) {
      text = "SIN CONEXIÓN";
      color = AppColors.error;
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
        case 0:
        default: text = "EN LÍNEA"; color = const Color(0xFF00FF94); break;
      }
    }

    // --- DISEÑO IDÉNTICO AL PLAYER (Industrial Light/Dark) ---
    final Color bgColor = isDarkMode
        ? const Color(0xFF0A0A0A).withOpacity(0.95)
        : const Color(0xFFFFFFFF).withOpacity(0.95);

    final Color textColor = isDarkMode
        ? Colors.white.withOpacity(0.9)
        : const Color(0xFF2D2D2D);

    final Color borderColor = isDarkMode
        ? Colors.white.withOpacity(0.1)
        : Colors.black.withOpacity(0.1);

    // WIDGET DEL REACTOR (barra de luz, mismo estilo que en el player)
    final Widget reactorBar = Container(
      width: 4,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
        boxShadow: isDarkMode
            ? [
                BoxShadow(color: color, blurRadius: 4, spreadRadius: 1),
                BoxShadow(color: color.withOpacity(0.6), blurRadius: 12, spreadRadius: 3),
              ]
            : [
                BoxShadow(color: color.withOpacity(0.6), blurRadius: 2, spreadRadius: 0),
              ],
      ),
    );

    return Container(
      padding: const EdgeInsets.only(left: 6, right: 12, top: 6, bottom: 6),
      decoration: ShapeDecoration(
        color: bgColor,
        shape: BeveledRectangleBorder(
          side: BorderSide(color: borderColor, width: 1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(0),
            bottomRight: Radius.circular(10),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(4),
          ),
        ),
        shadows: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.6 : 0.1),
            blurRadius: 10,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          reactorBar
              .animate(onPlay: (c) => c.repeat())
              .fadeIn(duration: 200.ms, curve: Curves.easeOut)
              .then(delay: isOnline ? 1300.ms : 200.ms)
              .fadeOut(duration: 800.ms, curve: Curves.easeIn)
              .then(delay: 150.ms),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontFamily: 'Courier',
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

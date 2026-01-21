// Archivo: lib/core/ui/widgets/custom_title_bar.dart
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class CustomTitleBar extends StatelessWidget {
  const CustomTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40, // Altura estándar compacta
      color: AppColors.background, // Mismo color de fondo para continuidad
      child: Row(
        children: [
          // 1. ÁREA DE ARRASTRE (DRAG AREA)
          // Ocupa todo el espacio izquierdo excepto los botones
          Expanded(
            child: DragToMoveArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    // Icono de la App (Pequeño logo)
                    Icon(Icons.hexagon_rounded, color: AppColors.primary, size: 16),
                    const SizedBox(width: 8),
                    // Título de la App
                    Text(
                      "BOTSLODE // FACTORY TERMINAL v1.0",
                      style: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.5),
                        fontSize: 12,
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. BOTONES DE VENTANA (MIN/MAX/CLOSE)
          // Los hacemos custom para que encajen con el tema
          _WindowButton(
            icon: Icons.remove,
            onTap: () => windowManager.minimize(),
          ),
          _WindowButton(
            icon: Icons.crop_square,
            onTap: () async {
              if (await windowManager.isMaximized()) {
                windowManager.restore();
              } else {
                windowManager.maximize();
              }
            },
          ),
          _WindowButton(
            icon: Icons.close,
            isClose: true, // Rojo al hacer hover
            onTap: () => windowManager.close(),
          ),
        ],
      ),
    );
  }
}

// Botón auxiliar individual
class _WindowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isClose;

  const _WindowButton({
    required this.icon,
    required this.onTap,
    this.isClose = false,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Definimos colores según el estado
    final hoverColor = widget.isClose ? AppColors.error : Colors.white.withOpacity(0.1);
    final iconColor = _isHovered && widget.isClose 
        ? Colors.white 
        : AppColors.textSecondary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 46, // Ancho estándar de botón de ventana
          height: double.infinity,
          color: _isHovered ? hoverColor : Colors.transparent,
          child: Icon(
            widget.icon,
            size: 16,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}
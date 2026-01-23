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
      color: AppColors.background, // Mismo color de fondo para continuidad (0xFF050505)
      child: Row(
        children: [
          // 1. ÁREA DE ARRASTRE (DRAG AREA)
          Expanded(
            child: DragToMoveArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                // CAMBIO: Eliminado el icono, solo texto técnico
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: 'Oxanium', // Fuente Sci-Fi principal
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                    children: [
                      TextSpan(
                        text: "BOTSLODE",
                        style: TextStyle(color: AppColors.primary), // Amarillo/Dorado
                      ),
                      TextSpan(
                        text: " // FACTORY TERMINAL v1.0",
                        style: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.5),
                          fontFamily: 'Courier', // Monospaced para la versión
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. BOTONES DE VENTANA (MIN/MAX/CLOSE)
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

// Botón auxiliar individual (Sin cambios lógicos, solo visuales)
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
          width: 46, // Ancho estándar Windows
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
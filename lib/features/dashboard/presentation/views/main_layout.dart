// Archivo: lib/features/dashboard/presentation/views/main_layout.dart
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/providers/connectivity_provider.dart';
import 'package:botslode/features/dashboard/presentation/widgets/sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';

class MainLayout extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const MainLayout({super.key, required this.navigationShell});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  // Estado local para evitar spam de notificaciones
  bool _wasOffline = false;

  @override
  Widget build(BuildContext context) {
    // ESCUCHA ACTIVA DE RED
    ref.listen(connectivityProvider, (prev, next) {
      next.whenData((isOnline) {
        if (!isOnline && !_wasOffline) {
          _showTacticalSnackbar(context, "CONEXIÓN PERDIDA: MODO OFFLINE ACTIVADO", isError: true);
          _wasOffline = true;
        } else if (isOnline && _wasOffline) {
          _showTacticalSnackbar(context, "ENLACE RESTABLECIDO: SISTEMAS ONLINE", isError: false);
          _wasOffline = false;
        }
      });
    });

    return Scaffold(
      body: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: Column(
              children: [
                _CustomTitleBar(),
                Expanded(child: widget.navigationShell),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SNACKBAR TÁCTICO ---
  void _showTacticalSnackbar(BuildContext context, String message, {required bool isError}) {
    final color = isError ? AppColors.error : AppColors.success;
    final icon = isError ? Icons.wifi_off_rounded : Icons.wifi_rounded;

    ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Limpiar cola
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: isError ? const Duration(days: 1) : const Duration(seconds: 4), // El error es persistente
        content: Center( // Centrado para efecto HUD
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.9),
              border: Border.all(color: color, width: 2),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 2),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 16),
                Text(
                  message,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier',
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomTitleBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 32,
        color: Colors.transparent, 
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // SE ELIMINÓ EL ÍCONO Y EL SIZEDBOX DE AQUÍ
            Text(
              "BOTSLODE // FACTORY TERMINAL v1.0",
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.5),
                fontSize: 10,
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(),
            // --- BOTONES DE VENTANA ---
             Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 14, color: Colors.white), 
                  onPressed: windowManager.minimize, 
                  padding: EdgeInsets.zero
                ),
                IconButton(
                  icon: const Icon(Icons.check_box_outline_blank, size: 14, color: Colors.white), 
                  onPressed: () async {
                    if (await windowManager.isMaximized()) {
                      windowManager.unmaximize();
                    } else {
                      windowManager.maximize();
                    }
                  }, 
                  padding: EdgeInsets.zero
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 14, color: Colors.white), 
                  onPressed: windowManager.close, 
                  padding: EdgeInsets.zero
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
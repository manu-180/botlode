// Archivo: lib/features/settings/presentation/views/settings_view.dart
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/providers/auth_provider.dart';
import 'package:botslode/features/settings/presentation/widgets/change_password_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsView extends ConsumerWidget {
  static const String routeName = 'settings';

  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // FONDO RADIAL INMERSIVO
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, 0.0),
                  radius: 1.2,
                  colors: [
                    AppColors.surface.withOpacity(0.6),
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),

          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- ICONO DE SEGURIDAD ANIMADO ---
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                      border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.1),
                          blurRadius: 50,
                          spreadRadius: 10,
                        )
                      ]
                    ),
                    child: Center(
                      child: Icon(Icons.shield_outlined, size: 50, color: AppColors.primary)
                          .animate(onPlay: (c) => c.repeat())
                          .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.5)),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // --- TÍTULOS ---
                  Text(
                    "PROTOCOLO DE SEGURIDAD",
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontFamily: 'Oxanium',
                      fontSize: 24,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Gestión de credenciales y acceso al sistema central.",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 60),

                  // --- BOTÓN 1: CAMBIAR CONTRASEÑA ---
                  _SecurityActionButton(
                    label: "ACTUALIZAR CONTRASEÑA",
                    subLabel: "Modificar clave de acceso del operador",
                    icon: Icons.password_rounded,
                    color: AppColors.primary,
                    onTap: () {
                      showDialog(
                        context: context, 
                        builder: (_) => const ChangePasswordDialog()
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // --- BOTÓN 2: CERRAR SESIÓN ---
                  _SecurityActionButton(
                    label: "CERRAR SESIÓN",
                    subLabel: "Desconectar y salir",
                    icon: Icons.power_settings_new_rounded,
                    color: AppColors.error,
                    isDestructive: true,
                    onTap: () async {
                      // Ejecutamos logout
                      await ref.read(authProvider.notifier).signOut();
                      // Redirección forzada por seguridad (aunque el router debería hacerlo solo)
                      if (context.mounted) GoRouter.of(context).go('/login');
                    },
                  ),

                  const SizedBox(height: 40),
                  
                  // FOOTER
                  Text(
                    "SECURE CONNECTION // ENCRYPTED",
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.3),
                      fontFamily: 'Courier',
                      fontSize: 10,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityActionButton extends StatefulWidget {
  final String label;
  final String subLabel;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SecurityActionButton({
    required this.label,
    required this.subLabel,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  State<_SecurityActionButton> createState() => _SecurityActionButtonState();
}

class _SecurityActionButtonState extends State<_SecurityActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.color;

    return Focus(
      onKeyEvent: (_, KeyEvent event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: widget.isDestructive 
                ? (_isHovered ? baseColor.withOpacity(0.15) : Colors.transparent)
                : (_isHovered ? baseColor.withOpacity(0.1) : Colors.black.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered ? baseColor : AppColors.borderGlass,
              width: 1.5,
            ),
            boxShadow: _isHovered 
                ? [BoxShadow(color: baseColor.withOpacity(0.1), blurRadius: 20)] 
                : [],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: baseColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: baseColor, size: 24),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: _isHovered ? Colors.white : AppColors.textPrimary,
                        fontFamily: 'Oxanium',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subLabel,
                      style: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded, 
                color: baseColor.withOpacity(_isHovered ? 1.0 : 0.3), 
                size: 16
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
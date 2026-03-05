// Archivo: lib/features/hunter_bot/presentation/widgets/bot_control_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/hunter_bot/presentation/providers/hunter_provider.dart';

/// Botón épico para prender/apagar el HunterBot
/// 
/// Funcionalidad:
/// - Prende o apaga el bot de búsqueda de dominios
/// - Animación WOW con pulsing
/// - Cambia de color según el estado
class BotControlButton extends ConsumerStatefulWidget {
  const BotControlButton({super.key});

  @override
  ConsumerState<BotControlButton> createState() => _BotControlButtonState();
}

class _BotControlButtonState extends ConsumerState<BotControlButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleBot() async {
    if (_isToggling) return;
    
    setState(() => _isToggling = true);
    
    try {
      final notifier = ref.read(hunterProvider.notifier);
      final currentState = ref.read(hunterProvider);
      
      // Toggle bot_enabled
      await notifier.updateBotEnabled(!currentState.botEnabled);
      
      if (!mounted) return;
      
      // Mostrar SnackBar con feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentState.botEnabled 
                ? '⏸️  Bot detenido' 
                : '🚀 Bot activado - buscando dominios...',
            style: const TextStyle(
              fontFamily: 'Oxanium',
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: currentState.botEnabled 
              ? AppColors.error.withOpacity(0.9)
              : AppColors.success.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isToggling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hunterState = ref.watch(hunterProvider);
    final isEnabled = hunterState.botEnabled;
    final isConfigured = hunterState.isConfigured;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return InkWell(
          onTap: isConfigured && !_isToggling ? _toggleBot : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isEnabled
                    ? [
                        AppColors.success.withOpacity(0.2),
                        AppColors.success.withOpacity(0.05),
                      ]
                    : [
                        AppColors.textSecondary.withOpacity(0.1),
                        AppColors.glassSurface,
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isEnabled
                    ? AppColors.success.withOpacity(_glowAnimation.value)
                    : AppColors.borderGlass,
                width: isEnabled ? 2 : 1,
              ),
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color: AppColors.success.withOpacity(_glowAnimation.value * 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                // Contenido principal
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Icono animado
                      Transform.scale(
                        scale: isEnabled ? _scaleAnimation.value : 1.0,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isEnabled
                                ? AppColors.success.withOpacity(0.15)
                                : AppColors.glassSurface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isEnabled
                                  ? AppColors.success.withOpacity(0.4)
                                  : AppColors.borderGlass,
                              width: 2,
                            ),
                          ),
                          child: FaIcon(
                            FontAwesomeIcons.crosshairs,
                            color: isEnabled 
                                ? AppColors.success 
                                : AppColors.textSecondary,
                            size: 32,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 20),
                      
                      // Texto
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isEnabled ? 'HUNTER BOT ACTIVO' : 'HUNTER BOT DETENIDO',
                              style: TextStyle(
                                color: isEnabled 
                                    ? AppColors.success 
                                    : AppColors.textSecondary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Oxanium',
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isEnabled
                                  ? 'Buscando dominios automáticamente...'
                                  : isConfigured
                                      ? 'Toca para activar la búsqueda automática'
                                      : 'Configura Resend primero',
                              style: TextStyle(
                                color: isConfigured 
                                    ? AppColors.textSecondary 
                                    : AppColors.warning,
                                fontSize: 12,
                                fontFamily: 'Oxanium',
                              ),
                            ),
                            if (isEnabled) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: AppColors.success,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.success.withOpacity(0.6),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Rotación automática (50+ nichos)',
                                    style: const TextStyle(
                                      color: AppColors.success,
                                      fontSize: 11,
                                      fontFamily: 'Oxanium',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Badge de estado (solo si no está configurado)
                if (!isConfigured)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.warning.withOpacity(0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber, color: AppColors.warning, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'SIN CONFIG',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Oxanium',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Loading overlay
                if (_isToggling)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.background.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.success,
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

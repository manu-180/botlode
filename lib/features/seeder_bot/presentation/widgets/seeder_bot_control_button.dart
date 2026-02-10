import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/seeder_bot/presentation/providers/seeder_provider.dart';

/// Botón para activar/pausar el Seeder Bot (mismo estilo que Hunter).
class SeederBotControlButton extends ConsumerStatefulWidget {
  const SeederBotControlButton({super.key});

  @override
  ConsumerState<SeederBotControlButton> createState() => _SeederBotControlButtonState();
}

class _SeederBotControlButtonState extends ConsumerState<SeederBotControlButton>
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
      final notifier = ref.read(seederProvider.notifier);
      final currentState = ref.read(seederProvider);
      await notifier.updateBotEnabled(!currentState.botEnabled);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentState.botEnabled
                ? 'Seeder Bot pausado'
                : 'Seeder Bot activado - llenando formularios...',
            style: const TextStyle(fontFamily: 'Oxanium', fontWeight: FontWeight.bold),
          ),
          backgroundColor: currentState.botEnabled
              ? AppColors.error.withOpacity(0.9)
              : AppColors.success.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _isToggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final seederState = ref.watch(seederProvider);
    final isEnabled = seederState.botEnabled;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return InkWell(
          onTap: !_isToggling ? _toggleBot : null,
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
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
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
                            isEnabled ? FontAwesomeIcons.seedling : FontAwesomeIcons.powerOff,
                            color: isEnabled ? AppColors.success : AppColors.textSecondary,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isEnabled ? 'BOT ACTIVO' : 'BOT DETENIDO',
                              style: TextStyle(
                                color: isEnabled ? AppColors.success : AppColors.textSecondary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Oxanium',
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isEnabled
                                  ? 'Llenando formularios en directorios...'
                                  : 'Toca para activar el envío a directorios',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontFamily: 'Oxanium',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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

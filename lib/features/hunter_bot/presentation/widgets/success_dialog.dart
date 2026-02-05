// Archivo: lib/features/hunter_bot/presentation/widgets/success_dialog.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:botslode/core/config/theme/app_colors.dart';

/// Diálogo épico de éxito con efectos visuales
class SuccessDialog extends StatefulWidget {
  final String title;
  final String message;
  final String? subtitle;
  final VoidCallback? onDismiss;

  const SuccessDialog({
    super.key,
    required this.title,
    required this.message,
    this.subtitle,
    this.onDismiss,
  });

  /// Muestra el diálogo con animación
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String? subtitle,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Success Dialog',
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return SuccessDialog(
          title: title,
          message: message,
          subtitle: subtitle,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<SuccessDialog> with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    
    // Controlador para partículas
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    
    // Controlador para pulso
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    // Controlador para rotación
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    
    // Generar partículas
    for (int i = 0; i < 30; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 4 + 2,
        speed: _random.nextDouble() * 0.5 + 0.2,
        opacity: _random.nextDouble() * 0.5 + 0.3,
      ));
    }
  }

  @override
  void dispose() {
    _particleController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 400,
        margin: const EdgeInsets.all(32),
        child: Material(
          color: Colors.transparent,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Fondo con partículas
              _buildParticleBackground(),
              
              // Contenido principal
              _buildMainContent(),
              
              // Icono flotante superior
              _buildFloatingIcon(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParticleBackground() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          return CustomPaint(
            painter: _ParticlePainter(
              particles: _particles,
              progress: _particleController.value,
              color: AppColors.success,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.surface.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.success.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withOpacity(0.2),
            blurRadius: 40,
            spreadRadius: 10,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Espacio para el icono flotante
          const SizedBox(height: 50),
          
          // Contenido
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 20, 32, 32),
            child: Column(
              children: [
                // Título
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Oxanium',
                    letterSpacing: 2,
                  ),
                ).animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms)
                  .slideY(begin: 0.2, end: 0),
                
                const SizedBox(height: 16),
                
                // Mensaje principal
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary.withOpacity(0.9),
                    fontSize: 16,
                    fontFamily: 'Oxanium',
                    height: 1.5,
                  ),
                ).animate()
                  .fadeIn(delay: 400.ms, duration: 400.ms)
                  .slideY(begin: 0.2, end: 0),
                
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    widget.subtitle!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.7),
                      fontSize: 13,
                      fontFamily: 'Oxanium',
                    ),
                  ).animate()
                    .fadeIn(delay: 500.ms, duration: 400.ms),
                ],
                
                const SizedBox(height: 28),
                
                // Barra de progreso animada
                _buildProgressBar(),
                
                const SizedBox(height: 28),
                
                // Botón de cerrar
                _buildCloseButton(),
              ],
            ),
          ),
        ],
      ),
    ).animate()
      .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 400.ms, curve: Curves.easeOutBack);
  }

  Widget _buildFloatingIcon() {
    return Positioned(
      top: -35,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = 1.0 + (_pulseController.value * 0.1);
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.success,
                  Color(0xFF00C853),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Anillo giratorio
                AnimatedBuilder(
                  animation: _rotateController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotateController.value * 2 * pi,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Icono central
                const Center(
                  child: FaIcon(
                    FontAwesomeIcons.check,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ).animate()
            .scale(delay: 100.ms, duration: 500.ms, curve: Curves.elasticOut),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Barra de progreso animada
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.success,
                      Color(0xFF00E676),
                      AppColors.success,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withOpacity(0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ).animate()
                .scaleX(
                  begin: 0,
                  end: 1,
                  alignment: Alignment.centerLeft,
                  delay: 600.ms,
                  duration: 800.ms,
                  curve: Curves.easeOutCubic,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCloseButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop();
          widget.onDismiss?.call();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(FontAwesomeIcons.crosshairs, size: 16),
            const SizedBox(width: 10),
            const Text(
              'EMPEZAR A CAZAR',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Oxanium',
                letterSpacing: 1.5,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ).animate()
        .fadeIn(delay: 800.ms, duration: 400.ms)
        .slideY(begin: 0.3, end: 0),
    );
  }
}

/// Clase para representar una partícula
class _Particle {
  double x;
  double y;
  final double size;
  final double speed;
  final double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

/// Painter para dibujar las partículas
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color color;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      // Actualizar posición (movimiento hacia arriba)
      final y = (particle.y - (progress * particle.speed)) % 1.0;
      
      final paint = Paint()
        ..color = color.withOpacity(particle.opacity * (1 - y))
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(particle.x * size.width, y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}

/// Extensión para facilitar el uso
extension SuccessDialogExtension on BuildContext {
  Future<void> showSuccessDialog({
    required String title,
    required String message,
    String? subtitle,
  }) {
    return SuccessDialog.show(
      this,
      title: title,
      message: message,
      subtitle: subtitle,
    );
  }
}

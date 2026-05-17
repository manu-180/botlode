// lib/core/ui/decorations/glow_box.dart
// GlowBox: wrapper que añade glow configurable a su hijo.
// Usar para elementos con emisión activa (botón primario, card activa, etc.)
import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';

class GlowBox extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final double blurRadius;
  final double spreadRadius;
  final BorderRadius? borderRadius;

  const GlowBox({
    super.key,
    required this.child,
    this.glowColor = AppColors.goldGlow,
    this.blurRadius = 24,
    this.spreadRadius = 1,
    this.borderRadius,
  });

  /// Glow dorado estándar.
  const GlowBox.gold({
    super.key,
    required this.child,
    this.borderRadius,
  })  : glowColor = AppColors.goldGlow,
        blurRadius = 24,
        spreadRadius = 1;

  /// Glow cyan estándar.
  const GlowBox.cyan({
    super.key,
    required this.child,
    this.borderRadius,
  })  : glowColor = AppColors.cyanGlow,
        blurRadius = 20,
        spreadRadius = 0;

  /// Glow de estado genérico.
  factory GlowBox.status({
    Key? key,
    required Widget child,
    required Color color,
    BorderRadius? borderRadius,
  }) =>
      GlowBox(
        key: key,
        glowColor: AppColors.glowStatus(color),
        blurRadius: 18,
        spreadRadius: 0,
        borderRadius: borderRadius,
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: glowColor,
            blurRadius: blurRadius,
            spreadRadius: spreadRadius,
          ),
        ],
      ),
      child: child,
    );
  }
}

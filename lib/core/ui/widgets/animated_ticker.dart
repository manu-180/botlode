// Archivo: lib/core/ui/widgets/animated_ticker.dart
import 'package:flutter/material.dart';

class AnimatedTicker extends StatelessWidget {
  final double value;
  final String prefix;
  final String suffix;
  final TextStyle? style;
  final int decimals;

  const AnimatedTicker({
    super.key,
    required this.value,
    this.prefix = '',
    this.suffix = '',
    this.style,
    this.decimals = 2,
  });

  @override
  Widget build(BuildContext context) {
    // TweenAnimationBuilder es la clave para animar valores numéricos sin controladores complejos
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: const Duration(seconds: 2),
      curve: Curves.easeOutExpo, // Efecto de frenado suave al final
      builder: (context, animatedValue, child) {
        return Text(
          '$prefix${animatedValue.toStringAsFixed(decimals)}$suffix',
          style: style,
        );
      },
    );
  }
}
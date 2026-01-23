// Archivo: lib/core/ui/widgets/skeleton_base.dart
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SkeletonBase extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxShape shape;
  final EdgeInsetsGeometry? margin;

  const SkeletonBase({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.shape = BoxShape.rectangle,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        // Color base oscuro (fondo de la placa)
        color: AppColors.surface.withOpacity(0.5),
        shape: shape,
        borderRadius: shape == BoxShape.rectangle 
            ? BorderRadius.circular(borderRadius) 
            : null,
        border: Border.all(
          color: Colors.white.withOpacity(0.05), // Borde sutil técnico
        ),
      ),
    )
    .animate(onPlay: (controller) => controller.repeat())
    .shimmer(
      duration: 1500.ms, 
      color: Colors.white.withOpacity(0.05), // Brillo de paso
      angle: 0.25, // Ángulo diagonal sci-fi
    );
  }
}
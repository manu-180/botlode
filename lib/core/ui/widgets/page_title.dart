// Archivo: lib/core/ui/widgets/page_title.dart
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum PageTitleStyle {
  minimal,      // Opción 1: Borde inferior
  techBar,      // Opción 2: Barra lateral
  elegant,      // Opción 3: Con punto indicador
}

class PageTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color? accentColor;
  final PageTitleStyle style;

  const PageTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.accentColor,
    this.style = PageTitleStyle.minimal, // Por defecto: minimalista
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;

    switch (style) {
      case PageTitleStyle.minimal:
        return _buildMinimalStyle(color);
      case PageTitleStyle.techBar:
        return _buildTechBarStyle(color);
      case PageTitleStyle.elegant:
        return _buildElegantStyle(color);
    }
  }

  // OPCIÓN 1: MINIMALISTA CON BORDE INFERIOR
  Widget _buildMinimalStyle(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            fontFamily: 'Oxanium',
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 60,
          height: 3,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.3)],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ).animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 3000.ms, color: Colors.white.withOpacity(0.3)),
        
        if (subtitle != null) ...[
          const SizedBox(height: 12),
          Text(
            subtitle!,
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.7),
              fontSize: 13,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ],
    );
  }

  // OPCIÓN 2: TECH CON BARRA LATERAL
  Widget _buildTechBarStyle(Color color) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.3)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ).animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 3000.ms, color: Colors.white.withOpacity(0.4)),
          
          const SizedBox(width: 16),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  fontFamily: 'Oxanium',
                  height: 1.2,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // OPCIÓN 3: ELEGANTE CON PUNTO INDICADOR
  Widget _buildElegantStyle(Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: 2,
              )
            ],
          ),
        ).animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 2500.ms, color: Colors.white.withOpacity(0.6)),
        
        const SizedBox(width: 20),
        
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                fontFamily: 'Oxanium',
                height: 1.2,
                shadows: [
                  Shadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// lib/core/ui/hud/hud_id_tag.dart
// Etiqueta mono pequeña tipo «UNIT-04F» para esquinas de cards.
import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_text_styles.dart';

class HudIdTag extends StatelessWidget {
  final String id;
  final Color color;

  const HudIdTag({
    super.key,
    required this.id,
    this.color = AppColors.textTertiary,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      id.toUpperCase(),
      style: AppTextStyles.mono.copyWith(
        color: color,
        fontSize: 10,
        letterSpacing: 1.2,
      ),
    );
  }
}

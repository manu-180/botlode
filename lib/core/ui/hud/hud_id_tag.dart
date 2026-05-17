// lib/core/ui/hud/hud_id_tag.dart
// Etiqueta mono pequeña tipo «UNIT-04F» para esquinas de cards.
// Fondo surfaceHud semitransparente, borde borderSubtle, radio radiusXS.
import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_dimens.dart';
import '../../config/theme/app_text_styles.dart';

class HudIdTag extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const HudIdTag({
    super.key,
    required this.text,
    this.color = AppColors.textTertiary,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space8,
        vertical: AppDimens.space4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceHud.withValues(alpha: 0.6),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
        borderRadius: BorderRadius.circular(AppDimens.radiusXS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppDimens.iconXS, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text.toUpperCase(),
            style: AppTextStyles.mono.copyWith(
              color: color,
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

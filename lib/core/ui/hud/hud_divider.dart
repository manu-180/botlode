// lib/core/ui/hud/hud_divider.dart
// Divisor técnico hairline con nodo brillante y etiqueta mono opcional.
import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_dimens.dart';
import '../../config/theme/app_text_styles.dart';

class HudDivider extends StatelessWidget {
  final String? label;
  final Color lineColor;
  final Color nodeColor;

  const HudDivider({
    super.key,
    this.label,
    this.lineColor = AppColors.borderDefault,
    this.nodeColor = AppColors.cyan,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(height: 1, color: lineColor),
        ),
        if (label != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.space12),
            child: Text(
              '// ${label!.toUpperCase()}',
              style: AppTextStyles.mono.copyWith(
                color: AppColors.textTertiary,
                letterSpacing: 1.6,
              ),
            ),
          ),
          Expanded(
            child: Container(height: 1, color: lineColor),
          ),
        ] else ...[
          Container(
            width: AppDimens.space8,
            height: AppDimens.space8,
            margin: const EdgeInsets.symmetric(horizontal: AppDimens.space8),
            decoration: BoxDecoration(
              color: nodeColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Container(height: 1, color: lineColor),
          ),
        ],
      ],
    );
  }
}

// Archivo: lib/features/settings/presentation/widgets/about_botslode_dialog.dart
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/hud/hud_corner_brackets.dart';
import 'package:botslode/core/ui/hud/hud_divider.dart';
import 'package:botslode/core/ui/panels/holo_panel.dart';
import 'package:botslode/core/ui/widgets/app_button.dart';
import 'package:flutter/material.dart';

class AboutBotslodeDialog extends StatelessWidget {
  const AboutBotslodeDialog({super.key});

  static const String _version = 'v1.0.5 - STABLE_CORE';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: HudCornerBrackets(
          color: AppColors.borderGold,
          child: HoloPanel(
            padding: const EdgeInsets.all(AppDimens.space32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context),
                const SizedBox(height: AppDimens.space16),
                const HudDivider(),
                const SizedBox(height: AppDimens.space16),
                _buildDataBlock(),
                const SizedBox(height: AppDimens.space16),
                _buildCredits(),
                const SizedBox(height: AppDimens.space24),
                AppButton.ghost(
                  label: 'Cerrar',
                  onPressed: () => Navigator.of(context).pop(),
                  expand: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceHud,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.borderGold,
                  width: 1.5,
                ),
                boxShadow: AppDimens.glowGold,
              ),
              child: const Center(
                child: Icon(
                  Icons.precision_manufacturing_rounded,
                  size: 22,
                  color: AppColors.gold,
                ),
              ),
            ),
            const SizedBox(width: AppDimens.space12),
            Text(
              'BOTLODE FACTORY\nTERMINAL',
              style: AppTextStyles.titleL.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        Semantics(
          label: 'Cerrar',
          child: IconButton(
            icon: const Icon(
              Icons.close_rounded,
              size: 20,
              color: AppColors.textSecondary,
            ),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Cerrar',
          ),
        ),
      ],
    );
  }

  Widget _buildDataBlock() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: AppColors.surfaceHud,
        borderRadius: AppDimens.brS,
        border: Border.all(
          color: AppColors.borderDefault,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _hudRow('VERSIÓN', _version),
          const SizedBox(height: AppDimens.space8),
          _hudRow('MOTOR', 'Flutter Desktop'),
          const SizedBox(height: AppDimens.space8),
          _hudRow('PLATAFORMA', 'Windows'),
        ],
      ),
    );
  }

  Widget _hudRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.mono.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.hudReadout.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCredits() {
    return Column(
      children: [
        Text(
          'Panel de administración y control para bots conversacionales.',
          style: AppTextStyles.bodyS.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimens.space8),
        Text(
          '© 2024–2025 BotLode. Todos los derechos reservados.',
          style: AppTextStyles.mono.copyWith(
            color: AppColors.textTertiary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimens.space4),
        Text(
          '// HANGAR OS',
          style: AppTextStyles.mono.copyWith(
            color: AppColors.textTertiary,
            letterSpacing: 2.0,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

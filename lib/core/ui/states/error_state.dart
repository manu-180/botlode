// lib/core/ui/states/error_state.dart
// Estado de error unificado: banner inline y pantalla completa.
import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_dimens.dart';
import '../../config/theme/app_icons.dart';
import '../../config/theme/app_text_styles.dart';
import '../buttons/app_button.dart';

/// Error card inline (dentro de un panel o sección).
class ErrorCard extends StatelessWidget {
  final String title;
  final String? message;
  final String? retryLabel;
  final VoidCallback? onRetry;

  const ErrorCard({
    super.key,
    required this.title,
    this.message,
    this.retryLabel,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppDimens.space16),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.08),
          borderRadius: AppDimens.brM,
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcons.icon(AppIcons.error, size: AppDimens.iconL, color: AppColors.danger),
            const SizedBox(width: AppDimens.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyM.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      message!,
                      style: AppTextStyles.bodyS.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onRetry != null && retryLabel != null) ...[
              const SizedBox(width: AppDimens.space12),
              AppButton.ghost(
                label: retryLabel!,
                onPressed: onRetry,
                size: AppButtonSize.sm,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error de pantalla completa con ícono y acción.
class ErrorScreen extends StatelessWidget {
  final String title;
  final String? message;
  final String? retryLabel;
  final VoidCallback? onRetry;

  const ErrorScreen({
    super.key,
    required this.title,
    this.message,
    this.retryLabel,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.space48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: AppDimens.brL,
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.3),
                ),
              ),
              child: AppIcons.icon(AppIcons.error, size: AppDimens.iconL, color: AppColors.danger),
            ),
            const SizedBox(height: AppDimens.space24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleM.copyWith(color: AppColors.textPrimary),
            ),
            if (message != null) ...[
              const SizedBox(height: AppDimens.space8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary),
              ),
            ],
            if (onRetry != null && retryLabel != null) ...[
              const SizedBox(height: AppDimens.space32),
              AppButton.secondary(
                label: retryLabel!,
                onPressed: onRetry,
                leadingIcon: AppIcons.refresh,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

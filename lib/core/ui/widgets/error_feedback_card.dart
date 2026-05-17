// Archivo: lib/core/ui/widgets/error_feedback_card.dart
// Estado de error global «Hangar OS»: panel con borde danger, anillo con dangerGlow,
// mensaje descriptivo y acción de recuperación obligatoria.
// Sanitización del mensaje del backend se hace FUERA de este widget, antes de pasarlo.
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_dimens.dart';
import '../../config/theme/app_motion.dart';
import '../../config/theme/app_text_styles.dart';
import '../hud/hud_grid_texture.dart';
import 'app_button.dart';
import 'app_icon_button.dart';

enum ErrorVariant { inline, fullScreen }

class ErrorFeedbackCard extends StatefulWidget {
  const ErrorFeedbackCard({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
    this.retryLabel = 'REINTENTAR',
    this.onDismiss,
    this.variant = ErrorVariant.inline,
  });

  final String title;

  /// Causa + cómo resolver. Sanitizar el texto del backend antes de pasarlo.
  final String message;

  /// Acción de recuperación obligatoria. El botón entra en loading mientras corre.
  final Future<void> Function() onRetry;

  final String retryLabel;

  /// inline: muestra X para cerrar. fullScreen: muestra botón «VOLVER».
  final VoidCallback? onDismiss;

  final ErrorVariant variant;

  @override
  State<ErrorFeedbackCard> createState() => _ErrorFeedbackCardState();
}

class _ErrorFeedbackCardState extends State<ErrorFeedbackCard> {
  bool _retrying = false;

  Future<void> _handleRetry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      await widget.onRetry();
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduced(context);

    final content = Semantics(
      liveRegion: true,
      child: widget.variant == ErrorVariant.inline
          ? _buildInline()
          : _buildFullScreen(),
    );

    if (reduce) {
      return content
          .animate()
          .fadeIn(duration: AppMotion.durCrossfadeReduced);
    }

    final slideBegin = widget.variant == ErrorVariant.inline ? 8.0 : 12.0;
    return content
        .animate()
        .fadeIn(
          duration: AppMotion.durBase,
          curve: AppMotion.easeEntrance,
        )
        .moveY(
          begin: slideBegin,
          end: 0,
          duration: AppMotion.durBase,
          curve: AppMotion.easeEntrance,
        );
  }

  Widget _buildInline() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.10),
        border: Border.all(
          color: AppColors.danger.withValues(alpha: 0.50),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        boxShadow: AppDimens.elev1,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIconRing(size: 36, iconSize: AppDimens.iconS, borderOpacity: 0.30),
          const SizedBox(width: AppDimens.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title.toUpperCase(),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.danger,
                  ),
                ),
                const SizedBox(height: AppDimens.space4),
                Text(
                  widget.message,
                  style: AppTextStyles.bodyS.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimens.space16),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppButton.danger(
                label: widget.retryLabel,
                onPressed: _retrying ? null : _handleRetry,
                size: AppButtonSize.sm,
                loading: _retrying,
              ),
              if (widget.onDismiss != null) ...[
                const SizedBox(width: AppDimens.space8),
                AppIconButton(
                  icon: Icons.close_rounded,
                  onPressed: widget.onDismiss,
                  tooltip: 'Cerrar',
                  variant: AppButtonVariant.ghost,
                  size: AppButtonSize.sm,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFullScreen() {
    return SizedBox.expand(
      child: HudGridTexture(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIconRing(size: 96, iconSize: 40, borderOpacity: 0.40),
              const SizedBox(height: AppDimens.space24),
              Text(
                widget.title.toUpperCase(),
                style: AppTextStyles.titleM,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimens.space8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Text(
                  widget.message,
                  style: AppTextStyles.bodyS.copyWith(
                    color: AppColors.textTertiary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppDimens.space24),
              AppButton(
                label: widget.retryLabel,
                onPressed: _retrying ? null : _handleRetry,
                variant: AppButtonVariant.primary,
                size: AppButtonSize.md,
                loading: _retrying,
              ),
              if (widget.onDismiss != null) ...[
                const SizedBox(height: AppDimens.space12),
                AppButton.ghost(
                  label: 'VOLVER',
                  onPressed: widget.onDismiss,
                  size: AppButtonSize.md,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconRing({
    required double size,
    required double iconSize,
    required double borderOpacity,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceHud,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.danger.withValues(alpha: borderOpacity),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.dangerGlow,
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(
        Icons.error_outline_rounded,
        color: AppColors.danger,
        size: iconSize,
      ),
    );
  }
}

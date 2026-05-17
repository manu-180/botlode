// lib/core/ui/toasts/app_toast.dart
// Widget visual de toast «Hangar OS»: success, warning, error, info.
// El ciclo de vida (timer, hover-pause, cola, overlay) vive en toast_service.dart.
import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_dimens.dart';
import '../../config/theme/app_icons.dart';
import '../../config/theme/app_text_styles.dart';
import '../hud/hud_corner_brackets.dart';
import '../widgets/app_button.dart';
import '../widgets/app_icon_button.dart';

// ─── Tipos semánticos ─────────────────────────────────────────────────────────

enum ToastType { success, warning, error, info }

// ─── Widget visual ────────────────────────────────────────────────────────────

class AppToast extends StatelessWidget {
  final ToastType type;
  final String message;
  final String? title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;

  /// Progreso de la barra inferior: 1.0 = llena, 0.0 = vacía.
  /// Si null, no se muestra barra de progreso.
  final Animation<double>? progress;

  const AppToast({
    super.key,
    required this.type,
    required this.message,
    this.title,
    this.actionLabel,
    this.onAction,
    required this.onDismiss,
    this.progress,
  });

  Color get _typeColor => switch (type) {
        ToastType.success => AppColors.success,
        ToastType.warning => AppColors.warning,
        ToastType.error => AppColors.danger,
        ToastType.info => AppColors.info,
      };

  IconData get _typeIcon => switch (type) {
        ToastType.success => AppIcons.check,
        ToastType.warning => AppIcons.warning,
        ToastType.error => AppIcons.error,
        ToastType.info => AppIcons.info,
      };

  String get _semanticsLabel => switch (type) {
        ToastType.success => 'Notificación de éxito',
        ToastType.warning => 'Advertencia',
        ToastType.error => 'Error',
        ToastType.info => 'Información',
      };

  @override
  Widget build(BuildContext context) {
    final color = _typeColor;
    final tintedSurface = Color.lerp(AppColors.surfaceRaised, color, 0.06)!;

    return Semantics(
      liveRegion: true,
      label: '$_semanticsLabel: $message',
      container: true,
      child: HudCornerBrackets(
        color: color.withValues(alpha: 0.45),
        armLength: 14,
        thickness: 1.5,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Container(
            decoration: BoxDecoration(
              color: tintedSurface,
              borderRadius: AppDimens.brM,
              border: Border.all(
                color: color.withValues(alpha: 0.55),
                width: 1.5,
              ),
              boxShadow: [
                ...AppDimens.elev3,
                BoxShadow(
                  color: color.withValues(alpha: 0.18),
                  blurRadius: 20,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: AppDimens.brM,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MainRow(
                    color: color,
                    icon: _typeIcon,
                    title: title,
                    message: message,
                    actionLabel: actionLabel,
                    onAction: onAction != null
                        ? () {
                            onAction!();
                            onDismiss();
                          }
                        : null,
                    onDismiss: onDismiss,
                  ),
                  if (progress != null)
                    _ProgressBar(color: color, progress: progress!),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Fila principal ───────────────────────────────────────────────────────────

class _MainRow extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String? title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;

  const _MainRow({
    required this.color,
    required this.icon,
    this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.space16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícono semántico del tipo
          AppIcons.icon(icon, size: AppDimens.iconS, color: color),
          const SizedBox(width: AppDimens.space12),

          // Bloque de texto (title + message)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null) ...[
                  Text(
                    title!.toUpperCase(),
                    style: AppTextStyles.labelSmall.copyWith(color: color),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDimens.space2),
                ],
                Text(
                  message,
                  style: AppTextStyles.bodyM
                      .copyWith(color: AppColors.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Botón de acción opcional
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: AppDimens.space12),
            AppButton(
              label: actionLabel!,
              onPressed: onAction!,
              variant: AppButtonVariant.ghost,
              size: AppButtonSize.sm,
            ),
          ],

          // Botón de cierre
          const SizedBox(width: AppDimens.space8),
          AppIconButton(
            icon: AppIcons.close,
            onPressed: onDismiss,
            tooltip: 'Cerrar',
            variant: AppButtonVariant.ghost,
            size: AppButtonSize.sm,
          ),
        ],
      ),
    );
  }
}

// ─── Barra de progreso ────────────────────────────────────────────────────────

class _ProgressBar extends AnimatedWidget {
  final Color color;

  const _ProgressBar({
    required this.color,
    required Animation<double> progress,
  }) : super(listenable: progress);

  Animation<double> get _progress => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2,
      width: double.infinity,
      child: CustomPaint(
        painter: _ProgressPainter(
          color: color,
          value: _progress.value.clamp(0.0, 1.0),
        ),
      ),
    );
  }
}

class _ProgressPainter extends CustomPainter {
  final Color color;
  final double value;

  const _ProgressPainter({required this.color, required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    // Fondo sutil
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppColors.borderSubtle,
    );
    // Relleno que se vacía linealmente de derecha a izquierda
    if (value > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width * value, size.height),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressPainter old) =>
      old.value != value || old.color != color;
}

// lib/core/ui/toasts/app_toast.dart
// Sistema de toasts HUD: success, warning, error, info.
// Aparecen en la parte superior derecha. z-index: zToast.
import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_dimens.dart';
import '../../config/theme/app_motion.dart';
import '../../config/theme/app_text_styles.dart';

enum ToastType { success, warning, error, info }

class AppToast extends StatelessWidget {
  final ToastType type;
  final String message;
  final String? action;
  final VoidCallback? onAction;

  const AppToast({
    super.key,
    required this.type,
    required this.message,
    this.action,
    this.onAction,
  });

  Color get _color => switch (type) {
        ToastType.success => AppColors.success,
        ToastType.warning => AppColors.warning,
        ToastType.error   => AppColors.danger,
        ToastType.info    => AppColors.info,
      };

  IconData get _icon => switch (type) {
        ToastType.success => Icons.check_circle_outline,
        ToastType.warning => Icons.warning_amber_outlined,
        ToastType.error   => Icons.error_outline,
        ToastType.info    => Icons.info_outline,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space16,
        vertical: AppDimens.space12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppDimens.brM,
        border: Border.all(
          color: _color.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [
          ...AppDimens.elev3,
          BoxShadow(
            color: _color.withValues(alpha: 0.18),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, color: _color, size: 18),
          const SizedBox(width: AppDimens.space12),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyM.copyWith(color: AppColors.textPrimary),
            ),
          ),
          if (action != null && onAction != null) ...[
            const SizedBox(width: AppDimens.space12),
            GestureDetector(
              onTap: onAction,
              child: Text(
                action!.toUpperCase(),
                style: AppTextStyles.label.copyWith(color: _color),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Muestra un toast en la pantalla actual.
/// Duración por defecto: 3 s. Aparece en top-right.
void showAppToast(
  BuildContext context, {
  required ToastType type,
  required String message,
  String? action,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 3),
}) {
  final overlay = Overlay.of(context);
  late final OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) => _ToastEntry(
      type: type,
      message: message,
      action: action,
      onAction: onAction,
      duration: duration,
      onDismiss: () => entry.remove(),
    ),
  );

  overlay.insert(entry);
}

class _ToastEntry extends StatefulWidget {
  final ToastType type;
  final String message;
  final String? action;
  final VoidCallback? onAction;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ToastEntry({
    required this.type,
    required this.message,
    this.action,
    this.onAction,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_ToastEntry> createState() => _ToastEntryState();
}

class _ToastEntryState extends State<_ToastEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppMotion.durSlow);
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: AppMotion.easeEntrance),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0.15, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: AppMotion.easeEntrance));

    _ctrl.forward();

    Future.delayed(widget.duration, _dismiss);
  }

  void _dismiss() async {
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: AppDimens.space32 + MediaQuery.of(context).padding.top + AppDimens.titleBarHeight,
      right: AppDimens.space24,
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) => FadeTransition(
            opacity: _opacity,
            child: SlideTransition(position: _slide, child: child),
          ),
          child: AppToast(
            type: widget.type,
            message: widget.message,
            action: widget.action,
            onAction: widget.onAction,
          ),
        ),
      ),
    );
  }
}

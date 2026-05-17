// Archivo: lib/features/bot_engine/presentation/widgets/status_indicator.dart
// Indicador de estado HUD — Hangar OS · Prompt 40.
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_icons.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/hud/hud_chamfer.dart';
import 'package:botslode/core/ui/hud/hud_reactor_bar.dart';
import 'package:flutter/material.dart';

// ─── Internal state enum ──────────────────────────────────────────────────────
enum _BotState { online, processing, offline, moodAngry, moodHappy, moodVendor, moodConfused, moodTech }

extension _BotStateX on _BotState {
  String get label => switch (this) {
    _BotState.online       => 'EN LÍNEA',
    _BotState.processing   => 'PROCESANDO...',
    _BotState.offline      => 'SIN CONEXIÓN',
    _BotState.moodAngry    => 'ENOJADO',
    _BotState.moodHappy    => 'FELIZ',
    _BotState.moodVendor   => 'VENDEDOR',
    _BotState.moodConfused => 'CONFUNDIDO',
    _BotState.moodTech     => 'TÉCNICO',
  };

  Color get color => switch (this) {
    _BotState.online       => AppColors.success,
    _BotState.processing   => AppColors.cyan,
    _BotState.offline      => AppColors.danger,
    _BotState.moodAngry    => AppColors.danger,
    _BotState.moodHappy    => AppColors.accentMagenta,
    _BotState.moodVendor   => AppColors.gold,
    _BotState.moodConfused => AppColors.accentViolet,
    _BotState.moodTech     => AppColors.cyan,
  };

  IconData get icon => switch (this) {
    _BotState.online       => AppIcons.moodOnline,
    _BotState.processing   => AppIcons.loading,
    _BotState.offline      => AppIcons.disconnected,
    _BotState.moodAngry    => AppIcons.moodAngry,
    _BotState.moodHappy    => AppIcons.moodHappy,
    _BotState.moodVendor   => AppIcons.moodVendor,
    _BotState.moodConfused => AppIcons.moodConfused,
    _BotState.moodTech     => AppIcons.moodTech,
  };

  bool get pulsing => this != _BotState.offline;

  Duration get beatDuration =>
      this == _BotState.processing ? AppMotion.durTicker : AppMotion.durHeartbeat;
}

// ─── Widget ───────────────────────────────────────────────────────────────────

const double _kChamfer = 8.0;

class StatusIndicator extends StatefulWidget {
  const StatusIndicator({
    super.key,
    required this.isLoading,
    required this.isOnline,
    required this.moodIndex,
  });

  final bool isLoading;
  final bool isOnline;
  final int moodIndex;

  @override
  State<StatusIndicator> createState() => _StatusIndicatorState();
}

class _StatusIndicatorState extends State<StatusIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _mountCtrl;
  late final Animation<double> _mountOpacity;

  @override
  void initState() {
    super.initState();
    _mountCtrl = AnimationController(vsync: this, duration: AppMotion.durFast);
    _mountOpacity = CurvedAnimation(parent: _mountCtrl, curve: AppMotion.easeStandard);
    _mountCtrl.forward();
  }

  @override
  void dispose() {
    _mountCtrl.dispose();
    super.dispose();
  }

  _BotState get _status {
    if (!widget.isOnline) return _BotState.offline;
    if (widget.isLoading) return _BotState.processing;
    return switch (widget.moodIndex) {
      1 => _BotState.moodAngry,
      2 => _BotState.moodHappy,
      3 => _BotState.moodVendor,
      4 => _BotState.moodConfused,
      5 => _BotState.moodTech,
      _ => _BotState.online,
    };
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.isReduced(context);
    final status = _status;
    final color = status.color;
    final colorDuration =
        reduced ? AppMotion.durCrossfadeReduced : AppMotion.durBase;
    final textDuration =
        reduced ? AppMotion.durCrossfadeReduced : AppMotion.durFast;

    final capsule = Container(
      padding: const EdgeInsets.only(
        left: AppDimens.space8,
        right: AppDimens.space12,
        top: AppDimens.space8,
        bottom: AppDimens.space8,
      ),
      decoration: const ShapeDecoration(
        color: AppColors.surfaceHud,
        shape: ChamferBorder(
          chamfer: _kChamfer,
          side: BorderSide(color: AppColors.borderDefault, width: 1),
        ),
        shadows: AppDimens.elev1,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: color),
            duration: colorDuration,
            curve: AppMotion.easeStandard,
            builder: (_, animColor, __) => HudReactorBar(
              axis: Axis.vertical,
              thickness: 4,
              length: 14,
              color: animColor ?? color,
              pulsing: status.pulsing,
              duration: status.beatDuration,
            ),
          ),
          const SizedBox(width: AppDimens.space8),
          TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: color),
            duration: colorDuration,
            curve: AppMotion.easeStandard,
            builder: (_, animColor, __) => AppIcons.icon(
              status.icon,
              size: 12,
              color: animColor ?? color,
            ),
          ),
          const SizedBox(width: AppDimens.space4),
          AnimatedSwitcher(
            duration: textDuration,
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: Text(
              status.label,
              key: ValueKey(status),
              style: AppTextStyles.hudReadout,
            ),
          ),
        ],
      ),
    );

    return FadeTransition(
      opacity: _mountOpacity,
      child: Semantics(
        label: 'Estado de la unidad: ${status.label}',
        liveRegion: true,
        child: ExcludeSemantics(child: capsule),
      ),
    );
  }
}

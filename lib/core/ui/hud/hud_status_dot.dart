// lib/core/ui/hud/hud_status_dot.dart
// Punto de estado con halo de glow pulsante.
// Respeta reduced-motion. Expone Semantics para accesibilidad.
import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_dimens.dart';
import '../../config/theme/app_motion.dart';
import '../../config/theme/app_text_styles.dart';

enum HudStatus { online, processing, suspended, offline }

class HudStatusDot extends StatefulWidget {
  final HudStatus status;
  final double size;
  final bool showLabel;

  const HudStatusDot({
    super.key,
    required this.status,
    this.size = 10,
    this.showLabel = false,
  });

  @override
  State<HudStatusDot> createState() => _HudStatusDotState();
}

class _HudStatusDotState extends State<HudStatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppMotion.durHeartbeat,
    );
    _pulse = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: AppMotion.easeStandard),
    );
    _updateAnimation();
  }

  @override
  void didUpdateWidget(HudStatusDot old) {
    super.didUpdateWidget(old);
    if (old.status != widget.status) _updateAnimation();
  }

  void _updateAnimation() {
    if (widget.status == HudStatus.online ||
        widget.status == HudStatus.processing) {
      _ctrl.repeat(reverse: true);
    } else {
      _ctrl.stop();
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _color => switch (widget.status) {
        HudStatus.online     => AppColors.success,
        HudStatus.processing => AppColors.cyan,
        HudStatus.suspended  => AppColors.warning,
        HudStatus.offline    => AppColors.textTertiary,
      };

  List<BoxShadow> get _glow => switch (widget.status) {
        HudStatus.online     => AppDimens.glowStatus(AppColors.success),
        HudStatus.processing => AppDimens.glowStatus(AppColors.cyan),
        HudStatus.suspended  => AppDimens.glowStatus(AppColors.warning),
        HudStatus.offline    => AppDimens.elev0,
      };

  String get _semanticLabel => switch (widget.status) {
        HudStatus.online     => 'online',
        HudStatus.processing => 'processing',
        HudStatus.suspended  => 'suspended',
        HudStatus.offline    => 'offline',
      };

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.isReduced(context);
    final shouldAnimate = !reduced &&
        (widget.status == HudStatus.online ||
            widget.status == HudStatus.processing);

    Widget dot = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
        boxShadow: _glow,
      ),
    );

    if (shouldAnimate) {
      dot = AnimatedBuilder(
        animation: _pulse,
        builder: (_, child) => Opacity(opacity: _pulse.value, child: child),
        child: dot,
      );
    }

    Widget content = widget.showLabel
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              dot,
              const SizedBox(width: AppDimens.space8),
              Text(
                _semanticLabel,
                style: AppTextStyles.labelSmall.copyWith(
                  color: _color,
                ),
              ),
            ],
          )
        : dot;

    return Semantics(
      label: _semanticLabel,
      child: ExcludeSemantics(child: content),
    );
  }
}

// Backward-compat alias — preferir HudStatus en código nuevo.
@Deprecated('Use HudStatus')
typedef HudDotStatus = HudStatus;

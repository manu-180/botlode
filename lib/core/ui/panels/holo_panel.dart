// lib/core/ui/panels/holo_panel.dart
// HoloPanel: contenedor de vidrio reutilizable — la «superficie» base de la UI.
// Soporta: hover elevado, borde dorado, glow, brackets HUD opcionales, chaflán.
import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_dimens.dart';
import '../../config/theme/app_motion.dart';
import '../hud/hud_corner_brackets.dart';

enum HoloPanelVariant { standard, gold, cyan, elevated }

class HoloPanel extends StatefulWidget {
  final Widget child;
  final HoloPanelVariant variant;
  final EdgeInsetsGeometry? padding;
  final bool hoverable;
  final bool hudBrackets;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const HoloPanel({
    super.key,
    required this.child,
    this.variant = HoloPanelVariant.standard,
    this.padding,
    this.hoverable = false,
    this.hudBrackets = false,
    this.borderRadius,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  State<HoloPanel> createState() => _HoloPanelState();
}

class _HoloPanelState extends State<HoloPanel>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppMotion.durInstant,
    );
    _scale = Tween<double>(begin: 1.0, end: AppMotion.pressScale)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  BoxDecoration _buildDecoration() {
    final br = widget.borderRadius ?? AppDimens.brL;
    final hov = _hovered && widget.hoverable;

    return switch (widget.variant) {
      HoloPanelVariant.gold => BoxDecoration(
          color: AppColors.glassSurface,
          borderRadius: br,
          border: Border.all(
            color: hov ? AppColors.gold : AppColors.borderGold,
            width: hov ? 1.5 : 1,
          ),
          boxShadow: hov ? AppDimens.glowGold : AppDimens.elev1,
        ),
      HoloPanelVariant.cyan => BoxDecoration(
          color: AppColors.glassSurface,
          borderRadius: br,
          border: Border.all(
            color: AppColors.cyan.withValues(alpha: hov ? 0.5 : 0.3),
            width: hov ? 1.5 : 1,
          ),
          boxShadow: hov ? AppDimens.glowCyan : AppDimens.elev1,
        ),
      HoloPanelVariant.elevated => BoxDecoration(
          color: hov ? AppColors.surfaceRaised : AppColors.surface,
          borderRadius: br,
          border: Border.all(
            color: hov ? AppColors.borderStrong : AppColors.borderDefault,
            width: 1,
          ),
          boxShadow: hov ? AppDimens.elev2 : AppDimens.elev1,
        ),
      HoloPanelVariant.standard => BoxDecoration(
          color: hov ? AppColors.surfaceRaised : AppColors.glassSurface,
          borderRadius: br,
          border: Border.all(
            color: hov ? AppColors.borderStrong : AppColors.glassBorder,
            width: 1,
          ),
          boxShadow: hov ? AppDimens.elev2 : AppDimens.elev1,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    Widget panel = AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: MouseRegion(
        cursor: widget.onTap != null
            ? SystemMouseCursors.click
            : MouseCursor.defer,
        onEnter: widget.hoverable ? (_) => setState(() => _hovered = true) : null,
        onExit: widget.hoverable ? (_) => setState(() => _hovered = false) : null,
        child: GestureDetector(
          onTapDown: widget.onTap != null ? (_) => _ctrl.forward() : null,
          onTapUp: widget.onTap != null ? (_) => _ctrl.reverse() : null,
          onTapCancel: widget.onTap != null ? _ctrl.reverse : null,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: AppMotion.durFast,
            curve: AppMotion.easeHover,
            width: widget.width,
            height: widget.height,
            padding: widget.padding ?? const EdgeInsets.all(AppDimens.paddingCard),
            decoration: _buildDecoration(),
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.hudBrackets) {
      panel = HudCornerBrackets(child: panel);
    }

    return panel;
  }
}

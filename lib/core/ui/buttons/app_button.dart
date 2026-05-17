// lib/core/ui/buttons/app_button.dart
// Sistema de botones «Hangar OS»: Primary, Secondary, Danger, Ghost, Icon.
// Todos los estados: default, hover, pressed, focused, loading, disabled.
import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_dimens.dart';
import '../../config/theme/app_motion.dart';
import '../../config/theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, danger, ghost }

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool loading;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.leadingIcon,
    this.trailingIcon,
    this.width,
    this.height = 48,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.leadingIcon,
    this.trailingIcon,
    this.width,
    this.height = 48,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.leadingIcon,
    this.trailingIcon,
    this.width,
    this.height = 48,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.leadingIcon,
    this.trailingIcon,
    this.width,
    this.height = 48,
  }) : variant = AppButtonVariant.danger;

  const AppButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.leadingIcon,
    this.trailingIcon,
    this.width,
    this.height = 40,
  }) : variant = AppButtonVariant.ghost;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  bool _pressed = false;
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: AppMotion.durInstant,
    );
    _scale = Tween<double>(begin: 1.0, end: AppMotion.pressScale)
        .animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  bool get _isEnabled => widget.onPressed != null && !widget.loading;

  _ButtonStyle get _style => _ButtonStyle.forVariant(widget.variant);

  void _onHoverChange(bool v) {
    setState(() => _hovered = v);
  }

  void _onTapDown(_) {
    if (!_isEnabled) return;
    setState(() => _pressed = true);
    _scaleCtrl.forward();
  }

  void _onTapUp(_) {
    setState(() => _pressed = false);
    _scaleCtrl.reverse();
  }

  void _onTapCancel() {
    setState(() => _pressed = false);
    _scaleCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = !_isEnabled;

    return Semantics(
      button: true,
      enabled: _isEnabled,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: MouseRegion(
          cursor: disabled
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          onEnter: (_) => _onHoverChange(true),
          onExit: (_) => _onHoverChange(false),
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            onTap: _isEnabled ? widget.onPressed : null,
            child: AnimatedOpacity(
              opacity: disabled ? 0.4 : 1.0,
              duration: AppMotion.durInstant,
              child: AnimatedContainer(
                duration: AppMotion.durFast,
                curve: AppMotion.easeHover,
                width: widget.width,
                height: widget.height,
                decoration: _buildDecoration(disabled),
                child: Center(child: _buildContent()),
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration(bool disabled) {
    final s = _style;

    if (widget.variant == AppButtonVariant.primary) {
      return BoxDecoration(
        gradient: disabled ? null : AppColors.gradGold,
        color: disabled ? AppColors.gold : null,
        borderRadius: AppDimens.brM,
        border: _hovered && !disabled
            ? Border.all(color: AppColors.goldBright, width: 1)
            : null,
        boxShadow: (!disabled && _hovered)
            ? AppDimens.glowGold
            : AppDimens.elev1,
      );
    }

    return BoxDecoration(
      color: _pressed && !disabled
          ? s.pressedFill
          : (_hovered && !disabled ? s.hoverFill : s.fill),
      borderRadius: AppDimens.brM,
      border: Border.all(
        color: _hovered && !disabled ? s.hoverBorder : s.border,
        width: 1,
      ),
      boxShadow: _hovered && !disabled ? AppDimens.elev2 : AppDimens.elev1,
    );
  }

  Widget _buildContent() {
    if (widget.loading) {
      return SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(_style.textColor),
        ),
      );
    }

    final textColor = _style.textColor;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.leadingIcon != null) ...[
          Icon(widget.leadingIcon, size: 16, color: textColor),
          const SizedBox(width: 8),
        ],
        Text(
          widget.label.toUpperCase(),
          style: AppTextStyles.label.copyWith(
            color: textColor,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (widget.trailingIcon != null) ...[
          const SizedBox(width: 8),
          Icon(widget.trailingIcon, size: 16, color: textColor),
        ],
      ],
    );
  }
}

class _ButtonStyle {
  final Color fill;
  final Color hoverFill;
  final Color pressedFill;
  final Color border;
  final Color hoverBorder;
  final Color textColor;

  const _ButtonStyle({
    required this.fill,
    required this.hoverFill,
    required this.pressedFill,
    required this.border,
    required this.hoverBorder,
    required this.textColor,
  });

  static _ButtonStyle forVariant(AppButtonVariant v) => switch (v) {
        AppButtonVariant.primary => const _ButtonStyle(
            fill: AppColors.gold,
            hoverFill: AppColors.goldBright,
            pressedFill: AppColors.goldDeep,
            border: Colors.transparent,
            hoverBorder: AppColors.goldBright,
            textColor: AppColors.textOnGold,
          ),
        AppButtonVariant.secondary => const _ButtonStyle(
            fill: AppColors.surface,
            hoverFill: AppColors.surfaceRaised,
            pressedFill: AppColors.bgElevated01,
            border: AppColors.borderDefault,
            hoverBorder: AppColors.borderStrong,
            textColor: AppColors.textPrimary,
          ),
        AppButtonVariant.danger => const _ButtonStyle(
            fill: AppColors.surface,
            hoverFill: Color.fromRGBO(255, 45, 85, 0.12),
            pressedFill: Color.fromRGBO(255, 45, 85, 0.20),
            border: AppColors.danger,
            hoverBorder: AppColors.danger,
            textColor: AppColors.danger,
          ),
        AppButtonVariant.ghost => const _ButtonStyle(
            fill: Colors.transparent,
            hoverFill: Color.fromRGBO(255, 255, 255, 0.06),
            pressedFill: Color.fromRGBO(255, 255, 255, 0.04),
            border: Colors.transparent,
            hoverBorder: AppColors.borderDefault,
            textColor: AppColors.textSecondary,
          ),
      };
}

/// Botón de solo ícono. Siempre lleva tooltip semántico.
class AppIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? hoverColor;
  final double size;
  final double hitSize;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
    this.hoverColor,
    this.size = 20,
    this.hitSize = 36,
  });

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppMotion.durInstant);
    _scale = Tween<double>(begin: 1.0, end: AppMotion.pressScale)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _hovered
        ? (widget.hoverColor ?? AppColors.textPrimary)
        : (widget.color ?? AppColors.textSecondary);
    final disabled = widget.onPressed == null;

    return Semantics(
      button: true,
      label: widget.tooltip,
      enabled: !disabled,
      child: Tooltip(
        message: widget.tooltip,
        child: MouseRegion(
          cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTapDown: disabled ? null : (_) => _ctrl.forward(),
            onTapUp: disabled ? null : (_) => _ctrl.reverse(),
            onTapCancel: disabled ? null : _ctrl.reverse,
            onTap: widget.onPressed,
            child: AnimatedOpacity(
              opacity: disabled ? 0.4 : 1.0,
              duration: AppMotion.durInstant,
              child: AnimatedBuilder(
                animation: _scale,
                builder: (_, child) =>
                    Transform.scale(scale: _scale.value, child: child),
                child: SizedBox(
                  width: widget.hitSize,
                  height: widget.hitSize,
                  child: Center(
                    child: AnimatedContainer(
                      duration: AppMotion.durFast,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _hovered
                            ? AppColors.borderSubtle
                            : Colors.transparent,
                        borderRadius: AppDimens.brS,
                      ),
                      child: Icon(widget.icon, size: widget.size, color: iconColor),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

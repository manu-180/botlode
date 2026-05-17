// lib/core/ui/widgets/app_icon_button.dart
// Botón icono canónico «Hangar OS» — variantes primary / secondary / danger / ghost.
// Implementa: hover, press (escala P2), focus ring cyan, disabled, loading, tooltip.
// TODO: reemplazar CircularProgressIndicator por AppSpinner cuando esté disponible.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_dimens.dart';
import '../../config/theme/app_icons.dart';
import '../../config/theme/app_motion.dart';
import 'app_button.dart'; // for AppButtonVariant, AppButtonSize

// ─── Spec-defined icon button sides (not in AppDimens) ───────────────────────

const double _kSideSm = 32; // per Hangar OS icon button spec table
const double _kSideMd = 44;
const double _kSideLg = 52;

// ─── Size data ────────────────────────────────────────────────────────────────

class _SizeData {
  final double side;
  final double iconSize;

  const _SizeData({required this.side, required this.iconSize});
}

_SizeData _sizeFor(AppButtonSize size) {
  switch (size) {
    case AppButtonSize.sm:
      return const _SizeData(side: _kSideSm, iconSize: AppDimens.iconXS); // 14
    case AppButtonSize.md:
      return const _SizeData(side: _kSideMd, iconSize: AppDimens.iconS); // 18
    case AppButtonSize.lg:
      return const _SizeData(side: _kSideLg, iconSize: AppDimens.iconS); // 18
  }
}

// ─── AppIconButton ────────────────────────────────────────────────────────────

class AppIconButton extends StatefulWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.variant = AppButtonVariant.ghost,
    this.size = AppButtonSize.md,
    this.loading = false,
  }) : assert(tooltip.length > 0, 'AppIconButton.tooltip must not be empty');

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool loading;

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton>
    with SingleTickerProviderStateMixin {
  // Interaction state
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  // Press scale controller
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scaleAnim;

  bool get _isDisabled => widget.onPressed == null && !widget.loading;
  bool get _isInteractive => !_isDisabled && !widget.loading;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: AppMotion.durInstant,
      reverseDuration: AppMotion.durFast,
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: AppMotion.pressScale,
    ).animate(CurvedAnimation(
      parent: _scaleCtrl,
      curve: AppMotion.easeEntrance,
      reverseCurve: AppMotion.easeStandard,
    ));
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AppIconButton old) {
    super.didUpdateWidget(old);
    final wasInteractive = old.onPressed != null && !old.loading;
    if (wasInteractive && !_isInteractive) {
      _hovered = false;
      _pressed = false;
      _scaleCtrl.reverse();
    }
  }

  // ─── Derived decoration ───────────────────────────────────────────────────

  List<BoxShadow> get _shadows {
    final List<BoxShadow> base = _baseElevation;
    final List<BoxShadow> focus = _focused ? [_focusRingShadow] : const [];

    if (_isDisabled || widget.loading) return [...focus];

    if (_pressed) {
      // Pressed: primary keeps glow, others flatten
      if (widget.variant == AppButtonVariant.primary) {
        return [...AppDimens.elev1, ...AppDimens.glowGold, ...focus];
      }
      return [...AppDimens.elev0, ...focus];
    }

    if (_hovered && _isInteractive) {
      switch (widget.variant) {
        case AppButtonVariant.primary:
          return [...AppDimens.elev1, ...AppDimens.glowGold, ...focus];
        case AppButtonVariant.secondary:
          return [
            ...AppDimens.elev2,
            ...AppDimens.glowStatus(AppColors.gold),
            ...focus,
          ];
        case AppButtonVariant.danger:
          return [
            ...AppDimens.glowStatus(AppColors.danger),
            ...focus,
          ];
        case AppButtonVariant.ghost:
          return [...focus];
      }
    }

    return [...base, ...focus];
  }

  List<BoxShadow> get _baseElevation {
    switch (widget.variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.secondary:
        return AppDimens.elev1;
      case AppButtonVariant.danger:
      case AppButtonVariant.ghost:
        return AppDimens.elev0;
    }
  }

  static const BoxShadow _focusRingShadow = BoxShadow(
    color: AppColors.cyan,
    blurRadius: 0,
    spreadRadius: AppDimens.space2,
  );

  /// Fill color for the AnimatedContainer (non-gradient variants).
  Color get _fillColor {
    if (widget.variant == AppButtonVariant.primary) {
      // Gradient handled separately; AnimatedContainer color is transparent.
      return Colors.transparent;
    }

    if (_isDisabled) return _baseFillColor;

    if (_pressed) {
      switch (widget.variant) {
        case AppButtonVariant.secondary:
        case AppButtonVariant.danger:
        case AppButtonVariant.ghost:
          return AppColors.surfaceHud;
        case AppButtonVariant.primary:
          return Colors.transparent;
      }
    }

    if (_hovered) {
      switch (widget.variant) {
        case AppButtonVariant.secondary:
          return AppColors.surface;
        case AppButtonVariant.danger:
          return AppColors.danger.withValues(alpha: 0.08);
        case AppButtonVariant.ghost:
          return AppColors.borderSubtle;
        case AppButtonVariant.primary:
          return Colors.transparent;
      }
    }

    return _baseFillColor;
  }

  Color get _baseFillColor {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return Colors.transparent;
      case AppButtonVariant.secondary:
        return AppColors.surface;
      case AppButtonVariant.danger:
        return AppColors.surface;
      case AppButtonVariant.ghost:
        return Colors.transparent;
    }
  }

  BorderSide get _borderSide {
    if (_isDisabled) return _baseBorderSide;

    if (_hovered && widget.variant == AppButtonVariant.secondary) {
      return const BorderSide(color: AppColors.borderGold, width: 1.5);
    }

    return _baseBorderSide;
  }

  BorderSide get _baseBorderSide {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return BorderSide.none;
      case AppButtonVariant.secondary:
        return const BorderSide(color: AppColors.borderStrong, width: 1.5);
      case AppButtonVariant.danger:
        return const BorderSide(color: AppColors.danger, width: 1.5);
      case AppButtonVariant.ghost:
        return BorderSide.none;
    }
  }

  Color get _iconColor {
    if (_hovered && widget.variant == AppButtonVariant.ghost) {
      return AppColors.textPrimary;
    }
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return AppColors.textOnGold;
      case AppButtonVariant.secondary:
        return AppColors.textPrimary;
      case AppButtonVariant.danger:
        return AppColors.danger;
      case AppButtonVariant.ghost:
        return AppColors.textSecondary;
    }
  }

  // ─── Event handlers ───────────────────────────────────────────────────────

  void _onEnter(PointerEnterEvent _) {
    if (!_isInteractive) return;
    setState(() => _hovered = true);
  }

  void _onExit(PointerExitEvent _) {
    setState(() => _hovered = false);
  }

  void _onTapDown(TapDownDetails _) {
    if (!_isInteractive) return;
    setState(() => _pressed = true);
    final reduced = AppMotion.reduced(context);
    if (!reduced) {
      _scaleCtrl.forward();
    }
  }

  void _onTapUp(TapUpDetails _) {
    if (!_isInteractive) {
      if (_pressed) {
        setState(() => _pressed = false);
        _scaleCtrl.reverse();
      }
      return;
    }
    setState(() => _pressed = false);
    _scaleCtrl.reverse();
    widget.onPressed?.call();
  }

  void _onTapCancel() {
    setState(() => _pressed = false);
    _scaleCtrl.reverse();
  }

  void _onFocusChange(bool focused) {
    setState(() => _focused = focused);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sd = _sizeFor(widget.size);
    final reduced = AppMotion.reduced(context);
    final dur = reduced ? AppMotion.durInstant : AppMotion.durFast;

    final MouseCursor cursor = _isInteractive
        ? SystemMouseCursors.click
        : SystemMouseCursors.basic;

    Widget button = _buildButtonBody(sd, dur);

    // Press scale (P2 pattern)
    button = AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnim.value,
        child: child,
      ),
      child: button,
    );

    // Disabled: global opacity 0.4
    if (_isDisabled) {
      button = AnimatedOpacity(
        opacity: 0.4,
        duration: dur,
        curve: AppMotion.easeStandard,
        child: button,
      );
    }

    // Semantics
    button = Semantics(
      button: true,
      enabled: _isInteractive,
      label: widget.loading ? '${widget.tooltip}, cargando' : widget.tooltip,
      onTap: _isInteractive ? widget.onPressed : null,
      child: button,
    );

    // Focus handling
    button = Focus(
      canRequestFocus: _isInteractive,
      descendantsAreFocusable: _isInteractive,
      onFocusChange: _onFocusChange,
      onKeyEvent: (node, event) {
        if (_isInteractive && event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space) {
            setState(() => _pressed = true);
            final reduced = AppMotion.reduced(context);
            if (!reduced) _scaleCtrl.forward();
            widget.onPressed?.call();
            // Schedule release after durInstant
            Future.delayed(AppMotion.durInstant, () {
              if (mounted) {
                setState(() => _pressed = false);
                _scaleCtrl.reverse();
              }
            });
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: button,
    );

    // Mouse region
    button = MouseRegion(
      cursor: cursor,
      onEnter: _onEnter,
      onExit: _onExit,
      child: button,
    );

    // Tooltip (native hover tooltip)
    button = Tooltip(
      message: widget.tooltip,
      excludeFromSemantics: true,
      child: button,
    );

    // Fixed square size
    return SizedBox(
      width: sd.side,
      height: sd.side,
      child: button,
    );
  }

  Widget _buildButtonBody(_SizeData sd, Duration dur) {
    final isPrimary = widget.variant == AppButtonVariant.primary;

    final Widget content = _buildContent(sd);

    if (isPrimary) {
      // Primary: gradient fill via BoxDecoration; shadows animate via AnimatedContainer.
      return GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedContainer(
          duration: dur,
          curve: AppMotion.easeStandard,
          width: sd.side,
          height: sd.side,
          decoration: BoxDecoration(
            gradient: AppColors.gradGold,
            borderRadius: AppDimens.brM,
            boxShadow: _shadows,
          ),
          child: ClipRRect(
            borderRadius: AppDimens.brM,
            child: Center(child: content),
          ),
        ),
      );
    }

    // Non-primary: single AnimatedContainer handles fill, border and shadows.
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedContainer(
        duration: dur,
        curve: AppMotion.easeStandard,
        width: sd.side,
        height: sd.side,
        decoration: BoxDecoration(
          color: _fillColor,
          borderRadius: AppDimens.brM,
          border: Border.fromBorderSide(_borderSide),
          boxShadow: _shadows,
        ),
        child: Center(child: content),
      ),
    );
  }

  Widget _buildContent(_SizeData sd) {
    if (widget.loading) {
      return SizedBox(
        width: sd.iconSize,
        height: sd.iconSize,
        child: CircularProgressIndicator(
          strokeWidth: AppDimens.space2,
          valueColor: AlwaysStoppedAnimation<Color>(_iconColor),
        ),
      );
    }

    return AppIcons.icon(
      widget.icon,
      size: sd.iconSize,
      color: _iconColor,
    );
  }
}

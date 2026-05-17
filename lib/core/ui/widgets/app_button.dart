// lib/core/ui/widgets/app_button.dart
// Botón canónico «Hangar OS» — variantes primary / secondary / danger / ghost.
// Implementa: hover, press (escala P2), focus ring cyan, disabled, loading.
// TODO: reemplazar CircularProgressIndicator por AppSpinner cuando esté disponible.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_dimens.dart';
import '../../config/theme/app_motion.dart';
import '../../config/theme/app_text_styles.dart';
import '../hud/hud_chamfer.dart';

// ─── Spec-defined button heights (not in AppDimens) ──────────────────────────

const double _kHeightSm = 32; // per Hangar OS button spec table
const double _kHeightMd = 44;
const double _kHeightLg = 52;

// ─── Enums ────────────────────────────────────────────────────────────────────

enum AppButtonVariant { primary, secondary, danger, ghost }

enum AppButtonSize { sm, md, lg }

// ─── Size data ────────────────────────────────────────────────────────────────

class _SizeData {
  final double height;
  final double hPad;
  final double iconSize;
  final double gap;
  final TextStyle textStyle;

  const _SizeData({
    required this.height,
    required this.hPad,
    required this.iconSize,
    required this.gap,
    required this.textStyle,
  });
}

_SizeData _sizeFor(AppButtonSize size) {
  switch (size) {
    case AppButtonSize.sm:
      return _SizeData(
        height: _kHeightSm,
        hPad: AppDimens.space12,
        iconSize: AppDimens.iconXS, // 14
        gap: AppDimens.space8,
        textStyle: AppTextStyles.labelSmall,
      );
    case AppButtonSize.md:
      return _SizeData(
        height: _kHeightMd,
        hPad: AppDimens.space20,
        iconSize: 16,
        gap: AppDimens.space8,
        textStyle: AppTextStyles.label,
      );
    case AppButtonSize.lg:
      return _SizeData(
        height: _kHeightLg,
        hPad: AppDimens.space24,
        iconSize: AppDimens.iconS, // 18
        gap: AppDimens.space12,
        textStyle: AppTextStyles.label,
      );
  }
}

// ─── AppButton ────────────────────────────────────────────────────────────────

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.leadingIcon,
    this.loading = false,
    this.chamfer = false,
    this.expand = false,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.md,
    this.leadingIcon,
    this.loading = false,
    this.chamfer = false,
    this.expand = false,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.md,
    this.leadingIcon,
    this.loading = false,
    this.chamfer = false,
    this.expand = false,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.md,
    this.leadingIcon,
    this.loading = false,
    this.chamfer = false,
    this.expand = false,
  }) : variant = AppButtonVariant.danger;

  const AppButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.md,
    this.leadingIcon,
    this.loading = false,
    this.chamfer = false,
    this.expand = false,
  }) : variant = AppButtonVariant.ghost;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? leadingIcon;
  final bool loading;

  /// When true and variant == primary, uses ChamferBorder instead of rounded rect.
  final bool chamfer;

  /// When true, button takes double.infinity width.
  final bool expand;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
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
  void didUpdateWidget(AppButton old) {
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
    final List<BoxShadow> focus =
        _focused ? [_focusRingShadow] : const [];

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

  /// Fill color for the AnimatedContainer (used for non-gradient variants).
  Color get _fillColor {
    if (widget.variant == AppButtonVariant.primary) {
      // Gradient is handled separately; AnimatedContainer color is transparent.
      return Colors.transparent;
    }

    if (_isDisabled) {
      return _baseFillColor;
    }

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
          // Tinted with danger at 8%
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
      return const BorderSide(
        color: AppColors.borderGold,
        width: 1.5,
      );
    }

    return _baseBorderSide;
  }

  BorderSide get _baseBorderSide {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return BorderSide.none;
      case AppButtonVariant.secondary:
        return const BorderSide(
          color: AppColors.borderStrong,
          width: 1.5,
        );
      case AppButtonVariant.danger:
        return const BorderSide(
          color: AppColors.danger,
          width: 1.5,
        );
      case AppButtonVariant.ghost:
        return BorderSide.none;
    }
  }

  Color get _contentColor {
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

  // ─── Shape helpers ────────────────────────────────────────────────────────

  bool get _useChamfer =>
      widget.variant == AppButtonVariant.primary && widget.chamfer;

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
    if (!_isInteractive) return;
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

    Widget button = _buildButtonBody(sd, dur, reduced);

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
      label: widget.loading ? '${widget.label}, cargando' : null,
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
            widget.onPressed?.call();
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

    if (widget.expand) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return button;
  }

  Widget _buildButtonBody(_SizeData sd, Duration dur, bool reduced) {
    // The strategy for primary gradient:
    // - AnimatedContainer handles shadows, border, and background color.
    // - For the primary variant, a gradient DecoratedBox is stacked underneath the content.
    // - ClipRRect (or ClipPath for chamfer) clips the whole thing.

    if (_useChamfer) {
      return _buildChamferPrimaryButton(sd, dur);
    }

    return _buildStandardButton(sd, dur);
  }

  Widget _buildStandardButton(_SizeData sd, Duration dur) {
    final isPrimary = widget.variant == AppButtonVariant.primary;

    Widget content = _buildContent(sd);

    // For primary: gradient fill + shadows via Stack approach
    if (isPrimary) {
      return GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedContainer(
          duration: dur,
          curve: AppMotion.easeStandard,
          height: sd.height,
          decoration: BoxDecoration(
            gradient: AppColors.gradGold,
            borderRadius: AppDimens.brM,
            boxShadow: _shadows,
          ),
          child: ClipRRect(
            borderRadius: AppDimens.brM,
            child: SizedBox(
              height: sd.height,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: sd.hPad),
                child: Center(child: content),
              ),
            ),
          ),
        ),
      );
    }

    // Non-primary: single AnimatedContainer handles everything
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedContainer(
        duration: dur,
        curve: AppMotion.easeStandard,
        height: sd.height,
        decoration: BoxDecoration(
          color: _fillColor,
          borderRadius: AppDimens.brM,
          border: Border.fromBorderSide(_borderSide),
          boxShadow: _shadows,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: sd.hPad),
          child: Center(child: content),
        ),
      ),
    );
  }

  Widget _buildChamferPrimaryButton(_SizeData sd, Duration dur) {
    // Chamfer primary: gradient fill clipped to chamfer path, shadows via outer container.
    Widget content = _buildContent(sd);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedContainer(
        duration: dur,
        curve: AppMotion.easeStandard,
        height: sd.height,
        decoration: ShapeDecoration(
          shape: const ChamferBorder(chamfer: AppDimens.chamferM),
          gradient: AppColors.gradGold,
          shadows: _shadows,
        ),
        child: ClipPath(
          clipper: const ChamferClipper(chamfer: AppDimens.chamferM),
          child: SizedBox(
            height: sd.height,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: sd.hPad),
              child: Center(child: content),
            ),
          ),
        ),
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
          valueColor: AlwaysStoppedAnimation<Color>(_contentColor),
        ),
      );
    }

    final label = Text(
      widget.label.toUpperCase(),
      style: sd.textStyle.copyWith(color: _contentColor),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (widget.leadingIcon == null) return label;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          widget.leadingIcon,
          size: sd.iconSize,
          color: _contentColor,
        ),
        SizedBox(width: sd.gap),
        label,
      ],
    );
  }
}

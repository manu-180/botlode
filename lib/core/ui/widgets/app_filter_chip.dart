// lib/core/ui/widgets/app_filter_chip.dart
// Chip de filtro canónico «Hangar OS».
// Implementa: 7 estados de interacción (default, hover, pressed, selected,
// selected+hover, focused, disabled), glow dorado, focus ring cyan y
// reduced-motion.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_dimens.dart';
import '../../config/theme/app_motion.dart';
import '../../config/theme/app_text_styles.dart';
import 'app_badge.dart';

// ─── Spec-defined constants ───────────────────────────────────────────────────

const double _kChipHeight = 32;

// Two glow variants for selected state per spec.
// selected default → AppDimens.glowGold (blurRadius 24, spreadRadius 1).
// selected+hover   → one step more intense.
const List<BoxShadow> _kGlowGoldSelectedHover = [
  BoxShadow(color: AppColors.goldGlow, blurRadius: 32, spreadRadius: 2),
];

// ─── AppFilterChip ────────────────────────────────────────────────────────────

class AppFilterChip extends StatefulWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.count,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  /// When non-null, renders an [AppBadge] to the right of the label.
  final int? count;
  final bool enabled;

  @override
  State<AppFilterChip> createState() => _AppFilterChipState();
}

class _AppFilterChipState extends State<AppFilterChip> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  void didUpdateWidget(AppFilterChip old) {
    super.didUpdateWidget(old);
    if (old.enabled && !widget.enabled) {
      _hovered = false;
      _pressed = false;
      _focused = false;
    }
  }

  // ─── Derived visual tokens ─────────────────────────────────────────────────

  /// Fill color driven by the full interaction state matrix.
  Color get _fillColor {
    if (!widget.enabled) return AppColors.surface;

    if (widget.selected) {
      // selected+hover
      if (_hovered) return AppColors.gold.withValues(alpha: 0.22);
      // selected default
      return AppColors.gold.withValues(alpha: 0.16);
    }

    // Unselected states
    if (_pressed) return AppColors.surfaceHud;
    if (_hovered) return AppColors.surfaceRaised;
    return AppColors.surface;
  }

  /// Border derived from state matrix.
  Border get _border {
    if (!widget.enabled) {
      return Border.all(color: AppColors.borderSubtle, width: 1);
    }

    if (widget.selected) {
      return Border.all(color: AppColors.borderGold, width: 1.5);
    }

    if (_pressed || _hovered) {
      return Border.all(color: AppColors.borderStrong, width: 1);
    }

    return Border.all(color: AppColors.borderDefault, width: 1);
  }

  /// Box shadows: glow when selected (stronger on selected+hover), none otherwise.
  List<BoxShadow> get _shadows {
    if (!widget.enabled || !widget.selected) return const [];
    if (_hovered) return _kGlowGoldSelectedHover;
    return AppDimens.glowGold;
  }

  /// Content (text + icon) color.
  Color get _contentColor {
    if (!widget.enabled) return AppColors.textTertiary;
    if (widget.selected) return AppColors.goldBright;
    if (_pressed || _hovered) return AppColors.textPrimary;
    return AppColors.textSecondary;
  }

  // ─── Interaction duration ──────────────────────────────────────────────────

  Duration _dur(bool reduced, {bool isSelection = false}) {
    if (reduced) return AppMotion.durCrossfadeReduced;
    return isSelection ? AppMotion.durBase : AppMotion.durFast;
  }

  // ─── Event handlers ────────────────────────────────────────────────────────

  void _onEnter(PointerEnterEvent _) {
    if (!widget.enabled) return;
    setState(() => _hovered = true);
  }

  void _onExit(PointerExitEvent _) {
    if (_hovered) setState(() => _hovered = false);
  }

  void _onTapDown(TapDownDetails _) {
    if (!widget.enabled) return;
    setState(() => _pressed = true);
  }

  void _onTapUp(TapUpDetails _) {
    if (!widget.enabled) return;
    setState(() => _pressed = false);
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() => _pressed = false);
  }

  void _onFocusChange(bool focused) {
    setState(() => _focused = focused);
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);

    // Press scale: disabled entirely when reduced motion is active.
    final double scale = (!reduced && _pressed) ? AppMotion.pressScale : 1.0;

    Widget chip = _buildChipBody(reduced);

    // Press scale animation (P2 pattern).
    chip = AnimatedScale(
      scale: scale,
      duration: _pressed ? AppMotion.durInstant : AppMotion.durFast,
      curve: AppMotion.easeStandard,
      child: chip,
    );

    // Focus ring: always in tree, animates padding+border when focused.
    chip = AnimatedContainer(
      duration: AppMotion.durFast,
      curve: AppMotion.easeStandard,
      padding: EdgeInsets.all(_focused ? 2 : 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimens.radiusPill + 4),
        border: _focused
            ? Border.all(color: AppColors.cyan, width: 2)
            : null,
      ),
      child: chip,
    );

    // Disabled: global opacity 0.4 on the whole widget.
    if (!widget.enabled) {
      chip = Opacity(opacity: 0.4, child: chip);
    }

    // Semantics.
    chip = Semantics(
      button: true,
      selected: widget.selected,
      enabled: widget.enabled,
      label: '${widget.label.toUpperCase()}${widget.count != null ? ", ${widget.count}" : ""}',
      child: chip,
    );

    // Keyboard activation (Space / Enter).
    chip = Focus(
      canRequestFocus: widget.enabled,
      onFocusChange: _onFocusChange,
      onKeyEvent: (node, event) {
        if (widget.enabled && event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space) {
            widget.onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: chip,
    );

    // Mouse cursor + hover tracking.
    chip = MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: _onEnter,
      onExit: _onExit,
      child: chip,
    );

    return chip;
  }

  Widget _buildChipBody(bool reduced) {
    // The selection transition (fill + border + glow) uses durBase;
    // hover transitions use durFast.  We drive both via a single
    // AnimatedContainer that re-evaluates all three whenever state changes.
    // Because selection state changes are structurally distinct from hover,
    // we use durBase as the governing duration for any selected-state change
    // and durFast for pure hover/press changes when not crossing a selection
    // boundary.  Simplest correct approximation: always use durBase when
    // selected, otherwise durFast.
    final Duration dur = _dur(
      reduced,
      isSelection: widget.selected,
    );

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedContainer(
        duration: dur,
        curve: AppMotion.easeStandard,
        height: _kChipHeight,
        decoration: BoxDecoration(
          color: _fillColor,
          borderRadius: BorderRadius.circular(AppDimens.radiusPill),
          border: _border,
          boxShadow: _shadows,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space12),
          child: Center(
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final color = _contentColor;

    final label = Text(
      widget.label.toUpperCase(),
      style: AppTextStyles.label.copyWith(color: color),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    final hasIcon = widget.icon != null;
    final hasCount = widget.count != null;

    if (!hasIcon && !hasCount) return label;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasIcon) ...[
          Icon(widget.icon, size: AppDimens.iconXS, color: color),
          const SizedBox(width: AppDimens.space8),
        ],
        label,
        if (hasCount) ...[
          const SizedBox(width: AppDimens.space8),
          AppBadge(
            text: widget.count.toString(),
            tone: AppBadgeTone.neutral,
          ),
        ],
      ],
    );
  }
}

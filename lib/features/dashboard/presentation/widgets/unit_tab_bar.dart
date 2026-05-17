// lib/features/dashboard/presentation/widgets/unit_tab_bar.dart
// Regleta de 5 tabs HUD para la estación de detalle de unidad.
// Indicador gold deslizante con spring physics, separadores verticales HUD,
// hover/press/focus por segmento, keyboard nav (flechas, Home, End).
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/hud/hud_chamfer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

// ─── Tab descriptors ──────────────────────────────────────────────────────────

class _TabData {
  final String label;
  final IconData icon;
  const _TabData(this.label, this.icon);
}

const List<_TabData> _kTabs = [
  _TabData('DASHBOARD', Icons.speed_rounded),
  _TabData('CONFIG', Icons.tune_rounded),
  _TabData('KNOWLEDGE', Icons.menu_book_rounded),
  _TabData('MOOD', Icons.auto_awesome_rounded),
  _TabData('EMBED', Icons.code_rounded),
];

const int _kTabCount = 5;
const double _kTabBarHeight = 52;
const double _kIndicatorHeight = 3;
// Below this segment width labels are hidden (icon-only mode).
const double _kMinSegmentForLabel = 92;
// 1 px vertical hairline between segments.
const double _kSepWidth = 1;

// ─── Public widget ────────────────────────────────────────────────────────────

class UnitTabBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const UnitTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  State<UnitTabBar> createState() => _UnitTabBarState();
}

class _UnitTabBarState extends State<UnitTabBar>
    with SingleTickerProviderStateMixin {
  // Unbounded so the spring can overshoot the 0–4 range.
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController.unbounded(vsync: this)
      ..value = widget.selectedIndex.toDouble();
  }

  @override
  void didUpdateWidget(UnitTabBar old) {
    super.didUpdateWidget(old);
    if (old.selectedIndex != widget.selectedIndex) {
      _animateTo(widget.selectedIndex);
    }
  }

  void _animateTo(int index) {
    // Reduced-motion: snap directly.
    if (AppMotion.reduced(context)) {
      _ctrl.value = index.toDouble();
      return;
    }
    // Spring from current position to target.
    final sim = SpringSimulation(
      AppMotion.springSoft,
      _ctrl.value,
      index.toDouble(),
      0.0, // initial velocity
    );
    _ctrl.animateWith(sim);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _selectByDelta(int delta) {
    final next = (widget.selectedIndex + delta).clamp(0, _kTabCount - 1);
    if (next != widget.selectedIndex) widget.onTabSelected(next);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Focus(
      // Arrow keys / Home / End navigate between tabs.
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          _selectByDelta(1);
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _selectByDelta(-1);
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.home) {
          widget.onTabSelected(0);
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.end) {
          widget.onTabSelected(_kTabCount - 1);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Semantics(
        explicitChildNodes: true,
        child: SizedBox(
          height: _kTabBarHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              // Each separator is 1 px; there are (tabCount-1) separators.
              final availableWidth =
                  totalWidth - (_kSepWidth * (_kTabCount - 1));
              final segWidth = availableWidth / _kTabCount;
              final showLabels = segWidth >= _kMinSegmentForLabel;

              return Container(
                decoration: const ShapeDecoration(
                  color: AppColors.surfaceHud,
                  shape: ChamferBorder(
                    chamfer: AppDimens.chamferM,
                    side: BorderSide(
                      color: AppColors.borderDefault,
                      width: 1,
                    ),
                  ),
                ),
                child: ClipPath(
                  clipper: const ChamferClipper(chamfer: AppDimens.chamferM),
                  child: AnimatedBuilder(
                    animation: _ctrl,
                    builder: (context, _) {
                      // Indicator left offset, accounting for separators.
                      // Position of segment i: i * (segWidth + _kSepWidth)
                      final rawLeft =
                          _ctrl.value * (segWidth + _kSepWidth) +
                              AppDimens.space8;
                      final indicatorWidth = segWidth - AppDimens.space16;
                      final indicatorLeft = rawLeft.clamp(
                        AppDimens.space8,
                        (totalWidth - indicatorWidth - AppDimens.space8)
                            .toDouble(),
                      );

                      return Stack(
                        children: [
                          // ── Segments row ──────────────────────────────
                          Positioned.fill(
                            child: Row(
                              children: [
                                for (int i = 0; i < _kTabCount; i++) ...[
                                  SizedBox(
                                    width: segWidth,
                                    child: _TabSegment(
                                      index: i,
                                      data: _kTabs[i],
                                      isSelected: widget.selectedIndex == i,
                                      showLabel: showLabels,
                                      onTap: () => widget.onTabSelected(i),
                                    ),
                                  ),
                                  if (i < _kTabCount - 1)
                                    const _VerticalSeparator(),
                                ],
                              ],
                            ),
                          ),
                          // ── Gold indicator ────────────────────────────
                          if (indicatorWidth > 0)
                            Positioned(
                              bottom: 0,
                              left: indicatorLeft,
                              width: indicatorWidth,
                              height: _kIndicatorHeight,
                              child: const DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppColors.gold,
                                  boxShadow: AppDimens.glowGold,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Tab segment ──────────────────────────────────────────────────────────────

class _TabSegment extends StatefulWidget {
  final int index;
  final _TabData data;
  final bool isSelected;
  final bool showLabel;
  final VoidCallback onTap;

  const _TabSegment({
    required this.index,
    required this.data,
    required this.isSelected,
    required this.showLabel,
    required this.onTap,
  });

  @override
  State<_TabSegment> createState() => _TabSegmentState();
}

class _TabSegmentState extends State<_TabSegment> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  Color get _iconColor {
    if (widget.isSelected) return AppColors.gold;
    if (_hovered) return AppColors.textPrimary.withValues(alpha: 0.8);
    return AppColors.textSecondary;
  }

  Color get _labelColor {
    if (widget.isSelected) return AppColors.textPrimary;
    if (_hovered) return AppColors.textPrimary.withValues(alpha: 0.8);
    return AppColors.textSecondary;
  }

  Color get _bgColor {
    if (_pressed) return AppColors.borderDefault;
    if (_hovered) return AppColors.borderSubtle;
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    Widget inner = AnimatedContainer(
      duration: AppMotion.durFast,
      curve: AppMotion.easeStandard,
      height: double.infinity,
      decoration: BoxDecoration(color: _bgColor),
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.space12),
      child: Center(
        child: AnimatedScale(
          scale: _pressed ? AppMotion.pressScale : 1.0,
          duration: AppMotion.durInstant,
          curve: AppMotion.easeEntrance,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.data.icon,
                size: 16,
                color: _iconColor,
              ),
              if (widget.showLabel) ...[
                const SizedBox(width: AppDimens.space8),
                AnimatedDefaultTextStyle(
                  duration: AppMotion.durFast,
                  curve: AppMotion.easeStandard,
                  style: AppTextStyles.label.copyWith(color: _labelColor),
                  child: Text(widget.data.label),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    // Cyan focus ring inset.
    if (_focused) {
      inner = Stack(
        children: [
          inner,
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.cyan, width: 2),
                  borderRadius: BorderRadius.circular(AppDimens.radiusXS),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Semantics(
      selected: widget.isSelected,
      label: '${widget.data.label}, pestaña ${widget.index + 1} de $_kTabCount',
      button: true,
      child: Focus(
        canRequestFocus: true,
        onFocusChange: (f) => setState(() => _focused = f),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() {
            _hovered = false;
            _pressed = false;
          }),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) {
              setState(() => _pressed = false);
              widget.onTap();
            },
            onTapCancel: () => setState(() => _pressed = false),
            onTap: widget.onTap,
            child: inner,
          ),
        ),
      ),
    );
  }
}

// ─── Vertical separator ───────────────────────────────────────────────────────

class _VerticalSeparator extends StatelessWidget {
  const _VerticalSeparator();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _kSepWidth,
      height: _kTabBarHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Hairline
          const Positioned.fill(
            child: ColoredBox(color: AppColors.borderSubtle),
          ),
          // Brighter node at center
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: AppColors.borderDefault,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

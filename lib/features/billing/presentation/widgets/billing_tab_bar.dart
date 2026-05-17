// lib/features/billing/presentation/widgets/billing_tab_bar.dart
// Tab bar HUD de 4 segmentos para el Centro de Crédito.
// Indicador de pastilla dorada deslizante guiado por TabController.animation.
// Keyboard nav (flechas, Home, End), focus cyan, reduced-motion.

import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Tab descriptors ──────────────────────────────────────────────────────────

class _TabData {
  final String label;
  final IconData icon;
  const _TabData(this.label, this.icon);
}

const List<_TabData> _kTabs = [
  _TabData('PLAN', Icons.workspace_premium_outlined),
  _TabData('MÉTODOS', Icons.credit_card_outlined),
  _TabData('FACTURAS', Icons.receipt_long_outlined),
  _TabData('HISTORIAL', Icons.history_outlined),
];

const int _kTabCount = 4;
const double _kTrackHeight = 48;
// Inner padding: the pill indicator breathes inside the track.
const double _kTrackInset = 4;
// Below this per-segment width, labels are hidden (icon-only).
const double _kMinSegmentForLabel = 132;
// 1 px vertical hairline between segments.
const double _kSepWidth = 1;

// Reduced glow for the indicator pill (spec: ~14 blur).
const List<BoxShadow> _kIndicatorGlow = [
  BoxShadow(
    color: AppColors.goldGlow,
    blurRadius: 14,
    spreadRadius: 0,
  ),
];

// ─── Public widget ────────────────────────────────────────────────────────────

class BillingTabBar extends StatelessWidget {
  /// The shared [TabController] — its [animation] drives the indicator position.
  final TabController controller;

  /// When false the tab bar renders at 50 % opacity and ignores all input
  /// (used during the loading state of the billing screen).
  final bool enabled;

  const BillingTabBar({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  void _selectTab(BuildContext context, int index) {
    if (!enabled) return;
    final reduced = AppMotion.reduced(context);
    controller.animateTo(
      index,
      duration: reduced ? Duration.zero : AppMotion.durBase,
      curve: AppMotion.easeStandard,
    );
  }

  void _selectByDelta(BuildContext context, int delta) {
    final next = (controller.index + delta).clamp(0, _kTabCount - 1);
    if (next != controller.index) _selectTab(context, next);
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Focus(
          onKeyEvent: (_, event) {
            if (event is! KeyDownEvent) return KeyEventResult.ignored;
            if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _selectByDelta(context, 1);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _selectByDelta(context, -1);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.home) {
              _selectTab(context, 0);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.end) {
              _selectTab(context, _kTabCount - 1);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Semantics(
            explicitChildNodes: true,
            child: SizedBox(
              height: _kTrackHeight,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final totalWidth = constraints.maxWidth;
                  // Width available for segments inside the inset padding.
                  final innerWidth = totalWidth - _kTrackInset * 2;
                  final availWidth =
                      innerWidth - (_kSepWidth * (_kTabCount - 1));
                  final segWidth = availWidth / _kTabCount;
                  final showLabels = segWidth >= _kMinSegmentForLabel;

                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHud,
                      border: Border.all(
                        color: AppColors.borderDefault,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(AppDimens.radiusM),
                    ),
                    padding: const EdgeInsets.all(_kTrackInset),
                    child: AnimatedBuilder(
                      animation: controller.animation!,
                      builder: (context, _) {
                        // Fractional tab position: 0.0 → 3.0.
                        final pos = controller.animation!.value;
                        // Left edge of the indicator pill.
                        final indicatorLeft = pos * (segWidth + _kSepWidth);

                        return Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            // ── Gold pill indicator (IgnorePointer so taps
                            //    fall through to the segments above) ──────
                            Positioned(
                              left: indicatorLeft,
                              top: 0,
                              bottom: 0,
                              width: segWidth,
                              child: IgnorePointer(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceRaised,
                                    border: Border.all(
                                      color: AppColors.borderGold,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppDimens.radiusS,
                                    ),
                                    boxShadow: _kIndicatorGlow,
                                  ),
                                ),
                              ),
                            ),

                            // ── Segments row ─────────────────────────────
                            Positioned.fill(
                              child: Row(
                                children: [
                                  for (int i = 0; i < _kTabCount; i++) ...[
                                    SizedBox(
                                      width: segWidth,
                                      child: _TabSegment(
                                        index: i,
                                        data: _kTabs[i],
                                        isSelected: controller.index == i,
                                        showLabel: showLabels,
                                        onTap: () => _selectTab(context, i),
                                      ),
                                    ),
                                    if (i < _kTabCount - 1)
                                      const SizedBox(
                                        width: _kSepWidth,
                                        height: double.infinity,
                                        child: ColoredBox(
                                          color: AppColors.borderSubtle,
                                        ),
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
            ),
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

  Color get _contentColor {
    if (widget.isSelected || _hovered) return AppColors.textPrimary;
    return AppColors.textSecondary;
  }

  FontWeight get _weight =>
      widget.isSelected ? FontWeight.w700 : FontWeight.w600;

  @override
  Widget build(BuildContext context) {
    Widget inner = AnimatedContainer(
      duration: AppMotion.durFast,
      curve: AppMotion.easeStandard,
      height: double.infinity,
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
                color: _contentColor,
              ),
              if (widget.showLabel) ...[
                const SizedBox(width: AppDimens.space8),
                AnimatedDefaultTextStyle(
                  duration: AppMotion.durFast,
                  curve: AppMotion.easeStandard,
                  style: AppTextStyles.label.copyWith(
                    color: _contentColor,
                    fontWeight: _weight,
                  ),
                  child: Text(widget.data.label),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    // Cyan 2 px focus ring inset.
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
      label:
          'Pestaña ${widget.data.label}, ${widget.index + 1} de $_kTabCount',
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

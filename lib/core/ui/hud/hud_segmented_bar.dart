// lib/core/ui/hud/hud_segmented_bar.dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_dimens.dart';
import '../../config/theme/app_motion.dart';

class HudSegmentedBar extends StatefulWidget {
  final double value;

  const HudSegmentedBar({super.key, required this.value});

  @override
  State<HudSegmentedBar> createState() => _HudSegmentedBarState();
}

class _HudSegmentedBarState extends State<HudSegmentedBar> {
  static const int _segmentCount = 28;
  static const double _segmentWidth = 4.0;
  static const double _segmentHeight = 10.0;
  static const double _segmentGap = 3.0;
  // Sub-token: half of AppDimens.radiusXS (6), intentional for tight segment cells.
  static const double _kSegmentRadius = 3.0;
  // Sub-token: per-segment tick below AppMotion.durInstant (90ms), intentional for bar fill animation.
  static const int _tickMs = 14;

  late int _displayedLit;
  Timer? _timer;

  int get _litCount =>
      (widget.value.clamp(0.0, 1.0) * _segmentCount).round();

  Color get _segmentColor {
    final v = widget.value;
    if (v >= 1.0) return AppColors.danger;
    if (v > 0.70) return AppColors.warning;
    return AppColors.success;
  }

  @override
  void initState() {
    super.initState();
    _displayedLit = 0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_timer == null && _displayedLit == 0) {
      _startSequence();
    }
  }

  @override
  void didUpdateWidget(HudSegmentedBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newLit = _litCount;
    final oldLit = (oldWidget.value.clamp(0.0, 1.0) * _segmentCount).round();
    if (newLit != oldLit) {
      _startSequence();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startSequence() {
    if (!mounted) return;
    final isReduced = AppMotion.isReduced(context);
    if (isReduced) {
      setState(() => _displayedLit = _litCount);
      return;
    }

    _timer?.cancel();
    final target = _litCount;

    if (_displayedLit == target) return;

    _timer = Timer.periodic(
      const Duration(milliseconds: _tickMs),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          if (_displayedLit < target) {
            _displayedLit++;
          } else if (_displayedLit > target) {
            _displayedLit--;
          }
          if (_displayedLit == target) timer.cancel();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isReduced = AppMotion.isReduced(context);
    final color = _segmentColor;
    final glow = AppDimens.glowStatus(color);

    return IgnorePointer(
      child: SizedBox(
        width: _segmentCount * _segmentWidth + (_segmentCount - 1) * _segmentGap,
        height: _segmentHeight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_segmentCount * 2 - 1, (i) {
            if (i.isOdd) {
              return const SizedBox(width: _segmentGap);
            }

            final index = i ~/ 2;
            final isLit = index < _displayedLit;

            final decoration = BoxDecoration(
              color: isLit ? color : AppColors.surfaceHud,
              borderRadius: BorderRadius.circular(_kSegmentRadius),
              border: isLit
                  ? null
                  : Border.all(color: AppColors.borderSubtle, width: 1),
              boxShadow: isLit ? glow : null,
            );

            if (isReduced) {
              return SizedBox(
                width: _segmentWidth,
                height: _segmentHeight,
                child: DecoratedBox(decoration: decoration),
              );
            }

            return SizedBox(
              width: _segmentWidth,
              height: _segmentHeight,
              child: AnimatedContainer(
                duration: AppMotion.durFast,
                curve: AppMotion.easeStandard,
                decoration: decoration,
              ),
            );
          }),
        ),
      ),
    );
  }
}

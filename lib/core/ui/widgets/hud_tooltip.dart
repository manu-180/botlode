// lib/core/ui/widgets/hud_tooltip.dart
// HudTooltip — Tooltip con estética HUD Hangar OS.
// Fondo surfaceRaised, borde borderGold, fuente mono, micro-flecha, delay 400 ms.
import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_dimens.dart';
import '../../config/theme/app_motion.dart';
import '../../config/theme/app_text_styles.dart';

enum TooltipPosition { top, bottom, left, right }

// ─── Public widget ────────────────────────────────────────────────────────────

class HudTooltip extends StatefulWidget {
  const HudTooltip({
    super.key,
    required this.child,
    required this.message,
    this.preferred = TooltipPosition.top,
  });

  final Widget child;
  final String message;
  final TooltipPosition preferred;

  @override
  State<HudTooltip> createState() => _HudTooltipState();
}

class _HudTooltipState extends State<HudTooltip>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _entry;
  Timer? _showTimer;
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;
  final _link = LayerLink();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppMotion.durFast);
    _opacity = CurvedAnimation(parent: _ctrl, curve: AppMotion.easeEntrance);
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: AppMotion.easeEntrance),
    );
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    _removeOverlay();
    _ctrl.dispose();
    super.dispose();
  }

  void _onEnter(PointerEnterEvent _) {
    _showTimer?.cancel();
    _showTimer = Timer(const Duration(milliseconds: 400), _show);
  }

  void _onExit(PointerExitEvent _) {
    _showTimer?.cancel();
    _hide();
  }

  void _show() {
    if (_entry != null || !mounted) return;
    final reduce = AppMotion.reduced(context);
    _ctrl.duration =
        reduce ? AppMotion.durCrossfadeReduced : AppMotion.durFast;
    _entry = OverlayEntry(
      builder: (_) => _TooltipOverlay(
        link: _link,
        message: widget.message,
        preferred: widget.preferred,
        opacity: _opacity,
        scale: _scale,
        reduced: reduce,
      ),
    );
    Overlay.of(context).insert(_entry!);
    _ctrl.forward(from: 0);
  }

  void _hide() {
    if (_entry == null) return;
    final reduce = AppMotion.reduced(context);
    final exitDur = reduce
        ? AppMotion.durCrossfadeReduced
        : AppMotion.exitOf(AppMotion.durFast);
    _ctrl.animateBack(0, duration: exitDur, curve: AppMotion.easeExit).then((_) {
      _removeOverlay();
    });
  }

  void _removeOverlay() {
    _entry?.remove();
    _entry = null;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.message,
      child: MouseRegion(
        onEnter: _onEnter,
        onExit: _onExit,
        child: CompositedTransformTarget(
          link: _link,
          child: widget.child,
        ),
      ),
    );
  }
}

// ─── Overlay widget ───────────────────────────────────────────────────────────

class _TooltipOverlay extends StatelessWidget {
  const _TooltipOverlay({
    required this.link,
    required this.message,
    required this.preferred,
    required this.opacity,
    required this.scale,
    required this.reduced,
  });

  final LayerLink link;
  final String message;
  final TooltipPosition preferred;
  final Animation<double> opacity;
  final Animation<double> scale;
  final bool reduced;

  Alignment get _targetAnchor => switch (preferred) {
        TooltipPosition.top => Alignment.topCenter,
        TooltipPosition.bottom => Alignment.bottomCenter,
        TooltipPosition.left => Alignment.centerLeft,
        TooltipPosition.right => Alignment.centerRight,
      };

  Alignment get _followerAnchor => switch (preferred) {
        TooltipPosition.top => Alignment.bottomCenter,
        TooltipPosition.bottom => Alignment.topCenter,
        TooltipPosition.left => Alignment.centerRight,
        TooltipPosition.right => Alignment.centerLeft,
      };

  Offset get _gap => switch (preferred) {
        TooltipPosition.top => const Offset(0, -6),
        TooltipPosition.bottom => const Offset(0, 6),
        TooltipPosition.left => const Offset(-6, 0),
        TooltipPosition.right => const Offset(6, 0),
      };

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CompositedTransformFollower(
        link: link,
        targetAnchor: _targetAnchor,
        followerAnchor: _followerAnchor,
        offset: _gap,
        showWhenUnlinked: false,
        child: AnimatedBuilder(
          animation: opacity,
          builder: (_, child) => FadeTransition(
            opacity: opacity,
            child: reduced
                ? child!
                : ScaleTransition(
                    scale: scale,
                    alignment: _followerAnchor,
                    child: child,
                  ),
          ),
          child: _TooltipBox(message: message, direction: preferred),
        ),
      ),
    );
  }
}

// ─── Tooltip box with arrow ───────────────────────────────────────────────────

class _TooltipBox extends StatelessWidget {
  const _TooltipBox({required this.message, required this.direction});

  final String message;
  final TooltipPosition direction;

  bool get _isVertical =>
      direction == TooltipPosition.top || direction == TooltipPosition.bottom;

  Size get _arrowSize =>
      _isVertical ? const Size(12, 6) : const Size(6, 12);

  @override
  Widget build(BuildContext context) {
    final box = Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space8,
        vertical: AppDimens.space4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppDimens.brS,
        border: Border.all(color: AppColors.borderGold, width: 1),
        boxShadow: AppDimens.elev2,
      ),
      child: Text(
        message,
        style: AppTextStyles.mono.copyWith(color: AppColors.textPrimary),
        softWrap: true,
      ),
    );

    final arrow = SizedBox.fromSize(
      size: _arrowSize,
      child: CustomPaint(painter: _ArrowPainter(direction: direction)),
    );

    if (_isVertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: direction == TooltipPosition.top
            ? [box, arrow]
            : [arrow, box],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: direction == TooltipPosition.left
          ? [box, arrow]
          : [arrow, box],
    );
  }
}

// ─── Arrow painter ────────────────────────────────────────────────────────────

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({required this.direction});

  final TooltipPosition direction;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = AppColors.surfaceRaised
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = AppColors.borderGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = _path(size);
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  Path _path(Size s) {
    final p = Path();
    switch (direction) {
      case TooltipPosition.top:
        // arrow points down toward child below
        p.moveTo(0, 0);
        p.lineTo(s.width, 0);
        p.lineTo(s.width / 2, s.height);
      case TooltipPosition.bottom:
        // arrow points up toward child above
        p.moveTo(s.width / 2, 0);
        p.lineTo(s.width, s.height);
        p.lineTo(0, s.height);
      case TooltipPosition.left:
        // arrow points right toward child
        p.moveTo(0, 0);
        p.lineTo(s.width, s.height / 2);
        p.lineTo(0, s.height);
      case TooltipPosition.right:
        // arrow points left toward child
        p.moveTo(s.width, 0);
        p.lineTo(0, s.height / 2);
        p.lineTo(s.width, s.height);
    }
    p.close();
    return p;
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => old.direction != direction;
}

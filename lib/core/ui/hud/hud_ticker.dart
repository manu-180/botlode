// lib/core/ui/hud/hud_ticker.dart
// Texto numérico mono con figuras tabulares que cuenta hacia su valor.
// Generaliza AnimatedTicker existente. Respeta reduced-motion.
import 'package:flutter/material.dart';
import '../../config/theme/app_motion.dart';
import '../../config/theme/app_text_styles.dart';

class HudTicker extends StatefulWidget {
  final double value;
  final String prefix;
  final String suffix;
  final int decimals;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;

  const HudTicker({
    super.key,
    required this.value,
    this.prefix = '',
    this.suffix = '',
    this.decimals = 0,
    this.style,
    this.duration = AppMotion.durTicker,
    this.curve = AppMotion.easeTicker,
  });

  @override
  State<HudTicker> createState() => _HudTickerState();
}

class _HudTickerState extends State<HudTicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late Animation<double> _anim;
  double _fromValue = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _anim = AlwaysStoppedAnimation(widget.value);
    _fromValue = widget.value;
  }

  @override
  void didUpdateWidget(HudTicker old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _fromValue = _anim.value;
      _ctrl.duration = widget.duration;
      _anim = Tween<double>(begin: _fromValue, end: widget.value)
          .animate(CurvedAnimation(parent: _ctrl, curve: widget.curve));
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.isReduced(context);
    final style = widget.style ?? AppTextStyles.numericTicker;

    if (reduced) {
      return Text(
        _formatValue(widget.value),
        style: style,
      );
    }

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Text(
        _formatValue(_anim.value),
        style: style,
      ),
    );
  }

  String _formatValue(double v) =>
      '${widget.prefix}${v.toStringAsFixed(widget.decimals)}${widget.suffix}';
}

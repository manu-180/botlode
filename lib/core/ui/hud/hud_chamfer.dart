// lib/core/ui/hud/hud_chamfer.dart
// ShapeBorder y Clipper con cantos biselados a 45° (chamfer).
// Usar en paneles HUD principales y botones destacados — no en cada caja.
import 'package:flutter/material.dart';
import '../../config/theme/app_dimens.dart';

/// Recorta el widget con esquinas biseladas a 45°.
class ChamferClipper extends CustomClipper<Path> {
  final double chamfer;

  const ChamferClipper({this.chamfer = AppDimens.chamferM});

  @override
  Path getClip(Size size) {
    final c = chamfer;
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(c, 0)
      ..lineTo(w - c, 0)
      ..lineTo(w, c)
      ..lineTo(w, h - c)
      ..lineTo(w - c, h)
      ..lineTo(c, h)
      ..lineTo(0, h - c)
      ..lineTo(0, c)
      ..close();
  }

  @override
  bool shouldReclip(ChamferClipper old) => old.chamfer != chamfer;
}

/// ShapeBorder con cantos biselados — úsalo en Container.decoration o BoxDecoration.
class ChamferBorder extends ShapeBorder {
  final double chamfer;
  final BorderSide side;

  const ChamferBorder({
    this.chamfer = AppDimens.chamferM,
    this.side = const BorderSide(color: Colors.transparent),
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _buildPath(rect.deflate(side.width));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _buildPath(rect);

  Path _buildPath(Rect r) {
    final c = chamfer;
    return Path()
      ..moveTo(r.left + c, r.top)
      ..lineTo(r.right - c, r.top)
      ..lineTo(r.right, r.top + c)
      ..lineTo(r.right, r.bottom - c)
      ..lineTo(r.right - c, r.bottom)
      ..lineTo(r.left + c, r.bottom)
      ..lineTo(r.left, r.bottom - c)
      ..lineTo(r.left, r.top + c)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width == 0) return;
    canvas.drawPath(
      getOuterPath(rect),
      side.toPaint(),
    );
  }

  @override
  ShapeBorder scale(double t) => ChamferBorder(
        chamfer: chamfer * t,
        side: side.scale(t),
      );

  ChamferBorder copyWith({double? chamfer, BorderSide? side}) => ChamferBorder(
        chamfer: chamfer ?? this.chamfer,
        side: side ?? this.side,
      );
}

/// Widget conveniente: recorta su hijo con cantos biselados y dibuja un borde.
class ChamferBox extends StatelessWidget {
  final Widget child;
  final double chamfer;
  final Color? fillColor;
  final BorderSide border;

  const ChamferBox({
    super.key,
    required this.child,
    this.chamfer = AppDimens.chamferM,
    this.fillColor,
    this.border = BorderSide.none,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: ChamferClipper(chamfer: chamfer),
      child: CustomPaint(
        painter: fillColor != null
            ? _FillPainter(chamfer: chamfer, color: fillColor!)
            : null,
        foregroundPainter: border.style != BorderStyle.none
            ? _BorderPainter(chamfer: chamfer, side: border)
            : null,
        child: child,
      ),
    );
  }
}

class _FillPainter extends CustomPainter {
  final double chamfer;
  final Color color;
  const _FillPainter({required this.chamfer, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = ChamferClipper(chamfer: chamfer)
        .getClip(size);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_FillPainter old) =>
      old.chamfer != chamfer || old.color != color;
}

class _BorderPainter extends CustomPainter {
  final double chamfer;
  final BorderSide side;
  const _BorderPainter({required this.chamfer, required this.side});

  @override
  void paint(Canvas canvas, Size size) {
    final path = ChamferClipper(chamfer: chamfer).getClip(size);
    canvas.drawPath(path, side.toPaint());
  }

  @override
  bool shouldRepaint(_BorderPainter old) =>
      old.chamfer != chamfer || old.side != side;
}

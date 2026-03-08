import 'package:flutter/material.dart';

/// Arrow thumb — custom [SliderComponentShape].
///
/// A rounded rectangle body with a pointed arrow tip at
/// the bottom, matching the blue-arrow screenshot reference.
class ArrowThumbShape extends SliderComponentShape {
  final double thumbWidth;
  final double thumbHeight;

  const ArrowThumbShape({this.thumbWidth = 18, this.thumbHeight = 30});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(thumbWidth, thumbHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final color = sliderTheme.thumbColor ?? const Color(0xFF6FA8DC);

    final w = thumbWidth;
    final h = thumbHeight;
    final halfW = w / 2;
    final r = w * 0.24; // corner radius

    // The body sits above center, arrow tip at center
    final top = center.dy - h * 0.75;
    final bodyBottom = center.dy - h * 0.1;
    final arrowTip = center.dy + h * 0.25;

    final path = Path();
    // Top-left rounded corner
    path.moveTo(center.dx - halfW, top + r);
    path.quadraticBezierTo(center.dx - halfW, top, center.dx - halfW + r, top);
    // Top edge
    path.lineTo(center.dx + halfW - r, top);
    // Top-right rounded corner
    path.quadraticBezierTo(center.dx + halfW, top, center.dx + halfW, top + r);
    // Right edge down to body bottom
    path.lineTo(center.dx + halfW, bodyBottom);
    // Arrow point
    path.lineTo(center.dx, arrowTip);
    // Left edge back up
    path.lineTo(center.dx - halfW, bodyBottom);
    path.close();

    // Subtle shadow
    canvas.drawShadow(path, const Color(0x30000000), 4, true);

    // Fill
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
  }
}

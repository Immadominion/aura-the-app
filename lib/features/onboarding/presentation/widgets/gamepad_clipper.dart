import 'package:flutter/material.dart';

/// Gamepad-shaped clip path used for the Rive illustration.
///
/// Shape anatomy (clockwise from top-left):
///  - Full-width rounded body at the top (~42% of height)
///  - Right grip: flares slightly outward with a cubic curve,
///    then drops to the bottom-right with rounded corner
///  - Concave valley: symmetric cubic pulled up to ~70% height,
///    forming the classic gap between the two grips
///  - Left grip: mirror of right
class GamepadClipper extends CustomClipper<Path> {
  const GamepadClipper();

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    const r = 18.0; // corner radius

    return Path()
      // ── Top edge ──
      ..moveTo(r, 0)
      ..lineTo(w - r, 0)
      ..quadraticBezierTo(w, 0, w, r) // top-right corner
      // ── Right body side ──
      ..lineTo(w, h * 0.42)
      // ── Right grip: flares outward, drops to bottom ──
      ..cubicTo(w, h * 0.52, w * 1.025, h * 0.63, w * 0.975, h * 0.77)
      ..lineTo(w * 0.965, h - r)
      ..quadraticBezierTo(w * 0.965, h, w * 0.965 - r, h) // bottom-right corner
      // ── Bottom of right grip → valley ──
      ..lineTo(w * 0.62, h)
      ..cubicTo(w * 0.62, h * 0.70, w * 0.38, h * 0.70, w * 0.38, h)
      // ── Bottom of left grip ──
      ..lineTo(w * 0.035 + r, h)
      ..quadraticBezierTo(w * 0.035, h, w * 0.035, h - r) // bottom-left corner
      // ── Left grip: rises, flares outward, back to body ──
      ..lineTo(w * 0.025, h * 0.77)
      ..cubicTo(-w * 0.025, h * 0.63, 0, h * 0.52, 0, h * 0.42)
      // ── Left body side ──
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0) // top-left corner
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

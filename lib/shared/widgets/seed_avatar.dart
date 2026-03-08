import 'dart:math';
import 'package:flutter/material.dart';

/// Local deterministic avatar — no network dependency.
///
/// Generates a unique geometric avatar from a seed string (e.g. wallet address).
/// Uses the seed's hashCode to derive colors and pattern, so the same seed
/// always produces the same avatar.
class SeedAvatar extends StatelessWidget {
  final String seed;
  final double size;

  const SeedAvatar({super.key, required this.seed, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _SeedAvatarPainter(seed)),
      ),
    );
  }
}

class _SeedAvatarPainter extends CustomPainter {
  final String seed;

  _SeedAvatarPainter(this.seed);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(seed.hashCode);
    final w = size.width;
    final h = size.height;

    // ── Background — pastel hue from seed ──
    final hue = rng.nextDouble() * 360;
    final bgColor = HSLColor.fromAHSL(1, hue, 0.45, 0.88).toColor();
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = bgColor);

    // ── Foreground accent ──
    final fgColor = HSLColor.fromAHSL(
      1,
      (hue + 120 + rng.nextDouble() * 60) % 360,
      0.55,
      0.55,
    ).toColor();

    // ── Draw a symmetric 5×5 grid pattern (mirrored horizontally) ──
    // Only compute left half + center, mirror to right.
    final gridSize = 5;
    final cellW = w / gridSize;
    final cellH = h / gridSize;
    final paint = Paint()..color = fgColor;

    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col <= gridSize ~/ 2; col++) {
        if (rng.nextBool()) {
          // Left side
          canvas.drawRect(
            Rect.fromLTWH(col * cellW, row * cellH, cellW, cellH),
            paint,
          );
          // Mirror — right side
          final mirrorCol = gridSize - 1 - col;
          if (mirrorCol != col) {
            canvas.drawRect(
              Rect.fromLTWH(mirrorCol * cellW, row * cellH, cellW, cellH),
              paint,
            );
          }
        }
      }
    }

    // ── Central accent circle ──
    final circleColor = HSLColor.fromAHSL(
      0.35,
      (hue + 200) % 360,
      0.6,
      0.65,
    ).toColor();
    canvas.drawCircle(
      Offset(w / 2, h / 2),
      w * 0.18,
      Paint()..color = circleColor,
    );
  }

  @override
  bool shouldRepaint(_SeedAvatarPainter old) => old.seed != seed;
}

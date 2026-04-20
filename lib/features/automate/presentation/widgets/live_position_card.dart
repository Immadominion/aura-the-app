import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura/core/models/bot.dart';
import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_radii.dart';

/// Card showing a single live position with PnL and hold time.
class LivePositionCard extends StatelessWidget {
  final LivePosition position;
  final AuraColors c;
  final TextTheme text;

  const LivePositionCard({
    super.key,
    required this.position,
    required this.c,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final pnlPct = position.pnlPercent;
    final pnlColor = pnlPct >= 0 ? c.profit : c.loss;
    final pnlStr = pnlPct >= 0
        ? '+${pnlPct.toStringAsFixed(2)}%'
        : '${pnlPct.toStringAsFixed(2)}%';
    final hold = position.holdDuration;
    final holdStr = hold.inMinutes < 60
        ? '${hold.inMinutes}m'
        : '${hold.inHours}h ${hold.inMinutes % 60}m';

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(14.w),
      decoration: ShapeDecoration(
        color: c.surface,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(context.auraRadii.md),
          side: BorderSide(color: c.borderSubtle),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      position.poolName ?? position.poolAddress.substring(0, 8),
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                        fontSize: 13.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${position.status} · Hold: $holdStr',
                      style: text.labelSmall?.copyWith(
                        color: c.textTertiary,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                pnlStr,
                style: text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: pnlColor,
                  fontSize: 13.sp,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          // Inline bin-drift indicator (audit §5.7). Live positions don't
          // carry binStep, so we use PnL% clamped to ±5% as a proxy for
          // drift. The marker turns warning-coloured if it strays out of
          // the central in-range band.
          Builder(
            builder: (context) {
              final driftNorm = (pnlPct / 5.0).clamp(-1.0, 1.0);
              final inBand = driftNorm.abs() <= 0.6;
              return SizedBox(
                height: 6.h,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _BinRowPainter(
                    driftNorm: driftNorm,
                    trackColor: c.borderSubtle,
                    bandColor: c.accent.withValues(alpha: 0.22),
                    markerColor: inBand ? c.profit : c.warning,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BinRowPainter extends CustomPainter {
  final double driftNorm; // -1..1
  final Color trackColor;
  final Color bandColor;
  final Color markerColor;

  _BinRowPainter({
    required this.driftNorm,
    required this.trackColor,
    required this.bandColor,
    required this.markerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final radius = size.height / 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ),
      Paint()..color = trackColor,
    );

    final bandRect = Rect.fromLTWH(
      size.width * 0.2,
      0,
      size.width * 0.6,
      size.height,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bandRect, Radius.circular(radius)),
      Paint()..color = bandColor,
    );

    final markerX = size.width / 2 + driftNorm * (size.width / 2 - radius);
    canvas.drawCircle(
      Offset(markerX, midY),
      radius + 1,
      Paint()..color = markerColor,
    );
  }

  @override
  bool shouldRepaint(covariant _BinRowPainter old) =>
      old.driftNorm != driftNorm || old.markerColor != markerColor;
}

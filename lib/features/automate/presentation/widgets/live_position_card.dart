import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura/core/models/bot.dart';
import 'package:aura/core/theme/app_colors.dart';

/// Card showing a single live position with PnL and hold time.
class LivePositionCard extends StatelessWidget {
  final LivePosition position;
  final SageColors c;
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
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: c.borderSubtle),
      ),
      child: Row(
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
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_theme.dart';
import 'package:aura/features/automate/models/strategy_state.dart';
import 'package:aura/features/automate/presentation/widgets/pulsing_dot.dart';

/// Strategy card — clean minimal row on dark canvas.
/// No heavy containers. State communicated via dot + label inline.
class StrategyCard extends StatelessWidget {
  final String botId;
  final String name;
  final String trigger;
  final String lastAction;
  final String pnl;
  final StrategyState state;

  const StrategyCard({
    super.key,
    required this.botId,
    required this.name,
    required this.trigger,
    required this.lastAction,
    required this.pnl,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sage;
    final text = context.sageText;

    final Color stateColor;
    final String stateLabel;

    switch (state) {
      case StrategyState.running:
        stateColor = c.profit;
        stateLabel = 'Running';
      case StrategyState.watching:
        stateColor = c.warning;
        stateLabel = 'Stopped';
      case StrategyState.paused:
        stateColor = c.textTertiary;
        stateLabel = 'Stopped';
      case StrategyState.notStarted:
        stateColor = c.textTertiary;
        stateLabel = 'Not Started';
    }

    final pnlColor = pnl.startsWith('-')
        ? c.loss
        : pnl.startsWith('+')
        ? c.profit
        : c.textSecondary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        context.push('/strategy/$botId');
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: state dot + name ── pnl ──
            Row(
              children: [
                // State indicator
                if (state == StrategyState.running)
                  PulsingDot(color: stateColor, size: 7)
                else
                  Container(
                    width: 7.w,
                    height: 7.w,
                    decoration: BoxDecoration(
                      color: stateColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                SizedBox(width: 10.w),
                // Name
                Expanded(
                  child: Text(
                    name,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                      fontSize: 15.sp,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 12.w),
                // PnL
                Text(
                  pnl,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: pnlColor,
                    fontSize: 15.sp,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),

            // ── Detail row: trigger · state label · last action ──
            Padding(
              padding: EdgeInsets.only(left: 17.w, top: 4.h),
              child: Row(
                children: [
                  Text(
                    stateLabel,
                    style: text.labelSmall?.copyWith(
                      color: stateColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.sp,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    child: Text(
                      '·',
                      style: text.labelSmall?.copyWith(
                        color: c.textTertiary,
                        fontSize: 11.sp,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      lastAction,
                      style: text.labelSmall?.copyWith(
                        color: c.textTertiary,
                        fontSize: 11.sp,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    PhosphorIconsBold.caretRight,
                    size: 12.sp,
                    color: c.textTertiary.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

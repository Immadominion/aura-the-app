import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:sage/core/theme/app_colors.dart';
import 'package:sage/features/fleet/models/fleet_models.dart';

/// Fleet leaderboard card — minimal row matching Automate's StrategyCard.
/// State dot + rank + name on left, PnL on right.
/// Tags below as colorful rounded pills (like status badges).
class FleetCard extends StatelessWidget {
  final FleetEntry entry;
  final SageColors c;
  final TextTheme text;

  const FleetCard({
    super.key,
    required this.entry,
    required this.c,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final profitable = entry.pnlSol >= 0;
    final pnlColor = profitable ? c.profit : c.loss;
    final pnlSign = profitable ? '+' : '';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () {
        // Copy bot ID to clipboard
        Clipboard.setData(ClipboardData(text: entry.botId));
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Bot ID copied: ${entry.botId}',
              style: TextStyle(color: c.textPrimary, fontSize: 13.sp),
            ),
            backgroundColor: c.surface,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: rank + name ── pnl ──
            Row(
              children: [
                // Rank
                _RankIndicator(rank: entry.rank, c: c, text: text),
                SizedBox(width: 10.w),
                // Name + owner
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                          fontSize: 15.sp,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        entry.owner,
                        style: text.labelSmall?.copyWith(
                          color: entry.isOwn ? c.accent : c.textTertiary,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                // PnL
                Text(
                  '$pnlSign${entry.pnlSol.toStringAsFixed(3)} SOL',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: pnlColor,
                    fontSize: 14.sp,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),

            SizedBox(height: 8.h),

            // ── Tags row — colorful pills ──
            Padding(
              padding: EdgeInsets.only(left: 34.w),
              child: Wrap(
                spacing: 6.w,
                runSpacing: 6.h,
                children: [
                  // Strategy mode tag
                  _StatusTag(
                    label: _strategyLabel(entry.strategyMode),
                    color: _strategyColor(entry.strategyMode),
                  ),

                  // Status tag
                  _StatusTag(
                    label: _statusLabel(entry.status),
                    color: _statusColor(entry.status, c),
                  ),

                  // Win rate
                  _StatusTag(label: '${entry.winRate}% win', color: c.profit),

                  // Trades
                  _StatusTag(
                    label: '${entry.totalTrades} trades',
                    color: c.info,
                  ),

                  // "You" tag
                  if (entry.isOwn) _StatusTag(label: 'You', color: c.accent),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (entry.rank * 50).ms);
  }

  String _strategyLabel(String mode) {
    switch (mode) {
      case 'rule-based':
        return 'Rule';
      case 'sage-ai':
        return 'AI';
      case 'both':
        return 'Hybrid';
      default:
        return mode;
    }
  }

  IconData _strategyIcon(String mode) {
    switch (mode) {
      case 'sage-ai':
        return PhosphorIconsBold.brain;
      case 'both':
        return PhosphorIconsBold.infinity;
      default:
        return PhosphorIconsBold.gear;
    }
  }

  Color _strategyColor(String mode) {
    switch (mode) {
      case 'sage-ai':
        return const Color(0xFF9B59B6); // purple
      case 'both':
        return const Color(0xFFE67E22); // orange
      default:
        return const Color(0xFF3498DB); // blue
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'running':
        return 'Running';
      case 'stopped':
        return 'Stopped';
      case 'error':
        return 'Error';
      default:
        return status;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'running':
        return PhosphorIconsBold.play;
      case 'stopped':
        return PhosphorIconsBold.pause;
      case 'error':
        return PhosphorIconsBold.warning;
      default:
        return PhosphorIconsBold.circleHalf;
    }
  }

  Color _statusColor(String status, SageColors c) {
    switch (status) {
      case 'running':
        return c.profit;
      case 'error':
        return c.loss;
      default:
        return c.warning;
    }
  }
}

// ─── Rank indicator — inline number with medal colors for top 3 ───

class _RankIndicator extends StatelessWidget {
  final int rank;
  final SageColors c;
  final TextTheme text;

  const _RankIndicator({
    required this.rank,
    required this.c,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final Color fg;
    if (rank == 1) {
      fg = const Color(0xFFFFD700);
    } else if (rank == 2) {
      fg = const Color(0xFFC0C0C0);
    } else if (rank == 3) {
      fg = const Color(0xFFCD7F32);
    } else {
      fg = c.textTertiary;
    }

    return SizedBox(
      width: 24.w,
      child: Text(
        '#$rank',
        style: text.labelMedium?.copyWith(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: 13.sp,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

// ─── Status tag — colorful rounded pill with icon ───
// Matches the reference image: rounded corners, tinted background,
// icon + label, soft color scheme.

class _StatusTag extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(right: 4.w),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationStyle: TextDecorationStyle.dotted,
            ),
          ),
        ],
      ),
    );
  }
}

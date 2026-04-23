import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:aura/core/models/bot_decision.dart';
import 'package:aura/core/repositories/decision_repository.dart';
import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_radii.dart';
import 'package:aura/core/theme/app_theme.dart';

/// Decision Log — Phase 16, audit §6.2.
///
/// Vertical timeline showing per-pool scan decisions: what the bot
/// entered, watched, or skipped — and why.
class DecisionLogScreen extends ConsumerWidget {
  const DecisionLogScreen({super.key, required this.botId});

  final String botId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.aura;
    final text = context.auraText;
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    final decisionsAsync = ref.watch(botDecisionsProvider(botId));

    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        children: [
          // ── Top bar ──
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, topPad + 12.h, 20.w, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.surface,
                      border: Border.all(color: c.borderSubtle, width: 1),
                    ),
                    child: Icon(
                      PhosphorIconsBold.arrowLeft,
                      size: 20.sp,
                      color: c.textSecondary,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'DECISION LOG',
                  style: text.titleSmall?.copyWith(
                    color: c.textTertiary,
                    fontWeight: FontWeight.w800,
                    fontSize: 11.sp,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                SizedBox(width: 36.w),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // ── Body ──
          Expanded(
            child: decisionsAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: c.accent,
                ),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.w),
                  child: Text(
                    'Failed to load decisions',
                    style: text.bodyMedium?.copyWith(color: c.textTertiary),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (decisions) {
                if (decisions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PhosphorIconsBold.magnifyingGlass,
                          size: 48.sp,
                          color: c.textTertiary.withValues(alpha: 0.4),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'No decisions yet',
                          style: text.bodyLarge?.copyWith(
                            color: c.textTertiary,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Start the bot to see scan evaluations',
                          style: text.bodySmall?.copyWith(
                            color: c.textTertiary.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Group by scanId for timeline sections
                final grouped = <String, List<BotDecision>>{};
                for (final d in decisions) {
                  grouped.putIfAbsent(d.scanId, () => []).add(d);
                }
                final scanIds = grouped.keys.toList();

                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, bottomPad + 20.h),
                  itemCount: scanIds.length,
                  itemBuilder: (context, index) {
                    final scanId = scanIds[index];
                    final group = grouped[scanId]!;
                    final ts = group.first.timestamp;
                    return _ScanGroup(
                      scanId: scanId,
                      timestamp: ts,
                      decisions: group,
                    ).animate().fadeIn(
                      delay: Duration(milliseconds: index * 60),
                      duration: 300.ms,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Scan Group (one scan cycle) ──

class _ScanGroup extends StatelessWidget {
  const _ScanGroup({
    required this.scanId,
    required this.timestamp,
    required this.decisions,
  });

  final String scanId;
  final DateTime timestamp;
  final List<BotDecision> decisions;

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final text = context.auraText;
    final radii = Theme.of(context).extension<AuraRadii>()!;

    final entered = decisions
        .where((d) => d.decision == DecisionVerdict.entered)
        .length;
    final watched = decisions
        .where((d) => d.decision == DecisionVerdict.watched)
        .length;
    final skipped = decisions
        .where((d) => d.decision == DecisionVerdict.skipped)
        .length;

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Container(
        decoration: ShapeDecoration(
          color: c.surface,
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.circular(radii.lg),
            side: BorderSide(color: c.borderSubtle, width: 1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: timestamp + summary pills
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 10.h),
              child: Row(
                children: [
                  Icon(
                    PhosphorIconsBold.clockCounterClockwise,
                    size: 14.sp,
                    color: c.textTertiary,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    _formatTime(timestamp),
                    style: text.bodySmall?.copyWith(
                      color: c.textTertiary,
                      fontSize: 11.sp,
                    ),
                  ),
                  const Spacer(),
                  if (entered > 0)
                    _MiniPill(label: '$entered entered', color: c.profit),
                  if (watched > 0) ...[
                    SizedBox(width: 6.w),
                    _MiniPill(label: '$watched watched', color: c.warning),
                  ],
                  if (skipped > 0) ...[
                    SizedBox(width: 6.w),
                    _MiniPill(
                      label: '$skipped skipped',
                      color: c.textTertiary.withValues(alpha: 0.5),
                    ),
                  ],
                ],
              ),
            ),
            Divider(height: 1, color: c.borderSubtle),

            // Decision rows
            ...decisions.map((d) => _DecisionRow(decision: d)),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    final s = local.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

// ── Single Decision Row ──

class _DecisionRow extends StatefulWidget {
  const _DecisionRow({required this.decision});

  final BotDecision decision;

  @override
  State<_DecisionRow> createState() => _DecisionRowState();
}

class _DecisionRowState extends State<_DecisionRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final text = context.auraText;
    final d = widget.decision;

    final verdictColor = switch (d.decision) {
      DecisionVerdict.entered => c.profit,
      DecisionVerdict.watched => c.warning,
      DecisionVerdict.skipped => c.textTertiary.withValues(alpha: 0.5),
    };

    final verdictIcon = switch (d.decision) {
      DecisionVerdict.entered => PhosphorIconsBold.checkCircle,
      DecisionVerdict.watched => PhosphorIconsBold.eye,
      DecisionVerdict.skipped => PhosphorIconsBold.minusCircle,
    };

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: Row(
              children: [
                Icon(verdictIcon, size: 16.sp, color: verdictColor),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.poolName,
                        style: text.bodySmall?.copyWith(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        d.reason,
                        style: text.bodySmall?.copyWith(
                          color: c.textTertiary,
                          fontSize: 10.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                // Score pill
                if (d.ruleScore != null)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: verdictColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      d.ruleScore!.toStringAsFixed(0),
                      style: text.bodySmall?.copyWith(
                        color: verdictColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.sp,
                      ),
                    ),
                  ),
                SizedBox(width: 4.w),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    PhosphorIconsBold.caretDown,
                    size: 12.sp,
                    color: c.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Expandable breakdown
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _ExpandedDetail(decision: d),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

// ── Expanded detail (score breakdown + ML) ──

class _ExpandedDetail extends StatelessWidget {
  const _ExpandedDetail({required this.decision});

  final BotDecision decision;

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final text = context.auraText;
    final d = decision;
    final sb = d.scoreBreakdown;

    return Container(
      color: c.background.withValues(alpha: 0.4),
      padding: EdgeInsets.fromLTRB(42.w, 4.h, 16.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sb != null) ...[
            _DetailRow('Volume', sb.volumeScore.toStringAsFixed(1)),
            _DetailRow('Liquidity', sb.liquidityScore.toStringAsFixed(1)),
            _DetailRow('Fee', sb.feeScore.toStringAsFixed(1)),
            _DetailRow('Momentum', sb.momentumScore.toStringAsFixed(1)),
            _DetailRow('Total', sb.totalScore.toStringAsFixed(1)),
            SizedBox(height: 4.h),
          ],
          if (d.mlProbability != null)
            _DetailRow(
              'ML Probability',
              '${(d.mlProbability! * 100).toStringAsFixed(2)}%',
            ),
          if (d.positionId != null) ...[
            SizedBox(height: 6.h),
            GestureDetector(
              onTap: () => context.push('/position/${d.positionId}'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    PhosphorIconsBold.arrowSquareOut,
                    size: 12.sp,
                    color: c.accent,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'View position',
                    style: text.bodySmall?.copyWith(
                      color: c.accent,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final text = context.auraText;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: text.bodySmall?.copyWith(
              color: c.textTertiary,
              fontSize: 10.sp,
            ),
          ),
          Text(
            value,
            style: text.bodySmall?.copyWith(
              color: c.textSecondary,
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mini Pill ──

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = context.auraText;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        label,
        style: text.bodySmall?.copyWith(
          color: color,
          fontSize: 9.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

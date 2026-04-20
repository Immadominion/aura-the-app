import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:aura/core/models/position.dart';
import 'package:aura/core/repositories/decision_repository.dart';
import 'package:aura/core/repositories/position_repository.dart';
import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_radii.dart';
import 'package:aura/core/theme/app_theme.dart';

/// Position Detail — Layer 2 of Delegate (Home) mode.
///
/// Redesigned to match Aura dark canvas design language.
/// Flat layout: circular back button, inline metrics, divider-separated rows.
class PositionDetailScreen extends ConsumerWidget {
  final String positionId;

  const PositionDetailScreen({super.key, required this.positionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.aura;
    final text = context.auraText;
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    final posAsync = ref.watch(positionDetailProvider(positionId));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: c.background,
        body: Column(
          children: [
            // ── Top bar — circular back button ──
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
                    'POSITION',
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
            ).animate().fadeIn(duration: 300.ms),

            Expanded(
              child: posAsync.when(
                skipLoadingOnReload: true,
                loading: () =>
                    Center(child: CircularProgressIndicator(color: c.accent)),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        PhosphorIconsBold.warningCircle,
                        size: 40.sp,
                        color: c.loss,
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'Failed to load position',
                        style: text.titleMedium?.copyWith(color: c.textPrimary),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '$err',
                        style: text.bodySmall?.copyWith(color: c.textTertiary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                data: (pos) =>
                    _buildContent(context, ref, c, text, bottomPad, pos),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    AuraColors c,
    TextTheme text,
    double bottomPad,
    Position pos,
  ) {
    final pnlColor = pos.isProfitable ? c.profit : c.loss;
    final pnlSol = pos.pnlSol ?? 0;

    // Range derivation — audit §5.6 “In Range / Out of Range / Closed”.
    // We don’t carry an authoritative active-bin id from the backend yet,
    // so we approximate using price drift relative to bin width:
    //   driftBins ≈ ln(current / entry) / ln(1 + binStep / 10000)
    // and consider the position in-range if |driftBins| <= halfWindow.
    // halfWindow defaults to 10 bins each side (matches the strategy default
    // bin range used during entry).
    const halfWindow = 10;
    double? driftBins;
    if (pos.binStep != null &&
        pos.binStep! > 0 &&
        pos.entryPrice > 0 &&
        pos.currentPrice > 0) {
      final ratio = pos.currentPrice / pos.entryPrice;
      final binFactor = math.log(1 + pos.binStep! / 10000.0);
      if (binFactor > 0) {
        driftBins = math.log(ratio) / binFactor;
      }
    }
    final _RangeStatus rangeStatus = !pos.isActive
        ? _RangeStatus.closed
        : (driftBins == null
              ? _RangeStatus.unknown
              : (driftBins.abs() <= halfWindow
                    ? _RangeStatus.inRange
                    : _RangeStatus.outOfRange));

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(28.w, 24.h, 28.w, bottomPad + 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Range pill + LIVE badge — audit §5.6.
          Row(
            children: [
              _RangePill(status: rangeStatus, c: c, text: text),
              const Spacer(),
              if (pos.isLive)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: ShapeDecoration(
                    color: c.accent.withValues(alpha: 0.15),
                    shape: ContinuousRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        context.auraRadii.sm,
                      ),
                    ),
                  ),
                  child: Text(
                    'LIVE',
                    style: text.labelSmall?.copyWith(
                      color: c.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.sp,
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: 12.h),

          // Pool name
          Text(
                pos.poolName ?? pos.poolAddress.substring(0, 8),
                style: text.displayMedium?.copyWith(letterSpacing: -0.8),
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 100.ms)
              .slideY(begin: 0.04, end: 0),

          SizedBox(height: 6.h),
          Text(
            'Meteora DLMM · ${pos.source == 'live' ? 'Real-time' : 'Database'}',
            style: text.titleMedium?.copyWith(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: c.textSecondary,
            ),
          ),

          SizedBox(height: 28.h),

          // ── P&L — inline metric on dark canvas ──
          Text(
            'P&L',
            style: text.titleSmall?.copyWith(
              fontSize: 10.sp,
              letterSpacing: 1.5,
              color: c.textTertiary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            pos.displayPnl,
            style: text.displayMedium?.copyWith(
              letterSpacing: -0.5,
              color: pnlColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
          SizedBox(height: 6.h),
          Text(
            '${pnlSol >= 0 ? '+' : ''}${pnlSol.toStringAsFixed(4)} SOL',
            style: text.bodySmall?.copyWith(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: c.textSecondary,
            ),
          ),

          SizedBox(height: 20.h),

          // Stat chips — flat inline
          Row(
                children: [
                  _StatChip(
                    label: 'Deposited',
                    value: '${pos.entryAmountYSol.toStringAsFixed(2)} SOL',
                    c: c,
                    text: text,
                  ),
                  SizedBox(width: 24.w),
                  _StatChip(
                    label: 'Fees',
                    value: '+${(pos.feesEarnedYSol ?? 0).toStringAsFixed(4)}',
                    valueColor: c.profit,
                    c: c,
                    text: text,
                  ),
                  SizedBox(width: 24.w),
                  _StatChip(
                    label: 'Hold Time',
                    value: pos.holdDurationFormatted,
                    c: c,
                    text: text,
                  ),
                ],
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 200.ms)
              .slideY(begin: 0.03, end: 0),

          SizedBox(height: 28.h),

          // ── Bin distribution mini-map ── (audit §5.6)
          // Symbolic: shows the deposited window centred on the entry bin
          // with the current-price marker offset by the price drift.
          if (pos.binStep != null) ...[
            Text(
              'BIN RANGE',
              style: text.titleSmall?.copyWith(
                fontSize: 10.sp,
                letterSpacing: 1.5,
                color: c.textTertiary,
              ),
            ),
            SizedBox(height: 10.h),
            _BinMiniMap(
              halfWindow: halfWindow,
              driftBins: driftBins,
              isActive: pos.isActive,
              c: c,
            ).animate().fadeIn(duration: 400.ms, delay: 220.ms),
            SizedBox(height: 28.h),
          ],

          // ── Details — divider-separated rows ──
          Text(
            'DETAILS',
            style: text.titleSmall?.copyWith(
              fontSize: 10.sp,
              letterSpacing: 1.5,
              color: c.textTertiary,
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 250.ms),
          SizedBox(height: 14.h),

          _DetailRow(label: 'Entry Price', value: _formatPrice(pos.entryPrice)),
          Divider(height: 1, color: c.borderSubtle),
          _DetailRow(
            label: 'Current Price',
            value: _formatPrice(pos.currentPrice),
          ),
          Divider(height: 1, color: c.borderSubtle),
          if (pos.binStep != null) ...[
            _DetailRow(label: 'Bin Step', value: '${pos.binStep}'),
            Divider(height: 1, color: c.borderSubtle),
          ],
          if (pos.entryActiveBinId != null) ...[
            _DetailRow(label: 'Entry Bin ID', value: '${pos.entryActiveBinId}'),
            Divider(height: 1, color: c.borderSubtle),
          ],
          _DetailRow(
            label: 'Entry Score',
            value: pos.entryScore.toStringAsFixed(0),
          ),
          if (pos.exitReason != null) ...[
            Divider(height: 1, color: c.borderSubtle),
            _DetailRow(label: 'Exit Reason', value: pos.exitReason!),
          ],

          SizedBox(height: 28.h),

          // ── Model Assessment — flat section ──
          Text(
            'MODEL ASSESSMENT',
            style: text.titleSmall?.copyWith(
              fontSize: 10.sp,
              letterSpacing: 1.5,
              color: c.textTertiary,
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 350.ms),
          SizedBox(height: 14.h),

          // ML confidence — radial gauge (audit §5.6: replace linear bar).
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ConfidenceGauge(
                value: pos.mlProbability ?? 0,
                hasValue: pos.mlProbability != null,
                c: c,
                text: text,
              ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
              SizedBox(width: 18.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ML Confidence',
                      style: text.titleMedium?.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      pos.mlProbability != null
                          ? 'XGBoost V3 model prediction — confidence at entry.'
                          : 'No ML prediction — entered by rule-based scoring.',
                      style: text.bodySmall?.copyWith(
                        height: 1.45,
                        color: c.textTertiary,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 32.h),

          // Why was this opened? (Decision Log drill-in)
          GestureDetector(
            onTap: () => _showDecisionSheet(context, ref, pos.positionId),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  PhosphorIconsBold.question,
                  size: 14.sp,
                  color: c.accent,
                ),
                SizedBox(width: 4.w),
                Text(
                  'Why was this opened?',
                  style: text.bodySmall?.copyWith(
                    color: c.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20.h),

          // Close button (active positions only)
          if (pos.isActive)
            GestureDetector(
              onTap: () => _confirmClose(context, ref, pos),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: c.loss.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(PhosphorIconsBold.x, size: 16.sp, color: c.loss),
                    SizedBox(width: 8.w),
                    Text(
                      'Close Position',
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: c.loss,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
        ],
      ),
    );
  }

  Future<void> _showDecisionSheet(
    BuildContext context,
    WidgetRef ref,
    String positionId,
  ) async {
    HapticFeedback.mediumImpact();
    final c = context.aura;
    final text = context.auraText;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final decisionAsync =
              ref.watch(positionDecisionProvider(positionId));
          return Container(
            decoration: ShapeDecoration(
              color: c.surfaceElevated,
              shape: ContinuousRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(ctx.auraRadii.xl),
                ),
                side: BorderSide(color: c.border, width: 1),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                24.w,
                12.h,
                24.w,
                MediaQuery.of(ctx).padding.bottom + 24.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: c.textTertiary.withValues(alpha: 0.25),
                        borderRadius:
                            BorderRadius.circular(ctx.auraRadii.xs),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Why Was This Opened?',
                      style: text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  decisionAsync.when(
                    loading: () => Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.h),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: c.accent,
                      ),
                    ),
                    error: (e, _) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.h),
                      child: Text(
                        'No decision record found',
                        style: text.bodyMedium?.copyWith(
                          color: c.textTertiary,
                        ),
                      ),
                    ),
                    data: (decision) {
                      final sb = decision.scoreBreakdown;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            decision.reason,
                            style: text.bodyMedium?.copyWith(
                              color: c.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          if (decision.ruleScore != null)
                            _sheetRow(c, text, 'Rule Score',
                                decision.ruleScore!.toStringAsFixed(0)),
                          if (decision.mlProbability != null)
                            _sheetRow(
                              c,
                              text,
                              'ML Probability',
                              '${(decision.mlProbability! * 100).toStringAsFixed(2)}%',
                            ),
                          if (sb != null) ...[
                            SizedBox(height: 8.h),
                            _sheetRow(c, text, 'Volume',
                                sb.volumeScore.toStringAsFixed(1)),
                            _sheetRow(c, text, 'Liquidity',
                                sb.liquidityScore.toStringAsFixed(1)),
                            _sheetRow(c, text, 'Fee',
                                sb.feeScore.toStringAsFixed(1)),
                            _sheetRow(c, text, 'Momentum',
                                sb.momentumScore.toStringAsFixed(1)),
                            _sheetRow(c, text, 'Total',
                                sb.totalScore.toStringAsFixed(1)),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sheetRow(
    AuraColors c,
    TextTheme? text,
    String label,
    String value,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: text?.bodySmall?.copyWith(
              color: c.textTertiary,
              fontSize: 12.sp,
            ),
          ),
          Text(
            value,
            style: text?.bodySmall?.copyWith(
              color: c.textSecondary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClose(
    BuildContext context,
    WidgetRef ref,
    Position pos,
  ) async {
    HapticFeedback.mediumImpact();
    final c = context.aura;
    final text = context.auraText;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: ShapeDecoration(
          color: c.surfaceElevated,
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(ctx.auraRadii.xl),
            ),
            side: BorderSide(color: c.border, width: 1),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24.w,
            12.h,
            24.w,
            MediaQuery.of(ctx).padding.bottom + 24.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: c.textTertiary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(ctx.auraRadii.xs),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Close Position',
                  style: text.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'This will remove liquidity, claim fees, and swap '
                'leftover tokens back to SOL.',
                style: text.bodyMedium?.copyWith(
                  color: c.textSecondary,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24.h),
              GestureDetector(
                onTap: () => Navigator.of(ctx).pop(true),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    color: c.loss,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Center(
                    child: Text(
                      'Confirm Close',
                      style: text.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              GestureDetector(
                onTap: () => Navigator.of(ctx).pop(false),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Text(
                      'Cancel',
                      style: text.bodyMedium?.copyWith(color: c.textTertiary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      final repo = ref.read(positionRepositoryProvider);
      final pnl = await repo.closePosition(positionId);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Position closed  ·  P&L: ${pnl >= 0 ? "+" : ""}${pnl.toStringAsFixed(4)} SOL',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to close: $e')));
    }
  }

  String _formatPrice(double price) {
    if (price == 0) return '\u2014';
    if (price < 0.0001) return price.toStringAsExponential(3);
    if (price < 1) return price.toStringAsFixed(6);
    return price.toStringAsFixed(4);
  }
}

/// Stat chip — inline label + value, matching strategy detail pattern.
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final AuraColors c;
  final TextTheme text;

  const _StatChip({
    required this.label,
    required this.value,
    this.valueColor,
    required this.c,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: text.labelSmall?.copyWith(
            color: c.textTertiary,
            fontSize: 10.sp,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: text.titleMedium?.copyWith(
            color: valueColor ?? c.textPrimary,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Flat key-value row used in detail sections — matches ParamRow pattern.
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final text = context.auraText;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: text.titleMedium?.copyWith(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: c.textSecondary,
            ),
          ),
          Text(
            value,
            style: text.titleMedium?.copyWith(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// Phase 10 (audit §5.6) helpers — range pill, bin mini-map, radial gauge
// ═════════════════════════════════════════════════════════════════════

enum _RangeStatus { inRange, outOfRange, closed, unknown }

class _RangePill extends StatelessWidget {
  final _RangeStatus status;
  final AuraColors c;
  final TextTheme text;

  const _RangePill({required this.status, required this.c, required this.text});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      _RangeStatus.inRange => ('In Range', c.profit),
      _RangeStatus.outOfRange => ('Out of Range', c.warning),
      _RangeStatus.closed => ('Closed', c.textTertiary),
      _RangeStatus.unknown => ('Active', c.profit),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: ShapeDecoration(
        color: color.withValues(alpha: 0.12),
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(context.auraRadii.pill),
          side: BorderSide(color: color.withValues(alpha: 0.35)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7.w,
            height: 7.w,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          SizedBox(width: 8.w),
          Text(
            label,
            style: text.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _BinMiniMap extends StatelessWidget {
  final int halfWindow;
  final double? driftBins;
  final bool isActive;
  final AuraColors c;

  const _BinMiniMap({
    required this.halfWindow,
    required this.driftBins,
    required this.isActive,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.h,
      child: CustomPaint(
        size: Size.infinite,
        painter: _BinMiniMapPainter(
          halfWindow: halfWindow,
          driftBins: driftBins,
          isActive: isActive,
          shadeColor: c.accent.withValues(alpha: 0.18),
          binColor: c.borderSubtle,
          entryMarkerColor: c.textTertiary,
          activeMarkerColor: isActive
              ? ((driftBins != null && driftBins!.abs() <= halfWindow)
                    ? c.profit
                    : c.warning)
              : c.textTertiary,
        ),
      ),
    );
  }
}

class _BinMiniMapPainter extends CustomPainter {
  final int halfWindow;
  final double? driftBins;
  final bool isActive;
  final Color shadeColor;
  final Color binColor;
  final Color entryMarkerColor;
  final Color activeMarkerColor;

  _BinMiniMapPainter({
    required this.halfWindow,
    required this.driftBins,
    required this.isActive,
    required this.shadeColor,
    required this.binColor,
    required this.entryMarkerColor,
    required this.activeMarkerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final totalBins = halfWindow * 4 + 1; // window + buffer on each side
    final binW = size.width / totalBins;
    final centerX = size.width / 2;
    final midY = size.height / 2;
    final barH = size.height * 0.45;

    // Bin ticks
    final binPaint = Paint()
      ..color = binColor
      ..strokeWidth = 1.2;
    for (var i = 0; i < totalBins; i++) {
      final x = (i + 0.5) * binW;
      canvas.drawLine(
        Offset(x, midY - barH / 2),
        Offset(x, midY + barH / 2),
        binPaint,
      );
    }

    // Deposited window (translucent band)
    final shadeRect = Rect.fromLTWH(
      centerX - halfWindow * binW,
      midY - barH / 2 - 2,
      halfWindow * 2 * binW,
      barH + 4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(shadeRect, const Radius.circular(4)),
      Paint()..color = shadeColor,
    );

    // Entry marker (centre, dashed-feel via a short solid line)
    canvas.drawLine(
      Offset(centerX, midY - barH / 2 - 4),
      Offset(centerX, midY + barH / 2 + 4),
      Paint()
        ..color = entryMarkerColor
        ..strokeWidth = 1.5,
    );

    // Active marker (current price drift)
    if (driftBins != null) {
      final clamped = driftBins!.clamp(
        -halfWindow * 2.0,
        halfWindow * 2.0,
      );
      final activeX = centerX + clamped * binW;
      canvas.drawCircle(
        Offset(activeX, midY),
        4.5,
        Paint()..color = activeMarkerColor,
      );
      canvas.drawCircle(
        Offset(activeX, midY),
        7.5,
        Paint()
          ..color = activeMarkerColor.withValues(alpha: 0.25)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BinMiniMapPainter old) =>
      old.driftBins != driftBins ||
      old.isActive != isActive ||
      old.activeMarkerColor != activeMarkerColor;
}

class _ConfidenceGauge extends StatelessWidget {
  final double value; // 0..1
  final bool hasValue;
  final AuraColors c;
  final TextTheme text;

  const _ConfidenceGauge({
    required this.value,
    required this.hasValue,
    required this.c,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value.clamp(0.0, 1.0) * 100).round();
    return SizedBox(
      width: 64.w,
      height: 64.w,
      child: CustomPaint(
        painter: _ConfidenceGaugePainter(
          value: value.clamp(0.0, 1.0),
          trackColor: c.borderSubtle,
          progressColor: c.accent,
        ),
        child: Center(
          child: Text(
            hasValue ? '$pct%' : '—',
            style: text.titleMedium?.copyWith(
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfidenceGaugePainter extends CustomPainter {
  final double value;
  final Color trackColor;
  final Color progressColor;

  _ConfidenceGaugePainter({
    required this.value,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 5.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );

    // Track — full ring
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = trackColor
        ..strokeWidth = stroke
        ..style = PaintingStyle.stroke,
    );

    // Progress — clockwise from 12 o'clock
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      Paint()
        ..color = progressColor
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _ConfidenceGaugePainter old) =>
      old.value != value || old.progressColor != progressColor;
}

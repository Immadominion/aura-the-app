import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:sage/core/theme/app_colors.dart';
import 'package:sage/features/setup/presentation/widgets/step_indicator.dart';
import 'package:sage/features/setup/presentation/widgets/tune_slider.dart';
import 'package:sage/shared/widgets/sage_button.dart';

/// Step 2 (Custom path) — Full strategy builder.
///
/// All backend `createBotSchema` parameters grouped into
/// four collapsible sections separated by minimal dividers.
class CustomStrategyStep extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback? onTalkToSage;

  // ── Values ──
  final double entryScoreThreshold;
  final double minVolume24h;
  final double minLiquidity;
  final double maxLiquidity;
  final double positionSizeSOL;
  final int maxConcurrentPositions;
  final int defaultBinRange;
  final double profitTargetPercent;
  final double stopLossPercent;
  final int maxHoldTimeMinutes;
  final double maxDailyLossSOL;
  final int cooldownMinutes;

  // ── Change handlers ──
  final ValueChanged<double> onEntryScoreChanged;
  final ValueChanged<double> onMinVolumeChanged;
  final ValueChanged<double> onMinLiquidityChanged;
  final ValueChanged<double> onMaxLiquidityChanged;
  final ValueChanged<double> onPositionSizeChanged;
  final ValueChanged<int> onMaxPositionsChanged;
  final ValueChanged<int> onBinRangeChanged;
  final ValueChanged<double> onProfitTargetChanged;
  final ValueChanged<double> onStopLossChanged;
  final ValueChanged<int> onMaxHoldChanged;
  final ValueChanged<double> onDailyLimitChanged;
  final ValueChanged<int> onCooldownChanged;

  // ── Theme ──
  final SageColors c;
  final TextTheme text;

  const CustomStrategyStep({
    super.key,
    required this.onBack,
    required this.onNext,
    this.onTalkToSage,
    required this.entryScoreThreshold,
    required this.minVolume24h,
    required this.minLiquidity,
    required this.maxLiquidity,
    required this.positionSizeSOL,
    required this.maxConcurrentPositions,
    required this.defaultBinRange,
    required this.profitTargetPercent,
    required this.stopLossPercent,
    required this.maxHoldTimeMinutes,
    required this.maxDailyLossSOL,
    required this.cooldownMinutes,
    required this.onEntryScoreChanged,
    required this.onMinVolumeChanged,
    required this.onMinLiquidityChanged,
    required this.onMaxLiquidityChanged,
    required this.onPositionSizeChanged,
    required this.onMaxPositionsChanged,
    required this.onBinRangeChanged,
    required this.onProfitTargetChanged,
    required this.onStopLossChanged,
    required this.onMaxHoldChanged,
    required this.onDailyLimitChanged,
    required this.onCooldownChanged,
    required this.c,
    required this.text,
  });

  @override
  State<CustomStrategyStep> createState() => _CustomStrategyStepState();
}

class _CustomStrategyStepState extends State<CustomStrategyStep> {
  bool _showEntry = true;
  bool _showSizing = false;
  bool _showRisk = false;
  bool _showTiming = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 28.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.h),

          // ── iOS-style back button ──
          GestureDetector(
            onTap: widget.onBack,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    PhosphorIconsBold.caretLeft,
                    size: 16.sp,
                    color: widget.c.accent,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'Back',
                    style: widget.text.titleMedium?.copyWith(
                      color: widget.c.accent,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          StepIndicator(current: 1, total: 3, c: widget.c),

          SizedBox(height: 28.h),

          // ── Headline ──
          Text('Build your\nstrategy', style: widget.text.headlineLarge)
              .animate()
              .fadeIn(duration: 600.ms)
              .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic),

          SizedBox(height: 8.h),

          Text(
            'Configure every parameter. All fields match what the '
            'trading engine uses on-chain.',
            style: widget.text.bodyMedium?.copyWith(
              color: widget.c.textSecondary,
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 100.ms),

          // ── "Talk to Sage" banner ──
          if (widget.onTalkToSage != null) ...[
            SizedBox(height: 20.h),
            GestureDetector(
                  onTap: widget.onTalkToSage,
                  child: _TalkToSageBanner(c: widget.c, text: widget.text),
                )
                .animate()
                .fadeIn(duration: 500.ms, delay: 150.ms)
                .slideY(begin: 0.04, end: 0, curve: Curves.easeOutCubic),
          ],

          SizedBox(height: 28.h),

          // ── Entry Conditions ──
          _SectionDivider(
            title: 'ENTRY CONDITIONS',
            isExpanded: _showEntry,
            onTap: () => setState(() => _showEntry = !_showEntry),
            c: widget.c,
            text: widget.text,
          ).animate().fadeIn(duration: 400.ms, delay: 150.ms),

          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: EdgeInsets.only(top: 16.h),
              child: Column(
                children: [
                  TuneSlider(
                    label: 'Entry Score',
                    value: widget.entryScoreThreshold,
                    min: 50,
                    max: 300,
                    divisions: 50,
                    unit: 'pts',
                    format: (v) => v.toStringAsFixed(0),
                    onChanged: widget.onEntryScoreChanged,
                    c: widget.c,
                    text: widget.text,
                  ),
                  SizedBox(height: 18.h),
                  TuneSlider(
                    label: 'Min 24h Volume',
                    value: widget.minVolume24h,
                    min: 100,
                    max: 50000,
                    divisions: 50,
                    unit: '\$',
                    format: (v) => v >= 1000
                        ? '${(v / 1000).toStringAsFixed(1)}k'
                        : v.toStringAsFixed(0),
                    onChanged: widget.onMinVolumeChanged,
                    c: widget.c,
                    text: widget.text,
                  ),
                  SizedBox(height: 18.h),
                  TuneSlider(
                    label: 'Min Liquidity',
                    value: widget.minLiquidity,
                    min: 0,
                    max: 50000,
                    divisions: 50,
                    unit: '\$',
                    format: (v) => v >= 1000
                        ? '${(v / 1000).toStringAsFixed(1)}k'
                        : v.toStringAsFixed(0),
                    onChanged: widget.onMinLiquidityChanged,
                    c: widget.c,
                    text: widget.text,
                  ),
                  SizedBox(height: 18.h),
                  TuneSlider(
                    label: 'Max Liquidity',
                    value: widget.maxLiquidity,
                    min: 10000,
                    max: 5000000,
                    divisions: 50,
                    unit: '\$',
                    format: (v) => v >= 1000000
                        ? '${(v / 1000000).toStringAsFixed(1)}M'
                        : '${(v / 1000).toStringAsFixed(0)}k',
                    onChanged: widget.onMaxLiquidityChanged,
                    c: widget.c,
                    text: widget.text,
                  ),
                ],
              ),
            ),
            crossFadeState: _showEntry
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),

          SizedBox(height: 20.h),

          // ── Position Sizing ──
          _SectionDivider(
            title: 'POSITION SIZING',
            isExpanded: _showSizing,
            onTap: () => setState(() => _showSizing = !_showSizing),
            c: widget.c,
            text: widget.text,
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: EdgeInsets.only(top: 16.h),
              child: Column(
                children: [
                  TuneSlider(
                    label: 'Position Size',
                    value: widget.positionSizeSOL,
                    min: 0.1,
                    max: 10.0,
                    divisions: 99,
                    unit: 'SOL',
                    format: (v) => v.toStringAsFixed(1),
                    onChanged: widget.onPositionSizeChanged,
                    c: widget.c,
                    text: widget.text,
                  ),
                  SizedBox(height: 18.h),
                  TuneSlider(
                    label: 'Max Concurrent',
                    value: widget.maxConcurrentPositions.toDouble(),
                    min: 1,
                    max: 20,
                    divisions: 19,
                    unit: '',
                    format: (v) => v.toStringAsFixed(0),
                    onChanged: (v) => widget.onMaxPositionsChanged(v.round()),
                    c: widget.c,
                    text: widget.text,
                  ),
                  SizedBox(height: 18.h),
                  TuneSlider(
                    label: 'Bin Range',
                    value: widget.defaultBinRange.toDouble(),
                    min: 1,
                    max: 50,
                    divisions: 49,
                    unit: 'bins',
                    format: (v) => v.toStringAsFixed(0),
                    onChanged: (v) => widget.onBinRangeChanged(v.round()),
                    c: widget.c,
                    text: widget.text,
                  ),
                ],
              ),
            ),
            crossFadeState: _showSizing
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),

          SizedBox(height: 20.h),

          // ── Risk Management ──
          _SectionDivider(
            title: 'RISK MANAGEMENT',
            isExpanded: _showRisk,
            onTap: () => setState(() => _showRisk = !_showRisk),
            c: widget.c,
            text: widget.text,
          ).animate().fadeIn(duration: 400.ms, delay: 250.ms),

          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: EdgeInsets.only(top: 16.h),
              child: Column(
                children: [
                  TuneSlider(
                    label: 'Profit Target',
                    value: widget.profitTargetPercent,
                    min: 1,
                    max: 25,
                    divisions: 48,
                    unit: '%',
                    format: (v) => v.toStringAsFixed(0),
                    onChanged: widget.onProfitTargetChanged,
                    c: widget.c,
                    text: widget.text,
                  ),
                  SizedBox(height: 18.h),
                  TuneSlider(
                    label: 'Stop Loss',
                    value: widget.stopLossPercent,
                    min: 1,
                    max: 20,
                    divisions: 38,
                    unit: '%',
                    format: (v) => v.toStringAsFixed(0),
                    onChanged: widget.onStopLossChanged,
                    c: widget.c,
                    text: widget.text,
                  ),
                  SizedBox(height: 18.h),
                  TuneSlider(
                    label: 'Max Hold Time',
                    value: widget.maxHoldTimeMinutes.toDouble(),
                    min: 15,
                    max: 1440,
                    divisions: 57,
                    unit: 'min',
                    format: (v) => v >= 60
                        ? '${(v / 60).toStringAsFixed(1)}h'
                        : v.toStringAsFixed(0),
                    onChanged: (v) => widget.onMaxHoldChanged(v.round()),
                    c: widget.c,
                    text: widget.text,
                  ),
                  SizedBox(height: 18.h),
                  TuneSlider(
                    label: 'Daily Loss Limit',
                    value: widget.maxDailyLossSOL,
                    min: 0.5,
                    max: 25.0,
                    divisions: 49,
                    unit: 'SOL',
                    format: (v) => v.toStringAsFixed(1),
                    onChanged: widget.onDailyLimitChanged,
                    c: widget.c,
                    text: widget.text,
                  ),
                ],
              ),
            ),
            crossFadeState: _showRisk
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),

          SizedBox(height: 20.h),

          // ── Timing ──
          _SectionDivider(
            title: 'TIMING',
            isExpanded: _showTiming,
            onTap: () => setState(() => _showTiming = !_showTiming),
            c: widget.c,
            text: widget.text,
          ).animate().fadeIn(duration: 400.ms, delay: 300.ms),

          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: EdgeInsets.only(top: 16.h),
              child: TuneSlider(
                label: 'Cooldown',
                value: widget.cooldownMinutes.toDouble(),
                min: 0,
                max: 240,
                divisions: 48,
                unit: 'min',
                format: (v) => v.toStringAsFixed(0),
                onChanged: (v) => widget.onCooldownChanged(v.round()),
                c: widget.c,
                text: widget.text,
              ),
            ),
            crossFadeState: _showTiming
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),

          SizedBox(height: 32.h),

          // ── Continue ──
          SageButton(
            label: 'Continue',
            onPressed: widget.onNext,
          ).animate().fadeIn(duration: 400.ms, delay: 400.ms),

          SizedBox(height: 28.h),
        ],
      ),
    );
  }
}

// ── Minimal section divider — no container, no icon ──

class _SectionDivider extends StatelessWidget {
  final String title;
  final bool isExpanded;
  final VoidCallback onTap;
  final SageColors c;
  final TextTheme text;

  const _SectionDivider({
    required this.title,
    required this.isExpanded,
    required this.onTap,
    required this.c,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            Text(
              title,
              style: text.labelSmall?.copyWith(
                color: isExpanded ? c.accent : c.textTertiary,
                fontWeight: FontWeight.w700,
                fontSize: 11.sp,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Container(
                height: 1,
                color: isExpanded
                    ? c.accent.withValues(alpha: 0.2)
                    : c.borderSubtle,
              ),
            ),
            SizedBox(width: 10.w),
            AnimatedRotation(
              duration: const Duration(milliseconds: 200),
              turns: isExpanded ? 0.5 : 0,
              child: Icon(
                PhosphorIconsBold.caretDown,
                size: 12.sp,
                color: isExpanded ? c.accent : c.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Talk to Sage — gradient banner
// ─────────────────────────────────────────────────────────────

class _TalkToSageBanner extends StatelessWidget {
  final SageColors c;
  final TextTheme text;

  const _TalkToSageBanner({required this.c, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.accent,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Stack(
          children: [
            // ── Decorative circles ──
            Positioned(
              top: 30,
              right: -15,
              child: Container(
                width: 180.w,
                height: 180.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),

            Positioned(
              top: 20,
              right: 0,
              child: Image.asset(
                'assets/images/rocket.png',
                width: 150.w,
                height: 150.w,
              ),
            ),

            // ── Content ──
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Build your strategy\nby talking',
                        style: text.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                          letterSpacing: -0.3,
                        ),
                      ),

                      SizedBox(height: 8.h),

                      Text(
                        'Describe how you trade and Sage\nsets every parameter for you.',
                        style: text.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.72),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SvgPicture.asset(
                    'assets/images/arrow-right.svg',
                    height: 12.w,
                    colorFilter: ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
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

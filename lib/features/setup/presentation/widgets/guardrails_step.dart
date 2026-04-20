import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/features/setup/models/risk_profile.dart';
import 'package:aura/features/setup/presentation/widgets/profile_card.dart';
import 'package:aura/features/setup/presentation/widgets/risk_slider.dart';
import 'package:aura/features/setup/presentation/widgets/step_indicator.dart';
import 'package:aura/features/setup/presentation/widgets/tune_slider.dart';
import 'package:aura/shared/widgets/aura_button.dart';

/// Step 2 (Aura AI path) — risk slider + fine-tune + continue.
class GuardrailsStep extends StatelessWidget {
  final RiskProfile risk;
  final ValueChanged<RiskProfile> onSelectRisk;
  final bool showCustomize;
  final VoidCallback onToggleCustomize;
  final double positionSize;
  final double dailyLimit;
  final double profitTarget;
  final double stopLoss;
  final ValueChanged<double> onPositionSizeChanged;
  final ValueChanged<double> onDailyLimitChanged;
  final ValueChanged<double> onProfitTargetChanged;
  final ValueChanged<double> onStopLossChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final AuraColors c;
  final TextTheme text;

  const GuardrailsStep({
    super.key,
    required this.risk,
    required this.onSelectRisk,
    required this.showCustomize,
    required this.onToggleCustomize,
    required this.positionSize,
    required this.dailyLimit,
    required this.profitTarget,
    required this.stopLoss,
    required this.onPositionSizeChanged,
    required this.onDailyLimitChanged,
    required this.onProfitTargetChanged,
    required this.onStopLossChanged,
    required this.onNext,
    required this.onBack,
    required this.c,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final riskValue = switch (risk) {
      RiskProfile.conservative => 0.0,
      RiskProfile.balanced => 1.0,
      RiskProfile.aggressive => 2.0,
    };

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 28.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.h),

          // ── Step indicator ──
          StepIndicator(current: 1, total: 3, c: c),

          SizedBox(height: 28.h),

          // ── Headline ──
          Text('Set your\nguardrails', style: text.headlineLarge)
              .animate()
              .fadeIn(duration: 600.ms)
              .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic),

          SizedBox(height: 8.h),

          Text(
            'Slide to set your risk appetite.',
            style: text.bodyMedium?.copyWith(color: c.textSecondary),
          ).animate().fadeIn(duration: 500.ms, delay: 100.ms),

          SizedBox(height: 32.h),

          // ── Risk slider ──
          RiskSlider(
            value: riskValue,
            onChanged: (v) {
              final profile = switch (v.round()) {
                0 => RiskProfile.conservative,
                2 => RiskProfile.aggressive,
                _ => RiskProfile.balanced,
              };
              onSelectRisk(profile);
            },
            c: c,
            text: text,
          ).animate().fadeIn(duration: 400.ms, delay: 180.ms),

          SizedBox(height: 24.h),

          // ── Profile card ──
          ProfileCard(
            risk: risk,
            profitTarget: profitTarget,
            stopLoss: stopLoss,
            c: c,
            text: text,
          ).animate().fadeIn(duration: 400.ms, delay: 260.ms),

          SizedBox(height: 16.h),

          // ── Fine-tune toggle ──
          GestureDetector(
            onTap: onToggleCustomize,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  showCustomize
                      ? PhosphorIconsBold.caretUp
                      : PhosphorIconsBold.caretDown,
                  size: 12.sp,
                  color: c.accent,
                ),
                SizedBox(width: 6.w),
                Text(
                  'Fine-tune parameters',
                  style: text.labelMedium?.copyWith(
                    color: c.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.sp,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 340.ms),

          // ── Collapsible sliders ──
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: EdgeInsets.only(top: 20.h),
              child: Column(
                children: [
                  TuneSlider(
                    label: 'Position Size',
                    value: positionSize,
                    min: 0.1,
                    max: 10.0,
                    divisions: 99,
                    unit: 'SOL',
                    format: (v) => v.toStringAsFixed(1),
                    onChanged: onPositionSizeChanged,
                    c: c,
                    text: text,
                  ),
                  SizedBox(height: 20.h),
                  TuneSlider(
                    label: 'Daily Limit',
                    value: dailyLimit,
                    min: 0.5,
                    max: 25.0,
                    divisions: 49,
                    unit: 'SOL',
                    format: (v) => v.toStringAsFixed(1),
                    onChanged: onDailyLimitChanged,
                    c: c,
                    text: text,
                  ),
                  SizedBox(height: 20.h),
                  TuneSlider(
                    label: 'Profit Target',
                    value: profitTarget,
                    min: 1,
                    max: 25,
                    divisions: 48,
                    unit: '%',
                    format: (v) => v.toStringAsFixed(0),
                    onChanged: onProfitTargetChanged,
                    c: c,
                    text: text,
                  ),
                  SizedBox(height: 20.h),
                  TuneSlider(
                    label: 'Stop Loss',
                    value: stopLoss,
                    min: 1,
                    max: 20,
                    divisions: 38,
                    unit: '%',
                    format: (v) => v.toStringAsFixed(0),
                    onChanged: onStopLossChanged,
                    c: c,
                    text: text,
                  ),
                ],
              ),
            ),
            crossFadeState: showCustomize
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),

          SizedBox(height: 28.h),

          // ── Continue ──
          AuraButton(
            label: 'Continue',
            onPressed: onNext,
          ).animate().fadeIn(duration: 400.ms, delay: 400.ms),

          SizedBox(height: 28.h),
        ],
      ),
    );
  }
}

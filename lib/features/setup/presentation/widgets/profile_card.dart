import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_radii.dart';
import 'package:aura/features/setup/models/risk_profile.dart';

/// Profile card — feature list for the selected risk plan.
///
/// Displays the active profile's parameters (per trade, daily limit,
/// profit target, stop loss, max positions) with an AnimatedSwitcher
/// crossfade on profile change.
class ProfileCard extends StatelessWidget {
  final RiskProfile risk;
  final double profitTarget;
  final double stopLoss;
  final AuraColors c;
  final TextTheme text;

  const ProfileCard({
    super.key,
    required this.risk,
    required this.profitTarget,
    required this.stopLoss,
    required this.c,
    required this.text,
  });

  String get _title => switch (risk) {
    RiskProfile.conservative => 'Conservative',
    RiskProfile.balanced => 'Balanced',
    RiskProfile.aggressive => 'Aggressive',
  };

  String get _subtitle => switch (risk) {
    RiskProfile.conservative => 'Minimal exposure, steady compounding',
    RiskProfile.balanced => 'Optimal risk-reward for most strategies',
    RiskProfile.aggressive => 'High opportunity, higher drawdown tolerance',
  };

  @override
  Widget build(BuildContext context) {
    final cfg = riskConfigs[risk]!;

    final features = <({Color color, String label, String val})>[
      (color: c.accent, label: 'Per trade', val: '${cfg.positionSizeSOL} SOL'),
      (
        color: c.accent,
        label: 'Daily limit',
        val: '${cfg.maxDailyLossSOL} SOL',
      ),
      (
        color: c.accent,
        label: 'Profit target',
        val: '${profitTarget.toStringAsFixed(0)}%',
      ),
      (
        color: c.accent,
        label: 'Stop loss',
        val: '${stopLoss.toStringAsFixed(0)}%',
      ),
      (
        color: c.accent,
        label: 'Max positions',
        val: '${cfg.maxConcurrentPositions}',
      ),
    ];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: Container(
        key: ValueKey(risk),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(context.auraRadii.lg),
          border: Border.all(color: c.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_title Profile',
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        _subtitle,
                        style: text.bodySmall?.copyWith(
                          color: c.textSecondary,
                          fontSize: 11.5.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                // SIM badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: c.profit.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(context.auraRadii.lg),
                  ),
                  child: Text(
                    'SIM',
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: c.profit,
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Divider(height: 1, color: c.borderSubtle),
            ),

            // Feature rows
            ...features.map(
              (f) => Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Row(
                  children: [
                    Icon(
                      PhosphorIconsBold.arrowBendDownRight,
                      size: 13.sp,
                      color: f.color,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        f.label,
                        style: text.bodySmall?.copyWith(
                          color: c.textSecondary,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                    Text(
                      f.val,
                      style: text.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

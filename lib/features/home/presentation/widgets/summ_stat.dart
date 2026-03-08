import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sage/core/theme/app_colors.dart';

/// Summary statistic column used in the trade history overview card.
class SummStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final SageColors c;
  final TextTheme text;

  const SummStat({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    required this.c,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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

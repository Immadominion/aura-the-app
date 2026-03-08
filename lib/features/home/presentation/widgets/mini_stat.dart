import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sage/core/theme/app_colors.dart';
import 'package:sage/core/theme/app_theme.dart';

class MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final CrossAxisAlignment alignment;

  const MiniStat({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.alignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sage;
    final text = context.sageText;
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          style: text.titleSmall?.copyWith(
            fontSize: 10.sp,
            letterSpacing: 1.5,
            color: c.textTertiary,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          value,
          style: text.headlineSmall?.copyWith(
            fontSize: 18.sp,
            letterSpacing: -0.3,
            color: valueColor ?? c.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

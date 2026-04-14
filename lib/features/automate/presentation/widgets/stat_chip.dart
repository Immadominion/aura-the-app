import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura/core/theme/app_colors.dart';

/// Quick stat chip — compact label/value pair.
class StatChip extends StatelessWidget {
  final String label;
  final String value;
  final SageColors c;
  final TextTheme text;

  const StatChip({
    super.key,
    required this.label,
    required this.value,
    required this.c,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: text.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: text.labelSmall?.copyWith(
            color: c.textTertiary,
            fontSize: 10.sp,
          ),
        ),
      ],
    );
  }
}

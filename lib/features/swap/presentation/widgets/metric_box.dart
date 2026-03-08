import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sage/core/theme/app_colors.dart';

/// Single metric display box used inside [ModelCard].
class MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final SageColors c;
  final TextTheme text;

  const MetricBox({
    super.key,
    required this.label,
    required this.value,
    required this.c,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: c.background,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: c.borderSubtle),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: text.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
                fontSize: 13.sp,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: text.labelSmall?.copyWith(
                color: c.textTertiary,
                fontSize: 8.sp,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

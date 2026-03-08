import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:sage/core/theme/app_colors.dart';

/// Minimal progress indicator — thin segmented bar.
class StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  final SageColors c;

  const StepIndicator({
    super.key,
    required this.current,
    required this.total,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final active = i <= current;
        return Expanded(
          child: Container(
            height: 3.h,
            margin: EdgeInsets.symmetric(horizontal: 3.w),
            decoration: BoxDecoration(
              color: active ? c.accent : c.border,
              borderRadius: BorderRadius.circular(1.5.r),
            ),
          ),
        );
      }),
    );
  }
}

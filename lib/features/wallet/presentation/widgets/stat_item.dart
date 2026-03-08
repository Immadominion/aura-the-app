import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:sage/core/theme/app_colors.dart';
import 'package:sage/core/theme/app_theme.dart';

/// Single portfolio stat shown in the profile header.
class StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const StatItem({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sage;
    final text = context.sageText;

    return Column(
      children: [
        Text(
          value,
          style: text.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 20.sp,
          ),
        ),
        SizedBox(height: 4.h),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: text.labelSmall?.copyWith(
                color: c.textTertiary,
                fontSize: 11.sp,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

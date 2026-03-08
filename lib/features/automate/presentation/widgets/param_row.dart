import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:sage/core/theme/app_colors.dart';
import 'package:sage/core/theme/app_theme.dart';

/// Single key-value row used in the parameters section.
class ParamRow extends StatelessWidget {
  final String label;
  final String value;
  const ParamRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = context.sage;
    final text = context.sageText;
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

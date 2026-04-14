import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_theme.dart';

/// Standard control button (surface background, border).
class ControlButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const ControlButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sage;
    final text = context.sageText;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: c.borderSubtle),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18.sp, color: c.textSecondary),
            SizedBox(width: 8.w),
            Text(
              label,
              style: text.titleMedium?.copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Danger-styled control button (red tint background, red border).
class DangerControlButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const DangerControlButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sage;
    final text = context.sageText;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: c.loss.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: c.loss.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18.sp, color: c.loss),
            SizedBox(width: 8.w),
            Text(
              label,
              style: text.titleMedium?.copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: c.loss,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

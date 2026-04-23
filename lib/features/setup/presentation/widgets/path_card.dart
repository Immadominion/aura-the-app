import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_radii.dart';

/// Path card — step 1 selection card for choosing
/// Aura AI vs Custom Strategy.
class PathCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final bool isSelected;
  final bool isRecommended;
  final VoidCallback onTap;
  final AuraColors c;
  final TextTheme text;

  const PathCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.isSelected,
    required this.isRecommended,
    required this.onTap,
    required this.c,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.all(12.r),
        decoration: ShapeDecoration(
          color: isSelected ? c.accent.withValues(alpha: 0.08) : c.surface,
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.circular(context.auraRadii.lg),
            side: BorderSide(
              color: isSelected ? c.accent.withValues(alpha: 0.4) : c.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20.sp,
                  color: isSelected ? c.accent : c.textSecondary,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: text.titleMedium?.copyWith(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? c.accent : c.textPrimary,
                            ),
                          ),
                          if (isRecommended) ...[
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: c.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                'RECOMMENDED',
                                style: TextStyle(
                                  fontSize: 8.sp,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: c.accent,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        subtitle,
                        style: text.bodySmall?.copyWith(
                          color: c.textSecondary,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                // Selection indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20.r,
                  height: 20.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? c.accent : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? c.accent : c.textTertiary,
                      width: isSelected ? 0 : 1.5,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          PhosphorIconsBold.check,
                          size: 12.sp,
                          color: c.buttonPrimaryText,
                        )
                      : null,
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              description,
              style: text.bodySmall?.copyWith(
                color: c.textSecondary,
                height: 1.4,
                fontSize: 11.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

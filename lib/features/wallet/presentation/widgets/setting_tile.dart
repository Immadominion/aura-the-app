import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_theme.dart';

/// Settings tile with icon, title, subtitle, and chevron.
class SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLast;

  const SettingTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sage;
    final text = context.sageText;

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, size: 20.sp, color: c.textSecondary),
          ),
          title: Text(
            title,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            subtitle,
            style: text.bodySmall?.copyWith(color: c.textTertiary),
          ),
          trailing: Icon(
            PhosphorIconsBold.caretRight,
            size: 16.sp,
            color: c.textTertiary.withValues(alpha: 0.5),
          ),
          onTap: onTap,
        ),
        if (!isLast)
          Divider(
            height: 1,
            color: c.borderSubtle.withValues(alpha: 0.5),
            indent: 56.w,
          ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }
}

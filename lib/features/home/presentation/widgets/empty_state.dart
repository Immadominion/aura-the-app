import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:aura/core/theme/app_colors.dart';

/// Home zero state — no bots, no positions.
///
/// Two flat rows. No nested containers, no boxed icons. The icon sits
/// inline at glyph weight; the chevron is the only afford. The whole row
/// is the tap target. Mirrors the interface-architecture rule: lists
/// are living objects, not data rows.
class HomeZeroState extends StatelessWidget {
  final AuraColors c;
  final TextTheme text;

  const HomeZeroState({super.key, required this.c, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Welcome to Aura',
            style: text.titleLarge?.copyWith(
              color: c.panelText,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Two ways in — just ask, or build it yourself.',
            style: text.bodyMedium?.copyWith(color: c.panelTextSecondary),
          ),
          SizedBox(height: 24.h),

          _ZeroStateRow(
            c: c,
            text: text,
            icon: PhosphorIconsRegular.chatCircle,
            title: 'Talk to Aura',
            subtitle: 'Ask “How should I start?” and Aura walks you through.',
            isPrimary: true,
            onTap: () {
              HapticFeedback.selectionClick();
              context.go('/intelligence');
            },
          ),

          Divider(height: 1, color: c.panelBorder),

          _ZeroStateRow(
            c: c,
            text: text,
            icon: PhosphorIconsRegular.sliders,
            title: 'Create a strategy',
            subtitle: 'Pick a path, set your rules, deploy.',
            isPrimary: false,
            onTap: () {
              HapticFeedback.selectionClick();
              context.push('/create-strategy');
            },
          ),
        ],
      ),
    );
  }
}

class _ZeroStateRow extends StatelessWidget {
  final AuraColors c;
  final TextTheme text;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ZeroStateRow({
    required this.c,
    required this.text,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isPrimary ? c.accent : c.panelText;
    final titleColor = isPrimary ? c.accent : c.panelText;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 18.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 22.sp, color: iconColor),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: text.titleMedium?.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 16.sp,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: text.bodySmall?.copyWith(
                      color: c.panelTextSecondary,
                      fontSize: 13.sp,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Icon(
              PhosphorIconsRegular.caretRight,
              size: 16.sp,
              color: c.panelTextSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

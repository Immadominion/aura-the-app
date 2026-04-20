import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_radii.dart';

/// Home zero state — shown when the user has no bots AND no positions.
///
/// Per audit §5.5: a 2-card vertical stack that warms the user up, instead
/// of a screen full of zeros. The stat boxes and YOUR BOTS / ACTIVE POSITIONS
/// sections are suppressed by the parent in this state.
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
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Two ways to get started — just ask, or build it yourself.',
            style: text.bodyMedium?.copyWith(color: c.panelTextSecondary),
          ),
          SizedBox(height: 20.h),

          // Card 1 — Talk to Aura (primary, accent-tinted)
          _ZeroStateCard(
            c: c,
            text: text,
            icon: PhosphorIconsBold.chatCircle,
            title: 'Talk to Aura',
            subtitle:
                'Ask “How should I start?” and Aura will walk you through it.',
            isPrimary: true,
            onTap: () {
              HapticFeedback.selectionClick();
              // TODO(phase-13): pass a starter prompt once chat supports it.
              context.go('/intelligence');
            },
          ),

          SizedBox(height: 12.h),

          // Card 2 — Create a strategy (secondary)
          _ZeroStateCard(
            c: c,
            text: text,
            icon: PhosphorIconsBold.sliders,
            title: 'Create a strategy',
            subtitle: 'Pick a path, set your rules, and deploy it yourself.',
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

class _ZeroStateCard extends StatelessWidget {
  final AuraColors c;
  final TextTheme text;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ZeroStateCard({
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
    final bg = isPrimary
        ? c.accent.withValues(alpha: 0.08)
        : c.panelBorder.withValues(alpha: 0.35);
    final borderColor = isPrimary
        ? c.accent.withValues(alpha: 0.35)
        : c.panelBorder;
    final iconColor = isPrimary ? c.accent : c.panelText;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: ShapeDecoration(
          color: bg,
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.circular(context.auraRadii.lg),
            side: BorderSide(color: borderColor),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: ShapeDecoration(
                color: isPrimary
                    ? c.accent.withValues(alpha: 0.15)
                    : c.panelBackground,
                shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.circular(context.auraRadii.md),
                ),
              ),
              child: Icon(icon, size: 20.sp, color: iconColor),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: text.titleMedium?.copyWith(
                      color: c.panelText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: text.bodySmall?.copyWith(
                      color: c.panelTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Icon(
              Icons.arrow_forward_ios,
              size: 12.sp,
              color: isPrimary ? c.accent : c.panelTextSecondary,
            ),
          ],
        ),
      ),
    );
  }
}


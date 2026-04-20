import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_radii.dart';

/// Reusable bottom sheet shell matching the app's design language.
///
/// White/panel background, drag handle, rounded top corners.
/// Pass [child] for content. Optional [title] rendered as headline.
///
/// Usage:
/// ```dart
/// AuraBottomSheet.show(
///   context: context,
///   title: 'Edit Parameter',
///   builder: (c, text) => YourContent(),
/// );
/// ```
class AuraBottomSheet extends StatelessWidget {
  final String? title;
  final Widget child;
  final AuraColors c;
  final TextTheme text;

  const AuraBottomSheet({
    super.key,
    this.title,
    required this.child,
    required this.c,
    required this.text,
  });

  /// Show the bottom sheet. Returns the result from [Navigator.pop].
  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    required Widget Function(AuraColors c, TextTheme text) builder,
  }) {
    final c = context.aura;
    final text = Theme.of(context).textTheme;
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AuraBottomSheet(
        title: title,
        c: c,
        text: text,
        child: builder(c, text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final radii = context.auraRadii;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: ShapeDecoration(
        color: c.surfaceElevated,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radii.xl)),
          side: BorderSide(color: c.border, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──
          Padding(
            padding: EdgeInsets.only(top: 12.h, bottom: 8.h),
            child: Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: c.textTertiary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(radii.xs),
                ),
              ),
            ),
          ),

          // ── Title ──
          if (title != null)
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 16.h),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title!,
                  style: text.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ),

          // ── Content ──
          Flexible(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                24.w,
                0,
                24.w,
                MediaQuery.of(context).viewInsets.bottom + 32.h,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

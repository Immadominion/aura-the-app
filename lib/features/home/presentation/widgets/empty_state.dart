import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura/core/theme/app_colors.dart';

/// Empty state shown when no bots are configured.
class EmptyState extends StatelessWidget {
  final SageColors c;
  final TextTheme text;

  const EmptyState({super.key, required this.c, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 32.h),
      child: Center(
        child: Column(
          children: [
            Text(
              'No bots yet',
              style: text.titleMedium?.copyWith(color: c.panelTextSecondary),
            ),
            SizedBox(height: 8.h),
            Text(
              'Create your first bot from the Automate tab',
              style: text.bodySmall?.copyWith(color: c.panelTextSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

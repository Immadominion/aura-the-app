import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:aura/core/theme/app_colors.dart';

/// External link row used in the support section.
class SupportLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;
  final SageColors c;
  final TextTheme text;

  const SupportLink({
    super.key,
    required this.icon,
    required this.label,
    required this.url,
    required this.c,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            Icon(icon, size: 20.sp, color: c.accent),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                label,
                style: text.bodyMedium?.copyWith(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              PhosphorIconsBold.arrowSquareOut,
              size: 16.sp,
              color: c.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

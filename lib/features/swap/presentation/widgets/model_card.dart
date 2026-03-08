import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sage/core/theme/app_colors.dart';

/// ML Model status card shown on the Intelligence screen.
class ModelCard extends StatelessWidget {
  final String status;
  final Color statusColor;
  final IconData icon;
  final List<Widget> children;
  final SageColors c;
  final TextTheme text;

  const ModelCard({
    super.key,
    required this.status,
    required this.statusColor,
    required this.icon,
    required this.children,
    required this.c,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: c.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20.sp, color: statusColor),
              SizedBox(width: 10.w),
              Text(
                status,
                style: text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
              const Spacer(),
              Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          if (children.isNotEmpty) ...[
            SizedBox(height: 14.h),
            ...children,
          ],
        ],
      ),
    );
  }
}

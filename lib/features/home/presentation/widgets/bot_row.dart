import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_theme.dart';

/// Single bot row in the light panel.
class BotRow extends StatelessWidget {
  final String name;
  final String balance;
  final String status;
  final Color statusColor;

  const BotRow({
    super.key,
    required this.name,
    required this.balance,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sage;
    final text = context.sageText;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: text.titleMedium?.copyWith(color: c.panelText),
                ),
                SizedBox(height: 3.h),
                Text(
                  status,
                  style: text.labelMedium?.copyWith(color: statusColor),
                ),
              ],
            ),
          ),
          Text(
            balance,
            style: text.titleMedium?.copyWith(
              color: c.panelText,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

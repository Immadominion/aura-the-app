import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:aura/core/theme/app_colors.dart';

/// Data class holding a label/value pair for the fleet overview.
class FleetInfo {
  final String label;
  final String value;
  const FleetInfo(this.label, this.value);
}

/// Horizontal row of [FleetInfo] items displayed in the fleet overview card.
class FleetInfoRow extends StatelessWidget {
  final List<FleetInfo> items;
  final SageColors c;
  final TextTheme text;

  const FleetInfoRow({
    super.key,
    required this.items,
    required this.c,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items.asMap().entries.expand((entry) {
        final i = entry.key;
        final item = entry.value;
        return [
          if (i > 0) SizedBox(width: 20.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.value,
                style: text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                item.label,
                style: text.labelSmall?.copyWith(
                  color: c.textTertiary,
                  fontSize: 10.sp,
                ),
              ),
            ],
          ),
        ];
      }).toList(),
    );
  }
}

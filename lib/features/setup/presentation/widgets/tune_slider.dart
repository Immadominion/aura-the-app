import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:sage/core/theme/app_colors.dart';
import 'package:sage/features/setup/presentation/widgets/arrow_thumb_shape.dart';
import 'package:sage/features/setup/presentation/widgets/tick_marks.dart';

/// Tune slider — custom arrow-thumb slider for fine-tuning
/// bot parameters. Matches the screenshot style: rounded track,
/// blue arrow pointer thumb, tick marks below.
class TuneSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String unit;
  final String Function(double) format;
  final ValueChanged<double> onChanged;
  final SageColors c;
  final TextTheme text;

  const TuneSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.unit,
    required this.format,
    required this.onChanged,
    required this.c,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final tickCount = divisions.clamp(4, 12);
    final fraction = (value.clamp(min, max) - min) / (max - min);
    final activeTickIndex = (fraction * tickCount).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label + value
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: text.bodySmall?.copyWith(
                color: c.textSecondary,
                fontSize: 13.sp,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                '${format(value)} $unit',
                style: text.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.sp,
                  color: c.accent,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),

        // Slider with arrow thumb
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: c.accent,
            inactiveTrackColor: c.textTertiary.withValues(alpha: 0.15),
            thumbShape: ArrowThumbShape(thumbWidth: 16.r, thumbHeight: 26.r),
            thumbColor: c.accent,
            overlayColor: c.accent.withValues(alpha: 0.08),
            trackHeight: 5.h,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
          ),
        ),

        // Tick marks
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: TickMarks(
            count: tickCount + 1,
            activeIndex: activeTickIndex,
            activeColor: c.accent.withValues(alpha: 0.6),
            inactiveColor: c.textTertiary.withValues(alpha: 0.25),
          ),
        ),
      ],
    );
  }
}

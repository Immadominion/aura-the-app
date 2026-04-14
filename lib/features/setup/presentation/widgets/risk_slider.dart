import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/features/setup/presentation/widgets/arrow_thumb_shape.dart';
import 'package:aura/features/setup/presentation/widgets/tick_marks.dart';

/// Compact gamified risk profile picker — a single slider with
/// 3 snap points (Conservative / Balanced / Aggressive) and
/// a custom arrow thumb.
class RiskSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final SageColors c;
  final TextTheme text;

  const RiskSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.c,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    const labels = ['Conservative', 'Balanced', 'Aggressive'];
    final colors = [c.info, c.accent, c.warning];
    final selectedIndex = value.round();

    return Column(
      children: [
        // Slider
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: c.accent,
            inactiveTrackColor: c.textTertiary.withValues(alpha: 0.18),
            thumbShape: ArrowThumbShape(thumbWidth: 22.r, thumbHeight: 34.r),
            thumbColor: c.accent,
            overlayColor: c.accent.withValues(alpha: 0.08),
            trackHeight: 6.h,
          ),
          child: Slider(
            value: value,
            min: 0,
            max: 2,
            divisions: 2,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
          ),
        ),

        SizedBox(height: 4.h),

        // Tick marks
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: TickMarks(
            count: 11,
            activeIndex: selectedIndex * 5,
            activeColor: c.accent,
            inactiveColor: c.textTertiary.withValues(alpha: 0.3),
          ),
        ),

        SizedBox(height: 14.h),

        // Profile labels
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (i) {
              final isActive = i == selectedIndex;
              return AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                  color: isActive ? colors[i] : c.textTertiary,
                  letterSpacing: isActive ? 0.2 : 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Text(labels[i])],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Row of evenly-spaced vertical dashes below the slider
/// track, matching the screenshot reference.
class TickMarks extends StatelessWidget {
  final int count;
  final int activeIndex;
  final Color activeColor;
  final Color inactiveColor;

  const TickMarks({
    super.key,
    required this.count,
    required this.activeIndex,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(count, (i) {
        return Container(
          width: 1.5.w,
          height: 8.h,
          decoration: BoxDecoration(
            color: i <= activeIndex ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(0.75.r),
          ),
        );
      }),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:sage/core/theme/app_colors.dart';

/// Three bare glyphs — no labels, no containers.
/// Fleet is accessible via the Automate screen CTA, not the top bar.
/// Active icon is full opacity, inactive dims to 35%.
class ModeSelector extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTap;

  const ModeSelector({
    super.key,
    required this.activeIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sage;

    final icons = [
      PhosphorIconsBold.stack,
      PhosphorIconsBold.sparkle,
      PhosphorIconsBold.chartBar,
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(icons.length, (i) {
        // Fleet (index 3) is reached via CTA — show Automate (index 2) as active.
        final effectiveIndex = activeIndex.clamp(0, icons.length - 1);
        final isActive = i == effectiveIndex;
        return GestureDetector(
          onTap: () => onTap(i),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isActive ? 1.0 : 0.35,
              child: Icon(icons[i], size: 20.sp, color: c.modeActive),
            ),
          ),
        );
      }),
    );
  }
}

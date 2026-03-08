import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:sage/core/theme/app_colors.dart';

/// Section header label (uppercase, spaced).
class SectionLabel extends StatelessWidget {
  final String label;
  final SageColors c;
  final TextTheme text;
  const SectionLabel({
    super.key,
    required this.label,
    required this.c,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: text.titleSmall?.copyWith(
        fontSize: 10.sp,
        letterSpacing: 1.5,
        color: c.textTertiary,
      ),
    );
  }
}

/// Standard text input field for bot creation.
class BotInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final SageColors c;
  final TextTheme text;

  const BotInputField({
    super.key,
    required this.controller,
    required this.hint,
    required this.c,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: text.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: c.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: text.titleMedium?.copyWith(color: c.textTertiary),
        filled: true,
        fillColor: c.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: c.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: c.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: c.accent, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      ),
    );
  }
}

/// Horizontal segmented picker for enum-like options.
class SegmentedPicker<T> extends StatelessWidget {
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;
  final SageColors c;
  final TextTheme text;

  const SegmentedPicker({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.c,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: c.borderSubtle),
      ),
      child: Row(
        children: options.entries.map((entry) {
          final isSelected = entry.key == value;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(entry.key);
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  color: isSelected ? c.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(11.r),
                ),
                child: Center(
                  child: Text(
                    entry.value,
                    style: text.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected ? c.textPrimary : c.textTertiary,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Slider with inline value badge.
class SliderRow extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String unit;
  final String Function(double) format;
  final ValueChanged<double> onChanged;
  final SageColors c;
  final TextTheme text;

  const SliderRow({
    super.key,
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
    return Row(
      children: [
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: c.accent,
              inactiveTrackColor: c.surface,
              thumbColor: c.accent,
              overlayColor: c.accent.withValues(alpha: 0.15),
              trackHeight: 3,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7.r),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: c.borderSubtle),
          ),
          child: Text(
            '${format(value)} $unit',
            style: text.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
              fontSize: 13.sp,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

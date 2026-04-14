import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────
// Sage 6.0 — Execution Engine Components
//
// Minimal. Institutional. Every widget earns its place.
// ─────────────────────────────────────────────────────────

/// Uppercase tracked label — the institutional signature.
class SageLabel extends StatelessWidget {
  final String text;
  final Color? color;
  final double? fontSize;
  final double? tracking;

  const SageLabel(
    this.text, {
    super.key,
    this.color,
    this.fontSize,
    this.tracking,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sage;
    final textTheme = context.sageText;
    return Text(
      text.toUpperCase(),
      style: textTheme.titleSmall?.copyWith(
        fontSize: fontSize ?? 11.sp,
        letterSpacing: tracking ?? 2.0,
        color: color ?? c.textSecondary,
      ),
    );
  }
}

/// Dominant metric — large light-weight number with optional decimal.
class SageMetric extends StatelessWidget {
  final String whole;
  final String? decimal;
  final String? prefix;
  final Color? color;

  const SageMetric(
    this.whole, {
    super.key,
    this.decimal,
    this.prefix,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sage;
    final text = context.sageText;
    final mainColor = color ?? c.textPrimary;

    return Text.rich(
      TextSpan(
        children: [
          if (prefix != null)
            TextSpan(
              text: prefix,
              style: text.displayLarge?.copyWith(color: mainColor),
            ),
          TextSpan(
            text: whole,
            style: text.displayLarge?.copyWith(color: mainColor),
          ),
          if (decimal != null)
            TextSpan(
              text: decimal,
              style: text.displayMedium?.copyWith(
                fontSize: 20.sp,
                color: mainColor.withValues(alpha: 0.4),
              ),
            ),
        ],
      ),
    );
  }
}

/// Stat box — label on top, big value below. Works on both dark and light zones.
class SageStatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool onPanel;

  const SageStatBox({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.onPanel = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sage;
    final text = context.sageText;
    final labelColor = onPanel ? c.panelTextSecondary : c.textTertiary;
    final valColor = valueColor ?? (onPanel ? c.panelText : c.textPrimary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: text.labelSmall?.copyWith(color: labelColor),
        ),
        SizedBox(height: 6.h),
        Text(value, style: text.displaySmall?.copyWith(color: valColor)),
      ],
    );
  }
}

/// Strategy/allocation row — uppercase name, detail, trailing value, chevron.
class SageAllocRow extends StatelessWidget {
  final String name;
  final String detail;
  final String? trailing;
  final VoidCallback? onTap;

  const SageAllocRow({
    super.key,
    required this.name,
    required this.detail,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sage;
    final text = context.sageText;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 18.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    name.toUpperCase(),
                    style: text.titleSmall?.copyWith(
                      fontSize: 13.sp,
                      letterSpacing: 1.2,
                      color: c.textPrimary,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (trailing != null)
                      Text(
                        trailing!,
                        style: text.bodySmall?.copyWith(
                          color: c.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    SizedBox(width: 8.w),
                    Icon(
                      PhosphorIconsBold.caretDown,
                      size: 14.sp,
                      color: c.textTertiary,
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              detail.toUpperCase(),
              style: text.labelSmall?.copyWith(
                letterSpacing: 1.0,
                color: c.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thin divider.
class SageDivider extends StatelessWidget {
  final bool onPanel;
  const SageDivider({super.key, this.onPanel = false});

  @override
  Widget build(BuildContext context) {
    final c = context.sage;
    return Divider(
      height: 1,
      thickness: 0.5,
      color: onPanel ? c.panelBorder : c.border,
    );
  }
}

/// Floating voice/AI button — white circle with waveform.
class SageVoiceButton extends StatelessWidget {
  final VoidCallback? onTap;

  const SageVoiceButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.sage;
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap?.call();
      },
      child: Container(
        width: 56.w,
        height: 56.w,
        decoration: BoxDecoration(
          color: c.textPrimary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: c.overlay,
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            PhosphorIconsBold.waveform,
            size: 22.sp,
            color: c.textInverse,
          ),
        ),
      ),
    );
  }
}

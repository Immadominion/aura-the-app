import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_radii.dart';
import 'package:aura/core/theme/app_theme.dart';

/// Aura primary button — solid color, iOS squircle radius, 3D shadow.
///
/// Pulls all colors from the active theme via `context.aura`.
/// No gradients. No hardcoded colors.
class AuraButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final bool enabled;
  final bool isLoading;
  final bool withBorder;

  /// Override the button color. Defaults to `aura.buttonPrimary`.
  final Color? color;

  /// Override the text color. Defaults to `aura.buttonPrimaryText`.
  final Color? textColor;

  const AuraButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.enabled = true,
    this.isLoading = false,
    this.withBorder = true,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final text = context.auraText;
    final radii = context.auraRadii;

    final btnColor = enabled ? (color ?? c.buttonPrimary) : c.buttonDisabled;
    final btnTextColor = textColor ?? c.buttonPrimaryText;
    final shape = ContinuousRectangleBorder(
      borderRadius: BorderRadius.circular(radii.lg),
    );

    final buttonChild = isLoading
        ? SizedBox(
            width: 20.w,
            height: 20.w,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(btnTextColor),
            ),
          )
        : Text(label, style: text.labelLarge?.copyWith(color: btnTextColor));

    return Container(
      width: double.infinity,
      decoration: ShapeDecoration(
        shape: shape,
        color: btnColor,
        shadows: withBorder
            ? [
                BoxShadow(
                  color: btnColor.withValues(alpha: 0.3),
                  blurRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: btnColor.withValues(alpha: 0.15),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: (enabled && !isLoading) ? onPressed : null,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: shape,
          padding: EdgeInsets.symmetric(vertical: 16.h),
        ),
        child: buttonChild,
      ),
    );
  }
}

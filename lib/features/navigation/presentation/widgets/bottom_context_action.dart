import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:sage/core/theme/app_colors.dart';

/// Floating action button at the bottom of the app shell.
///
/// On the Automate tab it expands to a "New Strategy" pill;
/// on Fleet it hides; otherwise it shows a compact waveform icon.
class BottomContextAction extends StatelessWidget {
  final int currentIndex;
  final VoidCallback onHomeVoiceTap;

  const BottomContextAction({
    super.key,
    required this.currentIndex,
    required this.onHomeVoiceTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sage;
    final text = Theme.of(context).textTheme;
    final isAutomate = currentIndex == 2;
    final showPill = isAutomate;

    return GestureDetector(
      onTap: () {
        if (isAutomate) {
          HapticFeedback.selectionClick();
          context.push('/create-strategy');
          return;
        }
        if (currentIndex == 0) {
          onHomeVoiceTap();
          return;
        }
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        height: 56.h,
        width: showPill ? 178.w : 56.w,
        padding: EdgeInsets.symmetric(horizontal: showPill ? 18.w : 0),
        decoration: BoxDecoration(
          color: c.textPrimary,
          borderRadius: BorderRadius.circular(999.r),
          boxShadow: [
            BoxShadow(
              color: c.overlay,
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: Icon(
                  showPill
                      ? PhosphorIconsBold.plus
                      : PhosphorIconsBold.waveform,
                  key: ValueKey(currentIndex),
                  size: showPill ? 18.sp : 22.sp,
                  color: c.textInverse,
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: SizedBox(width: showPill ? 8.w : 0),
              ),
              ClipRect(
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.centerLeft,
                  widthFactor: showPill ? 1 : 0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: showPill ? 1 : 0,
                    child: Text(
                      'New Strategy',
                      style: text.titleMedium?.copyWith(
                        color: c.textInverse,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

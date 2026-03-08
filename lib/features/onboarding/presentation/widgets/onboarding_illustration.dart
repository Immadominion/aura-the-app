import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';

import 'package:sage/features/onboarding/presentation/widgets/rive_illustration.dart';

/// Illustration widget that switches between Lottie assets
/// and the Rive gamepad illustration based on page index.
class OnboardingIllustration extends StatelessWidget {
  final int index;
  const OnboardingIllustration({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    // Page 3 uses an interactive Rive file — handled by its own widget.
    if (index == 2) return const RiveIllustration();

    final child = switch (index) {
      0 => Lottie.asset(
        'assets/animation/lottie/money.json',
        fit: BoxFit.contain,
      ),
      _ => Lottie.asset(
        'assets/animation/lottie/growth.json',
        fit: BoxFit.contain,
      ),
    };

    return Center(
          child: SizedBox(width: 250.w, height: 250.w, child: child),
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: 100.ms)
        .scale(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1, 1),
          curve: Curves.easeOutCubic,
        );
  }
}

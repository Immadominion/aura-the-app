import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:sage/core/theme/app_colors.dart';

/// Splash screen — holds while [authStateProvider], [onboardingSeenProvider],
/// and [splashMinDelayProvider] all resolve. The router owns navigation;
/// this screen never navigates itself.
///
/// Design: uses the current theme's onboarding navy as the background so
/// even brief flashes feel consistent with the active color scheme.
/// Layered stagger animations give a premium cascading reveal feel.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const _accent = Color(0xFF7B61FF); // purple from the A gradient
  static const _taglineColor = Color(0xFF5B8DEF);

  @override
  Widget build(BuildContext context) {
    // Use the theme-aware onboarding navy so it doesn't clash in light mode.
    final bg = context.sage.onboardingNavy;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // ── Ambient background glow — very subtle, non-distracting ──
          Positioned(
            top: -120.r,
            left: -80.r,
            child: Container(
              width: 340.r,
              height: 340.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_accent.withValues(alpha: 0.10), Colors.transparent],
                ),
              ),
            ),
          ).animate().fadeIn(duration: 1200.ms, curve: Curves.easeOut),

          Positioned(
            bottom: -100.r,
            right: -60.r,
            child: Container(
              width: 260.r,
              height: 260.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _taglineColor.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(duration: 1400.ms, curve: Curves.easeOut),

          // ── Main content ──
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo — rendered directly on the dark navy background.
                Image.asset(
                      'assets/images/splash-logo.png',
                      width: 240.w,
                      fit: BoxFit.contain,
                    )
                    .animate()
                    .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                    .scale(
                      begin: const Offset(0.88, 0.88),
                      end: const Offset(1.0, 1.0),
                      duration: 600.ms,
                      curve: Curves.easeOutCubic,
                    ),

                SizedBox(height: 20.h),

                // Tagline
                Text(
                      'Autonomous LP Intelligence',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: _taglineColor.withValues(alpha: 0.85),
                        letterSpacing: 1.8,
                      ),
                    )
                    .animate(delay: 350.ms)
                    .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                    .slideY(
                      begin: 0.4,
                      end: 0.0,
                      duration: 500.ms,
                      curve: Curves.easeOutCubic,
                    ),
              ],
            ),
          ),

          // ── Bottom accent line ──
          Positioned(
            bottom: 52.h,
            left: 0,
            right: 0,
            child: Center(
              child:
                  Container(
                        width: 32.w,
                        height: 2.h,
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      )
                      .animate(delay: 700.ms)
                      .fadeIn(duration: 600.ms)
                      .scaleX(
                        begin: 0.0,
                        end: 1.0,
                        duration: 700.ms,
                        curve: Curves.easeOutCubic,
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

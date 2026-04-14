import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_theme.dart';
import 'package:aura/shared/widgets/sage_button.dart';

import 'package:aura/features/onboarding/models/onboarding_page.dart';
import 'package:aura/features/onboarding/presentation/widgets/onboarding_illustration.dart';

/// Onboarding — 3 pages, NO PageView.
///
/// The dark illustration panel is static (no sliding).
/// Illustration + text crossfade on swipe/tap.
/// Swipe gestures detected manually on the whole screen.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _current = 0;

  static const _totalPages = 3;

  @override
  void initState() {
    super.initState();
  }

  // ── Page data ──
  static const _pages = [
    OnboardingPage(
      headline: 'Your capital,\nalways working',
      body:
          'Sage deploys SOL into Meteora LP positions '
          'using ML to find high-yield opportunities. '
          'Earn fees while you sleep.',
    ),
    OnboardingPage(
      headline: 'Automate your \ntrading strategy',
      body:
          'Define your rules, triggers, and conditions.'
          'Deploy your personal strategy that executes 24/7, '
          'No code.',
    ),
    OnboardingPage(
      headline: 'Controlled power, \nin your hands.',
      body:
          'Define strict risk and spending limits. '
          'Sage operates within your exact parameters',
    ),
  ];

  void _goTo(int index) {
    if (index < 0 || index >= _totalPages || index == _current) return;
    HapticFeedback.selectionClick();
    setState(() => _current = index);
  }

  void _next() {
    if (_current < _totalPages - 1) {
      _goTo(_current + 1);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    if (mounted) context.go('/connect-wallet');
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final page = _pages[_current];

    final c = context.sage;
    final text = context.sageText;
    final navy = c.onboardingNavy;
    final accentBlue = c.onboardingAccent;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: c.panelBackground,
        body: GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity == null) return;
            if (details.primaryVelocity! < -200) {
              // Swipe left → next
              _next();
            } else if (details.primaryVelocity! > 200) {
              // Swipe right → prev
              _goTo(_current - 1);
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Column(
            children: [
              // ════════════════════════════════════════
              // DARK ILLUSTRATION PANEL — static container,
              // content crossfades inside
              // ════════════════════════════════════════
              Expanded(
                flex: 75,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: navy,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(32.r),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: OnboardingIllustration(
                      key: ValueKey(_current),
                      index: _current,
                    ),
                  ),
                ),
              ),

              // ════════════════════════════════════════
              // WHITE CONTENT — text crossfades in place
              // ════════════════════════════════════════
              Expanded(
                flex: 45,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 28.w),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: Column(
                      key: ValueKey(_current),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          page.headline,
                          textAlign: TextAlign.center,
                          style: text.headlineLarge?.copyWith(
                            fontSize: 32.sp,
                            color: navy,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          page.body,
                          textAlign: TextAlign.center,
                          style: text.bodyMedium?.copyWith(
                            color: c.panelTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ════════════════════════════════════════
              // BOTTOM CONTROLS
              // ════════════════════════════════════════
              Padding(
                padding: EdgeInsets.fromLTRB(28.w, 0, 28.w, bottomPad + 24.h),
                child: SizedBox(
                  height: 100.h,
                  child: _current == _totalPages - 1
                      ? Align(
                          alignment: Alignment.topCenter,
                          child: SageButton(
                            onPressed: _finish,
                            label: 'Get Started',
                            color: accentBlue,
                          ),
                        )
                      : Align(
                          alignment: Alignment.topCenter,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Skip
                              GestureDetector(
                                onTap: _finish,
                                child: Text(
                                  'Skip',
                                  style: text.titleMedium?.copyWith(
                                    fontSize: 16.sp,
                                    color: c.panelTextSecondary,
                                  ),
                                ),
                              ),
                              // Dots
                              Row(
                                children: List.generate(_totalPages, (i) {
                                  final isActive = i == _current;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    width: isActive ? 10.w : 8.w,
                                    height: isActive ? 10.w : 8.w,
                                    margin: EdgeInsets.symmetric(
                                      horizontal: 4.w,
                                    ),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isActive ? navy : c.panelBorder,
                                    ),
                                  );
                                }),
                              ),
                              // Next
                              GestureDetector(
                                onTap: _next,
                                child: Text(
                                  'Next',
                                  style: text.titleMedium?.copyWith(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w800,
                                    color: navy,
                                  ),
                                ),
                              ),
                            ],
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

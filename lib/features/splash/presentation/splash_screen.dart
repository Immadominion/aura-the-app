import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura/core/theme/app_colors.dart';

/// Splash screen — holds while [authStateProvider], [onboardingSeenProvider],
/// and [splashMinDelayProvider] all resolve. The router owns navigation;
/// this screen never navigates itself.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _taglineColor = Color(0xFF5B8DEF);

  // Implicit animation state — mutated via setState + Timer
  double _titlePushDown = 2; // screenHeight / _titlePushDown → starts ~center
  double _logoScale = 1.5; // screenWidth / _logoScale → starts small
  double _textOpacity = 0.0;
  double _logoOpacity = 0.0;
  double _taglineOpacity = 0.0;

  late final AnimationController _fontSizeController;
  late final Animation<double> _titleFontSize;

  @override
  void initState() {
    super.initState();

    _fontSizeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Title font shrinks from 36 → 18 with a satisfying ease
    _titleFontSize = Tween<double>(begin: 36, end: 18).animate(
      CurvedAnimation(
        parent: _fontSizeController,
        curve: Curves.fastLinearToSlowEaseIn,
      ),
    );

    _fontSizeController.forward();

    // Text fades in immediately
    Timer(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      setState(() => _textOpacity = 1.0);
    });

    // After 2s: title drops down, logo reveals at center
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _titlePushDown = 1.06;
        _logoScale = 2;
        _logoOpacity = 1;
      });
    });

    // After 2.8s: tagline fades in
    Timer(const Duration(milliseconds: 2800), () {
      if (!mounted) return;
      setState(() => _taglineOpacity = 1.0);
    });
  }

  @override
  void dispose() {
    _fontSizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = context.sage.onboardingNavy;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // ── "SAGE" text — starts centered, then drops down ──
          Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 2000),
                curve: Curves.fastLinearToSlowEaseIn,
                height: screenHeight / _titlePushDown,
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 1000),
                opacity: _textOpacity,
                child: AnimatedBuilder(
                  animation: _titleFontSize,
                  builder: (context, _) => Text(
                    'SAGE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: _titleFontSize.value,
                      letterSpacing: 4,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Logo — fades in + expands at center ──
          Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 2000),
              curve: Curves.fastLinearToSlowEaseIn,
              opacity: _logoOpacity,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 2000),
                curve: Curves.fastLinearToSlowEaseIn,
                height: screenWidth / _logoScale,
                width: screenWidth / _logoScale,
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/images/sage-logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // ── Tagline — fades in below center ──
          Positioned(
            bottom: screenHeight * 0.15,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              opacity: _taglineOpacity,
              child: Text(
                'Autonomous LP Intelligence',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  color: _taglineColor.withValues(alpha: 0.85),
                  letterSpacing: 1.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:sage/core/theme/app_colors.dart';
import 'package:sage/core/theme/app_theme.dart';
import 'package:sage/core/services/auth_service.dart';
import 'package:sage/shared/widgets/sage_button.dart';

/// Connect Wallet — full-screen dark gate with Rive hero animation.
///
/// Completely theme-aware. No hardcoded colors.
class ConnectWalletScreen extends ConsumerStatefulWidget {
  const ConnectWalletScreen({super.key});

  @override
  ConsumerState<ConnectWalletScreen> createState() =>
      _ConnectWalletScreenState();
}

class _ConnectWalletScreenState extends ConsumerState<ConnectWalletScreen> {
  bool _connecting = false;
  String? _error;

  Future<void> _connectWallet() async {
    setState(() {
      _connecting = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();

    try {
      // Full SIWS flow in a single MWA session.
      // Wallet opens once → user authorizes + signs → returns to Sage.
      await ref.read(authStateProvider.notifier).signIn();

      if (!mounted) return;
      HapticFeedback.heavyImpact();
      // Router redirect handles navigation automatically when
      // authStateProvider transitions to authenticated. No need
      // for context.go('/') which caused a splash flash.
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.selectionClick();
      setState(() {
        _connecting = false;
        _error = _friendlyError(e.toString());
      });
    }
  }

  String _friendlyError(String? raw) {
    if (raw == null) return 'Connection failed. Try again.';
    if (raw.contains('cancelled') || raw.contains('cancel')) {
      return 'Connection cancelled.';
    }
    if (raw.contains('No wallet') || raw.contains('no wallet')) {
      return 'No compatible wallet found.\nInstall one from the store.';
    }
    if (raw.contains('Signing failed')) {
      return 'Message signing failed. Try again.';
    }
    // Network errors from Dio (backend unreachable, wrong IP, etc.)
    if (raw.contains('Backend unreachable') ||
        raw.contains('SocketException') ||
        raw.contains('connection timeout') ||
        raw.contains('Connection refused')) {
      return 'Cannot reach backend.\nCheck your network or backend URL.';
    }
    if (raw.contains('timeout') || raw.contains('Timeout')) {
      return 'Request timed out. Try again.';
    }
    return 'Connection failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sage;
    final text = context.sageText;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: c.background,
      ),
      child: Scaffold(
        backgroundColor: c.background,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 1),

                // ── Rive hero animation ──────────────────
                Center(
                  child: RepaintBoundary(
                    child: SizedBox(
                      width: 280.w,
                      height: 280.w,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28.r),
                        child: Image.asset(
                          'assets/images/onboarding1.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 100.ms),

                const Spacer(flex: 1),

                // ── Headline ─────────────────────────────
                Text('Connect your\nwallet', style: text.headlineLarge)
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 250.ms)
                    .slideY(begin: 0.05, end: 0),

                SizedBox(height: 12.h),

                // ── Subtitle ─────────────────────────────
                Text(
                  'Make your own rules, or use our Sage Agent.\nLP while you sleep, it\'s never been easier.',
                  style: text.bodyMedium,
                ).animate().fadeIn(duration: 500.ms, delay: 350.ms),

                const Spacer(flex: 1),

                // ── Error ────────────────────────────────
                if (_error != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: Text(
                      _error!,
                      style: text.bodySmall?.copyWith(
                        color: c.loss,
                        fontWeight: FontWeight.w600,
                      ),
                    ).animate().fadeIn(duration: 300.ms).shakeX(hz: 3),
                  ),

                // ── CTA ──────────────────────────────────
                SageButton(
                      label: 'Connect Wallet',
                      onPressed: _connectWallet,
                      isLoading: _connecting,
                    )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 500.ms)
                    .slideY(begin: 0.08, end: 0),

                SizedBox(height: 20.h),

                // ── Legal ────────────────────────────────
                Center(
                  child: Text(
                    'By connecting you agree to our Terms\nand Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: text.labelSmall?.copyWith(
                      color: c.textTertiary,
                      letterSpacing: 0,
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 600.ms),

                SizedBox(height: 8.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

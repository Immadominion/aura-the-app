import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_theme.dart';
import 'package:aura/core/services/auth_service.dart';
import 'package:aura/shared/widgets/aura_button.dart';

/// Connect Wallet — full-screen dark gate.
///
/// Primary: "Connect Wallet" opens the user's installed Solana wallet
/// via MWA (Mobile Wallet Adapter) for the standard SIWS flow.
///
/// Secondary: Google / Apple buttons create a Phantom embedded wallet
/// for users who don't have an external wallet installed.
///
/// On iOS (where MWA is unavailable) the embedded-wallet buttons are
/// promoted to primary.
class ConnectWalletScreen extends ConsumerStatefulWidget {
  const ConnectWalletScreen({super.key});

  @override
  ConsumerState<ConnectWalletScreen> createState() =>
      _ConnectWalletScreenState();
}

class _ConnectWalletScreenState extends ConsumerState<ConnectWalletScreen> {
  bool _connecting = false;
  String? _activeProvider; // 'google', 'apple', or 'mwa'
  String? _error;

  Future<void> _signInWithPhantom(String provider) async {
    setState(() {
      _connecting = true;
      _activeProvider = provider;
      _error = null;
    });
    HapticFeedback.mediumImpact();

    try {
      await ref.read(authStateProvider.notifier).signInWithPhantom(provider);
      if (!mounted) return;
      HapticFeedback.heavyImpact();
    } catch (e, st) {
      debugPrint('[ConnectWallet] signIn error: $e\n$st');
      if (!mounted) return;
      HapticFeedback.selectionClick();
      setState(() {
        _connecting = false;
        _activeProvider = null;
        _error = _friendlyError(e.toString());
      });
    }
  }

  Future<void> _connectMwa() async {
    setState(() {
      _connecting = true;
      _activeProvider = 'mwa';
      _error = null;
    });
    HapticFeedback.mediumImpact();

    try {
      await ref.read(authStateProvider.notifier).signIn();
      if (!mounted) return;
      HapticFeedback.heavyImpact();
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.selectionClick();
      setState(() {
        _connecting = false;
        _activeProvider = null;
        _error = _friendlyError(e.toString());
      });
    }
  }

  String _friendlyError(String? raw) {
    if (raw == null) return 'Connection failed. Try again.';
    if (raw.contains('cancelled') || raw.contains('cancel')) {
      return 'Sign-in cancelled.';
    }
    if (raw.contains('No wallet') || raw.contains('no wallet')) {
      return 'No compatible wallet found.\nInstall one from the store.';
    }
    if (raw.contains('Signing failed')) {
      return 'Message signing failed. Try again.';
    }
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
    final c = context.aura;
    final text = context.auraText;
    final providerButtons = Wrap(
      alignment: WrapAlignment.center,
      spacing: 16.w,
      children: [
        _ProviderCircleButton(
          icon: PhosphorIconsDuotone.googleLogo,
          tooltip: 'Continue with Google',
          onPressed: () => _signInWithPhantom('google'),
          isLoading: _connecting && _activeProvider == 'google',
          enabled: !_connecting,
        ),
        _ProviderCircleButton(
          icon: PhosphorIconsDuotone.appleLogo,
          tooltip: 'Continue with Apple',
          onPressed: () => _signInWithPhantom('apple'),
          isLoading: _connecting && _activeProvider == 'apple',
          enabled: !_connecting,
        ),
      ],
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: c.background,
      ),
      child: Scaffold(
        backgroundColor: c.background,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.16,
                  child: Image.asset(
                    'assets/images/bg-texture.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 28.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(flex: 3),

                    // ── Headline ─────────────────────────────
                    Text('Welcome to\nAura.', style: text.headlineLarge)
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 150.ms)
                        .slideY(begin: 0.05, end: 0),

                    SizedBox(height: 12.h),

                    // ── Subtitle ─────────────────────────────
                    Text(
                      Platform.isAndroid
                          ? 'Connect your Solana wallet to start trading.'
                          : 'Sign in to start trading. A secure Solana wallet '
                                'is created for you automatically.',
                      style: text.bodyMedium,
                    ).animate().fadeIn(duration: 500.ms, delay: 250.ms),

                    const Spacer(flex: 2),

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

                    // ── Connect Wallet (primary CTA — MWA on Android) ──
                    if (Platform.isAndroid) ...[
                      AuraButton(
                            label: _connecting && _activeProvider == 'mwa'
                                ? 'Connecting…'
                                : 'Connect Wallet',
                            onPressed: _connectMwa,
                            isLoading: _connecting && _activeProvider == 'mwa',
                            enabled: !_connecting,
                          )
                          .animate()
                          .fadeIn(duration: 500.ms, delay: 350.ms)
                          .slideY(begin: 0.08, end: 0),

                      SizedBox(height: 20.h),

                      Center(
                        child: Text(
                          'or continue with',
                          style: text.bodySmall?.copyWith(
                            color: c.textTertiary,
                          ),
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 420.ms),

                      SizedBox(height: 16.h),

                      Center(
                        child: providerButtons,
                      ).animate().fadeIn(duration: 500.ms, delay: 480.ms),
                    ] else ...[
                      Center(child: providerButtons)
                          .animate()
                          .fadeIn(duration: 500.ms, delay: 350.ms)
                          .slideY(begin: 0.08, end: 0),
                    ],

                    SizedBox(height: 16.h),

                    // ── Legal ────────────────────────────────
                    Center(
                      child: Text(
                        'By continuing you agree to our Terms\nand Privacy Policy.',
                        textAlign: TextAlign.center,
                        style: text.labelSmall?.copyWith(
                          color: c.textTertiary,
                          letterSpacing: 0,
                        ),
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 580.ms),

                    SizedBox(height: 8.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderCircleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool enabled;

  const _ProviderCircleButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final enabledState = enabled && !isLoading;

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: enabledState ? onPressed : null,
        child: Container(
          width: 56.w,
          height: 56.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.surface,
            border: Border.all(
              color: enabledState
                  ? c.borderSubtle
                  : c.borderSubtle.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        c.textSecondary,
                      ),
                    ),
                  )
                : Icon(
                    icon,
                    size: 24.sp,
                    color: enabledState ? c.textPrimary : c.textTertiary,
                  ),
          ),
        ),
      ),
    );
  }
}

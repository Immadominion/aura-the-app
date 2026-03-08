import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:rive/rive.dart';

import 'package:sage/core/repositories/wallet_repository.dart';
import 'package:sage/core/services/auth_service.dart';
import 'package:sage/core/services/mwa_wallet_service.dart';
import 'package:sage/core/theme/app_colors.dart';

/// Withdraw SOL from Sage wallet back to user's wallet.
///
/// Designed for use inside [SageBottomSheet.show()].
/// Handles its own loading/success/error state.
///
/// ```dart
/// SageBottomSheet.show<bool>(
///   context: context,
///   title: 'Withdraw',
///   builder: (c, text) => WithdrawSheet(
///     availableBalanceSol: balance,
///     c: c,
///     text: text,
///   ),
/// );
/// ```
class WithdrawSheet extends ConsumerStatefulWidget {
  final double availableBalanceSol;
  final SageColors c;
  final TextTheme text;

  const WithdrawSheet({
    super.key,
    required this.availableBalanceSol,
    required this.c,
    required this.text,
  });

  @override
  ConsumerState<WithdrawSheet> createState() => _WithdrawSheetState();
}

enum _SheetState { input, loading, success, error }

class _WithdrawSheetState extends ConsumerState<WithdrawSheet> {
  var _state = _SheetState.input;
  String? _errorMessage;
  String? _signature;
  double? _withdrawnSol;

  String get _connectedWallet => ref.read(connectedWalletAddressProvider) ?? '';

  /// Recover all SOL by closing the Seal wallet on-chain.
  /// This is the ONLY supported withdrawal path — direct SystemProgram
  /// transfer from the Seal PDA is impossible because the PDA is owned
  /// by the Seal program, not SystemProgram.
  Future<void> _executeWithdraw() async {
    if (_connectedWallet.isEmpty) {
      setState(() {
        _state = _SheetState.error;
        _errorMessage = 'Wallet not connected. Please reconnect your wallet.';
      });
      return;
    }

    setState(() => _state = _SheetState.loading);
    HapticFeedback.mediumImpact();

    try {
      final walletRepo = ref.read(walletRepositoryProvider);
      final mwa = ref.read(mwaWalletServiceProvider);

      // Step 1: Prepare the owner-signed recovery TX (DeregisterAgents + CloseWallet)
      final recovery = await walletRepo.prepareRecoverWallet();
      final txBase64 = recovery['transaction'] as String;
      final network = (recovery['network'] as String?) ?? 'mainnet-beta';

      // Step 2: Sign via MWA
      final signedTxs = await mwa.signTransactions([
        Uint8List.fromList(base64Decode(txBase64)),
      ], cluster: network);

      if (signedTxs.isEmpty) {
        throw Exception('Transaction signing was cancelled');
      }

      // Step 3: Submit
      final result = await walletRepo.submitSigned(
        transactionBase64: base64Encode(signedTxs.first),
        recoverWalletClose: true,
      );

      _signature = result['signature'] as String?;
      _withdrawnSol = widget.availableBalanceSol;
      ref.invalidate(walletBalanceProvider);

      if (mounted) {
        setState(() => _state = _SheetState.success);
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = _SheetState.error;
          _errorMessage = _parseError(e);
        });
        HapticFeedback.heavyImpact();
      }
    }
  }

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('Wallet not found')) {
      return 'No on-chain wallet found. It may already be closed.';
    }
    if (msg.contains('agents still registered') ||
        msg.contains('InvalidAccountData')) {
      return 'Some agents could not be removed. Try again or contact support.';
    }
    if (msg.contains('signing was cancelled')) {
      return 'You cancelled the transaction. No funds were moved.';
    }
    if (msg.contains('balance too low')) {
      return 'Wallet balance too low to withdraw.';
    }
    // Generic
    final match = RegExp(r'message:\s*(.+)').firstMatch(msg);
    return match?.group(1) ?? 'Recovery failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final text = widget.text;

    return switch (_state) {
      _SheetState.input => _buildInput(c, text),
      _SheetState.loading => _buildLoading(c, text),
      _SheetState.success => _buildSuccess(c, text),
      _SheetState.error => _buildError(c, text),
    };
  }

  // ═══════════════════════════════════════════════════════════════
  // Input state — recovery confirmation
  // ═══════════════════════════════════════════════════════════════

  Widget _buildInput(SageColors c, TextTheme text) {
    final hasEnough = widget.availableBalanceSol > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Close your on-chain Sage wallet and return all SOL to your connected wallet.',
          style: text.bodyMedium?.copyWith(color: c.textSecondary),
        ),

        SizedBox(height: 12.h),

        // Warning note
        SizedBox(
          width: double.infinity,

          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(PhosphorIconsBold.warning, size: 16.sp, color: c.warning),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'This will permanently close your Sage wallet. '
                  'All active bots will be stopped. You can create a new wallet later.',
                  style: text.bodySmall?.copyWith(
                    color: c.warning,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 20.h),

        // Balance info
        _InfoRow(
          label: 'Wallet Balance',
          value: '${widget.availableBalanceSol.toStringAsFixed(4)} SOL',
          c: c,
          text: text,
        ),

        Divider(height: 1, color: c.borderSubtle),

        // Destination
        _InfoRow(
          label: 'Destination',
          value: _connectedWallet.isNotEmpty
              ? '${_connectedWallet.substring(0, 6)}…${_connectedWallet.substring(_connectedWallet.length - 4)}'
              : 'Not connected',
          c: c,
          text: text,
        ),

        Divider(height: 1, color: c.borderSubtle),

        // Big amount display
        Padding(
          padding: EdgeInsets.symmetric(vertical: 24.h),
          child: Center(
            child: Text(
              '${widget.availableBalanceSol.toStringAsFixed(4)} SOL',
              style: text.displayMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: c.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),

        if (!hasEnough)
          Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: Text(
              'No balance to recover.',
              style: text.bodySmall?.copyWith(color: c.loss),
            ),
          ),

        // Recover button
        GestureDetector(
          onTap: hasEnough ? _executeWithdraw : null,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            decoration: BoxDecoration(
              color: hasEnough ? c.accent : c.buttonDisabled,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Center(
              child: Text(
                'Recover All SOL',
                style: text.titleMedium?.copyWith(
                  color: c.buttonPrimaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),

        SizedBox(height: 8.h),

        // Cancel
        GestureDetector(
          onTap: () => Navigator.pop(context, false),
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Text(
                'Cancel',
                style: text.bodyMedium?.copyWith(color: c.textTertiary),
              ),
            ),
          ),
        ),

        SizedBox(height: 8.h),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Loading state
  // ═══════════════════════════════════════════════════════════════

  Widget _buildLoading(SageColors c, TextTheme text) {
    return SizedBox(
      height: 200.h,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32.w,
              height: 32.w,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(c.accent),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Closing wallet…',
              style: text.titleMedium?.copyWith(
                color: c.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Recovering ${widget.availableBalanceSol.toStringAsFixed(4)} SOL to your wallet',
              style: text.bodySmall?.copyWith(color: c.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Success state
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSuccess(SageColors c, TextTheme text) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 16.h),

        // Success animation
        SizedBox(
          width: 80.w,
          height: 80.w,
          child: const _RiveAsset(asset: 'assets/animation/rive/success.riv'),
        ),

        SizedBox(height: 20.h),

        Text(
          'Recovery Complete',
          style: text.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),

        SizedBox(height: 8.h),

        Text(
          '${(_withdrawnSol ?? widget.availableBalanceSol).toStringAsFixed(4)} SOL returned to your wallet',
          style: text.bodyMedium?.copyWith(color: c.textSecondary),
        ),

        if (_signature != null) ...[
          SizedBox(height: 12.h),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: _signature!));
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Signature copied')));
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  PhosphorIconsBold.copy,
                  size: 12.sp,
                  color: c.textTertiary,
                ),
                SizedBox(width: 4.w),
                Text(
                  'TX: ${_signature!.substring(0, 8)}…${_signature!.substring(_signature!.length - 4)}',
                  style: text.bodySmall?.copyWith(
                    color: c.textTertiary,
                    fontFamily: 'monospace',
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
        ],

        SizedBox(height: 28.h),

        // Done button
        GestureDetector(
          onTap: () => Navigator.pop(context, true),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            decoration: BoxDecoration(
              color: c.accent,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Center(
              child: Text(
                'Done',
                style: text.titleMedium?.copyWith(
                  color: c.buttonPrimaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),

        SizedBox(height: 16.h),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Error state
  // ═══════════════════════════════════════════════════════════════

  Widget _buildError(SageColors c, TextTheme text) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 16.h),

        // Failure animation
        SizedBox(
          width: 80.w,
          height: 80.w,
          child: const _RiveAsset(asset: 'assets/animation/rive/failure.riv'),
        ),

        SizedBox(height: 20.h),

        Text(
          'Recovery Failed',
          style: text.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),

        SizedBox(height: 8.h),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            _errorMessage ?? 'An unknown error occurred.',
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: c.textSecondary),
          ),
        ),

        SizedBox(height: 28.h),

        // Retry button
        GestureDetector(
          onTap: () => setState(() => _state = _SheetState.input),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            decoration: BoxDecoration(
              color: c.accent,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Center(
              child: Text(
                'Try Again',
                style: text.titleMedium?.copyWith(
                  color: c.buttonPrimaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),

        SizedBox(height: 8.h),

        GestureDetector(
          onTap: () => Navigator.pop(context, false),
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Text(
                'Cancel',
                style: text.bodyMedium?.copyWith(color: c.textTertiary),
              ),
            ),
          ),
        ),

        SizedBox(height: 8.h),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Shared info row (label: value)
// ═══════════════════════════════════════════════════════════════

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final SageColors c;
  final TextTheme text;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.c,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        children: [
          Text(
            label,
            style: text.titleMedium?.copyWith(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: c.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: text.titleMedium?.copyWith(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// One-shot Rive animation from asset
// ═══════════════════════════════════════════════════════════════

class _RiveAsset extends StatefulWidget {
  final String asset;
  const _RiveAsset({required this.asset});

  @override
  State<_RiveAsset> createState() => _RiveAssetState();
}

class _RiveAssetState extends State<_RiveAsset> {
  late final FileLoader _loader;

  @override
  void initState() {
    super.initState();
    _loader = FileLoader.fromAsset(widget.asset, riveFactory: Factory.rive);
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RiveWidgetBuilder(
      fileLoader: _loader,
      builder: (context, state) => switch (state) {
        RiveLoading() => const SizedBox.expand(),
        RiveFailed() => const SizedBox.expand(),
        RiveLoaded() => RiveWidget(
          controller: state.controller,
          fit: Fit.contain,
        ),
      },
    );
  }
}

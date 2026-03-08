import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:sage/core/models/bot.dart';
import 'package:sage/core/config/env_config.dart';
import 'package:sage/core/models/bot_event.dart';
import 'package:sage/core/repositories/bot_repository.dart';
import 'package:sage/core/repositories/wallet_repository.dart';
import 'package:sage/core/services/event_service.dart';
import 'package:sage/core/services/mwa_wallet_service.dart';
import 'package:sage/core/services/seal_agent_service.dart';
import 'package:sage/core/theme/app_colors.dart';
import 'package:sage/core/theme/app_theme.dart';

import 'package:sage/features/automate/presentation/widgets/stat_chip.dart';
import 'package:sage/features/automate/presentation/widgets/live_position_card.dart';
import 'package:sage/features/automate/presentation/widgets/param_row.dart';
import 'package:sage/features/automate/presentation/widgets/pulsing_dot.dart';
import 'package:sage/features/automate/presentation/widgets/edit_config_sheet.dart';
import 'package:sage/shared/widgets/mwa_button_tap_effect.dart';
import 'package:sage/shared/widgets/sage_bottom_sheet.dart';
import 'package:sage/shared/widgets/withdraw_sheet.dart';

/// Bot Detail — Layer 2 of Automate mode.
///
/// Shows a live bot's state, recent actions, PnL, parameters,
/// and controls to start/stop/emergency-stop.
///

/// Extract a human-readable error from API responses / DioExceptions.
String _apiError(Object e) {
  if (e is DioException && e.response?.data is Map) {
    final msg = (e.response!.data as Map)['message'];
    if (msg is String && msg.isNotEmpty) return msg;
  }
  if (e is DioException) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Connection timed out';
      case DioExceptionType.connectionError:
        return 'Cannot reach server';
      default:
        break;
    }
  }
  final s = e.toString();
  // Strip Dart exception class prefixes
  if (s.startsWith('Exception: ')) return s.substring(11);
  return s;
}

/// Fully wired to real data via [botDetailProvider].
class StrategyDetailScreen extends ConsumerStatefulWidget {
  final String botId;

  const StrategyDetailScreen({super.key, required this.botId});

  @override
  ConsumerState<StrategyDetailScreen> createState() =>
      _StrategyDetailScreenState();
}

class _StrategyDetailScreenState extends ConsumerState<StrategyDetailScreen> {
  bool _isPerformingAction = false;
  Timer? _pollTimer;
  bool _lowBalanceShown = false;

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        ref.invalidate(botDetailProvider(widget.botId));
      }
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _deleteBot() async {
    // Confirm with bottom sheet — matches Sage design language
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final c = ctx.sage;
        final text = ctx.sageText;
        return Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.r),
              topRight: Radius.circular(24.r),
            ),
            border: Border(top: BorderSide(color: c.borderSubtle)),
          ),
          padding: EdgeInsets.fromLTRB(
            24.w,
            20.h,
            24.w,
            MediaQuery.of(ctx).padding.bottom + 24.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: c.borderSubtle,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'Delete Bot',
                style: text.titleLarge?.copyWith(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'This will permanently delete this bot and all its history.\n\nThis action cannot be undone.',
                style: text.bodyMedium?.copyWith(color: c.textSecondary),
              ),
              SizedBox(height: 28.h),
              MWAButtonTapEffect(
                onTap: () => Navigator.pop(ctx, true),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    color: c.loss.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: c.loss.withValues(alpha: 0.35)),
                  ),
                  child: Center(
                    child: Text(
                      'Delete',
                      style: text.titleMedium?.copyWith(
                        color: c.loss,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              MWAButtonTapEffect(
                onTap: () => Navigator.pop(ctx, false),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: c.borderSubtle),
                  ),
                  child: Center(
                    child: Text(
                      'Cancel',
                      style: text.titleMedium?.copyWith(color: c.textSecondary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true || _isPerformingAction) return;

    setState(() => _isPerformingAction = true);
    try {
      // Clean up stored Seal agent/session keys
      final agentService = ref.read(sealAgentServiceProvider);
      await agentService.deleteKeysForBot(widget.botId);

      await ref.read(botListProvider.notifier).deleteBot(widget.botId);
      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Bot deleted')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: ${_apiError(e)}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPerformingAction = false);
    }
  }

  void _showEditConfig(Bot bot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditConfigSheet(
        bot: bot,
        onSave: (config) async {
          try {
            await ref
                .read(botListProvider.notifier)
                .updateConfig(widget.botId, config);
            ref.invalidate(botDetailProvider(widget.botId));
            HapticFeedback.mediumImpact();
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Config updated')));
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
            }
          }
        },
      ),
    );
  }

  Future<void> _startBot() async {
    if (_isPerformingAction) return;
    setState(() => _isPerformingAction = true);
    try {
      final repo = ref.read(botRepositoryProvider);
      final botData = ref.read(botDetailProvider(widget.botId)).value;

      // ── Pre-check: if this is a live bot with no agent keys, skip
      //    straight to setup-live instead of making a doomed API call.
      final needsSetupPreCheck =
          botData != null &&
          botData.mode == BotMode.live &&
          botData.agentPubkey == null;

      if (!needsSetupPreCheck) {
        // Try starting directly — the backend knows if setup is valid
        try {
          await repo.startBot(widget.botId);
          HapticFeedback.mediumImpact();
          ref.invalidate(botDetailProvider(widget.botId));
          ref.invalidate(botListProvider);
          return;
        } catch (startErr) {
          // Extract the actual API message from DioException.response.data,
          // not toString() which omits the response body.
          final msg = _apiError(startErr);
          final needsSetup =
              msg.contains('wallet setup') ||
              msg.contains('session setup') ||
              msg.contains('Live mode requires');
          if (!needsSetup) rethrow;
        }
      }

      // Live-mode bot needs setup-live → build TX + sign via MWA
      if (botData != null && botData.mode == BotMode.live) {
        try {
          await _runSetupLive(botData);
        } catch (e) {
          // Setup failed (signing rejected / simulation error).
          // Do NOT proceed to startBot — the on-chain accounts don't exist.
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Setup failed: ${_apiError(e)}')),
            );
          }
          return;
        }
        // Now try starting again after successful setup
        await repo.startBot(widget.botId);
        HapticFeedback.mediumImpact();
        ref.invalidate(botDetailProvider(widget.botId));
        ref.invalidate(botListProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start: ${_apiError(e)}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPerformingAction = false);
    }
  }

  /// Run setup-live for a live bot that's missing agent + session keys.
  /// Calls the backend to generate keypairs + build TX, then signs via MWA.
  Future<void> _runSetupLive(Bot bot) async {
    final walletRepo = ref.read(walletRepositoryProvider);
    final mwa = ref.read(mwaWalletServiceProvider);

    // Ensure Seal wallet exists on-chain (may have been closed/recovered)
    final walletState = await walletRepo.getWalletState();
    if (!walletState.exists) {
      try {
        final txData = await walletRepo.prepareCreate(
          dailyLimitSol: bot.maxDailyLossSOL,
          perTxLimitSol: bot.positionSizeSOL,
        );
        final network =
            (txData['network'] as String?) ?? EnvConfig.solanaNetwork;
        final txBytes = Uint8List.fromList(
          base64Decode(txData['transaction'] as String),
        );
        final signedTxs = await mwa.signTransactions([
          txBytes,
        ], cluster: network);
        if (signedTxs.isEmpty) {
          throw Exception('Wallet creation signing was cancelled');
        }
        final txBase64 = base64Encode(signedTxs.first);
        await walletRepo.submitSigned(transactionBase64: txBase64);
      } catch (e) {
        final msg = e.toString();
        if (!msg.contains('409') && !msg.contains('already exists')) rethrow;
      }
    }

    final setupData = await walletRepo.setupLive(
      botId: bot.botId,
      dailyLimitSol: bot.maxDailyLossSOL,
      perTxLimitSol: bot.positionSizeSOL,
      sessionMaxAmountSol: bot.maxDailyLossSOL,
      sessionMaxPerTxSol: bot.positionSizeSOL,
    );

    final txBase64 = setupData['transaction'] as String;
    final txBytes = Uint8List.fromList(base64Decode(txBase64));
    final network =
        (setupData['network'] as String?) ?? EnvConfig.solanaNetwork;

    final signedTxs = await mwa.signTransactions([txBytes], cluster: network);
    if (signedTxs.isEmpty) {
      throw Exception('Transaction signing was cancelled');
    }

    final signed64 = base64Encode(signedTxs.first);
    await walletRepo.submitSigned(
      transactionBase64: signed64,
      setupLiveBotId: bot.botId,
    );

    // Refresh bot data so agentPubkey/sessionAddress are populated
    ref.invalidate(botDetailProvider(widget.botId));
    // Small delay for invalidation to propagate
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _stopBot() async {
    if (_isPerformingAction) return;
    setState(() => _isPerformingAction = true);
    try {
      final repo = ref.read(botRepositoryProvider);
      await repo.stopBot(widget.botId);
      HapticFeedback.mediumImpact();
      ref.invalidate(botDetailProvider(widget.botId));
      ref.invalidate(botListProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to stop: ${_apiError(e)}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPerformingAction = false);
    }
  }

  /// Bottom sheet with stop options — replaces the old separate
  /// Emergency Stop button.
  Future<void> _showStopSheet(Bot bot) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final c = ctx.sage;
        final text = ctx.sageText;
        final hasPositions = bot.livePositions.isNotEmpty;
        return Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.r),
              topRight: Radius.circular(24.r),
            ),
            border: Border(top: BorderSide(color: c.borderSubtle)),
          ),
          padding: EdgeInsets.fromLTRB(
            24.w,
            20.h,
            24.w,
            MediaQuery.of(ctx).padding.bottom + 24.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: c.borderSubtle,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'Stop Bot',
                style: text.titleLarge?.copyWith(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Choose how to stop this bot.',
                style: text.bodyMedium?.copyWith(color: c.textSecondary),
              ),
              SizedBox(height: 24.h),

              // Option 1 — Stop scanning only
              MWAButtonTapEffect(
                onTap: () => Navigator.pop(ctx, 'stop'),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: 14.h,
                    horizontal: 16.w,
                  ),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: c.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        PhosphorIconsBold.pause,
                        size: 20.sp,
                        color: c.textSecondary,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stop Scanning',
                              style: text.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: c.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'Engine stops. Open positions remain active.',
                              style: text.bodySmall?.copyWith(
                                color: c.textTertiary,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10.h),

              // Option 2 — Close all positions & stop
              MWAButtonTapEffect(
                onTap: () => Navigator.pop(ctx, 'emergency'),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: 14.h,
                    horizontal: 16.w,
                  ),
                  decoration: BoxDecoration(
                    color: c.loss.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: c.loss.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(PhosphorIconsBold.stop, size: 20.sp, color: c.loss),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Close All & Stop',
                              style: text.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: c.loss,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              hasPositions
                                  ? 'Close ${bot.livePositions.length} '
                                        'position${bot.livePositions.length != 1 ? 's' : ''} '
                                        'at market price, then stop.'
                                  : 'Close all positions at market price, then stop.',
                              style: text.bodySmall?.copyWith(
                                color: c.loss.withValues(alpha: 0.7),
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // Cancel
              MWAButtonTapEffect(
                onTap: () => Navigator.pop(ctx),
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
            ],
          ),
        );
      },
    );

    if (result == null || _isPerformingAction) return;

    if (result == 'stop') {
      await _stopBot();
    } else if (result == 'emergency') {
      await _performEmergencyStop();
    }
  }

  Future<void> _performEmergencyStop() async {
    if (_isPerformingAction) return;
    setState(() => _isPerformingAction = true);
    try {
      final repo = ref.read(botRepositoryProvider);
      await repo.emergencyStop(widget.botId);
      HapticFeedback.heavyImpact();
      ref.invalidate(botDetailProvider(widget.botId));
      ref.invalidate(botListProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Emergency stop failed: ${_apiError(e)}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPerformingAction = false);
    }
  }

  /// Show a bottom sheet to fund the Seal wallet (live bots only).
  Future<void> _showFundSheet(Bot bot) async {
    if (bot.mode != BotMode.live) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Simulation bots don\'t need real funding'),
        ),
      );
      return;
    }

    final recommended = bot.positionSizeSOL * bot.maxConcurrentPositions;

    final result = await SageBottomSheet.show<double>(
      context: context,
      title: 'Fund Wallet',
      builder: (c, text) => _FundSheetContent(
        recommended: recommended,
        positionSize: bot.positionSizeSOL,
        maxPositions: bot.maxConcurrentPositions,
        c: c,
        text: text,
      ),
    );

    if (result == null || result <= 0 || _isPerformingAction) return;

    setState(() => _isPerformingAction = true);
    try {
      final walletRepo = ref.read(walletRepositoryProvider);
      final mwa = ref.read(mwaWalletServiceProvider);

      final txData = await walletRepo.prepareDeposit(amountSol: result);
      final network = txData['network'] as String? ?? EnvConfig.solanaNetwork;
      final txBytes = Uint8List.fromList(
        base64Decode(txData['transaction'] as String),
      );

      // Try signAndSend, fall back to sign + backend submit
      try {
        final signatures = await mwa.signAndSendTransactions([
          txBytes,
        ], cluster: network);
        if (signatures.isEmpty) {
          throw Exception('Transaction was rejected');
        }
      } catch (e) {
        final msg = e.toString();
        final isSimErr =
            msg.contains('simulation') ||
            msg.contains('Simulation') ||
            msg.contains('Transaction failed') ||
            msg.contains('failed to send');
        if (!isSimErr) rethrow;

        debugPrint('[Fund] signAndSend failed, trying sign + submit');
        final signedTxs = await mwa.signTransactions([
          txBytes,
        ], cluster: network);
        if (signedTxs.isEmpty) throw Exception('Signing cancelled');

        final txBase64 = base64Encode(signedTxs.first);
        await walletRepo.submitSigned(transactionBase64: txBase64);
      }

      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Funded ${result.toStringAsFixed(1)} SOL')),
        );
        ref.invalidate(walletBalanceProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Funding failed: ${_apiError(e)}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPerformingAction = false);
    }
  }

  /// Show withdraw bottom sheet — pull SOL from Sage wallet back to user.
  Future<void> _showWithdrawSheet() async {
    final walletRepo = ref.read(walletRepositoryProvider);

    // Get current balance
    double balance;
    try {
      final wb = await walletRepo.getBalance();
      balance = wb.balanceSOL;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load wallet balance')),
        );
      }
      return;
    }

    if (balance <= 0.003) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No funds available to withdraw')),
        );
      }
      return;
    }

    if (!mounted) return;
    final success = await SageBottomSheet.show<bool>(
      context: context,
      title: 'Withdraw',
      builder: (c, text) =>
          WithdrawSheet(availableBalanceSol: balance, c: c, text: text),
    );

    if (success == true && mounted) {
      ref.invalidate(walletBalanceProvider);
      ref.invalidate(botDetailProvider(widget.botId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sage;
    final text = context.sageText;
    final botAsync = ref.watch(botDetailProvider(widget.botId));

    // Listen to SSE events — auto-refresh when this bot's state changes
    ref.listen<AsyncValue<BotEvent>>(botEventStreamProvider, (_, next) {
      next.whenData((event) {
        if (event.botId != widget.botId) return;

        if (event.isBotStarted ||
            event.isBotStopped ||
            event.isBotError ||
            event.isPositionOpened ||
            event.isPositionClosed ||
            event.isScanCompleted) {
          ref.invalidate(botDetailProvider(widget.botId));
          ref.invalidate(botListProvider);
        }

        // Start/stop polling alongside engine lifecycle
        if (event.isBotStarted) {
          _startPolling();
          _lowBalanceShown = false;
        } else if (event.isBotStopped) {
          _stopPolling();
        }

        // Insufficient balance toast — only show once per engine run
        if (event.isBotError && !_lowBalanceShown) {
          final errMsg = event.data?['error'] as String? ?? '';
          if (errMsg.startsWith('insufficient_balance:') && mounted) {
            _lowBalanceShown = true;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Bot wallet balance too low to trade. '
                  'Deposit SOL to your Sage wallet.',
                ),
                duration: const Duration(seconds: 5),
                action: SnackBarAction(label: 'Dismiss', onPressed: () {}),
              ),
            );
          }
        }
      });
    });

    // Start/stop polling based on current bot state
    final currentBot = botAsync.whenOrNull(data: (b) => b);
    if (currentBot != null && currentBot.engineRunning && _pollTimer == null) {
      _startPolling();
    } else if (currentBot != null &&
        !currentBot.engineRunning &&
        _pollTimer != null) {
      _stopPolling();
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: c.background,
        body: botAsync.when(
          loading: () =>
              Center(child: CircularProgressIndicator(color: c.accent)),
          error: (err, _) => _buildError(c, text, err),
          data: (bot) => _buildBody(context, c, text, bot),
        ),
      ),
    );
  }

  Widget _buildError(SageColors c, TextTheme text, Object err) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIconsBold.warningCircle, color: c.loss, size: 40.sp),
          SizedBox(height: 12.h),
          Text(
            'Failed to load bot',
            style: text.titleMedium?.copyWith(color: c.textPrimary),
          ),
          SizedBox(height: 4.h),
          Text(
            '$err',
            style: text.bodySmall?.copyWith(color: c.textTertiary),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          GestureDetector(
            onTap: () => ref.invalidate(botDetailProvider(widget.botId)),
            child: Text('Retry', style: TextStyle(color: c.accent)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    SageColors c,
    TextTheme text,
    Bot bot,
  ) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    // Status indicators
    final isRunning = bot.engineRunning;
    final statusColor = isRunning
        ? c.profit
        : bot.status == BotStatus.error
        ? c.loss
        : c.textTertiary;
    final statusLabel = isRunning
        ? 'Running'
        : bot.status == BotStatus.error
        ? 'Error'
        : bot.status == BotStatus.stopping
        ? 'Stopping'
        : bot.status == BotStatus.starting
        ? 'Starting'
        : 'Stopped';
    final isTransitioning =
        bot.status == BotStatus.starting || bot.status == BotStatus.stopping;

    // PnL
    final pnl = bot.performanceSummary?.totalPnlSol ?? bot.totalPnlSOL;
    final pnlColor = pnl >= 0 ? c.profit : c.loss;
    final pnlStr = pnl >= 0
        ? '+${pnl.toStringAsFixed(4)} SOL'
        : '${pnl.toStringAsFixed(4)} SOL';

    // Strategy mode label
    final strategyLabel = bot.strategyMode == StrategyMode.ruleBased
        ? 'Rule-Based'
        : bot.strategyMode == StrategyMode.sageAi
        ? 'Sage AI'
        : 'Hybrid';

    // Engine stats
    final stats = bot.engineStats;
    final totalScans = stats?.totalScans ?? 0;
    final posOpened = stats?.positionsOpened ?? 0;
    final posClosed = stats?.positionsClosed ?? 0;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(botDetailProvider(widget.botId));
        await Future.delayed(const Duration(milliseconds: 600));
      },
      color: c.accent,
      backgroundColor: c.surface,
      child: Column(
        children: [
          // ── Top bar — profile-style circular icons ──
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, topPad + 12.h, 20.w, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.surface,
                      border: Border.all(color: c.borderSubtle, width: 1),
                    ),
                    child: Icon(
                      PhosphorIconsBold.arrowLeft,
                      size: 20.sp,
                      color: c.textSecondary,
                    ),
                  ),
                ),
                const Spacer(),
                // Play / Stop action icon
                if (_isPerformingAction)
                  SizedBox(
                    width: 36.w,
                    height: 36.w,
                    child: Padding(
                      padding: EdgeInsets.all(8.w),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: c.accent,
                      ),
                    ),
                  )
                else if (!isTransitioning) ...[
                  if (!isRunning)
                    MWAButtonTapEffect(
                      onTap: _startBot,
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.profit.withValues(alpha: 0.15),
                          border: Border.all(
                            color: c.profit.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          PhosphorIconsBold.play,
                          size: 20.sp,
                          color: c.profit,
                        ),
                      ),
                    ),
                  if (isRunning)
                    MWAButtonTapEffect(
                      onTap: () => _showStopSheet(bot),
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.loss.withValues(alpha: 0.12),
                          border: Border.all(
                            color: c.loss.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          PhosphorIconsBold.stop,
                          size: 20.sp,
                          color: c.loss,
                        ),
                      ),
                    ),
                ],
                SizedBox(width: 8.w),
                // More menu (edit / delete)
                PopupMenuButton<String>(
                  icon: Icon(
                    PhosphorIconsBold.dotsThreeVertical,
                    size: 22.sp,
                    color: c.textSecondary,
                  ),
                  color: c.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    side: BorderSide(color: c.borderSubtle),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      final botAsync = ref.read(
                        botDetailProvider(widget.botId),
                      );
                      botAsync.whenData((bot) {
                        if (bot.engineRunning) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Stop the bot before editing config',
                              ),
                            ),
                          );
                        } else {
                          _showEditConfig(bot);
                        }
                      });
                    } else if (value == 'fund') {
                      final botAsync = ref.read(
                        botDetailProvider(widget.botId),
                      );
                      botAsync.whenData((bot) => _showFundSheet(bot));
                    } else if (value == 'withdraw') {
                      _showWithdrawSheet();
                    } else if (value == 'delete') {
                      _deleteBot();
                    }
                  },
                  itemBuilder: (ctx) {
                    final botData = ref.read(botDetailProvider(widget.botId));
                    final isLiveBot = botData.value?.mode == BotMode.live;

                    return [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              PhosphorIconsBold.pencilSimple,
                              size: 18.sp,
                              color: c.textSecondary,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Edit',
                              style: TextStyle(color: c.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      if (isLiveBot)
                        PopupMenuItem(
                          value: 'fund',
                          child: Row(
                            children: [
                              Icon(
                                PhosphorIconsBold.wallet,
                                size: 18.sp,
                                color: c.accent,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Fund Wallet',
                                style: TextStyle(color: c.accent),
                              ),
                            ],
                          ),
                        ),
                      if (isLiveBot)
                        PopupMenuItem(
                          value: 'withdraw',
                          child: Row(
                            children: [
                              Icon(
                                PhosphorIconsBold.arrowUp,
                                size: 18.sp,
                                color: c.textSecondary,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Withdraw',
                                style: TextStyle(color: c.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              PhosphorIconsBold.trash,
                              size: 18.sp,
                              color: c.loss,
                            ),
                            SizedBox(width: 8.w),
                            Text('Delete', style: TextStyle(color: c.loss)),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),

          // ── Content ──
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(28.w, 24.h, 28.w, bottomPad + 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status indicator + mode badge
                  Row(
                    children: [
                      if (isRunning)
                        PulsingDot(color: statusColor, size: 8)
                      else
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      SizedBox(width: 10.w),
                      Text(
                        statusLabel,
                        style: text.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: c.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          strategyLabel,
                          style: text.labelSmall?.copyWith(
                            color: c.accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 11.sp,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12.h),

                  // Bot name
                  Text(
                    bot.name,
                    style: text.displayMedium?.copyWith(letterSpacing: -0.8),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    '${bot.mode.name} · ${bot.positionSizeSOL.toStringAsFixed(1)} SOL per position',
                    style: text.titleMedium?.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: c.textSecondary,
                    ),
                  ),

                  // ── Setup Required Banner ──
                  // Shown when a live bot has no agent/session keys —
                  // the signing step was interrupted during creation.
                  if (bot.mode == BotMode.live &&
                      bot.agentPubkey == null &&
                      !isRunning) ...[
                    SizedBox(height: 16.h),
                    MWAButtonTapEffect(
                      onTap: _startBot,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: c.accent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: c.accent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              PhosphorIconsBold.warning,
                              size: 20.sp,
                              color: c.accent,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Wallet setup required',
                                    style: text.bodyMedium?.copyWith(
                                      color: c.accent,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    'Tap to sign and complete setup',
                                    style: text.bodySmall?.copyWith(
                                      color: c.accent.withValues(alpha: 0.7),
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              PhosphorIconsBold.caretRight,
                              size: 18.sp,
                              color: c.accent.withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  SizedBox(height: 28.h),

                  // ── P&L — inline metric on dark canvas ──
                  Text(
                    'NET P&L',
                    style: text.titleSmall?.copyWith(
                      fontSize: 10.sp,
                      letterSpacing: 1.5,
                      color: c.textTertiary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    pnlStr,
                    style: text.displayMedium?.copyWith(
                      letterSpacing: -0.5,
                      color: pnlColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    '${bot.totalTrades} trades · ${bot.winRate.toStringAsFixed(0)}% win rate',
                    style: text.bodySmall?.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: c.textSecondary,
                    ),
                  ),

                  SizedBox(height: 28.h),

                  // ── Engine Stats (if running) ──
                  if (stats != null) ...[
                    Text(
                      'ENGINE',
                      style: text.titleSmall?.copyWith(
                        fontSize: 10.sp,
                        color: c.textTertiary,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Row(
                      children: [
                        StatChip(
                          label: 'Scans',
                          value: '$totalScans',
                          c: c,
                          text: text,
                        ),
                        SizedBox(width: 24.w),
                        StatChip(
                          label: 'Opened',
                          value: '$posOpened',
                          c: c,
                          text: text,
                        ),
                        SizedBox(width: 24.w),
                        StatChip(
                          label: 'Closed',
                          value: '$posClosed',
                          c: c,
                          text: text,
                        ),
                        SizedBox(width: 24.w),
                        StatChip(
                          label: 'Active',
                          value: '${bot.activePositionCount}',
                          c: c,
                          text: text,
                        ),
                      ],
                    ),
                    SizedBox(height: 28.h),
                  ],

                  // ── Live Positions ──
                  if (bot.livePositions.isNotEmpty) ...[
                    Text(
                      'ACTIVE POSITIONS',
                      style: text.titleSmall?.copyWith(
                        fontSize: 10.sp,
                        color: c.textTertiary,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    ...bot.livePositions.map(
                      (pos) => GestureDetector(
                        onTap: () => context.push('/position/${pos.id}'),
                        child: LivePositionCard(
                          position: pos,
                          c: c,
                          text: text,
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    GestureDetector(
                      onTap: () => context.push('/history'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'View Position History',
                            style: text.bodySmall?.copyWith(
                              color: c.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Icon(
                            PhosphorIconsBold.arrowRight,
                            size: 14.sp,
                            color: c.accent,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],

                  // ── Parameters ──
                  Text(
                    'PARAMETERS',
                    style: text.titleSmall?.copyWith(
                      fontSize: 10.sp,
                      color: c.textTertiary,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  ParamRow(
                    label: 'Entry Threshold',
                    value: '${bot.entryScoreThreshold.toStringAsFixed(0)}%',
                  ),
                  Divider(height: 1, color: c.borderSubtle),
                  ParamRow(
                    label: 'Position Size',
                    value: '${bot.positionSizeSOL.toStringAsFixed(1)} SOL',
                  ),
                  Divider(height: 1, color: c.borderSubtle),
                  ParamRow(
                    label: 'Max Concurrent',
                    value: '${bot.maxConcurrentPositions}',
                  ),
                  Divider(height: 1, color: c.borderSubtle),
                  ParamRow(
                    label: 'Cooldown',
                    value: '${bot.cooldownMinutes} min',
                  ),
                  Divider(height: 1, color: c.borderSubtle),
                  ParamRow(
                    label: 'Stop Loss',
                    value: '-${bot.stopLossPercent.toStringAsFixed(1)}%',
                  ),
                  Divider(height: 1, color: c.borderSubtle),
                  ParamRow(
                    label: 'Profit Target',
                    value: '+${bot.profitTargetPercent.toStringAsFixed(1)}%',
                  ),
                  Divider(height: 1, color: c.borderSubtle),
                  ParamRow(
                    label: 'Max Hold Time',
                    value: '${bot.maxHoldTimeMinutes} min',
                  ),
                  Divider(height: 1, color: c.borderSubtle),
                  ParamRow(
                    label: 'Scan Interval',
                    value: '${bot.cronIntervalSeconds}s',
                  ),

                  if (bot.lastError != null) ...[
                    SizedBox(height: 24.h),
                    Text(
                      'LATEST NOTE',
                      style: text.titleSmall?.copyWith(
                        fontSize: 10.sp,
                        color: c.textSecondary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.w),
                      child: Text(
                        bot.lastError!,
                        style: text.bodySmall?.copyWith(
                          color: c.textSecondary,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ],

                  // ── Seal Session Status (live mode only) ──
                  if (bot.mode == BotMode.live) ...[
                    SizedBox(height: 28.h),
                    _SealStatusBanner(bot: bot),
                    SizedBox(height: 14.h),
                    _WalletBalanceRow(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Fund Sheet Content — tap-to-edit amount via SageBottomSheet
// ═══════════════════════════════════════════════════════════════

class _FundSheetContent extends StatefulWidget {
  final double recommended;
  final double positionSize;
  final int maxPositions;
  final SageColors c;
  final TextTheme text;

  const _FundSheetContent({
    required this.recommended,
    required this.positionSize,
    required this.maxPositions,
    required this.c,
    required this.text,
  });

  @override
  State<_FundSheetContent> createState() => _FundSheetContentState();
}

class _FundSheetContentState extends State<_FundSheetContent> {
  late double _amount;

  @override
  void initState() {
    super.initState();
    _amount = widget.recommended;
  }

  void _openAmountEditor() {
    final minDeposit = widget.positionSize;
    final maxDeposit = widget.recommended * 3;

    SageBottomSheet.show<double>(
      context: context,
      title: 'Deposit Amount',
      builder: (c, text) => _AmountEditorContent(
        current: _amount,
        min: minDeposit,
        max: maxDeposit,
        c: c,
        text: text,
      ),
    ).then((value) {
      if (value != null) setState(() => _amount = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final text = widget.text;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add SOL to your Seal wallet for live trading.',
          style: text.bodyMedium?.copyWith(color: c.textSecondary),
        ),

        SizedBox(height: 24.h),

        // Tappable amount row — tap to edit
        GestureDetector(
          onTap: _openAmountEditor,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Row(
              children: [
                Text(
                  'Deposit Amount',
                  style: text.titleMedium?.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: c.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_amount.toStringAsFixed(1)} SOL',
                  style: text.titleMedium?.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: c.accent,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                SizedBox(width: 6.w),
                Icon(
                  PhosphorIconsBold.pencilSimple,
                  size: 12.sp,
                  color: c.textTertiary.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),

        Divider(height: 1, color: c.borderSubtle),

        // Recommendation info
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Text(
            'Recommended: ${widget.recommended.toStringAsFixed(1)} SOL '
            '(${widget.positionSize.toStringAsFixed(1)} × ${widget.maxPositions} positions)',
            style: text.bodySmall?.copyWith(
              color: c.textTertiary,
              fontSize: 11.sp,
            ),
          ),
        ),

        SizedBox(height: 20.h),

        // Fund button
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.pop(context, _amount);
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            decoration: BoxDecoration(
              color: c.accent,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Center(
              child: Text(
                'Fund ${_amount.toStringAsFixed(1)} SOL',
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
          onTap: () => Navigator.pop(context),
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
// Amount Editor — slider inside SageBottomSheet (like param editor)
// ═══════════════════════════════════════════════════════════════

class _AmountEditorContent extends StatefulWidget {
  final double current;
  final double min;
  final double max;
  final SageColors c;
  final TextTheme text;

  const _AmountEditorContent({
    required this.current,
    required this.min,
    required this.max,
    required this.c,
    required this.text,
  });

  @override
  State<_AmountEditorContent> createState() => _AmountEditorContentState();
}

class _AmountEditorContentState extends State<_AmountEditorContent> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final text = widget.text;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 8.h),

        // Big value display
        Text(
          '${_value.toStringAsFixed(1)} SOL',
          style: text.displayMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: c.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),

        SizedBox(height: 28.h),

        // Slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: c.accent,
            inactiveTrackColor: c.border,
            thumbColor: c.accent,
            overlayColor: c.accent.withValues(alpha: 0.12),
            trackHeight: 3,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.r),
          ),
          child: Slider(
            value: _value,
            min: widget.min,
            max: widget.max,
            divisions: ((widget.max - widget.min) * 10).round().clamp(1, 200),
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _value = v);
            },
          ),
        ),

        // Range labels
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.min.toStringAsFixed(1)} SOL',
                style: text.labelSmall?.copyWith(
                  color: c.textTertiary,
                  fontSize: 10.sp,
                ),
              ),
              Text(
                '${widget.max.toStringAsFixed(1)} SOL',
                style: text.labelSmall?.copyWith(
                  color: c.textTertiary,
                  fontSize: 10.sp,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 28.h),

        // Confirm button
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.pop(context, _value);
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            decoration: BoxDecoration(
              color: c.accent,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: c.accent.withValues(alpha: 0.25),
                  blurRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Set Amount',
                style: text.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
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
// Seal Status Banner (read-only)
// ═══════════════════════════════════════════════════════════════

/// Lightweight read-only banner showing Seal session status for live bots.
/// Agent + session are now auto-created during bot deployment — no manual
/// registration needed.
class _SealStatusBanner extends StatelessWidget {
  final Bot bot;

  const _SealStatusBanner({required this.bot});

  @override
  Widget build(BuildContext context) {
    final c = context.sage;
    final text = context.sageText;

    final hasSession = bot.sessionAddress != null;
    final hasAgent = bot.agentPubkey != null;

    // Distinguish "keys exist on-chain" from "engine is running".
    // The engine status chip (Running / Stopped) is rendered separately.
    final Color statusColor = hasSession
        ? (bot.engineRunning ? c.profit : c.accent)
        : hasAgent
        ? c.accent
        : c.textTertiary;
    final String statusLabel = hasSession
        ? (bot.engineRunning ? 'Live Active' : 'Live Ready')
        : hasAgent
        ? 'Wallet Ready'
        : 'Tap Start to complete setup';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WALLET',
          style: text.titleSmall?.copyWith(
            color: c.textTertiary,
            fontWeight: FontWeight.w800,
            fontSize: 11.sp,
            letterSpacing: 1.5,
          ),
        ),
        SizedBox(height: 8.h),

        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(4.r),
            border: Border.all(color: statusColor.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  statusLabel,
                  style: text.bodyMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (hasAgent)
                Text(
                  _truncate(bot.agentPubkey!),
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
    );
  }

  String _truncate(String addr) {
    if (addr.length <= 12) return addr;
    return '${addr.substring(0, 4)}…${addr.substring(addr.length - 4)}';
  }
}

// ═══════════════════════════════════════════════════════════════
// Wallet Balance Row (live bots only)
// ═══════════════════════════════════════════════════════════════

/// Shows the current Seal wallet SOL balance — flat inline row.
class _WalletBalanceRow extends ConsumerWidget {
  const _WalletBalanceRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.sage;
    final text = context.sageText;
    final balanceAsync = ref.watch(walletBalanceProvider);

    return balanceAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (balance) => Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            Icon(PhosphorIconsBold.wallet, size: 14.sp, color: c.textTertiary),
            SizedBox(width: 8.w),
            Text(
              'Wallet Balance',
              style: text.titleMedium?.copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: c.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              '${balance.balanceSOL.toStringAsFixed(4)} SOL',
              style: text.titleMedium?.copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

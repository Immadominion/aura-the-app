import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';

import 'package:aura/core/config/env_config.dart';
import 'package:aura/core/config/live_trading_flags.dart';
import 'package:aura/core/repositories/bot_repository.dart';
import 'package:aura/core/services/auth_service.dart';
import 'package:aura/core/services/domain_resolver.dart';
import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_theme.dart';
import 'package:aura/core/theme/app_radii.dart';

import 'package:aura/core/models/bot.dart';
import 'package:aura/core/models/bot_event.dart';
import 'package:aura/core/services/notification_service.dart';
import 'package:aura/core/services/event_service.dart';

import 'package:aura/features/wallet/presentation/widgets/settings_info_row.dart';
import 'package:aura/features/wallet/presentation/widgets/support_link.dart';
import 'package:aura/features/wallet/presentation/widgets/setting_tile.dart';
import 'package:aura/shared/widgets/mwa_button_tap_effect.dart';
import 'package:aura/shared/widgets/aura_bottom_sheet.dart';
import 'package:aura/shared/widgets/deposit_sheet.dart';
import 'package:aura/shared/widgets/withdraw_sheet.dart';
import 'package:aura/shared/widgets/smart_withdraw_sheet.dart';
import 'package:aura/core/repositories/wallet_repository.dart';

/// Profile — wallet identity, portfolio summary, settings entry.
///
/// Refactored to match the "Aura Capital Allocator" aesthetic.
/// Card-based identity, compact portfolio, and setting entry points.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  void _openSettings() {
    final c = context.aura;
    final text = context.auraText;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _SettingsSheet(c: c, text: text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final c = context.aura;
    final text = context.auraText;
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    // Real data from providers
    final connectedWallet = ref.watch(connectedWalletAddressProvider);
    final botsAsync = ref.watch(botListProvider);
    final bots = botsAsync.value ?? [];

    // Listen to SSE events — auto-refresh portfolio stats on bot state changes
    ref.listen<AsyncValue<BotEvent>>(botEventStreamProvider, (_, next) {
      next.whenData((event) {
        if (event.isBotStarted ||
            event.isBotStopped ||
            event.isBotError ||
            event.isPositionOpened ||
            event.isPositionClosed) {
          ref.read(botListProvider.notifier).refresh();
        }
      });
    });
    final walletAddr = connectedWallet ?? '—';
    final shortAddr = walletAddr.length > 8
        ? '${walletAddr.substring(0, 4)}...${walletAddr.substring(walletAddr.length - 4)}'
        : walletAddr;
    final avatarSeed = walletAddr == '—' ? 'aura_guest' : walletAddr;

    // Resolve AllDomains ANS name (e.g. miester.abc)
    final domainAsync = walletAddr != '—'
        ? ref.watch(domainNameProvider(walletAddr))
        : const AsyncValue<String?>.data(null);
    final domainName = domainAsync.when(
      data: (d) => d,
      loading: () => null,
      error: (_, _) => null,
    );

    // Aggregated stats — totalBots/avgWinRate/totalTrades dropped with the
    // hero identity card; portfolio block now uses totalDeployed/totalPnl.
    final totalDeployed = bots.fold<double>(
      0,
      (s, b) => s + b.currentBalanceSol,
    );
    final totalPnl = bots.fold<double>(
      0,
      (s, b) => s + (b.performanceSummary?.totalPnlSol ?? b.totalPnlSOL),
    );
    final runningBots = bots.where((b) => b.engineRunning).length;

    // Separate live vs simulation balances
    final liveBotsList = bots.where((b) => b.mode == BotMode.live).toList();
    final simBotsList = bots
        .where((b) => b.mode == BotMode.simulation)
        .toList();
    final liveBalance = liveBotsList.fold<double>(
      0,
      (s, b) => s + b.currentBalanceSol,
    );
    final simBalance = simBotsList.fold<double>(
      0,
      (s, b) => s + b.currentBalanceSol,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: c.background,
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, bottomPad + 32.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──
                  Padding(
                    padding: EdgeInsets.only(top: topPad + 12.h, bottom: 24.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: c.surface,
                              border: Border.all(
                                color: c.borderSubtle,
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              PhosphorIconsBold.arrowLeft,
                              size: 20.sp,
                              color: c.textSecondary,
                            ),
                          ),
                        ),
                        Text(
                          'IDENTITY',
                          style: text.labelMedium?.copyWith(
                            letterSpacing: 1.2,
                            color: c.textTertiary,
                          ),
                        ),
                        GestureDetector(
                          onTap: _openSettings,
                          child: Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: c.surface,
                              border: Border.all(
                                color: c.borderSubtle,
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              PhosphorIconsBold.gear,
                              size: 20.sp,
                              color: c.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Identity strip (compact, audit §5.x) ──
                  // Was a hero-sized card with avatar, name, status pill, and
                  // a triple stats row. Demoted: portfolio is now the hero.
                  Container(
                    padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
                    decoration: ShapeDecoration(
                      color: c.surface,
                      shape: ContinuousRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          context.auraRadii.lg,
                        ),
                        side: BorderSide(color: c.borderSubtle),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40.w,
                          height: 40.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c.background,
                            border: Border.all(
                              color: c.accent.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.network(
                              'https://api.dicebear.com/9.x/micah/png?seed=$avatarSeed',
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Icon(
                                PhosphorIconsBold.user,
                                size: 18.sp,
                                color: c.textTertiary,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                domainName ?? shortAddr,
                                style: text.titleMedium?.copyWith(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                  color: c.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (domainName != null)
                                Text(
                                  shortAddr,
                                  style: text.labelSmall?.copyWith(
                                    color: c.textTertiary,
                                    fontSize: 11.sp,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: ShapeDecoration(
                            color: c.background,
                            shape: StadiumBorder(
                              side: BorderSide(
                                color: c.borderSubtle.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6.w,
                                height: 6.w,
                                decoration: BoxDecoration(
                                  color: runningBots > 0
                                      ? c.profit
                                      : c.textTertiary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                runningBots > 0
                                    ? '$runningBots Active'
                                    : 'Idle',
                                style: text.labelSmall?.copyWith(
                                  color: runningBots > 0
                                      ? c.profit
                                      : c.textTertiary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 250.ms),

                  SizedBox(height: 32.h),

                  // ── Compact Portfolio ──
                  Text(
                    'PORTFOLIO',
                    style: text.labelMedium?.copyWith(
                      letterSpacing: 1.2,
                      color: c.textTertiary,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  SizedBox(height: 16.h),

                  // Portfolio Summary Card with integrated actions
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24.r),
                      color: c.surface,
                      border: Border.all(color: c.borderSubtle, width: 1),
                    ),
                    child: Column(
                      children: [
                        // ── Top: Value + Breakdown ──
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Left: Total Net Worth
                              Expanded(
                                flex: 3,
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    20.w,
                                    20.w,
                                    12.w,
                                    20.w,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Total Value',
                                        style: text.labelSmall?.copyWith(
                                          color: c.textTertiary,
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          '${totalDeployed.toStringAsFixed(1)} SOL',
                                          style: text.displaySmall?.copyWith(
                                            fontSize: 26.sp,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -1,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 8.h),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8.w,
                                          vertical: 4.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              (totalPnl >= 0
                                                      ? c.profit
                                                      : c.loss)
                                                  .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            8.r,
                                          ),
                                        ),
                                        child: Text(
                                          '${totalPnl >= 0 ? "+" : ""}${totalPnl.toStringAsFixed(2)} SOL P&L',
                                          style: text.labelSmall?.copyWith(
                                            color: totalPnl >= 0
                                                ? c.profit
                                                : c.loss,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(width: 1, color: c.borderSubtle),
                              // Right: Deployed + Idle stacked compactly
                              Expanded(
                                flex: 3,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14.w,
                                    vertical: 16.h,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Live Balance
                                      Row(
                                        children: [
                                          Icon(
                                            PhosphorIconsFill.pulse,
                                            size: 12.sp,
                                            color: c.accent,
                                          ),
                                          SizedBox(width: 5.w),
                                          Text(
                                            'Live',
                                            style: text.labelSmall?.copyWith(
                                              color: c.textTertiary,
                                              fontSize: 10.sp,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        '${liveBalance.toStringAsFixed(2)} SOL',
                                        style: text.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 12.h),
                                      // Simulation Balance
                                      Row(
                                        children: [
                                          Icon(
                                            PhosphorIconsFill.flask,
                                            size: 12.sp,
                                            color: c.textTertiary,
                                          ),
                                          SizedBox(width: 5.w),
                                          Text(
                                            'Simulation',
                                            style: text.labelSmall?.copyWith(
                                              color: c.textTertiary,
                                              fontSize: 10.sp,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        '${simBalance.toStringAsFixed(2)} SOL',
                                        style: text.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // ── Bottom: Deposit / Withdraw buttons ──
                        if (kLiveTradingEnabled)
                          Container(
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: c.borderSubtle,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: MWAButtonTapEffect(
                                    onTap: () => _showDepositSheet(
                                      context,
                                      ref,
                                      c,
                                      text,
                                    ),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 14.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: c.accent.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(24.r),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            PhosphorIconsBold.arrowDown,
                                            size: 16.sp,
                                            color: c.accent,
                                          ),
                                          SizedBox(width: 6.w),
                                          Text(
                                            'Deposit',
                                            style: text.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: c.accent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 44.h,
                                  color: c.borderSubtle,
                                ),
                                Expanded(
                                  child: MWAButtonTapEffect(
                                    onTap: () => _showWithdrawSheet(
                                      context,
                                      ref,
                                      0.0,
                                      c,
                                      text,
                                    ),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 14.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: c.accent.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.only(
                                          bottomRight: Radius.circular(24.r),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            PhosphorIconsBold.arrowUp,
                                            size: 16.sp,
                                            color: c.accent,
                                          ),
                                          SizedBox(width: 6.w),
                                          Text(
                                            'Withdraw',
                                            style: text.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: c.accent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: c.borderSubtle,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Text(
                              kLiveTradingDisabledReason,
                              style: text.bodySmall?.copyWith(
                                color: c.textSecondary,
                                fontSize: 12.sp,
                                height: 1.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),

                  // ── LIVE WALLETS list removed (audit §5.x) ──
                  // Per-bot wallets now live on Bot Detail where they belong.
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Settings Bottom Sheet
// ─────────────────────────────────────────────────────────

class _SettingsSheet extends ConsumerWidget {
  final AuraColors c;
  final TextTheme text;

  const _SettingsSheet({required this.c, required this.text});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, bottomPad + 24.h),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border(top: BorderSide(color: c.borderSubtle)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: c.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'SETTINGS',
            style: text.labelMedium?.copyWith(
              letterSpacing: 1.2,
              color: c.textTertiary,
            ),
          ),
          SizedBox(height: 16.h),
          SettingTile(
            icon: PhosphorIconsBold.slidersHorizontal,
            title: 'Risk preferences',
            subtitle: 'Defaults for new bots',
            onTap: () => _showRiskPreferencesSheet(context, ref, c, text),
          ),
          SettingTile(
            icon: PhosphorIconsBold.bell,
            title: 'Notifications',
            subtitle: 'Execution alerts, price moves',
            onTap: () => _showNotificationsSheet(context, c, text),
          ),
          SettingTile(
            icon: PhosphorIconsBold.dotsThreeOutline,
            title: 'Advanced',
            subtitle: 'Security · Network · Support',
            onTap: () => _showAdvancedSheet(context, c, text),
            isLast: true,
          ),
          SizedBox(height: 20.h),
          _KillSwitchButton(c: c, text: text),
          SizedBox(height: 8.h),
          // Disconnect Wallet
          Center(
            child: TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await ref.read(authStateProvider.notifier).signOut();
                if (context.mounted) {
                  context.go('/connect-wallet');
                }
              },
              child: Text(
                'Disconnect Wallet',
                style: text.titleSmall?.copyWith(
                  color: c.loss,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Deposit Sheet Launcher
// ─────────────────────────────────────────────────────────

void _showDepositSheet(
  BuildContext context,
  WidgetRef ref,
  AuraColors c,
  TextTheme text,
) {
  final bots = ref.read(botListProvider).value ?? [];
  final liveBots = bots.where((b) => b.mode == BotMode.live).toList();
  if (liveBots.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Create a live bot first')));
    return;
  }
  if (liveBots.length == 1) {
    _depositForBot(context, ref, liveBots.first);
  } else {
    _showBotPicker(context, ref, liveBots, deposit: true);
  }
}

void _depositForBot(BuildContext context, WidgetRef ref, Bot bot) async {
  // Include rent+fees overhead per position (~0.07 SOL) in recommendation
  final recommended = (bot.positionSizeSOL + 0.07) * bot.maxConcurrentPositions;
  final success = await AuraBottomSheet.show<bool>(
    context: context,
    title: 'Fund Wallet',
    builder: (c, text) => DepositSheet(
      botId: bot.botId,
      recommendedSol: recommended,
      minSol: bot.positionSizeSOL + 0.07,
      c: c,
      text: text,
    ),
  );
  if (success == true) {
    ref.invalidate(walletBalanceProvider(bot.botId));
    ref.invalidate(botDetailProvider(bot.botId));
  }
}

// ─────────────────────────────────────────────────────────
// Withdraw Sheet Launcher
// ─────────────────────────────────────────────────────────

void _showWithdrawSheet(
  BuildContext context,
  WidgetRef ref,
  double balance,
  AuraColors c,
  TextTheme text,
) {
  final bots = ref.read(botListProvider).value ?? [];
  final liveBots = bots.where((b) => b.mode == BotMode.live).toList();
  if (liveBots.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Create a live bot first')));
    return;
  }
  if (liveBots.length == 1) {
    _withdrawForBot(context, ref, liveBots.first);
  } else {
    // Smart withdraw — multi-wallet picker
    _showSmartWithdraw(context, ref);
  }
}

void _showSmartWithdraw(BuildContext context, WidgetRef ref) async {
  final success = await AuraBottomSheet.show<bool>(
    context: context,
    title: 'Smart Withdraw',
    builder: (c, text) => SmartWithdrawSheet(c: c, text: text),
  );
  if (success == true) {
    ref.invalidate(botListProvider);
  }
}

void _withdrawForBot(BuildContext context, WidgetRef ref, Bot bot) async {
  final walletRepo = ref.read(walletRepositoryProvider);
  double bal;
  try {
    final wb = await walletRepo.getBalance(bot.botId);
    bal = wb.balanceSOL;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load wallet balance')),
      );
    }
    return;
  }
  if (bal <= 0.003) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No funds available to withdraw')),
      );
    }
    return;
  }
  if (!context.mounted) return;
  final success = await AuraBottomSheet.show<bool>(
    context: context,
    title: 'Withdraw',
    builder: (c, text) => WithdrawSheet(
      botId: bot.botId,
      availableBalanceSol: bal,
      c: c,
      text: text,
    ),
  );
  if (success == true) {
    ref.invalidate(walletBalanceProvider(bot.botId));
    ref.invalidate(botDetailProvider(bot.botId));
  }
}

void _showBotPicker(
  BuildContext context,
  WidgetRef ref,
  List<Bot> liveBots, {
  required bool deposit,
}) {
  final c = context.aura;
  final text = context.auraText;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 32.h),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border(top: BorderSide(color: c.borderSubtle)),
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
                color: c.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            deposit ? 'Select Bot to Fund' : 'Select Bot to Withdraw',
            style: text.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          ...liveBots.map(
            (bot) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                PhosphorIconsBold.wallet,
                color: c.accent,
                size: 20.sp,
              ),
              title: Text(
                bot.name,
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${bot.currentBalanceSol.toStringAsFixed(4)} SOL',
                style: text.bodySmall?.copyWith(color: c.textSecondary),
              ),
              onTap: () {
                Navigator.pop(ctx);
                if (deposit) {
                  _depositForBot(context, ref, bot);
                } else {
                  _withdrawForBot(context, ref, bot);
                }
              },
            ),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────
// Settings Sheet Helpers
// ─────────────────────────────────────────────────────────

void _showSecuritySheet(BuildContext context, AuraColors c, TextTheme text) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 32.h),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border(top: BorderSide(color: c.borderSubtle)),
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
                color: c.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Security & Privacy',
            style: text.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          SizedBox(height: 20.h),
          SettingsInfoRow(
            label: 'Authentication',
            value: 'Sign-In With Solana',
            c: c,
            text: text,
          ),
          Divider(height: 1, color: c.borderSubtle),
          SettingsInfoRow(
            label: 'Key Storage',
            value: 'Secure Enclave / Keychain',
            c: c,
            text: text,
          ),
          Divider(height: 1, color: c.borderSubtle),
          SettingsInfoRow(
            label: 'Connection',
            value: 'Encrypted',
            c: c,
            text: text,
          ),
        ],
      ),
    ),
  );
}

void _showNotificationsSheet(
  BuildContext context,
  AuraColors c,
  TextTheme text,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => const _NotificationsSheetBody(),
  );
}

/// Notification settings sheet — backed by real [NotificationService] prefs.
///
/// Uses [Consumer] to read / write per-event-type toggles stored in
/// [SharedPreferences]. Changes take effect immediately (no save button).
class _NotificationsSheetBody extends ConsumerStatefulWidget {
  const _NotificationsSheetBody();

  @override
  ConsumerState<_NotificationsSheetBody> createState() =>
      _NotificationsSheetBodyState();
}

class _NotificationsSheetBodyState
    extends ConsumerState<_NotificationsSheetBody> {
  /// Local copy of toggle states — seeded from SharedPreferences,
  /// mutated on tap, and persisted asynchronously.
  Map<String, bool> _toggles = {};
  bool _permissionGranted = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final service = ref.read(notificationServiceProvider);
    final prefs = await service.loadAllPreferences();
    final granted = await service.arePermissionsGranted();
    if (!mounted) return;
    setState(() {
      _toggles = prefs;
      _permissionGranted = granted;
      _loaded = true;
    });
  }

  Future<void> _requestPermission() async {
    final service = ref.read(notificationServiceProvider);
    final granted = await service.requestPermission();
    if (!mounted) return;
    setState(() => _permissionGranted = granted);
  }

  Future<void> _toggle(String key, bool value) async {
    setState(() => _toggles[key] = value);
    final service = ref.read(notificationServiceProvider);
    await service.setEnabled(key, value);
    // Invalidate the cached provider so other consumers see the change
    ref.invalidate(notificationPrefsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final text = context.auraText;
    final eventService = ref.watch(eventServiceProvider);

    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 32.h),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border(top: BorderSide(color: c.borderSubtle)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: c.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // Title
          Text(
            'Notifications',
            style: text.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),

          // SSE connection status
          Row(
            children: [
              Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: eventService.isConnected ? c.profit : c.loss,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                eventService.isConnected
                    ? 'Real-time stream connected'
                    : 'Stream disconnected',
                style: text.bodySmall?.copyWith(
                  color: eventService.isConnected ? c.profit : c.loss,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // Permission banner
          if (_loaded && !_permissionGranted) ...[
            GestureDetector(
              onTap: _requestPermission,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: c.accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      PhosphorIconsBold.bellRinging,
                      size: 20.sp,
                      color: c.accent,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Tap to enable notification permissions',
                        style: text.bodySmall?.copyWith(
                          color: c.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      PhosphorIconsBold.caretRight,
                      size: 14.sp,
                      color: c.accent,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),
          ],

          // Toggle list
          if (!_loaded)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Center(
                child: SizedBox(
                  width: 24.w,
                  height: 24.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: c.textTertiary,
                  ),
                ),
              ),
            )
          else
            ...NotificationPrefKeys.allKeys
                .expand(
                  (key) => [
                    _NotificationToggleRow(
                      label: NotificationPrefKeys.label(key),
                      description: NotificationPrefKeys.description(key),
                      enabled: _toggles[key] ?? true,
                      onChanged: (val) => _toggle(key, val),
                      c: c,
                      text: text,
                    ),
                    Divider(height: 1, color: c.borderSubtle),
                  ],
                )
                .toList()
              ..removeLast(), // Remove trailing divider

          SizedBox(height: 16.h),

          // Push notifications note
          Row(
            children: [
              Icon(
                PhosphorIconsBold.cloudArrowDown,
                size: 16.sp,
                color: c.textTertiary,
              ),
              SizedBox(width: 8.w),
              Text(
                'Push notifications — coming soon',
                style: text.bodySmall?.copyWith(
                  color: c.textTertiary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A single notification toggle row with label, description, and switch.
class _NotificationToggleRow extends StatelessWidget {
  final String label;
  final String description;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final AuraColors c;
  final TextTheme text;

  const _NotificationToggleRow({
    required this.label,
    required this.description,
    required this.enabled,
    required this.onChanged,
    required this.c,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: text.bodyMedium?.copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  description,
                  style: text.bodySmall?.copyWith(
                    color: c.textTertiary,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          SizedBox(
            height: 28.h,
            child: Switch.adaptive(
              value: enabled,
              onChanged: onChanged,
              activeThumbColor: c.accent,
              activeTrackColor: c.accent.withValues(alpha: 0.3),
              inactiveThumbColor: c.textTertiary,
              inactiveTrackColor: c.surface,
            ),
          ),
        ],
      ),
    );
  }
}

void _showNetworkSheet(BuildContext context, AuraColors c, TextTheme text) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 32.h),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border(top: BorderSide(color: c.borderSubtle)),
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
                color: c.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Network',
            style: text.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          SizedBox(height: 20.h),
          SettingsInfoRow(
            label: 'Solana Network',
            value: EnvConfig.isProduction ? 'Mainnet' : 'Devnet',
            c: c,
            text: text,
          ),
          Divider(height: 1, color: c.borderSubtle),
          SettingsInfoRow(
            label: 'Priority Fee',
            value: 'Dynamic (auto-scale)',
            c: c,
            text: text,
          ),
        ],
      ),
    ),
  );
}

void _showSupportSheet(BuildContext context, AuraColors c, TextTheme text) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 32.h),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border(top: BorderSide(color: c.borderSubtle)),
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
                color: c.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Support & Info',
            style: text.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          SizedBox(height: 20.h),
          SupportLink(
            icon: PhosphorIconsBold.globe,
            label: 'Aura Website',
            url: 'https://useaura.wtf',
            c: c,
            text: text,
          ),
          SupportLink(
            icon: PhosphorIconsBold.githubLogo,
            label: 'Source Code',
            url: 'https://github.com/Immadominion/aura',
            c: c,
            text: text,
          ),
          SupportLink(
            icon: PhosphorIconsBold.envelope,
            label: 'Contact Us',
            url: 'mailto:hello@useaura.wtf',
            c: c,
            text: text,
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────
// Phase 12 — Risk preferences sheet
// ─────────────────────────────────────────────────────────

void _showRiskPreferencesSheet(
  BuildContext context,
  WidgetRef ref,
  AuraColors c,
  TextTheme text,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) {
        // Selected stance is local-only for now. When the user-prefs API
        // lands, persist via a Riverpod notifier.
        // TODO(phase-12-followup): persist via /user/risk-stance endpoint.
        return Container(
          padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 32.h),
          decoration: ShapeDecoration(
            color: c.background,
            shape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(context.auraRadii.xl),
              ),
              side: BorderSide(color: c.borderSubtle),
            ),
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
                    color: c.textTertiary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Risk preferences',
                style: text.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                "Sets the default stance for new bots. You can override on each bot's setup.",
                style: text.bodySmall?.copyWith(
                  color: c.textSecondary,
                  height: 1.45,
                ),
              ),
              SizedBox(height: 20.h),
              ...['Conservative', 'Balanced', 'Aggressive'].map(
                (label) => Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Default risk: $label')),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                      decoration: ShapeDecoration(
                        color: c.surface,
                        shape: ContinuousRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            context.auraRadii.md,
                          ),
                          side: BorderSide(color: c.borderSubtle),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            label,
                            style: text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            PhosphorIconsBold.caretRight,
                            size: 16.sp,
                            color: c.textTertiary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

// ─────────────────────────────────────────────────────────
// Phase 12 — Advanced sheet (groups Security / Network / Support)
// ─────────────────────────────────────────────────────────

void _showAdvancedSheet(BuildContext context, AuraColors c, TextTheme text) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 32.h),
      decoration: ShapeDecoration(
        color: c.background,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(context.auraRadii.xl),
          ),
          side: BorderSide(color: c.borderSubtle),
        ),
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
                color: c.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Advanced',
            style: text.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          SettingTile(
            icon: PhosphorIconsBold.shieldCheck,
            title: 'Security & Privacy',
            subtitle: 'Biometrics, auto-lock',
            onTap: () {
              Navigator.of(ctx).pop();
              _showSecuritySheet(context, c, text);
            },
          ),
          SettingTile(
            icon: PhosphorIconsBold.globe,
            title: 'Network',
            subtitle: 'RPC endpoints, priority fees',
            onTap: () {
              Navigator.of(ctx).pop();
              _showNetworkSheet(context, c, text);
            },
          ),
          SettingTile(
            icon: PhosphorIconsBold.question,
            title: 'Support',
            subtitle: 'Docs, community, help',
            onTap: () {
              Navigator.of(ctx).pop();
              _showSupportSheet(context, c, text);
            },
            isLast: true,
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────
// Phase 12 — Global kill switch
// ─────────────────────────────────────────────────────────

class _KillSwitchButton extends ConsumerWidget {
  final AuraColors c;
  final TextTheme text;

  const _KillSwitchButton({required this.c, required this.text});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bots = ref.watch(botListProvider).value ?? [];
    final running = bots.where((b) => b.engineRunning).toList();
    final canFire = running.isNotEmpty;

    return GestureDetector(
      onTap: canFire ? () => _confirmKillSwitch(context, ref, running) : null,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: ShapeDecoration(
          color: canFire ? c.loss.withValues(alpha: 0.08) : c.surface,
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.circular(context.auraRadii.md),
            side: BorderSide(
              color: canFire ? c.loss.withValues(alpha: 0.4) : c.borderSubtle,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              PhosphorIconsBold.stopCircle,
              size: 18.sp,
              color: canFire ? c.loss : c.textTertiary,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pause all operations',
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: canFire ? c.loss : c.textTertiary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    canFire
                        ? '${running.length} bot${running.length == 1 ? '' : 's'} running. Stops every engine.'
                        : 'Nothing is running.',
                    style: text.labelSmall?.copyWith(
                      color: c.textTertiary,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _confirmKillSwitch(
  BuildContext context,
  WidgetRef ref,
  List<Bot> running,
) async {
  final c = context.aura;
  final text = context.auraText;
  final go = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 24.h),
      decoration: ShapeDecoration(
        color: c.background,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(context.auraRadii.xl),
          ),
          side: BorderSide(color: c.borderSubtle),
        ),
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
                color: c.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Pause all operations?',
            style: text.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Aura will stop every running engine. Open positions are not closed — you can resume each bot manually.',
            style: text.bodySmall?.copyWith(
              color: c.textSecondary,
              height: 1.45,
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(ctx).pop(false),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    decoration: ShapeDecoration(
                      color: c.surface,
                      shape: ContinuousRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          context.auraRadii.md,
                        ),
                        side: BorderSide(color: c.borderSubtle),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Cancel',
                        style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(ctx).pop(true),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    decoration: ShapeDecoration(
                      color: c.loss,
                      shape: ContinuousRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          context.auraRadii.md,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Pause all',
                        style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  if (go != true) return;
  final repo = ref.read(botRepositoryProvider);
  for (final b in running) {
    try {
      await repo.stopBot(b.botId);
    } catch (_) {
      /* swallow per-bot, continue stopping the rest */
    }
  }
  ref.read(botListProvider.notifier).refresh();
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Stopped ${running.length} bot${running.length == 1 ? '' : 's'}',
        ),
      ),
    );
  }
}

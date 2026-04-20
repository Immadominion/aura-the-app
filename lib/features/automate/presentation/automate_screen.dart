import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:aura/core/models/bot.dart';
import 'package:aura/core/models/bot_event.dart';
import 'package:aura/core/repositories/bot_repository.dart';
import 'package:aura/core/services/event_service.dart';
import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_radii.dart';
import 'package:aura/core/theme/app_theme.dart';
import 'package:aura/shared/widgets/aura_components.dart';

import 'package:aura/features/automate/models/strategy_state.dart';
import 'package:aura/features/automate/presentation/widgets/strategy_card.dart';
import 'package:aura/features/automate/presentation/widgets/stat_chip.dart';
import 'package:aura/features/automate/presentation/widgets/pulsing_dot.dart';

/// Mode 2 — Automate
///
/// Layer 1: Dominant metric (net PnL) + quick stats strip — pinned at top.
/// Layer 2: Bots as individual surface-cards — scrollable with pull-to-refresh.
///
/// Deliberately different from Home — no white panel lift.
/// Everything lives on the same dark plane. Bots are objects, not rows.
class AutomateScreen extends ConsumerWidget {
  const AutomateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.aura;
    final text = context.auraText;
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    final botsAsync = ref.watch(botListProvider);

    // Listen to SSE events — auto-refresh bot list on relevant events
    ref.listen<AsyncValue<BotEvent>>(botEventStreamProvider, (_, next) {
      next.whenData((event) {
        if (event.isPositionOpened ||
            event.isPositionClosed ||
            event.isBotStarted ||
            event.isBotStopped ||
            event.isBotError ||
            event.isScanCompleted) {
          ref.invalidate(botListProvider);
        }
      });
    });

    return Scaffold(
      backgroundColor: c.background,
      body: botsAsync.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: c.accent)),
        error: (err, _) => _buildErrorState(ref, c, text, err),
        data: (bots) =>
            _buildBody(context, ref, c, text, topPad, bottomPad, bots),
      ),
    );
  }

  Widget _buildErrorState(
    WidgetRef ref,
    AuraColors c,
    TextTheme text,
    Object err,
  ) {
    final msg = err.toString();
    String friendly;
    if (msg.contains('DioException') ||
        msg.contains('Connection refused') ||
        msg.contains('connection timeout')) {
      friendly = 'Backend unavailable.\nCheck your connection.';
    } else if (msg.contains('SocketException')) {
      friendly = 'Network error.\nCheck your internet.';
    } else if (msg.contains('401') || msg.contains('Unauthorized')) {
      friendly = 'Authentication failed.\nPlease sign in again.';
    } else {
      friendly = 'Failed to load bots.';
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, color: c.textSecondary, size: 40.sp),
          SizedBox(height: 12.h),
          Text(
            friendly,
            style: text.bodyMedium?.copyWith(color: c.textSecondary),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          TextButton.icon(
            onPressed: () => ref.invalidate(botListProvider),
            icon: Icon(Icons.refresh, size: 18.sp, color: c.accent),
            label: Text('Retry', style: TextStyle(color: c.accent)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AuraColors c,
    TextTheme text,
    double topPad,
    double bottomPad,
    List<Bot> bots,
  ) {
    // Aggregated stats
    final runningBots = bots.where((b) => b.engineRunning).toList();
    final totalPnl = bots.fold<double>(
      0,
      (s, b) => s + (b.performanceSummary?.totalPnlSol ?? b.totalPnlSOL),
    );
    final totalTrades = bots.fold<int>(
      0,
      (s, b) => s + (b.engineStats?.positionsOpened ?? b.totalTrades),
    );
    final avgWinRate = bots.isEmpty
        ? 0.0
        : bots.fold<double>(0, (s, b) => s + b.winRate) / bots.length;

    final pnlWhole = totalPnl.abs().toStringAsFixed(2).split('.')[0];
    final pnlDecimal =
        '.${totalPnl.abs().toStringAsFixed(2).split('.')[1]} SOL';
    final pnlPrefix = totalPnl >= 0 ? '+' : '-';

    // RefreshIndicator wraps the full Column so the spinner always
    // appears at the very top of the screen, not below the pinned header.
    return RefreshIndicator(
      onRefresh: () => ref.read(botListProvider.notifier).refresh(),
      color: c.accent,
      backgroundColor: c.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ════════════════════════════════════════
          // PINNED HEADER — never scrolls
          // ════════════════════════════════════════
          Padding(
            padding: EdgeInsets.fromLTRB(28.w, topPad + 48.h, 28.w, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Label ──
                const AuraLabel('Automate'),

                SizedBox(height: 20.h),

                // ── Dominant metric — net PnL ──
                AuraMetric('$pnlPrefix$pnlWhole', decimal: pnlDecimal),

                SizedBox(height: 12.h),

                // ── Intelligence line ──
                Row(
                  children: [
                    if (runningBots.isNotEmpty) PulsingDot(color: c.profit),
                    if (runningBots.isNotEmpty) SizedBox(width: 8.w),
                    Text(
                      '${runningBots.length} running · $totalTrades trades total',
                      style: text.bodySmall?.copyWith(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 28.h),

                // ── Quick stats strip ──
                Row(
                  children: [
                    StatChip(
                      label: 'Trades',
                      value: '$totalTrades',
                      c: c,
                      text: text,
                    ),
                    SizedBox(width: 10.w),
                    StatChip(
                      label: 'Win Rate',
                      value: '${avgWinRate.toStringAsFixed(0)}%',
                      c: c,
                      text: text,
                    ),
                    SizedBox(width: 10.w),
                    StatChip(
                      label: 'Bots',
                      value: '${bots.length}',
                      c: c,
                      text: text,
                    ),
                  ],
                ),

                SizedBox(height: 28.h),

                // ── Fleet leaderboard CTA — banner style ──
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.push('/fleet');
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: ShapeDecoration(
                      color: c.accent,
                      shape: ContinuousRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          context.auraRadii.lg,
                        ),
                      ),
                    ),
                    child: ClipPath(
                      clipper: ShapeBorderClipper(
                        shape: ContinuousRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            context.auraRadii.lg,
                          ),
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 20,
                            right: -15,
                            child: Container(
                              width: 120.w,
                              height: 120.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.07),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 16,
                            right: 16,
                            child: Image.asset(
                              'assets/images/rocket.png',
                              width: 150.w,
                              height: 150.w,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(20.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fleet Leaderboard',
                                  style: text.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    height: 1.15,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                Text(
                                  'See how your bots rank against\nthe platform.',
                                  style: text.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.72),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 36.h),

                // ── Section label ──
                Text(
                  'BOTS',
                  style: text.titleSmall?.copyWith(
                    color: c.textTertiary,
                    letterSpacing: 1.5,
                  ),
                ),

                if (bots.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    'Long-press to rename',
                    style: text.bodySmall?.copyWith(
                      color: c.textTertiary.withValues(alpha: 0.5),
                      fontSize: 11.sp,
                    ),
                  ),
                ],

                SizedBox(height: 16.h),
              ],
            ),
          ),

          // ════════════════════════════════════════
          // SCROLLABLE BOT CARDS — only cards scroll
          // ════════════════════════════════════════
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(28.w, 0, 28.w, bottomPad + 80.h),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (bots.isEmpty)
                  // ── Phase 14 (audit §5.8) — illustrated empty state ──
                  Padding(
                    padding: EdgeInsets.only(top: 32.h),
                    child: _AutomateEmptyCard(c: c, text: text),
                  )
                else
                  ...bots.asMap().entries.map((entry) {
                    final i = entry.key;
                    final bot = entry.value;

                    final StrategyState state;
                    if (bot.engineRunning) {
                      state = StrategyState.running;
                    } else if (bot.status == BotStatus.error) {
                      state = StrategyState.paused;
                    } else if (bot.status == BotStatus.stopped &&
                        bot.totalTrades == 0 &&
                        bot.lastActivityAt == null) {
                      state = StrategyState.notStarted;
                    } else {
                      // Bot is stopped (with prior trade history)
                      state = StrategyState.paused;
                    }

                    final pnl =
                        bot.performanceSummary?.totalPnlSol ?? bot.totalPnlSOL;
                    final pnlStr = pnl >= 0
                        ? '+${pnl.toStringAsFixed(2)} SOL'
                        : '${pnl.toStringAsFixed(2)} SOL';

                    final lastActivity = bot.lastActivityAt != null
                        ? _relativeTime(bot.lastActivityAt!)
                        : 'No activity';

                    return Column(
                      children: [
                        if (i > 0)
                          Divider(
                            height: 1,
                            thickness: 0.5,
                            color: c.borderSubtle,
                          ),
                        GestureDetector(
                          onLongPress: () =>
                              _showRenameDialog(context, ref, bot),
                          child: StrategyCard(
                            botId: bot.botId,
                            name: bot.name,
                            trigger:
                                'Score ≥ ${bot.entryScoreThreshold.toStringAsFixed(0)}% · ${bot.positionSizeSOL.toStringAsFixed(1)} SOL',
                            lastAction:
                                '$lastActivity · ${bot.engineStats?.totalScans ?? 0} scans',
                            pnl: pnlStr,
                            state: state,
                          ),
                        ),
                      ],
                    );
                  }),

                SizedBox(height: 36.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, Bot bot) {
    final c = context.aura;
    final controller = TextEditingController(text: bot.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        title: Text(
          'Rename Strategy',
          style: TextStyle(color: c.textPrimary, fontSize: 16.sp),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 64,
          style: TextStyle(color: c.textPrimary),
          cursorColor: c.accent,
          decoration: InputDecoration(
            hintText: 'Strategy name',
            hintStyle: TextStyle(color: c.textTertiary),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: c.borderSubtle),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: c.accent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: c.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              await ref
                  .read(botListProvider.notifier)
                  .renameBot(bot.botId, name);
            },
            child: Text('Save', style: TextStyle(color: c.accent)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Phase 14 (audit §5.8) — Automate empty state
// Illustrated card replacing the bare grey "No bots configured yet"
// line. Two paths: chat-led setup or hands-on composer.
// ─────────────────────────────────────────────────────────────

class _AutomateEmptyCard extends StatelessWidget {
  final AuraColors c;
  final TextTheme text;

  const _AutomateEmptyCard({required this.c, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 28.h, 20.w, 20.h),
      decoration: ShapeDecoration(
        color: c.surface,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(context.auraRadii.xl),
          side: BorderSide(color: c.borderSubtle),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Symbolic illustration: three stacked offset bin lines that
          // suggest the shape of an empty strategy slot.
          SizedBox(
            height: 64.h,
            child: CustomPaint(
              size: Size.infinite,
              painter: _EmptyBotsIllustrationPainter(
                lineColor: c.borderSubtle,
                accentColor: c.accent,
              ),
            ),
          ),
          SizedBox(height: 22.h),
          Text(
            'No bots yet.',
            textAlign: TextAlign.center,
            style: text.titleLarge?.copyWith(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Want Aura to set one up for you, or build it yourself?',
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(
              color: c.textSecondary,
              height: 1.45,
            ),
          ),
          SizedBox(height: 22.h),
          // Primary — chat-led setup
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              context.push('/intelligence');
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              decoration: ShapeDecoration(
                color: c.accent,
                shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.circular(context.auraRadii.md),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    PhosphorIconsBold.chatCircle,
                    size: 16.sp,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Talk to Aura',
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 10.h),
          // Secondary — hands-on composer
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              context.push('/create-strategy');
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              decoration: ShapeDecoration(
                color: c.background,
                shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.circular(context.auraRadii.md),
                  side: BorderSide(color: c.borderSubtle),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    PhosphorIconsBold.slidersHorizontal,
                    size: 16.sp,
                    color: c.textPrimary,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Build it yourself',
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBotsIllustrationPainter extends CustomPainter {
  final Color lineColor;
  final Color accentColor;

  _EmptyBotsIllustrationPainter({
    required this.lineColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Three nested bin-distribution arcs — symbolic of strategy "slots"
    // waiting to be filled.
    for (var ring = 0; ring < 3; ring++) {
      final ringW = 60 + ring * 28.0;
      final binCount = 18 + ring * 4;
      final isOuter = ring == 0;
      final paint = Paint()
        ..color = isOuter ? accentColor.withValues(alpha: 0.6) : lineColor
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < binCount; i++) {
        final t = (i - binCount / 2) / (binCount / 2); // -1..1
        final x = centerX + t * (ringW / 2);
        final h = (1 - t.abs()) * (isOuter ? 26 : 14);
        canvas.drawLine(
          Offset(x, centerY - h / 2 - ring * 4.0),
          Offset(x, centerY + h / 2 - ring * 4.0),
          paint,
        );
      }
    }

    // Centre dot — the "no bot" focal point
    canvas.drawCircle(
      Offset(centerX, centerY - 8),
      3,
      Paint()..color = accentColor,
    );
  }

  @override
  bool shouldRepaint(covariant _EmptyBotsIllustrationPainter old) =>
      old.lineColor != lineColor || old.accentColor != accentColor;
}

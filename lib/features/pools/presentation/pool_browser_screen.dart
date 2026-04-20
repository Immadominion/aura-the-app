import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_radii.dart';
import 'package:aura/core/theme/app_theme.dart';

import 'package:aura/features/pools/models/pool_candidate.dart';
import 'package:aura/features/pools/providers/pool_provider.dart';

/// Phase 15 (audit §6.1) — Pool Browser.
///
/// Lists candidate DLMM pools the model is currently scoring, sorted
/// by score. Read-only in v1: proves Aura is *thinking* even when it
/// isn't trading. Live data lands when the LP Agent pool endpoint is
/// wired (audit §10).
class PoolBrowserScreen extends ConsumerStatefulWidget {
  const PoolBrowserScreen({super.key});

  @override
  ConsumerState<PoolBrowserScreen> createState() => _PoolBrowserScreenState();
}

enum _PoolSort { score, tvl, volume }

class _PoolBrowserScreenState extends ConsumerState<PoolBrowserScreen> {
  _PoolSort _sort = _PoolSort.score;

  List<PoolCandidate> _applySort(List<PoolCandidate> input) {
    final out = [...input];
    switch (_sort) {
      case _PoolSort.score:
        out.sort((a, b) => b.score.compareTo(a.score));
      case _PoolSort.tvl:
        out.sort((a, b) => b.tvlSol.compareTo(a.tvlSol));
      case _PoolSort.volume:
        out.sort((a, b) => b.volume24hSol.compareTo(a.volume24hSol));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final text = context.auraText;
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final candidatesAsync = ref.watch(poolCandidatesProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: c.background,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, topPad + 12.h, 20.w, 16.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.surface,
                        border: Border.all(color: c.borderSubtle),
                      ),
                      child: Icon(
                        PhosphorIconsBold.arrowLeft,
                        size: 20.sp,
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'POOLS AURA IS WATCHING',
                          style: text.labelSmall?.copyWith(
                            letterSpacing: 1.4,
                            fontSize: 10.sp,
                            color: c.textTertiary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Model is scoring in real time',
                          style: text.bodySmall?.copyWith(
                            color: c.textSecondary,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Sort chips ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                children: [
                  _SortChip(
                    label: 'Score',
                    selected: _sort == _PoolSort.score,
                    onTap: () => setState(() => _sort = _PoolSort.score),
                    c: c,
                    text: text,
                  ),
                  SizedBox(width: 8.w),
                  _SortChip(
                    label: 'TVL',
                    selected: _sort == _PoolSort.tvl,
                    onTap: () => setState(() => _sort = _PoolSort.tvl),
                    c: c,
                    text: text,
                  ),
                  SizedBox(width: 8.w),
                  _SortChip(
                    label: '24h Vol',
                    selected: _sort == _PoolSort.volume,
                    onTap: () => setState(() => _sort = _PoolSort.volume),
                    c: c,
                    text: text,
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // ── List ──
            Expanded(
              child: candidatesAsync.when(
                loading: () => Center(
                  child: SizedBox(
                    width: 24.w,
                    height: 24.w,
                    child: CircularProgressIndicator(
                      color: c.accent,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Could not load pools.',
                    style: text.bodySmall?.copyWith(color: c.textTertiary),
                  ),
                ),
                data: (raw) {
                  final pools = _applySort(raw);
                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      20.w,
                      0,
                      20.w,
                      bottomPad + 24.h,
                    ),
                    itemCount: pools.length + 1,
                    separatorBuilder: (_, _) => SizedBox(height: 10.h),
                    itemBuilder: (ctx, i) {
                      if (i == pools.length) {
                        // Footer per audit §6.1 — discoverable links to the
                        // other Meteora products. v1 = link-out only.
                        return Padding(
                          padding: EdgeInsets.only(top: 16.h),
                          child: _MoreWaysToEarnCard(c: c, text: text),
                        );
                      }
                      return _PoolRow(pool: pools[i], c: c, text: text)
                          .animate()
                          .fadeIn(
                            duration: 240.ms,
                            delay: (40 * i).ms,
                          )
                          .slideY(begin: 0.05, end: 0);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Sort chip
// ─────────────────────────────────────────────────────────────

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final AuraColors c;
  final TextTheme text;

  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.c,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
        decoration: ShapeDecoration(
          color: selected ? c.accent.withValues(alpha: 0.12) : c.surface,
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.circular(context.auraRadii.pill),
            side: BorderSide(
              color: selected
                  ? c.accent.withValues(alpha: 0.4)
                  : c.borderSubtle,
            ),
          ),
        ),
        child: Text(
          label,
          style: text.labelSmall?.copyWith(
            color: selected ? c.accent : c.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 11.sp,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Pool row
// ─────────────────────────────────────────────────────────────

class _PoolRow extends StatelessWidget {
  final PoolCandidate pool;
  final AuraColors c;
  final TextTheme text;

  const _PoolRow({required this.pool, required this.c, required this.text});

  Color _recColor() => switch (pool.recommendation) {
    PoolRecommendation.enter => c.profit,
    PoolRecommendation.watch => c.accent,
    PoolRecommendation.skip => c.textTertiary,
  };

  String _fmtSol(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final recColor = _recColor();
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
      decoration: ShapeDecoration(
        color: c.surface,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(context.auraRadii.lg),
          side: BorderSide(color: c.borderSubtle),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pool.pairName,
                      style: text.titleMedium?.copyWith(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'bin step ${pool.binStep}',
                      style: text.labelSmall?.copyWith(
                        color: c.textTertiary,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
              // Recommendation pill
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: ShapeDecoration(
                  color: recColor.withValues(alpha: 0.14),
                  shape: StadiumBorder(
                    side: BorderSide(color: recColor.withValues(alpha: 0.4)),
                  ),
                ),
                child: Text(
                  pool.recommendation.label,
                  style: text.labelSmall?.copyWith(
                    color: recColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 10.sp,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          // Stats grid
          Row(
            children: [
              Expanded(
                child: _PoolStat(
                  label: 'Score',
                  value: pool.score.toStringAsFixed(2),
                  c: c,
                  text: text,
                ),
              ),
              Container(width: 1, height: 28.h, color: c.borderSubtle),
              Expanded(
                child: _PoolStat(
                  label: 'Confidence',
                  value: '${(pool.mlConfidence * 100).toStringAsFixed(0)}%',
                  c: c,
                  text: text,
                ),
              ),
              Container(width: 1, height: 28.h, color: c.borderSubtle),
              Expanded(
                child: _PoolStat(
                  label: 'TVL',
                  value: '${_fmtSol(pool.tvlSol)} SOL',
                  c: c,
                  text: text,
                ),
              ),
              Container(width: 1, height: 28.h, color: c.borderSubtle),
              Expanded(
                child: _PoolStat(
                  label: '24h Vol',
                  value: '${_fmtSol(pool.volume24hSol)} SOL',
                  c: c,
                  text: text,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PoolStat extends StatelessWidget {
  final String label;
  final String value;
  final AuraColors c;
  final TextTheme text;

  const _PoolStat({
    required this.label,
    required this.value,
    required this.c,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: text.labelSmall?.copyWith(
            color: c.textTertiary,
            fontSize: 10.sp,
            letterSpacing: 0.6,
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          value,
          style: text.titleSmall?.copyWith(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// More ways to earn — discoverable Meteora products (audit §6.1)
// v1: link-out only. v2 (DAMM v2) gets native integration later.
// ─────────────────────────────────────────────────────────────

class _MoreWaysToEarnCard extends StatelessWidget {
  final AuraColors c;
  final TextTheme text;

  const _MoreWaysToEarnCard({required this.c, required this.text});

  static const _products = <({String label, String url})>[
    (label: 'DAMM v2', url: 'https://docs.meteora.ag/product-overview/dlmm-overview/dlmm-overview-introduction'),
    (label: 'DBC', url: 'https://docs.meteora.ag/product-overview/meteora-dbc'),
    (label: 'Alpha Vault', url: 'https://docs.meteora.ag/product-overview/alpha-vault'),
    (label: 'Stake2Earn', url: 'https://docs.meteora.ag/product-overview/stake2earn'),
    (label: 'Dynamic Vault', url: 'https://docs.meteora.ag/product-overview/dynamic-vaults'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
      decoration: ShapeDecoration(
        color: c.background,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(context.auraRadii.lg),
          side: BorderSide(color: c.borderSubtle),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MORE WAYS TO EARN ON METEORA',
            style: text.labelSmall?.copyWith(
              color: c.textTertiary,
              letterSpacing: 1.3,
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              for (final p in _products)
                GestureDetector(
                  onTap: () async {
                    final uri = Uri.parse(p.url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: ShapeDecoration(
                      color: c.surface,
                      shape: StadiumBorder(
                        side: BorderSide(color: c.borderSubtle),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          p.label,
                          style: text.labelSmall?.copyWith(
                            color: c.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(
                          PhosphorIconsBold.arrowUpRight,
                          size: 11.sp,
                          color: c.textTertiary,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

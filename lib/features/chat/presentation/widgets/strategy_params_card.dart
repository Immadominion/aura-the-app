import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_radii.dart';
import 'package:aura/features/chat/models/chat_models.dart';
import 'package:aura/shared/widgets/aura_bottom_sheet.dart';

/// Inline strategy receipt — replaces voice input when AI picks a strategy.
///
/// 3D-ish card (subtle outer + inner shadow, no gradient).
/// Cancel icon top-left. Apply pill bottom-right.
/// Each parameter row is tappable → opens editor bottom sheet.
class StrategyParamsCard extends StatelessWidget {
  final StrategyParams params;
  final VoidCallback? onApply;
  final VoidCallback? onDismiss;
  final ValueChanged<StrategyParams>? onParamsChanged;
  final AuraColors c;
  final TextTheme text;

  const StrategyParamsCard({
    super.key,
    required this.params,
    this.onApply,
    this.onDismiss,
    this.onParamsChanged,
    required this.c,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final entries = _buildEntries();
    final radii = context.auraRadii;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
      decoration: ShapeDecoration(
        color: c.surface,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(radii.lg),
          side: BorderSide(color: c.borderSubtle, width: 1),
        ),
        shadows: [
          // Outer lift shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          // Subtle bottom edge (3D depth)
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.06),
            blurRadius: 0,
            spreadRadius: 0,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.auraRadii.lg),
        child: CustomPaint(
          painter: _InnerShadowPainter(c: c),
          child: Padding(
            padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 18.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Top bar: cancel + label ──
                Row(
                  children: [
                    if (onDismiss != null)
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onDismiss!();
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 28.w,
                          height: 28.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c.textTertiary.withValues(alpha: 0.08),
                          ),
                          child: Icon(
                            PhosphorIconsBold.x,
                            size: 12.sp,
                            color: c.textTertiary,
                          ),
                        ),
                      ),
                    if (onDismiss != null) SizedBox(width: 10.w),

                    Text(
                      'AURA STRATEGY',
                      style: text.labelSmall?.copyWith(
                        color: c.textTertiary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 18.h),

                // ── Receipt lines ──
                ...entries.asMap().entries.map((mapEntry) {
                  final idx = mapEntry.key;
                  final e = mapEntry.value;
                  return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ReceiptRow(
                            entry: e,
                            c: c,
                            text: text,
                            onTap: onParamsChanged != null
                                ? () => _openEditor(context, e)
                                : null,
                          ),
                          // Divider between rows
                          if (idx < entries.length - 1)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 4.h),
                            ),
                        ],
                      )
                      .animate()
                      .fadeIn(duration: 250.ms, delay: (80 + idx * 40).ms)
                      .slideX(begin: -0.02, end: 0);
                }),

                SizedBox(height: 8.h),

                // ── Receipt section divider (wavy edge) ──
                LayoutBuilder(
                  builder: (context, constraints) {
                    return CustomPaint(
                      painter: _ReceiptWavyDividerPainter(color: c.accentMuted),
                      size: Size(constraints.maxWidth, 24.h),
                    );
                  },
                ),

                SizedBox(height: 16.h),

                // ── Tap to edit hint ──
                if (onParamsChanged != null)
                  Padding(
                    padding: EdgeInsets.only(top: 0.h, bottom: 8.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Tap any value to edit',
                          style: text.labelSmall?.copyWith(
                            color: c.accent.withAlpha(120),
                            fontSize: 10.sp,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                SizedBox(height: 24.h),

                // ── Apply button — small pill, right-aligned ──
                if (onApply != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        onApply!();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 9.h,
                        ),
                        decoration: BoxDecoration(
                          color: c.textPrimary,
                          borderRadius: BorderRadius.circular(context.auraRadii.pill),
                          boxShadow: [
                            BoxShadow(
                              color: c.textPrimary.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              PhosphorIconsBold.check,
                              size: 13.sp,
                              color: c.textInverse,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'Apply',
                              style: text.labelMedium?.copyWith(
                                color: c.textInverse,
                                fontWeight: FontWeight.w700,
                                fontSize: 13.sp,
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
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.04, end: 0);
  }

  // ─── Open parameter editor bottom sheet ──────────────────

  void _openEditor(BuildContext context, _ParamEntry entry) {
    HapticFeedback.selectionClick();

    AuraBottomSheet.show(
      context: context,
      title: entry.label,
      builder: (c, text) => _ParamEditorContent(
        entry: entry,
        currentParams: params,
        onChanged: (updated) {
          onParamsChanged?.call(updated);
          Navigator.of(context).pop();
        },
        c: c,
        text: text,
      ),
    );
  }

  // ─── Build entries ───────────────────────────────────────

  List<_ParamEntry> _buildEntries() {
    final entries = <_ParamEntry>[];

    if (params.entryScoreThreshold != null) {
      entries.add(
        _ParamEntry(
          label: 'Entry Score',
          value: '${params.entryScoreThreshold!.toStringAsFixed(0)} pts',
          key: 'entryScoreThreshold',
          current: params.entryScoreThreshold!,
          min: 50,
          max: 300,
          divisions: 50,
          unit: 'pts',
          format: (v) => v.toStringAsFixed(0),
        ),
      );
    }
    if (params.minVolume24h != null) {
      entries.add(
        _ParamEntry(
          label: 'Min 24h Volume',
          value: _formatDollar(params.minVolume24h!),
          key: 'minVolume24h',
          current: params.minVolume24h!,
          min: 0,
          max: 100000,
          divisions: 100,
          unit: '\$',
          format: (v) => _formatDollar(v),
        ),
      );
    }
    if (params.minLiquidity != null) {
      entries.add(
        _ParamEntry(
          label: 'Min Liquidity',
          value: _formatDollar(params.minLiquidity!),
          key: 'minLiquidity',
          current: params.minLiquidity!,
          min: 0,
          max: 500000,
          divisions: 100,
          unit: '\$',
          format: (v) => _formatDollar(v),
        ),
      );
    }
    if (params.maxLiquidity != null) {
      entries.add(
        _ParamEntry(
          label: 'Max Liquidity',
          value: _formatDollar(params.maxLiquidity!),
          key: 'maxLiquidity',
          current: params.maxLiquidity!,
          min: 10000,
          max: 5000000,
          divisions: 100,
          unit: '\$',
          format: (v) => _formatDollar(v),
        ),
      );
    }
    if (params.positionSizeSOL != null) {
      entries.add(
        _ParamEntry(
          label: 'Position Size',
          value: '${params.positionSizeSOL!.toStringAsFixed(1)} SOL',
          key: 'positionSizeSOL',
          current: params.positionSizeSOL!,
          min: 0.1,
          max: 10.0,
          divisions: 99,
          unit: 'SOL',
          format: (v) => v.toStringAsFixed(1),
        ),
      );
    }
    if (params.maxConcurrentPositions != null) {
      entries.add(
        _ParamEntry(
          label: 'Max Concurrent',
          value: '${params.maxConcurrentPositions}',
          key: 'maxConcurrentPositions',
          current: params.maxConcurrentPositions!.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          unit: '',
          format: (v) => v.toStringAsFixed(0),
          isInt: true,
        ),
      );
    }
    if (params.defaultBinRange != null) {
      entries.add(
        _ParamEntry(
          label: 'Bin Range',
          value: '${params.defaultBinRange} bins',
          key: 'defaultBinRange',
          current: params.defaultBinRange!.toDouble(),
          min: 1,
          max: 30,
          divisions: 29,
          unit: 'bins',
          format: (v) => v.toStringAsFixed(0),
          isInt: true,
        ),
      );
    }
    if (params.profitTargetPercent != null) {
      entries.add(
        _ParamEntry(
          label: 'Profit Target',
          value: '${params.profitTargetPercent!.toStringAsFixed(0)}%',
          key: 'profitTargetPercent',
          current: params.profitTargetPercent!,
          min: 1,
          max: 50,
          divisions: 49,
          unit: '%',
          format: (v) => v.toStringAsFixed(1),
        ),
      );
    }
    if (params.stopLossPercent != null) {
      entries.add(
        _ParamEntry(
          label: 'Stop Loss',
          value: '${params.stopLossPercent!.toStringAsFixed(0)}%',
          key: 'stopLossPercent',
          current: params.stopLossPercent!,
          min: 1,
          max: 30,
          divisions: 29,
          unit: '%',
          format: (v) => v.toStringAsFixed(1),
        ),
      );
    }
    if (params.maxHoldTimeMinutes != null) {
      final min = params.maxHoldTimeMinutes!;
      entries.add(
        _ParamEntry(
          label: 'Max Hold',
          value: min >= 60 ? '${(min / 60).toStringAsFixed(1)}h' : '${min}min',
          key: 'maxHoldTimeMinutes',
          current: min.toDouble(),
          min: 10,
          max: 480,
          divisions: 47,
          unit: 'min',
          format: (v) {
            final m = v.round();
            return m >= 60 ? '${(m / 60).toStringAsFixed(1)}h' : '${m}min';
          },
          isInt: true,
        ),
      );
    }
    if (params.maxDailyLossSOL != null) {
      entries.add(
        _ParamEntry(
          label: 'Daily Loss Limit',
          value: '${params.maxDailyLossSOL!.toStringAsFixed(1)} SOL',
          key: 'maxDailyLossSOL',
          current: params.maxDailyLossSOL!,
          min: 0.5,
          max: 20.0,
          divisions: 39,
          unit: 'SOL',
          format: (v) => v.toStringAsFixed(1),
        ),
      );
    }
    if (params.cooldownMinutes != null) {
      entries.add(
        _ParamEntry(
          label: 'Cooldown',
          value: '${params.cooldownMinutes}min',
          key: 'cooldownMinutes',
          current: params.cooldownMinutes!.toDouble(),
          min: 5,
          max: 240,
          divisions: 47,
          unit: 'min',
          format: (v) => '${v.round()}min',
          isInt: true,
        ),
      );
    }

    return entries;
  }

  String _formatDollar(double v) {
    if (v >= 1000000) return '\$${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '\$${(v / 1000).toStringAsFixed(1)}k';
    return '\$${v.toStringAsFixed(0)}';
  }
}

// ═══════════════════════════════════════════════════════════
// Receipt row — label ....... value
// ═══════════════════════════════════════════════════════════

class _ReceiptRow extends StatelessWidget {
  final _ParamEntry entry;
  final AuraColors c;
  final TextTheme text;
  final VoidCallback? onTap;

  const _ReceiptRow({
    required this.entry,
    required this.c,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 1.h),
        child: Row(
          children: [
            Text(
              entry.label,
              style: text.bodySmall?.copyWith(
                color: c.textSecondary,
                fontSize: 13.sp,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return CustomPaint(
                    size: Size(constraints.maxWidth, 1),
                    painter: _DottedLinePainter(color: c.accentMuted),
                  );
                },
              ),
            ),
            SizedBox(width: 10.w),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.value,
                  style: text.bodySmall?.copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (onTap != null) ...[
                  SizedBox(width: 4.w),
                  Icon(
                    PhosphorIconsBold.pencilSimple,
                    size: 10.sp,
                    color: c.textTertiary.withValues(alpha: 0.4),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Dotted line painter (receipt dots between key and value)
// ═══════════════════════════════════════════════════════════

class _DottedLinePainter extends CustomPainter {
  final Color color;
  _DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const dashWidth = 2.0;
    const dashGap = 3.0;
    double x = 0;
    final y = size.height / 2;

    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + dashWidth, y), paint);
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════
// Receipt wavy divider (perforated edge effect)
// ═══════════════════════════════════════════════════════════

class _ReceiptWavyDividerPainter extends CustomPainter {
  final Color color;
  _ReceiptWavyDividerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    final scallop = 6.0; // Wave height
    final wavelength = 20.0; // Distance between waves
    const margin = 16.0; // Margin from edges

    double x = margin;
    final y = size.height / 2;
    bool waveUp = true;

    // Draw wavy line
    path.moveTo(x, y);
    while (x < size.width - margin) {
      final nextX = x + wavelength / 2;
      final arcY = waveUp ? y - scallop : y + scallop;

      path.quadraticBezierTo(x + wavelength / 4, arcY, nextX, y);

      x = nextX;
      waveUp = !waveUp;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════
// Inner shadow painter (3D depth effect)
// ═══════════════════════════════════════════════════════════

class _InnerShadowPainter extends CustomPainter {
  final AuraColors c;
  _InnerShadowPainter({required this.c});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Top inner shadow (pushed in from top)
    final topGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.black.withValues(alpha: 0.04), Colors.transparent],
      stops: const [0.0, 0.08],
    );
    canvas.drawRect(rect, Paint()..shader = topGradient.createShader(rect));

    // Bottom inner highlight
    final bottomGradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [Colors.black.withValues(alpha: 0.02), Colors.transparent],
      stops: const [0.0, 0.05],
    );
    canvas.drawRect(rect, Paint()..shader = bottomGradient.createShader(rect));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════
// Parameter editor — content inside AuraBottomSheet
// ═══════════════════════════════════════════════════════════

class _ParamEditorContent extends StatefulWidget {
  final _ParamEntry entry;
  final StrategyParams currentParams;
  final ValueChanged<StrategyParams> onChanged;
  final AuraColors c;
  final TextTheme text;

  const _ParamEditorContent({
    required this.entry,
    required this.currentParams,
    required this.onChanged,
    required this.c,
    required this.text,
  });

  @override
  State<_ParamEditorContent> createState() => _ParamEditorContentState();
}

class _ParamEditorContentState extends State<_ParamEditorContent> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.entry.current;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final text = widget.text;
    final e = widget.entry;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 8.h),

        // ── Big value display ──
        Text(
          e.format(_value),
          style: text.displayMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: c.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),

        if (e.unit.isNotEmpty)
          Text(
            e.unit,
            style: text.bodySmall?.copyWith(
              color: c.textTertiary,
              fontSize: 12.sp,
            ),
          ),

        SizedBox(height: 28.h),

        // ── Slider ──
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
            min: e.min,
            max: e.max,
            divisions: e.divisions,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _value = v);
            },
          ),
        ),

        // ── Range labels ──
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                e.format(e.min),
                style: text.labelSmall?.copyWith(
                  color: c.textTertiary,
                  fontSize: 10.sp,
                ),
              ),
              Text(
                e.format(e.max),
                style: text.labelSmall?.copyWith(
                  color: c.textTertiary,
                  fontSize: 10.sp,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 28.h),

        // ── Confirm button ──
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              final updated = _applyValue(
                widget.currentParams,
                e.key,
                e.isInt ? _value.round().toDouble() : _value,
              );
              widget.onChanged(updated);
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              decoration: BoxDecoration(
                color: c.accent,
                borderRadius: BorderRadius.circular(context.auraRadii.md),
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
                  'Set ${e.label}',
                  style: text.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),

        SizedBox(height: 8.h),
      ],
    );
  }

  StrategyParams _applyValue(StrategyParams p, String key, double v) {
    switch (key) {
      case 'entryScoreThreshold':
        return p.copyWith(entryScoreThreshold: v);
      case 'minVolume24h':
        return p.copyWith(minVolume24h: v);
      case 'minLiquidity':
        return p.copyWith(minLiquidity: v);
      case 'maxLiquidity':
        return p.copyWith(maxLiquidity: v);
      case 'positionSizeSOL':
        return p.copyWith(positionSizeSOL: v);
      case 'maxConcurrentPositions':
        return p.copyWith(maxConcurrentPositions: v.round());
      case 'defaultBinRange':
        return p.copyWith(defaultBinRange: v.round());
      case 'profitTargetPercent':
        return p.copyWith(profitTargetPercent: v);
      case 'stopLossPercent':
        return p.copyWith(stopLossPercent: v);
      case 'maxHoldTimeMinutes':
        return p.copyWith(maxHoldTimeMinutes: v.round());
      case 'maxDailyLossSOL':
        return p.copyWith(maxDailyLossSOL: v);
      case 'cooldownMinutes':
        return p.copyWith(cooldownMinutes: v.round());
      default:
        return p;
    }
  }
}

// ═══════════════════════════════════════════════════════════
// Data model for a single parameter entry
// ═══════════════════════════════════════════════════════════

class _ParamEntry {
  final String label;
  final String value;
  final String key;
  final double current;
  final double min;
  final double max;
  final int divisions;
  final String unit;
  final String Function(double) format;
  final bool isInt;

  const _ParamEntry({
    required this.label,
    required this.value,
    required this.key,
    required this.current,
    required this.min,
    required this.max,
    required this.divisions,
    required this.unit,
    required this.format,
    this.isInt = false,
  });
}

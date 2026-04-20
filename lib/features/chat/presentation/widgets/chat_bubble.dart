import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_radii.dart';
import 'package:aura/features/chat/models/chat_models.dart';
import 'package:aura/shared/utils/simple_markdown.dart';

/// A single chat message bubble.
///
/// [opacity] controls how faded older messages appear.
/// User messages: right-aligned, accent-tinted.
/// Assistant messages: left-aligned, surface-tinted.
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final AuraColors c;
  final TextTheme text;

  /// 0.0–1.0. Older messages should pass lower values to visually recede.
  final double opacity;

  /// Called when the user taps the "View Strategy" chip on a message that
  /// contains strategy parameters.
  final VoidCallback? onTapStrategy;

  const ChatBubble({
    super.key,
    required this.message,
    required this.c,
    required this.text,
    this.opacity = 1.0,
    this.onTapStrategy,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          margin: EdgeInsets.only(bottom: 24.h),
          child: Column(
            crossAxisAlignment: isUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(
                  children: parseSimpleMarkdown(
                    message.content,
                    (isUser
                            ? text.bodyMedium?.copyWith(
                                color: c.textSecondary.withValues(
                                  alpha: opacity,
                                ),
                                height: 1.45,
                              )
                            : text.labelLarge?.copyWith(
                                color: c.textPrimary.withValues(alpha: opacity),
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                              )) ??
                        const TextStyle(),
                  ),
                ),
              ),

              // Strategy chip for assistant messages that carry params
              if (!isUser && message.hasStrategy && onTapStrategy != null)
                Padding(
                  padding: EdgeInsets.only(top: 10.h),
                  child: GestureDetector(
                    onTap: onTapStrategy,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: c.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(context.auraRadii.sm),
                        border: Border.all(
                          color: c.accent.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Strategy',
                            style: text.bodySmall?.copyWith(
                              color: c.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Icon(
                            PhosphorIconsBold.arrowRight,
                            size: 14.sp,
                            color: c.accent,
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

// ─────────────────────────────────────────────────────────────
// Typing indicator — animated dots + cycling thought text
// ─────────────────────────────────────────────────────────────

class TypingIndicator extends StatefulWidget {
  final AuraColors c;

  const TypingIndicator({super.key, required this.c});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> {
  static const _thoughts = [
    'Analyzing your style...',
    'Reviewing market data...',
    'Configuring parameters...',
    'Thinking it through...',
    'Almost there...',
  ];

  int _thoughtIndex = 0;
  bool _textVisible = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), _cycle);
  }

  void _cycle(Timer t) {
    if (!mounted) return;
    setState(() => _textVisible = false);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _thoughtIndex = (_thoughtIndex + 1) % _thoughts.length;
        _textVisible = true;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated dots
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return Container(
                      width: 6.w,
                      height: 6.w,
                      margin: EdgeInsets.symmetric(horizontal: 2.w),
                      decoration: BoxDecoration(
                        color: widget.c.accent,
                        shape: BoxShape.circle,
                      ),
                    )
                    .animate(onPlay: (ctrl) => ctrl.repeat())
                    .scaleXY(
                      begin: 0.6,
                      end: 1.0,
                      duration: 600.ms,
                      delay: (i * 180).ms,
                      curve: Curves.easeInOut,
                    )
                    .then()
                    .scaleXY(begin: 1.0, end: 0.6, duration: 600.ms);
              }),
            ),

            SizedBox(width: 10.w),

            // Cycling thought text
            AnimatedOpacity(
              duration: const Duration(milliseconds: 280),
              opacity: _textVisible ? 1.0 : 0.0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 280),
                offset: _textVisible ? Offset.zero : const Offset(0, 0.15),
                child: Text(
                  _thoughts[_thoughtIndex],
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: widget.c.accent,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

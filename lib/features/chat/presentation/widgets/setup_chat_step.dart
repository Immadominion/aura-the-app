import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/features/chat/models/chat_models.dart';
import 'package:aura/features/chat/providers/chat_provider.dart';
import 'package:aura/features/chat/presentation/widgets/chat_bubble.dart';
import 'package:aura/features/chat/presentation/widgets/sage_voice_input.dart';
import 'package:aura/features/chat/presentation/widgets/strategy_params_card.dart';
import 'package:aura/features/setup/presentation/widgets/step_indicator.dart';

/// Setup Step 1.5 — Talk to Sage to configure strategy via conversation.
class SetupChatStep extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  final void Function(StrategyParams params) onApplyParams;
  final SageColors c;
  final TextTheme text;

  const SetupChatStep({
    super.key,
    required this.onBack,
    required this.onApplyParams,
    required this.c,
    required this.text,
  });

  @override
  ConsumerState<SetupChatStep> createState() => _SetupChatStepState();
}

class _SetupChatStepState extends ConsumerState<SetupChatStep> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only start a new conversation if we don't already have one
      // (i.e. wasn't restored from persistence).
      final state = ref.read(setupChatProvider);
      if (state.conversationId == null && state.messages.isEmpty) {
        ref.read(setupChatProvider.notifier).newConversation();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  /// Compute opacity so recent messages are vivid, older ones recede.
  double _bubbleOpacity(int index, int total) {
    final fromEnd = total - index;
    return switch (fromEnd) {
      1 => 1.0,
      2 => 0.80,
      3 => 0.58,
      _ => 0.38,
    };
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(setupChatProvider);

    ref.listen<ChatState>(setupChatProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length || next.isLoading) {
        _scrollToBottom();
      }
    });

    final hasMessages = chatState.messages.isNotEmpty;
    final notifier = ref.read(setupChatProvider.notifier);
    final hasStrategy =
        chatState.latestParams != null && !chatState.latestParams!.isEmpty;

    return Column(
      children: [
        // ── Header ──
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16.h),

              // ── iOS-style back button ──
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onBack();
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        PhosphorIconsBold.caretLeft,
                        size: 16.sp,
                        color: widget.c.accent,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Back',
                        style: widget.text.titleMedium?.copyWith(
                          color: widget.c.accent,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              StepIndicator(current: 1, total: 3, c: widget.c),

              SizedBox(height: 28.h),

              // ── Headline ──
              Text('Talk to Sage', style: widget.text.headlineLarge)
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic),

              SizedBox(height: 8.h),

              Text(
                'Describe your trading style and Sage\nconfigures your strategy.',
                style: widget.text.bodyMedium?.copyWith(
                  color: widget.c.textSecondary,
                  height: 1.4,
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 100.ms),

              SizedBox(height: 16.h),
            ],
          ),
        ),

        // ── Chat messages OR animated suggestion ──
        Expanded(
          child: Stack(
            children: [
              // Messages / suggestion
              Positioned.fill(
                child: !hasMessages
                    ? SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: _AnimatedSuggestion(
                          c: widget.c,
                          text: widget.text,
                          onTap: (msg) => notifier.sendMessage(msg),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 4.h,
                        ),
                        itemCount:
                            chatState.messages.length +
                            (chatState.isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          final total = chatState.messages.length;

                          // Typing indicator
                          if (index >= total) {
                            return TypingIndicator(c: widget.c);
                          }

                          return ChatBubble(
                            message: chatState.messages[index],
                            opacity: _bubbleOpacity(index, total),
                            c: widget.c,
                            text: widget.text,
                            onTapStrategy: chatState.messages[index].hasStrategy
                                ? () => notifier.surfaceParamsFromMessage(index)
                                : null,
                          );
                        },
                      ),
              ),

              // Blur overlay — fades in when strategy card is visible
              if (hasStrategy)
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 3.0),
                    child: Container(
                      color: widget.c.background.withValues(alpha: 0.35),
                    ),
                  ),
                ).animate().fadeIn(duration: 220.ms),
            ],
          ),
        ),

        // ── Error banner ──
        if (chatState.error != null)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
            color: widget.c.loss.withValues(alpha: 0.12),
            child: Row(
              children: [
                Icon(
                  PhosphorIconsBold.warning,
                  size: 13.sp,
                  color: widget.c.loss,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    chatState.error!,
                    style: widget.text.bodySmall?.copyWith(
                      color: widget.c.loss,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: notifier.clearError,
                  child: Icon(
                    PhosphorIconsBold.x,
                    size: 13.sp,
                    color: widget.c.loss,
                  ),
                ),
              ],
            ),
          ),

        // ── Bottom: Voice input OR Strategy card ──
        if (hasStrategy)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: StrategyParamsCard(
              params: chatState.latestParams!,
              onApply: () {
                HapticFeedback.mediumImpact();
                widget.onApplyParams(chatState.latestParams!);
              },
              onDismiss: () {
                HapticFeedback.lightImpact();
                notifier.dismissParams();
              },
              onParamsChanged: (updated) {
                notifier.updateLatestParams(updated);
              },
              c: widget.c,
              text: widget.text,
            ),
          )
        else
          SageVoiceInput(
            isRecording: chatState.isRecording,
            isTranscribing: chatState.isTranscribing,
            isLoading: chatState.isLoading,
            pendingTranscript: chatState.pendingTranscript,
            onSend: notifier.sendMessage,
            onStartRecording: notifier.startRecording,
            onStopRecordingForReview: notifier.stopRecordingForReview,
            onCancelRecording: notifier.cancelRecording,
            onConfirmTranscript: notifier.confirmTranscript,
            onDiscardTranscript: notifier.discardTranscript,
            c: widget.c,
            text: widget.text,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Animated single cycling suggestion
// ─────────────────────────────────────────────────────────────

class _AnimatedSuggestion extends StatefulWidget {
  final SageColors c;
  final TextTheme text;
  final ValueChanged<String> onTap;

  const _AnimatedSuggestion({
    required this.c,
    required this.text,
    required this.onTap,
  });

  @override
  State<_AnimatedSuggestion> createState() => _AnimatedSuggestionState();
}

class _AnimatedSuggestionState extends State<_AnimatedSuggestion> {
  static const _prompts = [
    "I'm a conservative trader — small, safe positions only",
    "I want to maximise fee yield with higher risk tolerance",
    "I like quick flips — tight profit targets, fast exits",
    "I'm a beginner, give me balanced safe defaults",
    "I follow volume spikes and ride momentum hard",
    "Capital preservation first — I hate losing money",
  ];

  int _index = 0;
  bool _visible = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), _cycle);
  }

  void _cycle(Timer t) {
    if (!mounted) return;
    setState(() => _visible = false);
    Future.delayed(const Duration(milliseconds: 320), () {
      if (!mounted) return;
      setState(() {
        _index = (_index + 1) % _prompts.length;
        _visible = true;
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 6.h),

          Text(
            'TRY SAYING',
            style: widget.text.labelSmall?.copyWith(
              color: widget.c.textTertiary,
              letterSpacing: 1.3,
              fontSize: 10.sp,
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

          SizedBox(height: 14.h),

          // Cycling suggestion text
          GestureDetector(
            onTap: () => widget.onTap(_prompts[_index]),
            behavior: HitTestBehavior.opaque,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _visible ? 1.0 : 0.0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 300),
                offset: _visible ? Offset.zero : const Offset(0, 0.08),
                child: Text(
                  '"${_prompts[_index]}"',
                  style: widget.text.bodyLarge?.copyWith(
                    color: widget.c.textPrimary,
                    fontStyle: FontStyle.italic,
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 300.ms),
        ],
      ),
    );
  }
}

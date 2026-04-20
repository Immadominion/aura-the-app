import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_theme.dart';
import 'package:aura/shared/widgets/aura_components.dart';
import 'package:aura/features/chat/models/chat_models.dart';
import 'package:aura/features/chat/providers/chat_provider.dart';
import 'package:aura/features/chat/presentation/widgets/chat_bubble.dart';
import 'package:aura/features/chat/presentation/widgets/aura_voice_input.dart';
import 'package:aura/features/chat/presentation/widgets/strategy_params_card.dart';

/// Intelligence Mode — Aura AI Chat.
///
/// Voice-first input, cycling suggestions when idle, conversation
/// history when sessions exist, strategy card with blur overlay.
/// Minimal containers — content sits on the dark canvas.
class AuraChatScreen extends ConsumerStatefulWidget {
  const AuraChatScreen({super.key});

  @override
  ConsumerState<AuraChatScreen> createState() => _AuraChatScreenState();
}

class _AuraChatScreenState extends ConsumerState<AuraChatScreen> {
  final _scrollController = ScrollController();

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
    final c = context.aura;
    final text = context.auraText;
    final topPad = MediaQuery.of(context).padding.top;
    final chatState = ref.watch(chatProvider);
    final conversationsAsync = ref.watch(conversationListProvider);

    final notifier = ref.read(chatProvider.notifier);
    final hasMessages = chatState.messages.isNotEmpty;
    final hasStrategy =
        chatState.latestParams != null && !chatState.latestParams!.isEmpty;

    // Auto-scroll when messages change.
    ref.listen<ChatState>(chatProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length || next.isLoading) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        children: [
          // ── Header ──
          Padding(
            padding: EdgeInsets.only(
              left: 28.w,
              right: 28.w,
              top: topPad + 48.h,
              bottom: 12.h,
            ),
            child: Row(
              children: [
                const AuraLabel('Intelligence'),

                const Spacer(),

                // New chat shortcut
                if (hasMessages)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      notifier.newConversation();
                      ref.invalidate(conversationListProvider);
                    },
                    child: Text(
                      'Go back',
                      style: text.bodySmall?.copyWith(
                        color: c.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Bot status is shown on the Automate tab; omitted here
          // to reduce clutter.

          // ── Chat content ──
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: !hasMessages
                      ? _IdleView(
                          c: c,
                          text: text,
                          conversations: conversationsAsync.value ?? [],
                          onSuggestionTap: notifier.sendMessage,
                          onConversationTap: (id) {
                            notifier.loadConversation(id);
                          },
                          onDeleteConversation: (id) {
                            notifier.deleteConversation(id);
                            ref.invalidate(conversationListProvider);
                          },
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

                            if (index >= total) {
                              return TypingIndicator(c: c);
                            }

                            return ChatBubble(
                              message: chatState.messages[index],
                              opacity: _bubbleOpacity(index, total),
                              c: c,
                              text: text,
                              onTapStrategy:
                                  chatState.messages[index].hasStrategy
                                  ? () =>
                                        notifier.surfaceParamsFromMessage(index)
                                  : null,
                            );
                          },
                        ),
                ),

                // Blur overlay when strategy card is visible.
                if (hasStrategy)
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 3.0),
                      child: Container(
                        color: c.background.withValues(alpha: 0.35),
                      ),
                    ),
                  ).animate().fadeIn(duration: 220.ms),
              ],
            ),
          ),

          // ── Error banner ──
          if (chatState.error != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              child: Row(
                children: [
                  Icon(PhosphorIconsBold.warning, size: 13.sp, color: c.loss),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      chatState.error!,
                      style: text.bodySmall?.copyWith(color: c.loss),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: notifier.clearError,
                    child: Icon(
                      PhosphorIconsBold.x,
                      size: 13.sp,
                      color: c.loss,
                    ),
                  ),
                ],
              ),
            ),

          // ── Bottom: Strategy card OR Voice input ──
          if (hasStrategy)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: StrategyParamsCard(
                params: chatState.latestParams!,
                onDismiss: () {
                  HapticFeedback.lightImpact();
                  notifier.dismissParams();
                },
                c: c,
                text: text,
              ),
            )
          else
            AuraVoiceInput(
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
              c: c,
              text: text,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Idle view — suggestions or past conversations
// ─────────────────────────────────────────────────────────────

class _IdleView extends StatefulWidget {
  final AuraColors c;
  final TextTheme text;
  final List<ConversationSummary> conversations;
  final ValueChanged<String> onSuggestionTap;
  final ValueChanged<String> onConversationTap;
  final ValueChanged<String> onDeleteConversation;

  const _IdleView({
    required this.c,
    required this.text,
    required this.conversations,
    required this.onSuggestionTap,
    required this.onConversationTap,
    required this.onDeleteConversation,
  });

  @override
  State<_IdleView> createState() => _IdleViewState();
}

class _IdleViewState extends State<_IdleView> {
  late List<ConversationSummary> _local;

  // Conversations removed optimistically but not yet confirmed to backend.
  // Key: conversationId, Value: (item, originalIndex)
  final Map<String, ({ConversationSummary item, int index})> _pendingDelete =
      {};

  @override
  void initState() {
    super.initState();
    _local = List.of(widget.conversations);
  }

  @override
  void didUpdateWidget(_IdleView old) {
    super.didUpdateWidget(old);
    if (widget.conversations.length != old.conversations.length) {
      final ids = {for (final c in widget.conversations) c.conversationId};
      setState(() {
        _local = widget.conversations
            .where((c) => ids.contains(c.conversationId))
            .toList();
      });
    }
  }

  void _swipeDelete(BuildContext context, ConversationSummary conv, int idx) {
    // 1. Remove optimistically.
    setState(() {
      _local.removeWhere((c) => c.conversationId == conv.conversationId);
      _pendingDelete[conv.conversationId] = (item: conv, index: idx);
    });

    // 2. Show undo snackbar.
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    final ctrl = messenger.showSnackBar(
      SnackBar(
        content: const Text('Conversation deleted'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => _undoDelete(conv.conversationId),
        ),
      ),
    );

    // 3. Only hit the backend once snackbar closes without undo.
    ctrl.closed.then((reason) {
      if (!mounted) return;
      if (reason == SnackBarClosedReason.action) return; // undone
      if (!_pendingDelete.containsKey(conv.conversationId)) {
        return; // already undone
      }
      _pendingDelete.remove(conv.conversationId);
      widget.onDeleteConversation(conv.conversationId);
    });
  }

  void _undoDelete(String conversationId) {
    final pending = _pendingDelete.remove(conversationId);
    if (pending == null || !mounted) return;
    setState(() {
      final insertAt = pending.index.clamp(0, _local.length);
      _local.insert(insertAt, pending.item);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_local.isEmpty) {
      return SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: _AnimatedSuggestion(
          c: widget.c,
          text: widget.text,
          onTap: widget.onSuggestionTap,
        ),
      );
    }

    // Past conversations — minimal, no heavy containers.
    // Suggestions hidden when history exists.
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 4.h),
      children: [
        SizedBox(height: 28.h),

        Text(
          'RECENT',
          style: widget.text.labelSmall?.copyWith(
            color: widget.c.textTertiary,
            letterSpacing: 1.3,
            fontSize: 10.sp,
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

        SizedBox(height: 12.h),

        ..._local.take(15).toList().asMap().entries.map((entry) {
          final idx = entry.key;
          final conv = entry.value;
          final title = conv.title ?? 'Conversation';
          final displayTitle = title.length > 50
              ? '${title.substring(0, 50)}...'
              : title;
          final ago = _relativeTime(conv.updatedAt);

          return Dismissible(
            key: ValueKey(conv.conversationId),
            direction: DismissDirection.endToStart,
            background: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(right: 16.w),
                child: Icon(
                  PhosphorIconsBold.trash,
                  size: 18.sp,
                  color: widget.c.loss,
                ),
              ),
            ),
            onDismissed: (_) => _swipeDelete(context, conv, idx),
            child: GestureDetector(
              onTap: () => widget.onConversationTap(conv.conversationId),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                child: Row(
                  children: [
                    // Icon — lightbulb for strategy chats, chat bubble for others
                    Padding(
                      padding: EdgeInsets.only(right: 10.w),
                      child: Icon(
                        conv.hasStrategyParams
                            ? PhosphorIconsBold.lightbulb
                            : PhosphorIconsBold.chatCircle,
                        size: 14.sp,
                        color: idx == 0
                            ? widget.c.accent
                            : widget.c.accent.withValues(alpha: 0.4),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayTitle,
                            style: widget.text.bodyMedium?.copyWith(
                              color: idx == 0
                                  ? widget.c.textPrimary
                                  : widget.c.textSecondary,
                              fontWeight: idx == 0
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            '${conv.messageCount} messages · $ago',
                            style: widget.text.bodySmall?.copyWith(
                              color: widget.c.textTertiary,
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      PhosphorIconsBold.caretRight,
                      size: 12.sp,
                      color: widget.c.textTertiary.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}';
  }
}

// ─────────────────────────────────────────────────────────────
// Animated cycling suggestion (matches setup chat)
// ─────────────────────────────────────────────────────────────

class _AnimatedSuggestion extends StatefulWidget {
  final AuraColors c;
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
  // Audit §5.9 — 4 categories, rotating one prompt per category to teach
  // chat scope without a tutorial. Order is intentional: Strategy first
  // (the primary value prop), then Portfolio (state), Action (control),
  // Discover (exploration).
  static const _categories = <({String label, String prompt})>[
    (label: 'STRATEGY', prompt: 'Create a strategy for SOL/USDC'),
    (label: 'PORTFOLIO', prompt: 'How are my bots doing?'),
    (label: 'ACTION', prompt: 'Pause everything'),
    (label: 'DISCOVER', prompt: 'What pools are trending?'),
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
        _index = (_index + 1) % _categories.length;
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
    final current = _categories[_index];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 6.h),

          Text(
            'TRY ASKING',
            style: widget.text.labelSmall?.copyWith(
              color: widget.c.textTertiary,
              letterSpacing: 1.3,
              fontSize: 10.sp,
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

          SizedBox(height: 14.h),

          GestureDetector(
            onTap: () => widget.onTap(current.prompt),
            behavior: HitTestBehavior.opaque,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: AnimatedOpacity(
                key: ValueKey(_index),
                duration: const Duration(milliseconds: 300),
                opacity: _visible ? 1.0 : 0.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      current.label,
                      style: widget.text.labelSmall?.copyWith(
                        color: widget.c.accent,
                        letterSpacing: 1.4,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      '"${current.prompt}"',
                      style: widget.text.bodyLarge?.copyWith(
                        color: widget.c.textPrimary,
                        fontStyle: FontStyle.italic,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 300.ms),
        ],
      ),
    );
  }
}

// (State pill removed — bot status shown on Automate tab.)

import 'package:aura/shared/widgets/sage_components.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:aura/core/theme/app_colors.dart';

/// Voice-first input widget for Sage chat.
///
/// Replaces the old mic+textfield+send trio with a centred floating mic
/// button that expands into recording / transcript-review flows.
///
/// States (driven by parent provider state + local [_showTyping] flag):
///   – idle          : glowing mic button + "or type" link
///   – recording     : waveform bars + timer + done/cancel
///   – transcribing  : spinner + "Understanding you..."
///   – reviewing     : editable transcript card + send / re-record / discard
///   – typing        : compact text field + mic button
class SageVoiceInput extends StatefulWidget {
  final bool isRecording;
  final bool isTranscribing;
  final bool isLoading;

  /// Non-null when a transcript is ready and waiting for user confirmation.
  final String? pendingTranscript;

  final ValueChanged<String> onSend;
  final VoidCallback onStartRecording;

  /// Stops recording, transcribes, and surfaces the text for review.
  final VoidCallback onStopRecordingForReview;
  final VoidCallback onCancelRecording;

  /// Called when the user approves (possibly edited) transcript text.
  final ValueChanged<String> onConfirmTranscript;
  final VoidCallback onDiscardTranscript;

  final SageColors c;
  final TextTheme text;

  const SageVoiceInput({
    super.key,
    required this.isRecording,
    required this.isTranscribing,
    required this.isLoading,
    required this.pendingTranscript,
    required this.onSend,
    required this.onStartRecording,
    required this.onStopRecordingForReview,
    required this.onCancelRecording,
    required this.onConfirmTranscript,
    required this.onDiscardTranscript,
    required this.c,
    required this.text,
  });

  @override
  State<SageVoiceInput> createState() => _SageVoiceInputState();
}

class _SageVoiceInputState extends State<SageVoiceInput>
    with SingleTickerProviderStateMixin {
  bool _showTyping = false;
  final TextEditingController _typeController = TextEditingController();
  late final TextEditingController _transcriptController;
  bool _hasTypedText = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _transcriptController = TextEditingController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _typeController.addListener(() {
      final has = _typeController.text.trim().isNotEmpty;
      if (has != _hasTypedText) setState(() => _hasTypedText = has);
    });
  }

  @override
  void didUpdateWidget(SageVoiceInput old) {
    super.didUpdateWidget(old);
    // Pre-fill transcript controller when a new transcript arrives.
    if (old.pendingTranscript == null && widget.pendingTranscript != null) {
      _transcriptController.text = widget.pendingTranscript!;
      _transcriptController.selection = TextSelection.collapsed(
        offset: _transcriptController.text.length,
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _typeController.dispose();
    _transcriptController.dispose();
    super.dispose();
  }

  void _sendTyped() {
    final msg = _typeController.text.trim();
    if (msg.isEmpty || widget.isLoading) return;
    HapticFeedback.selectionClick();
    widget.onSend(msg);
    _typeController.clear();
    setState(() => _showTyping = false);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    if (widget.isRecording) {
      return _RecordingPanel(
        c: widget.c,
        text: widget.text,
        bottomInset: bottomInset,
        onStop: () {
          HapticFeedback.mediumImpact();
          widget.onStopRecordingForReview();
        },
        onCancel: () {
          HapticFeedback.selectionClick();
          widget.onCancelRecording();
        },
      );
    }

    if (widget.isTranscribing) {
      return _TranscribingPanel(
        c: widget.c,
        text: widget.text,
        bottomInset: bottomInset,
      );
    }

    if (widget.pendingTranscript != null) {
      return _TranscriptReviewPanel(
        controller: _transcriptController,
        c: widget.c,
        text: widget.text,
        isLoading: widget.isLoading,
        bottomInset: bottomInset,
        onConfirm: () {
          final msg = _transcriptController.text.trim();
          if (msg.isEmpty) return;
          HapticFeedback.mediumImpact();
          widget.onConfirmTranscript(msg);
        },
        onDiscard: () {
          HapticFeedback.selectionClick();
          widget.onDiscardTranscript();
        },
        onReRecord: () {
          HapticFeedback.selectionClick();
          widget.onDiscardTranscript();
          widget.onStartRecording();
        },
      ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.06, end: 0);
    }

    if (_showTyping) {
      return _TypingPanel(
        controller: _typeController,
        hasText: _hasTypedText,
        isLoading: widget.isLoading,
        c: widget.c,
        text: widget.text,
        bottomInset: bottomInset,
        onSend: _sendTyped,
        onMicTap: () {
          setState(() => _showTyping = false);
          HapticFeedback.selectionClick();
          widget.onStartRecording();
        },
        onClose: () {
          setState(() {
            _showTyping = false;
            _typeController.clear();
          });
        },
      ).animate().slideY(begin: 0.1, end: 0, duration: 250.ms);
    }

    // ── Idle ──
    return _IdlePanel(
      c: widget.c,
      text: widget.text,
      isLoading: widget.isLoading,
      pulseController: _pulseController,
      bottomInset: bottomInset,
      onMicTap: () {
        HapticFeedback.heavyImpact();
        widget.onStartRecording();
      },
      onTypeTap: () => setState(() => _showTyping = true),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Idle — pulsing floating mic
// ─────────────────────────────────────────────────────────────

class _IdlePanel extends StatelessWidget {
  final SageColors c;
  final TextTheme text;
  final bool isLoading;
  final AnimationController pulseController;
  final double bottomInset;
  final VoidCallback onMicTap;
  final VoidCallback onTypeTap;

  const _IdlePanel({
    required this.c,
    required this.text,
    required this.isLoading,
    required this.pulseController,
    required this.bottomInset,
    required this.onMicTap,
    required this.onTypeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset + 20.h, top: 12.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SageVoiceButton(onTap: isLoading ? null : onMicTap),

          SizedBox(height: 14.h),

          GestureDetector(
            onTap: onTypeTap,
            child: Text(
              'or type instead',
              style: text.bodySmall?.copyWith(
                color: c.accent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Recording
// ─────────────────────────────────────────────────────────────

class _RecordingPanel extends StatefulWidget {
  final SageColors c;
  final TextTheme text;
  final double bottomInset;
  final VoidCallback onStop;
  final VoidCallback onCancel;

  const _RecordingPanel({
    required this.c,
    required this.text,
    required this.bottomInset,
    required this.onStop,
    required this.onCancel,
  });

  @override
  State<_RecordingPanel> createState() => _RecordingPanelState();
}

class _RecordingPanelState extends State<_RecordingPanel> {
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timeStr {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24.w,
        right: 24.w,
        top: 18.h,
        bottom: widget.bottomInset + 20.h,
      ),

      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Waveform bars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(11, (i) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 3.w),
                child: _WaveBar(index: i, c: widget.c),
              );
            }),
          ),

          SizedBox(height: 14.h),

          // Rec dot + timer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(
                      color: widget.c.loss,
                      shape: BoxShape.circle,
                    ),
                  )
                  .animate(onPlay: (ctrl) => ctrl.repeat())
                  .fadeOut(duration: 700.ms)
                  .then()
                  .fadeIn(duration: 700.ms),
              SizedBox(width: 8.w),
              Text(
                'Recording  $_timeStr',
                style: widget.text.bodyMedium?.copyWith(
                  color: widget.c.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          SizedBox(height: 18.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Cancel
              GestureDetector(
                onTap: widget.onCancel,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 18.w,
                    vertical: 11.h,
                  ),
                  decoration: BoxDecoration(
                    color: widget.c.surfaceElevated,
                    borderRadius: BorderRadius.circular(22.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        PhosphorIconsBold.x,
                        size: 13.sp,
                        color: widget.c.textSecondary,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'Cancel',
                        style: widget.text.bodySmall?.copyWith(
                          color: widget.c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(width: 14.w),

              // Done
              GestureDetector(
                onTap: widget.onStop,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 28.w,
                    vertical: 13.h,
                  ),
                  decoration: BoxDecoration(
                    color: widget.c.accent,
                    borderRadius: BorderRadius.circular(22.r),
                    boxShadow: [
                      BoxShadow(
                        color: widget.c.accent.withValues(alpha: 0.4),
                        blurRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'Done',
                    style: widget.text.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
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

class _WaveBar extends StatelessWidget {
  final int index;
  final SageColors c;

  const _WaveBar({required this.index, required this.c});

  @override
  Widget build(BuildContext context) {
    final delay = (index * 60) % 400;
    final height = 8.0 + (index % 3) * 12.0;
    return Container(
          width: 4.w,
          height: height.h,
          decoration: BoxDecoration(
            color: c.accent.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(4.r),
          ),
        )
        .animate(onPlay: (ctrl) => ctrl.repeat(reverse: true))
        .scaleY(
          begin: 0.25,
          end: 1.0,
          duration: Duration(milliseconds: 380 + delay),
          delay: Duration(milliseconds: delay),
          curve: Curves.easeInOut,
        );
  }
}

// ─────────────────────────────────────────────────────────────
// Transcribing
// ─────────────────────────────────────────────────────────────

class _TranscribingPanel extends StatelessWidget {
  final SageColors c;
  final TextTheme text;
  final double bottomInset;

  const _TranscribingPanel({
    required this.c,
    required this.text,
    required this.bottomInset,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 24.h, bottom: bottomInset + 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 26.w,
            height: 26.w,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: c.accent),
          ),
          SizedBox(height: 12.h),
          Text(
            'Understanding you...',
            style: text.bodySmall?.copyWith(
              color: c.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Transcript review
// ─────────────────────────────────────────────────────────────

class _TranscriptReviewPanel extends StatelessWidget {
  final TextEditingController controller;
  final SageColors c;
  final TextTheme text;
  final bool isLoading;
  final double bottomInset;
  final VoidCallback onConfirm;
  final VoidCallback onDiscard;
  final VoidCallback onReRecord;

  const _TranscriptReviewPanel({
    required this.controller,
    required this.c,
    required this.text,
    required this.isLoading,
    required this.bottomInset,
    required this.onConfirm,
    required this.onDiscard,
    required this.onReRecord,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.45,
      ),
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 12.h,
        bottom: bottomInset + 12.h,
      ),

      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Transcript card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: c.accent.withValues(alpha: 0.22)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        PhosphorIconsBold.microphone,
                        size: 13.sp,
                        color: c.accent,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'YOU SAID',
                        style: text.labelSmall?.copyWith(
                          color: c.accent,
                          letterSpacing: 1.1,
                          fontSize: 10.sp,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: onDiscard,
                        child: Icon(
                          PhosphorIconsBold.x,
                          size: 15.sp,
                          color: c.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  // Editable transcript — capped to 5 lines to prevent
                  // overflow when keyboard is open
                  TextField(
                    controller: controller,
                    style: text.bodyMedium?.copyWith(
                      color: c.textPrimary,
                      height: 1.45,
                    ),
                    maxLines: 5,
                    minLines: 1,
                    cursorColor: c.accent,
                    decoration: InputDecoration.collapsed(
                      hintText: 'Tap to edit...',
                      hintStyle: text.bodyMedium?.copyWith(
                        color: c.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 12.h),

            Row(
              children: [
                // Re-record
                GestureDetector(
                  onTap: onReRecord,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: c.surfaceElevated,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PhosphorIconsBold.microphone,
                          size: 13.sp,
                          color: c.textSecondary,
                        ),
                        SizedBox(width: 5.w),
                        Text(
                          'Re-record',
                          style: text.bodySmall?.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Send
                GestureDetector(
                  onTap: isLoading ? null : onConfirm,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color: isLoading ? c.surfaceElevated : c.accent,
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: isLoading
                          ? null
                          : [
                              BoxShadow(
                                color: c.accent.withValues(alpha: 0.38),
                                blurRadius: 0,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: isLoading
                        ? SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: c.textTertiary,
                            ),
                          )
                        : Text(
                            'Send  →',
                            style: text.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
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
  }
}

// ─────────────────────────────────────────────────────────────
// Typing mode
// ─────────────────────────────────────────────────────────────

class _TypingPanel extends StatelessWidget {
  final TextEditingController controller;
  final bool hasText;
  final bool isLoading;
  final SageColors c;
  final TextTheme text;
  final double bottomInset;
  final VoidCallback onSend;
  final VoidCallback onMicTap;
  final VoidCallback onClose;

  const _TypingPanel({
    required this.controller,
    required this.hasText,
    required this.isLoading,
    required this.c,
    required this.text,
    required this.bottomInset,
    required this.onSend,
    required this.onMicTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 12.w,
        right: 12.w,
        top: 10.h,
        bottom: bottomInset + 10.h,
      ),

      child: Row(
        children: [
          // Switch back to mic
          GestureDetector(
            onTap: onMicTap,
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                PhosphorIconsBold.microphone,
                size: 18.sp,
                color: c.accent,
              ),
            ),
          ),

          SizedBox(width: 8.w),

          // Text field
          Expanded(
            child: Container(
              constraints: BoxConstraints(maxHeight: 120.h),
              decoration: BoxDecoration(
                color: c.inputFill,
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: c.border.withValues(alpha: 0.3)),
              ),
              child: TextField(
                controller: controller,
                autofocus: true,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                style: text.bodyMedium?.copyWith(color: c.textPrimary),
                cursorColor: c.accent,
                decoration: InputDecoration(
                  hintText: 'Describe how you trade...',
                  hintStyle: text.bodyMedium?.copyWith(color: c.textTertiary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 10.h,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(width: 8.w),

          // Send
          GestureDetector(
            onTap: hasText && !isLoading ? onSend : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: hasText && !isLoading ? c.accent : c.surfaceElevated,
                shape: BoxShape.circle,
              ),
              child: isLoading
                  ? Padding(
                      padding: EdgeInsets.all(10.w),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: c.textTertiary,
                      ),
                    )
                  : Icon(
                      PhosphorIconsBold.arrowUp,
                      size: 18.sp,
                      color: hasText ? Colors.white : c.textTertiary,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_radii.dart';

/// Chat input bar with text field, send button, and voice toggle.
class ChatInputBar extends StatefulWidget {
  final bool isLoading;
  final bool isRecording;
  final bool isTranscribing;
  final ValueChanged<String> onSend;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onCancelRecording;
  final AuraColors c;
  final TextTheme text;
  final String? hintText;

  const ChatInputBar({
    super.key,
    required this.isLoading,
    required this.isRecording,
    required this.isTranscribing,
    required this.onSend,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onCancelRecording,
    required this.c,
    required this.text,
    this.hintText,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    if (_controller.text.trim().isEmpty || widget.isLoading) return;
    HapticFeedback.selectionClick();
    widget.onSend(_controller.text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    // Recording state
    if (widget.isRecording) {
      return _RecordingBar(
        onStop: widget.onStopRecording,
        onCancel: widget.onCancelRecording,
        c: widget.c,
        text: widget.text,
      );
    }

    // Transcribing state
    if (widget.isTranscribing) {
      return _TranscribingBar(c: widget.c, text: widget.text);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: widget.c.surface,
        border: Border(
          top: BorderSide(color: widget.c.border.withValues(alpha: 0.3)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Voice button
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onStartRecording();
              },
              child: Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: widget.c.surfaceElevated,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  PhosphorIconsBold.microphone,
                  size: 20.sp,
                  color: widget.c.textSecondary,
                ),
              ),
            ),

            SizedBox(width: 8.w),

            // Text field
            Expanded(
              child: Container(
                constraints: BoxConstraints(maxHeight: 120.h),
                decoration: BoxDecoration(
                  color: widget.c.inputFill,
                  borderRadius: BorderRadius.circular(
                    context.auraRadii.lg,
                  ),
                  border: Border.all(
                    color: widget.c.border.withValues(alpha: 0.3),
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(),
                  style: widget.text.bodyMedium?.copyWith(
                    color: widget.c.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText ?? 'Talk to Aura...',
                    hintStyle: widget.text.bodyMedium?.copyWith(
                      color: widget.c.textTertiary,
                    ),
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

            // Send button
            GestureDetector(
              onTap: _hasText && !widget.isLoading ? _handleSend : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: _hasText && !widget.isLoading
                      ? widget.c.accent
                      : widget.c.surfaceElevated,
                  shape: BoxShape.circle,
                ),
                child: widget.isLoading
                    ? Padding(
                        padding: EdgeInsets.all(10.w),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: widget.c.textTertiary,
                        ),
                      )
                    : Icon(
                        PhosphorIconsBold.arrowUp,
                        size: 20.sp,
                        color: _hasText ? Colors.white : widget.c.textTertiary,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Recording state bar — shows waveform animation + stop/cancel.
class _RecordingBar extends StatelessWidget {
  final VoidCallback onStop;
  final VoidCallback onCancel;
  final AuraColors c;
  final TextTheme text;

  const _RecordingBar({
    required this.onStop,
    required this.onCancel,
    required this.c,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.accent.withValues(alpha: 0.3))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Cancel
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onCancel();
              },
              child: Icon(PhosphorIconsBold.x, size: 24.sp, color: c.loss),
            ),

            SizedBox(width: 16.w),

            // Recording indicator
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                        width: 10.w,
                        height: 10.w,
                        decoration: BoxDecoration(
                          color: c.loss,
                          shape: BoxShape.circle,
                        ),
                      )
                      .animate(onPlay: (ctrl) => ctrl.repeat())
                      .fadeOut(duration: 800.ms)
                      .then()
                      .fadeIn(duration: 800.ms),
                  SizedBox(width: 10.w),
                  Text(
                    'Recording...',
                    style: text.bodyMedium?.copyWith(color: c.textPrimary),
                  ),
                ],
              ),
            ),

            SizedBox(width: 16.w),

            // Stop & send
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                onStop();
              },
              child: Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: c.accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  PhosphorIconsBold.arrowUp,
                  size: 22.sp,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Transcribing state bar — shows spinner.
class _TranscribingBar extends StatelessWidget {
  final AuraColors c;
  final TextTheme text;

  const _TranscribingBar({required this.c, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border.withValues(alpha: 0.3))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16.w,
              height: 16.w,
              child: CircularProgressIndicator(strokeWidth: 2, color: c.accent),
            ),
            SizedBox(width: 10.w),
            Text(
              'Transcribing...',
              style: text.bodyMedium?.copyWith(color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_radii.dart';
import 'package:aura/features/setup/models/risk_profile.dart';
import 'package:aura/features/setup/presentation/widgets/step_indicator.dart';
import 'package:aura/shared/widgets/aura_button.dart';

/// Step 2 (LLM path) — Anthropic API key + risk profile.
///
/// The bot uses Claude as its trading brain. The user supplies their
/// own Anthropic key (encrypted at rest server-side) and a risk profile
/// to size positions.
class LlmConfigStep extends StatelessWidget {
  final TextEditingController apiKeyController;
  final TextEditingController modelController;
  final TextEditingController dailyCapController;
  final RiskProfile risk;
  final ValueChanged<RiskProfile> onSelectRisk;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final AuraColors c;
  final TextTheme text;

  const LlmConfigStep({
    super.key,
    required this.apiKeyController,
    required this.modelController,
    required this.dailyCapController,
    required this.risk,
    required this.onSelectRisk,
    required this.onNext,
    required this.onBack,
    required this.c,
    required this.text,
  });

  bool get _canContinue => apiKeyController.text.trim().length >= 10;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 28.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.h),

          StepIndicator(current: 1, total: 3, c: c),

          SizedBox(height: 28.h),

          Text('Give Claude\nthe keys', style: text.headlineLarge)
              .animate()
              .fadeIn(duration: 600.ms)
              .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic),

          SizedBox(height: 10.h),

          Text(
            'Your API key never leaves your bot. '
            'Encrypted at rest, decrypted only in memory while trading.',
            style: text.bodyMedium?.copyWith(color: c.textSecondary),
          ).animate().fadeIn(duration: 500.ms, delay: 150.ms),

          SizedBox(height: 24.h),

          // ── API key field ──
          _LabeledField(
            label: 'Anthropic API key',
            hint: 'sk-ant-...',
            controller: apiKeyController,
            obscure: true,
            keyboardType: TextInputType.visiblePassword,
            c: c,
            text: text,
            leadingIcon: PhosphorIconsRegular.key,
          ).animate().fadeIn(duration: 500.ms, delay: 200.ms),

          SizedBox(height: 14.h),

          // ── Model + daily cap (optional, side by side) ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _LabeledField(
                  label: 'Model (optional)',
                  hint: 'claude-haiku-4-5',
                  controller: modelController,
                  c: c,
                  text: text,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _LabeledField(
                  label: 'Daily cap (USD)',
                  hint: '5',
                  controller: dailyCapController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  c: c,
                  text: text,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 500.ms, delay: 250.ms),

          SizedBox(height: 24.h),

          // ── Risk picker ──
          Text(
            'Sizing & risk',
            style: text.labelLarge?.copyWith(
              color: c.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 280.ms),

          SizedBox(height: 12.h),

          Row(
            children: [
              Expanded(
                child: _RiskPill(
                  label: 'Conservative',
                  isSelected: risk == RiskProfile.conservative,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelectRisk(RiskProfile.conservative);
                  },
                  c: c,
                  text: text,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _RiskPill(
                  label: 'Balanced',
                  isSelected: risk == RiskProfile.balanced,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelectRisk(RiskProfile.balanced);
                  },
                  c: c,
                  text: text,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _RiskPill(
                  label: 'Aggressive',
                  isSelected: risk == RiskProfile.aggressive,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelectRisk(RiskProfile.aggressive);
                  },
                  c: c,
                  text: text,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 500.ms, delay: 320.ms),

          SizedBox(height: 32.h),

          AuraButton(
            label: 'Continue',
            onPressed: onNext,
            enabled: _canContinue,
          ).animate().fadeIn(duration: 400.ms, delay: 400.ms),

          SizedBox(height: 12.h),

          Center(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onBack();
              },
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Text(
                  'Back',
                  style: text.titleMedium?.copyWith(
                    color: c.textTertiary,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}

class _LabeledField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final IconData? leadingIcon;
  final AuraColors c;
  final TextTheme text;

  const _LabeledField({
    required this.label,
    required this.hint,
    required this.controller,
    this.obscure = false,
    this.keyboardType,
    this.leadingIcon,
    required this.c,
    required this.text,
  });

  @override
  State<_LabeledField> createState() => _LabeledFieldState();
}

class _LabeledFieldState extends State<_LabeledField> {
  late bool _obscured = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final text = widget.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: text.labelMedium?.copyWith(
            color: c.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12.sp,
          ),
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: widget.controller,
          obscureText: _obscured,
          keyboardType: widget.keyboardType,
          autocorrect: false,
          enableSuggestions: false,
          style: text.bodyMedium?.copyWith(
            color: c.textPrimary,
            fontFamily: widget.obscure ? 'monospace' : null,
          ),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: text.bodyMedium?.copyWith(
              color: c.textSecondary.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: c.surface,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: widget.leadingIcon == null ? 14.w : 8.w,
              vertical: 14.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.auraRadii.md),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.auraRadii.md),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.auraRadii.md),
              borderSide: BorderSide(color: c.accent, width: 1),
            ),
            prefixIcon: widget.leadingIcon != null
                ? Padding(
                    padding: EdgeInsets.only(left: 12.w, right: 8.w),
                    child: Icon(
                      widget.leadingIcon,
                      size: 18.sp,
                      color: c.textSecondary,
                    ),
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            suffixIcon: widget.obscure
                ? GestureDetector(
                    onTap: () => setState(() => _obscured = !_obscured),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: Icon(
                        _obscured
                            ? PhosphorIconsRegular.eye
                            : PhosphorIconsRegular.eyeSlash,
                        size: 18.sp,
                        color: c.textSecondary,
                      ),
                    ),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _RiskPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final AuraColors c;
  final TextTheme text;

  const _RiskPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.c,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 12.h),
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: isSelected ? c.accent.withValues(alpha: 0.12) : c.surface,
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.circular(context.auraRadii.md),
            side: BorderSide(
              color: isSelected
                  ? c.accent.withValues(alpha: 0.45)
                  : c.borderSubtle,
              width: isSelected ? 1.4 : 1,
            ),
          ),
        ),
        child: Text(
          label,
          style: text.labelLarge?.copyWith(
            color: isSelected ? c.accent : c.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12.sp,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:aura/core/models/bot.dart';
import 'package:aura/core/theme/app_colors.dart';
import 'package:aura/core/theme/app_theme.dart';
import 'package:aura/core/utils/bot_validators.dart';

/// Bottom sheet for editing a bot's configuration parameters.
class EditConfigSheet extends StatefulWidget {
  final Bot bot;
  final Future<void> Function(Map<String, dynamic>) onSave;

  const EditConfigSheet({super.key, required this.bot, required this.onSave});

  @override
  State<EditConfigSheet> createState() => _EditConfigSheetState();
}

class _EditConfigSheetState extends State<EditConfigSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _entryThreshold;
  late final TextEditingController _positionSize;
  late final TextEditingController _maxConcurrent;
  late final TextEditingController _cooldown;
  late final TextEditingController _stopLoss;
  late final TextEditingController _profitTarget;
  late final TextEditingController _maxHoldTime;
  late final TextEditingController _cronInterval;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final b = widget.bot;
    _entryThreshold =
        TextEditingController(text: b.entryScoreThreshold.toStringAsFixed(0));
    _positionSize =
        TextEditingController(text: b.positionSizeSOL.toStringAsFixed(1));
    _maxConcurrent =
        TextEditingController(text: '${b.maxConcurrentPositions}');
    _cooldown = TextEditingController(text: '${b.cooldownMinutes}');
    _stopLoss =
        TextEditingController(text: b.stopLossPercent.toStringAsFixed(1));
    _profitTarget =
        TextEditingController(text: b.profitTargetPercent.toStringAsFixed(1));
    _maxHoldTime = TextEditingController(text: '${b.maxHoldTimeMinutes}');
    _cronInterval = TextEditingController(text: '${b.cronIntervalSeconds}');
  }

  @override
  void dispose() {
    _entryThreshold.dispose();
    _positionSize.dispose();
    _maxConcurrent.dispose();
    _cooldown.dispose();
    _stopLoss.dispose();
    _profitTarget.dispose();
    _maxHoldTime.dispose();
    _cronInterval.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final config = <String, dynamic>{
        'entryScoreThreshold':
            double.parse(_entryThreshold.text.trim()),
        'positionSizeSOL':
            double.parse(_positionSize.text.trim()),
        'maxConcurrentPositions':
            int.parse(_maxConcurrent.text.trim()),
        'cooldownMinutes':
            int.parse(_cooldown.text.trim()),
        'stopLossPercent':
            double.parse(_stopLoss.text.trim()),
        'profitTargetPercent':
            double.parse(_profitTarget.text.trim()),
        'maxHoldTimeMinutes':
            int.parse(_maxHoldTime.text.trim()),
        'cronIntervalSeconds':
            int.parse(_cronInterval.text.trim()),
      };
      await widget.onSave(config);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sage;
    final text = context.sageText;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, bottomInset + 24.h),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border(top: BorderSide(color: c.borderSubtle)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
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
            Text(
              'Edit Configuration',
              style: text.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Changes apply next time the bot starts.',
              style: text.bodySmall?.copyWith(color: c.textTertiary),
            ),
            SizedBox(height: 20.h),

            _ConfigField(
              label: 'Entry Threshold (%)',
              controller: _entryThreshold,
              c: c,
              text: text,
              validator: BotValidators.entryThreshold,
            ),
            _ConfigField(
              label: 'Position Size (SOL)',
              controller: _positionSize,
              c: c,
              text: text,
              validator: BotValidators.positionSize,
            ),
            _ConfigField(
              label: 'Max Concurrent',
              controller: _maxConcurrent,
              c: c,
              text: text,
              isInt: true,
              validator: BotValidators.maxConcurrent,
            ),
            _ConfigField(
              label: 'Cooldown (min)',
              controller: _cooldown,
              c: c,
              text: text,
              isInt: true,
              validator: BotValidators.cooldown,
            ),
            _ConfigField(
              label: 'Stop Loss (%)',
              controller: _stopLoss,
              c: c,
              text: text,
              validator: BotValidators.stopLoss,
            ),
            _ConfigField(
              label: 'Profit Target (%)',
              controller: _profitTarget,
              c: c,
              text: text,
              validator: BotValidators.profitTarget,
            ),
            _ConfigField(
              label: 'Max Hold Time (min)',
              controller: _maxHoldTime,
              c: c,
              text: text,
              isInt: true,
              validator: BotValidators.maxHoldTime,
            ),
            _ConfigField(
              label: 'Scan Interval (sec)',
              controller: _cronInterval,
              c: c,
              text: text,
              isInt: true,
              validator: BotValidators.cronInterval,
            ),

            SizedBox(height: 24.h),

            // Save button
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: _saving ? null : _save,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    color: _saving
                        ? c.accent.withValues(alpha: 0.5)
                        : c.accent,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Center(
                    child: _saving
                        ? SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Save Changes',
                            style: text.titleMedium?.copyWith(
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
        ),
      ),
    );
  }
}

/// Single config field row — label on left, text input on right.
class _ConfigField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final SageColors c;
  final TextTheme text;
  final bool isInt;
  final String? Function(String?)? validator;

  const _ConfigField({
    required this.label,
    required this.controller,
    required this.c,
    required this.text,
    this.isInt = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.only(top: 10.h),
              child: Text(
                label,
                style: text.bodyMedium?.copyWith(
                  color: c.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: controller,
              validator: validator,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              keyboardType: TextInputType.numberWithOptions(
                decimal: !isInt,
              ),
              inputFormatters: [
                if (isInt)
                  FilteringTextInputFormatter.digitsOnly
                else
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              textAlign: TextAlign.right,
              style: text.titleMedium?.copyWith(
                color: c.textPrimary,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                filled: true,
                fillColor: c.surface,
                errorMaxLines: 1,
                errorStyle: TextStyle(fontSize: 10.sp, height: 1.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide(color: c.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide(color: c.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide(color: c.accent),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: const BorderSide(color: Colors.redAccent),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

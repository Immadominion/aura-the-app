import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rive/rive.dart';

import 'package:sage/features/onboarding/presentation/widgets/gamepad_clipper.dart';

/// Rive interactive illustration — onboarding page 3.
///
/// Uses raw pointer events (always reliable, no Rive event nodes
/// required in the .riv file):
///   - Tap (no drag)  → selectionClick haptic + SystemSound click
///   - Drag / joystick→ heavyImpact haptic, rate-limited to 80 ms
class RiveIllustration extends StatefulWidget {
  const RiveIllustration({super.key});

  @override
  State<RiveIllustration> createState() => _RiveIllustrationState();
}

class _RiveIllustrationState extends State<RiveIllustration> {
  late final FileLoader _fileLoader;

  Offset? _pointerDownPosition;
  bool _isDragging = false;
  DateTime _lastJoystickHaptic = DateTime.fromMillisecondsSinceEpoch(0);
  static const double _dragThreshold = 6.0;

  @override
  void initState() {
    super.initState();
    _fileLoader = FileLoader.fromAsset(
      'assets/animation/rive/onboarding3.riv',
      riveFactory: Factory.rive,
    );
  }

  @override
  void dispose() {
    _fileLoader.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent e) {
    _pointerDownPosition = e.localPosition;
    _isDragging = false;
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (_pointerDownPosition == null) return;
    final delta = (e.localPosition - _pointerDownPosition!).distance;
    if (delta > _dragThreshold) {
      _isDragging = true;
      final now = DateTime.now();
      if (now.difference(_lastJoystickHaptic).inMilliseconds >= 80) {
        _lastJoystickHaptic = now;
        HapticFeedback.heavyImpact();
      }
    }
  }

  void _onPointerUp(PointerUpEvent e) {
    if (!_isDragging) {
      HapticFeedback.selectionClick();
      SystemSound.play(SystemSoundType.click);
    }
    _pointerDownPosition = null;
    _isDragging = false;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 270.w,
        height: 184.w,
        child: ClipPath(
          clipper: const GamepadClipper(),
          child: ColoredBox(
            color: const Color(0xFF1E2244),
            child: RiveWidgetBuilder(
              fileLoader: _fileLoader,
              builder: (context, state) => switch (state) {
                RiveLoading() => const SizedBox.expand(),
                RiveFailed() => const SizedBox.expand(),
                RiveLoaded() => Listener(
                  onPointerDown: _onPointerDown,
                  onPointerMove: _onPointerMove,
                  onPointerUp: _onPointerUp,
                  child: RiveWidget(
                    controller: state.controller,
                    fit: Fit.cover,
                  ).animate().fadeIn(duration: 600.ms, delay: 100.ms),
                ),
              },
            ),
          ),
        ),
      ),
    );
  }
}

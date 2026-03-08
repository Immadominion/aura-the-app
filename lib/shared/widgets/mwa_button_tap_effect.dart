import 'package:flutter/material.dart';

/// Simple tap effect wrapper — scales down slightly on tap.
///
/// Used across the app for interactive elements that need
/// tactile feedback without a full Material InkWell.
class MWAButtonTapEffect extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const MWAButtonTapEffect({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  State<MWAButtonTapEffect> createState() => _MWAButtonTapEffectState();
}

class _MWAButtonTapEffectState extends State<MWAButtonTapEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}

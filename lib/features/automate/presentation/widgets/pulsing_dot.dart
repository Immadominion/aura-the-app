import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Pulsing dot — animated running state indicator.
class PulsingDot extends StatelessWidget {
  final Color color;
  final double size;

  const PulsingDot({super.key, required this.color, this.size = 7});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.w,
      height: size.w,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

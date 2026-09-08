// lib/features/home/presentation/widgets/pumping_status/pulsing_live_dot.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A pulsing circle used exclusively on the live-pumping card to signal that
/// water is actively being pumped right now.
///
/// The animation loops indefinitely while the widget is in the tree; it is
/// automatically stopped when the widget is disposed.
class PulsingLiveDot extends StatefulWidget {
  const PulsingLiveDot({required this.color, super.key});

  final Color color;

  @override
  State<PulsingLiveDot> createState() => _PulsingLiveDotState();
}

class _PulsingLiveDotState extends State<PulsingLiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _opacity = Tween<double>(begin: 0.4, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _scale = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) => Transform.scale(
        scale: _scale.value,
        child: Container(
          width: 12.w,
          height: 12.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: _opacity.value),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _opacity.value * 0.5),
                blurRadius: 8 * _scale.value,
                spreadRadius: 1 * _scale.value,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

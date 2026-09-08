import 'dart:async';

import 'package:flutter/material.dart';

/// A reusable widget that applies a smooth up-and-down bounce animation
/// to its [child] while [isRefreshing] is true.
///
/// Even if [isRefreshing] flips to false very quickly, the animation
/// is guaranteed to run for at least one full cycle so the user can
/// actually see it.
///
/// Place this anywhere you want the "silent refresh" hint to appear
/// (e.g. next to a title, on an icon, top-right corner…).
class SilentRefreshAnimator extends StatefulWidget {
  const SilentRefreshAnimator({
    required this.isRefreshing,
    required this.child,
    super.key,
    this.animationDuration = const Duration(milliseconds: 400),
    this.offset = 10,
  });

  /// Whether the background refresh is in progress.
  final bool isRefreshing;

  /// The widget that will be animated (usually an icon or a small badge).
  final Widget child;

  /// How long one half-cycle (up or down) takes.
  final Duration animationDuration;

  /// How many logical pixels the child moves up (and down).
  final double offset;

  @override
  State<SilentRefreshAnimator> createState() => _SilentRefreshAnimatorState();
}

class _SilentRefreshAnimatorState extends State<SilentRefreshAnimator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  Timer? _minShowTimer;
  bool _pendingStop = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _offsetAnimation =
        Tween<Offset>(
          begin: Offset.zero,
          end: Offset(0, -widget.offset),
        ).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        );

    if (widget.isRefreshing) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    _pendingStop = false;
    _minShowTimer?.cancel();
    _controller.repeat(reverse: true);
  }

  void _scheduleStop() {
    _pendingStop = true;
    // Guarantee at least one full up-down cycle so the user sees it.
    _minShowTimer?.cancel();
    _minShowTimer = Timer(widget.animationDuration * 2, () {
      if (_pendingStop && mounted) {
        _controller.stop();
        _controller.reset();
      }
    });
  }

  @override
  void didUpdateWidget(covariant SilentRefreshAnimator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRefreshing && !oldWidget.isRefreshing) {
      _startAnimation();
    } else if (!widget.isRefreshing && oldWidget.isRefreshing) {
      _scheduleStop();
    }
  }

  @override
  void dispose() {
    _minShowTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _offsetAnimation.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

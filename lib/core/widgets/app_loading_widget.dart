import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:qatrah/core/extensions/theme_extension.dart';

class AppLoadingWidget extends StatefulWidget {
  const AppLoadingWidget({
    this.color,
    this.trackColor,
    this.waveColor,
    this.size = 40.0,
    this.duration = const Duration(milliseconds: 3000),
    this.curve = Curves.decelerate,
    this.child,
    this.controller,
    super.key,
  });

  final Color? color;
  final Color? trackColor;
  final Color? waveColor;
  final double size;
  final Duration duration;
  final Curve curve;
  final Widget? child;
  final AnimationController? controller;

  @override
  State<AppLoadingWidget> createState() => _AppLoadingWidgetState();
}

class _AppLoadingWidgetState extends State<AppLoadingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller =
        (widget.controller ??
              AnimationController(duration: widget.duration, vsync: this))
          ..repeat();

    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.color ?? context.colorScheme.primary;
    final fallbackTrack =
        widget.trackColor ??
        context.colorScheme.outlineVariant.withValues(alpha: .3);
    final fallbackWave =
        widget.waveColor ??
        context.colorScheme.primaryContainer.withValues(alpha: .4);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Center(
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _AppLoadingPainter(
                    progress: _animation.value,
                    color: primaryColor,
                    trackColor: fallbackTrack,
                    waveColor: fallbackWave,
                    drawWave: widget.child == null,
                  ),
                ),
                if (widget.child != null)
                  SizedBox.square(
                    dimension: widget.size * 0.6,
                    child: Center(child: widget.child),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AppLoadingPainter extends CustomPainter {
  _AppLoadingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.waveColor,
    required this.drawWave,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final Color waveColor;
  final bool drawWave;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.05;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius - (strokeWidth / 2), trackPaint);

    final spinnerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    final startAngle = progress * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - (strokeWidth / 2)),
      startAngle,
      math.pi,
      false,
      spinnerPaint,
    );

    if (drawWave) {
      _paintWave(canvas, size, center, radius * 0.7);
    }
  }

  void _paintWave(Canvas canvas, Size size, Offset center, double waveRadius) {
    final wavePaint = Paint()..color = waveColor;
    final path = Path();

    final clipRect = Rect.fromCircle(center: center, radius: waveRadius);
    canvas
      ..save()
      ..clipPath(Path()..addOval(clipRect));

    final waveAmplitude = size.width * 0.08;
    final verticalShift =
        waveRadius * (1 - (progress * 2)); // Slide up animation

    path.moveTo(center.dx - waveRadius, center.dy + waveRadius);

    for (double i = 0; i <= waveRadius * 2; i++) {
      final x = (center.dx - waveRadius) + i;
      final y =
          center.dy +
          verticalShift +
          (waveAmplitude *
              math.sin((i / waveRadius * math.pi) + (progress * 2 * math.pi)));
      path.lineTo(x, y);
    }

    path
      ..lineTo(center.dx + waveRadius, center.dy + waveRadius)
      ..close();

    canvas
      ..drawPath(path, wavePaint)
      ..restore();
  }

  @override
  bool shouldRepaint(covariant _AppLoadingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.drawWave != drawWave;
  }
}

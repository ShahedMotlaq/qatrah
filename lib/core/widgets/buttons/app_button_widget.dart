import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qatrah/core/extensions/theme_extension.dart';
import 'package:qatrah/core/theme/app_colors.dart';

class AppButton extends StatefulWidget {
  const AppButton({
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.isDisabled = false,
    this.width,
    this.height,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.isOutline = false,
    super.key,
  });

  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final bool isDisabled;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? textColor;
  final Widget? icon;
  final bool isOutline;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveCtrl;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (widget.isLoading) _waveCtrl.repeat();
  }

  @override
  void didUpdateWidget(AppButton old) {
    super.didUpdateWidget(old);
    if (widget.isLoading && !old.isLoading) {
      _waveCtrl.repeat();
    } else if (!widget.isLoading && old.isLoading) {
      _waveCtrl.stop();
      _waveCtrl.reset();
    }
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActionDisabled =
        widget.isDisabled || widget.isLoading || widget.onPressed == null;

    if (widget.isLoading) {
      return _buildWaveLoadingButton(context);
    }

    return widget.isOutline
        ? _buildOutlineButton(context, isActionDisabled)
        : _buildElevatedButton(context, isActionDisabled);
  }

  // ── wave button ──────────────────────────────────────────────────────────

  Widget _buildWaveLoadingButton(BuildContext context) {
    final primary = widget.backgroundColor ?? context.colorScheme.primary;
    final labelColor = widget.textColor ?? AppColors.white;
    final btnHeight = widget.height ?? 52.h;
    final btnWidth = widget.width ?? double.infinity;
    final isOutline = widget.isOutline;

    return SizedBox(
      width: btnWidth,
      height: btnHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ColoredBox(
          color: isOutline ? Colors.transparent : primary,
          child: isOutline
              ? _buildOutlineWave(context, primary, labelColor, btnHeight)
              : _buildFilledWave(context, primary, labelColor),
        ),
      ),
    );
  }

  Widget _buildFilledWave(
    BuildContext context,
    Color primary,
    Color labelColor,
  ) {
    return AnimatedBuilder(
      animation: _waveCtrl,
      builder: (_, child) => CustomPaint(
        painter: _ButtonWavePainter(
          progress: _waveCtrl.value,
          backWaveColor: Colors.white.withValues(alpha: .18),
          frontWaveColor: Colors.white.withValues(alpha: .12),
        ),
        child: child,
      ),
      child: Center(
        child: _buttonLabel(context, labelColor),
      ),
    );
  }

  Widget _buildOutlineWave(
    BuildContext context,
    Color primary,
    Color labelColor,
    double btnHeight,
  ) {
    return Stack(
      children: [
        // outline border
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: primary, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        // wave fill
        AnimatedBuilder(
          animation: _waveCtrl,
          builder: (_, child) => CustomPaint(
            painter: _ButtonWavePainter(
              progress: _waveCtrl.value,
              backWaveColor: primary.withValues(alpha: .18),
              frontWaveColor: primary.withValues(alpha: .12),
            ),
            child: child,
          ),
          child: Center(
            child: _buttonLabel(context, primary),
          ),
        ),
      ],
    );
  }

  Widget _buttonLabel(BuildContext context, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          widget.icon!,
          8.horizontalSpace,
        ],
        Text(
          widget.text,
          style: context.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // ── normal buttons ───────────────────────────────────────────────────────

  Widget _buildElevatedButton(BuildContext context, bool disabled) {
    final primaryColor = widget.backgroundColor ?? context.colorScheme.primary;

    return ElevatedButton(
      onPressed: disabled ? null : widget.onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: widget.textColor ?? AppColors.white,
        disabledBackgroundColor: primaryColor,
        disabledForegroundColor: widget.textColor ?? AppColors.white,
        elevation: 0,
        minimumSize: Size(
          widget.width ?? double.infinity,
          widget.height ?? 52.h,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: _buildButtonContent(context),
    );
  }

  Widget _buildOutlineButton(BuildContext context, bool disabled) {
    final primaryColor = widget.backgroundColor ?? context.colorScheme.primary;

    return OutlinedButton(
      onPressed: disabled ? null : widget.onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        minimumSize: Size(
          widget.width ?? double.infinity,
          widget.height ?? 52.h,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(
          color: disabled ? context.theme.disabledColor : primaryColor,
        ),
      ),
      child: _buildButtonContent(context),
    );
  }

  Widget _buildButtonContent(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          widget.icon!,
          8.horizontalSpace,
        ],
        Text(
          widget.text,
          style: context.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: widget.isOutline
                ? (widget.backgroundColor ?? context.colorScheme.primary)
                : (widget.textColor ?? context.colorScheme.secondary),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Wave painter — draws two sinusoidal waves that fill the lower portion
// ---------------------------------------------------------------------------

class _ButtonWavePainter extends CustomPainter {
  _ButtonWavePainter({
    required this.progress,
    required this.backWaveColor,
    required this.frontWaveColor,
  });

  final double progress;
  final Color backWaveColor;
  final Color frontWaveColor;

  @override
  void paint(Canvas canvas, Size size) {
    // back wave: moves slightly faster, higher amplitude, offset phase
    _drawWave(
      canvas,
      size,
      phase: progress * 2 * math.pi + math.pi * 0.6,
      amplitude: size.height * 0.10,
      waterLevel: size.height * 0.52,
      color: backWaveColor,
    );

    // front wave: main animation
    _drawWave(
      canvas,
      size,
      phase: progress * 2 * math.pi,
      amplitude: size.height * 0.08,
      waterLevel: size.height * 0.56,
      color: frontWaveColor,
    );
  }

  void _drawWave(
    Canvas canvas,
    Size size, {
    required double phase,
    required double amplitude,
    required double waterLevel,
    required Color color,
  }) {
    final paint = Paint()..color = color;
    final path = Path();

    path.moveTo(0, waterLevel);

    // step every 2px — smooth enough, faster than 1px
    for (double x = 0; x <= size.width; x += 2) {
      final angle = (x / size.width * 2 * math.pi) + phase;
      final y = waterLevel + amplitude * math.sin(angle);
      path.lineTo(x, y);
    }

    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ButtonWavePainter old) =>
      old.progress != progress ||
      old.backWaveColor != backWaveColor ||
      old.frontWaveColor != frontWaveColor;
}
